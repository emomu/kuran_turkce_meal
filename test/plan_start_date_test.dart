@TestOn('mac-os')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/data/db/app_database.dart';
import 'package:kuran_turkce_meal/data/models/plan_schedule.dart';
import 'package:kuran_turkce_meal/data/models/reading_plan.dart';
import 'package:kuran_turkce_meal/data/repositories/progress_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kuran_turkce_meal/core/providers/app_providers.dart';
import 'package:kuran_turkce_meal/features/plans/providers/plans_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Plan başlangıç tarihinin saklanmasını ve "bugünden devam et" davranışını
/// gerçek depolar üzerinde sınar.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  AppDatabase.factoryOverride = databaseFactoryFfi;
  AppDatabase.pathOverride = Directory.systemTemp
      .createTempSync('plan_start_db_')
      .path;

  late ProgressRepository repo;

  setUp(() async {
    await AppDatabase.instance.close();
    // Silinecek dosya pathOverride'tan türetilir. `getDatabasesPath()`
    // override'ı yok sayıp .dart_tool altındaki varsayılan dizini döndürüyor
    // — ölçüldü; o yol silinseydi gerçek veritabanı hiç temizlenmez ve bir
    // testin tamamladığı günler sonrakine taşardı.
    await databaseFactory.deleteDatabase(
      p.join(AppDatabase.pathOverride!, 'kuran.db'),
    );
    SharedPreferences.setMockInitialValues({});
    repo = ProgressRepository(
      AppDatabase.instance,
      await SharedPreferences.getInstance(),
    );
  });

  group('Plan başlangıç tarihi', () {
    test('hiç başlatılmamış plan null döner', () {
      expect(repo.planStartDate('mushaf_30'), isNull);
    });

    test('yazılan tarih gün başına indirgenmiş olarak geri okunur', () async {
      await repo.setPlanStartDate('mushaf_30', DateTime(2026, 1, 5, 17, 42));
      expect(repo.planStartDate('mushaf_30'), DateTime(2026, 1, 5));
    });

    test('planlar birbirinin tarihini ezmez', () async {
      await repo.setPlanStartDate('mushaf_30', DateTime(2026, 1, 5));
      await repo.setPlanStartDate('mushaf_90', DateTime(2026, 2, 9));
      expect(repo.planStartDate('mushaf_30'), DateTime(2026, 1, 5));
      expect(repo.planStartDate('mushaf_90'), DateTime(2026, 2, 9));
    });

    test('ensurePlanStarted yalnızca ilk çağrıda yazar', () async {
      await repo.ensurePlanStarted('mushaf_30', DateTime(2026, 1, 5));
      // İkinci tamamlama başlangıcı ileri kaydırsaydı, kullanıcı her gün
      // okudukça plan sürekli "1. gün"de kalırdı.
      await repo.ensurePlanStarted('mushaf_30', DateTime(2026, 1, 20));
      expect(repo.planStartDate('mushaf_30'), DateTime(2026, 1, 5));
    });

    test('setPlanStartDate mevcut tarihi ezer', () async {
      await repo.setPlanStartDate('mushaf_30', DateTime(2026, 1, 5));
      await repo.setPlanStartDate('mushaf_30', DateTime(2026, 3, 1));
      expect(repo.planStartDate('mushaf_30'), DateTime(2026, 3, 1));
    });
  });

  group('Bugünden devam et', () {
    test('başlangıç sıfırlanınca tamamlanan günler korunur', () async {
      await repo.markDayComplete('mushaf_30', 1);
      await repo.markDayComplete('mushaf_30', 2);
      await repo.markDayComplete('mushaf_30', 3);
      await repo.setPlanStartDate('mushaf_30', DateTime(2026, 1, 1));

      // "Bugünden devam et" yalnızca tarihi taşır.
      await repo.setPlanStartDate('mushaf_30', DateTime(2026, 2, 1));

      expect(await repo.completedDayCount('mushaf_30'), 3);
      expect(await repo.completedDays('mushaf_30'), {1, 2, 3});
    });

    test('gecikme sıfırlanır ama ilerleme sayılmaya devam eder', () async {
      // 1 Ocak'ta başlayıp 3 gün okumuş, 20 Ocak'ta bakıyor: 17 gün geride.
      final before = PlanSchedule.from(
        startDate: DateTime(2026, 1, 1),
        today: DateTime(2026, 1, 20),
        completedDays: 3,
        dayCount: 30,
      );
      expect(before.daysBehind, 17);

      // Bugünden devam edince aynı 3 gün korunur ve borç kalmaz.
      final after = PlanSchedule.from(
        startDate: DateTime(2026, 1, 20),
        today: DateTime(2026, 1, 20),
        completedDays: 3,
        dayCount: 30,
      );
      expect(after.currentDay, 1);
      expect(after.isBehind, isFalse);
      expect(after.completedDays, 3);
    });
  });

  group('PlanActions', () {
    /// Sağlayıcıları gerçek depolara bağlar; plan dökümü sahtelenir çünkü
    /// asset okuması bu testin konusu değil.
    Future<ProviderContainer> makeContainer() async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
          planDaysProvider.overrideWith((ref, id) async => const <PlanDay>[]),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('ilk gün tamamlanınca plan kendiliğinden başlar', () async {
      final container = await makeContainer();
      expect(
        container.read(progressRepositoryProvider).planStartDate('mushaf_30'),
        isNull,
      );

      await container
          .read(planActionsProvider)
          .toggleDay('mushaf_30', 1, false);

      final start = container
          .read(progressRepositoryProvider)
          .planStartDate('mushaf_30');
      expect(start, isNotNull, reason: 'takvim bağı ilk tamamlamada kurulur');
      expect(start, startOfDay(DateTime.now()));
    });

    test('günün işaretini kaldırmak planı başlatmaz', () async {
      final container = await makeContainer();
      // Yanlışlıkla işaretlenmiş bir günü geri almak plan başlatma niyeti
      // değildir; tarih yazılırsa kullanıcı hiç okumadan "1. gün"e düşer.
      await container.read(planActionsProvider).toggleDay('mushaf_30', 1, true);
      expect(
        container.read(progressRepositoryProvider).planStartDate('mushaf_30'),
        isNull,
      );
    });

    test('restartFromToday tarihi bugüne çeker, günleri korur', () async {
      final container = await makeContainer();
      final repo = container.read(progressRepositoryProvider);

      await repo.markDayComplete('mushaf_30', 1);
      await repo.markDayComplete('mushaf_30', 2);
      await repo.setPlanStartDate('mushaf_30', DateTime(2026, 1, 1));

      await container.read(planActionsProvider).restartFromToday('mushaf_30');

      expect(repo.planStartDate('mushaf_30'), startOfDay(DateTime.now()));
      expect(await repo.completedDays('mushaf_30'), {1, 2});
    });
  });

  group('completionDates', () {
    test('boş planda boş liste', () async {
      expect(await repo.completionDates('mushaf_30'), isEmpty);
    });

    test('tamamlanan günleri zamanlarıyla döndürür', () async {
      await repo.markDayComplete('mushaf_30', 1);
      await repo.markDayComplete('mushaf_30', 2);

      final rows = await repo.completionDates('mushaf_30');
      expect(rows.length, 2);
      expect(rows.map((r) => r.dayIndex).toSet(), {1, 2});
      // completed_at markDayComplete tarafından yazılıyor; bugüne düşmeli.
      for (final r in rows) {
        expect(startOfDay(r.completedAt), startOfDay(DateTime.now()));
      }
    });

    test('işareti kaldırılan gün listeden düşer', () async {
      await repo.markDayComplete('mushaf_30', 1);
      await repo.markDayComplete('mushaf_30', 2);
      await repo.markDayIncomplete('mushaf_30', 1);

      final rows = await repo.completionDates('mushaf_30');
      expect(rows.map((r) => r.dayIndex).toList(), [2]);
    });

    test('planlar birbirinin kaydını göstermez', () async {
      await repo.markDayComplete('mushaf_30', 1);
      await repo.markDayComplete('mushaf_90', 7);

      expect((await repo.completionDates('mushaf_30')).single.dayIndex, 1);
      expect((await repo.completionDates('mushaf_90')).single.dayIndex, 7);
    });
  });
}
