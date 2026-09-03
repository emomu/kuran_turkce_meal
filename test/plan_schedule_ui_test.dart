import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/core/providers/app_providers.dart';
import 'package:kuran_turkce_meal/core/theme/app_theme.dart';
import 'package:kuran_turkce_meal/data/models/plan_schedule.dart';
import 'package:kuran_turkce_meal/data/models/reading_plan.dart';
import 'package:kuran_turkce_meal/features/plans/providers/plans_provider.dart';
import 'package:kuran_turkce_meal/features/plans/view/plan_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/localized_app.dart';

/// Plan detayındaki takvim satırının ne zaman ve nasıl göründüğünü sınar.
void main() async {
  await TestApp.ensureInitialized();
  setUp(TestApp.reset);

  /// Tek günlük sahte plan dökümü — ekranın liste kurabilmesi için yeter.
  List<PlanDay> fakeDays() => const [
    PlanDay(index: 1, ayahIds: [1, 2, 3], label: 'Alak 1–3', isCompleted: true),
    PlanDay(
      index: 2,
      ayahIds: [4, 5, 6],
      label: 'Alak 4–6',
      isCompleted: false,
    ),
  ];

  Future<void> pumpDetail(
    WidgetTester tester, {
    required PlanSchedule? schedule,
    int completed = 1,
    Brightness brightness = Brightness.light,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            planDaysProvider.overrideWith((ref, id) async => fakeDays()),
            planProgressProvider.overrideWith((ref, id) async => completed),
            planScheduleProvider.overrideWith((ref, id) async => schedule),
          ],
          child: TestApp.wrap(
            const PlanDetailScreen(planId: 'mushaf_30'),
            theme: brightness == Brightness.light
                ? AppTheme.light
                : AppTheme.dark,
          ),
        ),
      );
      await tester.pump();
    });
    await tester.pumpAndSettle();
  }

  testWidgets('başlatılmamış planda takvim bilgisi hiç çizilmez', (
    tester,
  ) async {
    await pumpDetail(tester, schedule: null, completed: 0);

    expect(find.textContaining('gün'), findsWidgets, reason: 'liste dolu');
    expect(find.textContaining('Bugün'), findsNothing);
    expect(find.textContaining('geride'), findsNothing);
    expect(find.text('Bugünden devam et'), findsNothing);
  });

  testWidgets('takvimdeyken gün numarası görünür, gecikme görünmez', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      schedule: PlanSchedule.from(
        startDate: DateTime(2026, 1, 1),
        today: DateTime(2026, 1, 5),
        completedDays: 5,
        dayCount: 30,
      ),
      completed: 5,
    );

    expect(find.text('Bugün 5. gün'), findsOneWidget);
    expect(find.textContaining('geride'), findsNothing);
    // Takvimdeyken telafi eylemi sunulmaz; gösterilecek bir sorun yok.
    expect(find.text('Bugünden devam et'), findsNothing);
  });

  testWidgets('öndeyken de öndelik ayrıca vurgulanmaz', (tester) async {
    await pumpDetail(
      tester,
      schedule: PlanSchedule.from(
        startDate: DateTime(2026, 1, 1),
        today: DateTime(2026, 1, 3),
        completedDays: 9,
        dayCount: 30,
      ),
      completed: 9,
    );

    expect(find.text('Bugün 3. gün'), findsOneWidget);
    expect(find.textContaining('önde'), findsNothing);
    expect(find.textContaining('geride'), findsNothing);
  });

  testWidgets('gerideyken gecikme ve telafi eylemi görünür', (tester) async {
    await pumpDetail(
      tester,
      schedule: PlanSchedule.from(
        startDate: DateTime(2026, 1, 1),
        today: DateTime(2026, 1, 10),
        completedDays: 7,
        dayCount: 30,
      ),
      completed: 7,
    );

    expect(find.text('Bugün 10. gün'), findsOneWidget);
    expect(find.text('3 gün geride'), findsOneWidget);
    expect(find.text('Bugünden devam et'), findsOneWidget);
  });

  testWidgets('plan süresi dolunca gün sayacı yerine bitiş metni çıkar', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      schedule: PlanSchedule.from(
        startDate: DateTime(2026, 1, 1),
        today: DateTime(2026, 3, 1),
        completedDays: 30,
        dayCount: 30,
      ),
      completed: 30,
    );

    expect(find.text('Plan süresi doldu'), findsOneWidget);
    expect(find.textContaining('Bugün 60'), findsNothing);
    // Planı bitiren kullanıcıya gecikme gösterilmez.
    expect(find.textContaining('geride'), findsNothing);
  });

  testWidgets('telafi eylemi onay ister ve vazgeçilebilir', (tester) async {
    await pumpDetail(
      tester,
      schedule: PlanSchedule.from(
        startDate: DateTime(2026, 1, 1),
        today: DateTime(2026, 1, 10),
        completedDays: 7,
        dayCount: 30,
      ),
      completed: 7,
    );

    await tester.tap(find.text('Bugünden devam et'));
    await tester.pumpAndSettle();

    expect(find.text('Bugünden devam edilsin mi?'), findsOneWidget);
    // Onay metni "ilerlemem silinecek mi" sorusunu açıkça yanıtlamalı.
    expect(find.textContaining('silinmez'), findsOneWidget);

    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(find.text('Bugünden devam edilsin mi?'), findsNothing);
  });

  testWidgets('koyu temada da çizilir', (tester) async {
    await pumpDetail(
      tester,
      schedule: PlanSchedule.from(
        startDate: DateTime(2026, 1, 1),
        today: DateTime(2026, 1, 10),
        completedDays: 7,
        dayCount: 30,
      ),
      completed: 7,
      brightness: Brightness.dark,
    );

    expect(find.text('Bugün 10. gün'), findsOneWidget);
    expect(find.text('3 gün geride'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
