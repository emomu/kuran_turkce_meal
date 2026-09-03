@TestOn('mac-os')
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/core/providers/app_providers.dart';
import 'package:kuran_turkce_meal/core/theme/app_theme.dart';
import 'package:kuran_turkce_meal/data/db/app_database.dart';
import 'package:kuran_turkce_meal/data/models/ayah.dart';
import 'package:kuran_turkce_meal/data/models/reader_preferences.dart';
import 'package:kuran_turkce_meal/data/models/user_marks.dart';
import 'package:kuran_turkce_meal/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:kuran_turkce_meal/features/home/providers/home_provider.dart';
import 'package:kuran_turkce_meal/features/reader/providers/reader_provider.dart';
import 'package:kuran_turkce_meal/features/reader/widgets/ayah_tile.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/localized_app.dart';

/// Gerçek veritabanı üzerinde durum eşitlemesini sınar.
///
/// Belirti: kullanıcı vurgu yapıyor ama ekranda görünmüyor, uygulama yeniden
/// açılınca geliyor. Kök neden, yazma sonrası ilgili sağlayıcıların
/// tazelenmemesiydi.
void main() async {
  await TestApp.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Uygulama artık paketlenmiş SQLite'ı ve `path_provider` ile bulunan bir
  // dizini kullanıyor. Testte platform kanalı yok; motor ve yol doğrudan
  // verilir, böylece veritabanı bellekte açılır.
  AppDatabase.factoryOverride = databaseFactoryFfi;
  // Her test dosyası kendi veritabanı dizinini kullanır. Test dosyaları
  // paralel çalışıyor; ortak bir dosyayı paylaştıklarında SQLite
  // "disk I/O error" verip rastgele testleri düşürüyordu.
  AppDatabase.pathOverride = Directory.systemTemp
      .createTempSync('state_sync_db_')
      .path;

  late ProviderContainer container;

  setUp(() async {
    // Her test taze bir veritabanıyla başlar; singleton kapatılıp dosya
    // silinmezse önceki testin verisi taşar.
    await AppDatabase.instance.close();
    final path = p.join(await getDatabasesPath(), 'kuran.db');
    await databaseFactory.deleteDatabase(path);

    // İlerleme deposu plan başlangıç tarihleri için SharedPreferences de
    // kullanıyor; testte platform kanalı olmadığı için bellek içi bir
    // örnekle beslenir.
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
      ],
    );

    // Asset'ler test ortamında okunamadığı için şema elle doldurulur;
    // yabancı anahtar kısıtı gerçek ayet kaydı ister.
    final db = await AppDatabase.instance.database;
    await db.insert('surahs', conflictAlgorithm: ConflictAlgorithm.replace, {
      'number': 96,
      'name': 'Alak',
      'meaning': 'Kan Pıhtısı',
      'revelation_order': 1,
      'revelation_place': 'mekke',
      'ayah_count': 19,
    });
    for (var n = 1; n <= 19; n++) {
      await db.insert('ayahs', conflictAlgorithm: ConflictAlgorithm.replace, {
        'id': 6186 + n,
        'surah_number': 96,
        'ayah_number': n,
        'end_ayah_number': n,
        'translation': '$n. ayet metni',
      });
    }
  });

  tearDown(() async {
    container.dispose();
    await AppDatabase.instance.close();
  });

  group('İşaret eşitlemesi', () {
    test('vurgu eklenince durum anında güncellenir', () async {
      final notifier = container.read(surahMarksProvider(96).notifier);

      // Yükleme bitene kadar bekle.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(container.read(surahMarksProvider(96)), isEmpty);

      await notifier.setHighlight(6187, 0xFFF5D77E);

      final marks = container.read(surahMarksProvider(96));
      expect(
        marks[6187]?.highlightColor,
        0xFFF5D77E,
        reason: 'Vurgu beklemeden duruma yansımalı',
      );
    });

    test('vurgu Kayıtlar listesini de tazeler', () async {
      final notifier = container.read(surahMarksProvider(96).notifier);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Kayıtlar sekmesini bir kez okut (önbelleğe alınsın).
      await container.read(savedEntriesProvider(SavedTab.highlights).future);

      await notifier.setHighlight(6187, 0xFF9FD4AE);

      // Yazma sonrası liste geçersiz kılınmış olmalı: yeniden okunduğunda
      // yeni vurgu görünür.
      final entries = await container.read(
        savedEntriesProvider(SavedTab.highlights).future,
      );
      expect(
        entries.any((e) => e.ayah.id == 6187),
        isTrue,
        reason: 'Kayıtlar listesi yeni vurguyu göstermeli',
      );
    });

    test('yer imi kaldırılınca listeden düşer', () async {
      final notifier = container.read(surahMarksProvider(96).notifier);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      await notifier.toggleBookmark(6187);
      var entries = await container.read(
        savedEntriesProvider(SavedTab.bookmarks).future,
      );
      expect(entries.any((e) => e.ayah.id == 6187), isTrue);

      await notifier.toggleBookmark(6187);
      entries = await container.read(
        savedEntriesProvider(SavedTab.bookmarks).future,
      );
      expect(entries.any((e) => e.ayah.id == 6187), isFalse);
    });
  });

  group('İlerleme eşitlemesi', () {
    test('ilerleme kaydı ana ekran sağlayıcılarını tazeler', () async {
      // Ana ekranı bir kez okut.
      final before = await container.read(surahProgressProvider.future);
      expect(before[96], isNull);

      await container.read(saveProgressProvider)(96, 12);

      final after = await container.read(surahProgressProvider.future);
      expect(
        after[96],
        12,
        reason: 'Okuma ekranından çıkınca çubuk güncel olmalı',
      );

      final last = await container.read(lastReadProvider.future);
      expect(last?.surah.number, 96);
      expect(last?.ayahNumber, 12);
    });
  });

  group('AyahTile vurgu gösterimi', () {
    testWidgets('vurgu rengi ayete uygulanır', (tester) async {
      const ayah = Ayah(
        id: 1,
        surahNumber: 96,
        ayahNumber: 1,
        translation: 'Yaratan Rabbinin adıyla oku',
      );

      await TestApp.pump(
        tester,
        AyahTile(
          ayah: ayah,
          prefs: const ReaderPreferences(),
          mark: AyahMark(
            ayahId: 1,
            highlightColor: 0xFFF5D77E,
            updatedAt: DateTime(2026),
          ),
          onTap: () {},
          onLongPress: () {},
        ),
        theme: AppTheme.light,
      );

      // Vurgulu metin, zemini olan bir kapsayıcı içinde çizilir.
      final decorated = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(AyahTile),
          matching: find.byType(Container),
        ),
      );
      expect(
        decorated.any((c) {
          final d = c.decoration;
          return d is BoxDecoration &&
              d.color != null &&
              d.color!.a > 0 &&
              d.color!.r > 0.8;
        }),
        isTrue,
        reason: 'Sarı vurgu zemini çizilmeli',
      );
    });
  });
}
