@TestOn('mac-os')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/core/theme/app_theme.dart';
import 'package:kuran_turkce_meal/data/models/surah.dart';
import 'package:kuran_turkce_meal/features/reader/widgets/surah_end_card.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/localized_app.dart';
const _alak = Surah(
  number: 96,
  name: 'Alak',
  meaning: 'Kan Pıhtısı',
  revelationOrder: 1,
  revelationPlace: RevelationPlace.mekke,
  ayahCount: 19,
);

const _kalem = Surah(
  number: 68,
  name: 'Kalem',
  meaning: 'Kalem',
  revelationOrder: 2,
  revelationPlace: RevelationPlace.mekke,
  ayahCount: 52,
);

/// Widget'ı çeviri bağlamıyla çizer ve yüklenmesini bekler.
Future<void> _pump(WidgetTester tester, Widget child) =>
    TestApp.pump(
      tester,
      SingleChildScrollView(child: child),
      theme: AppTheme.light,
    );

void main() async {
  await TestApp.ensureInitialized();

  group('nextSurah sorgusu', () {
    sqfliteFfiInit();
    late Database db;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await db.execute('''
        CREATE TABLE surahs (
          number INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          meaning TEXT NOT NULL,
          revelation_order INTEGER NOT NULL UNIQUE,
          revelation_place TEXT NOT NULL,
          ayah_count INTEGER NOT NULL
        )
      ''');
      // Fâtiha mushafta 1. ama inişte 5.; Alak inişte 1. ama mushafta 96.
      // Bu üçlü, iki sıralamanın gerçekten farklı sonuç verdiğini gösterir.
      for (final s in [
        (1, 'Fâtiha', 5),
        (68, 'Kalem', 2),
        (96, 'Alak', 1),
        (114, 'Nâs', 21),
        (110, 'Nasr', 114),
      ]) {
        await db.insert('surahs', {
          'number': s.$1,
          'name': s.$2,
          'meaning': '-',
          'revelation_order': s.$3,
          'revelation_place': 'mekke',
          'ayah_count': 5,
        });
      }
    });

    tearDown(() async => db.close());

    /// Repository'deki sorgunun aynısı.
    Future<String?> next(int current, {required bool byRevelation}) async {
      final col = byRevelation ? 'revelation_order' : 'number';
      final rows = await db.rawQuery(
        '''
        SELECT * FROM surahs
        WHERE $col > (SELECT $col FROM surahs WHERE number = ?)
        ORDER BY $col ASC LIMIT 1
        ''',
        [current],
      );
      return rows.isEmpty ? null : rows.first['name'] as String?;
    }

    test('iniş sırasında kronolojik sonrakini verir', () async {
      // Alak (1. iniş) -> Kalem (2. iniş)
      expect(await next(96, byRevelation: true), 'Kalem');
    });

    test('mushaf sırasında numaraca sonrakini verir', () async {
      // Fâtiha (mushaf 1) -> Kalem (mushaf 68)
      expect(await next(1, byRevelation: false), 'Kalem');
    });

    test('iki sıralama farklı sonuç verir', () async {
      final byRev = await next(1, byRevelation: true); // Fâtiha 5. iniş
      final byMushaf = await next(1, byRevelation: false);
      expect(byRev, isNot(byMushaf));
    });

    test('son surede null döner', () async {
      // Nasr en son inen (114. iniş)
      expect(await next(110, byRevelation: true), isNull);
      // Nâs mushafın sonu (114)
      expect(await next(114, byRevelation: false), isNull);
    });
  });

  group('SurahEndCard', () {
    testWidgets('sıradaki sureyi ve bitiş ayracını gösterir', (tester) async {
      await _pump(tester, SurahEndCard(
        current: _alak,
        nextSurah: _kalem,
        showRevelationOrder: true,
        onTap: () {},
      ));

      expect(find.text('Alak sûresi bitti'), findsOneWidget);
      expect(find.text('SIRADAKİ'), findsOneWidget);
      expect(find.text('Kalem'), findsOneWidget);
      expect(find.textContaining('2. sırada indi'), findsOneWidget);
    });

    testWidgets('mushaf sırasında mushaf numarasını yazar', (tester) async {
      await _pump(tester, SurahEndCard(
        current: _alak,
        nextSurah: _kalem,
        showRevelationOrder: false,
        onTap: () {},
      ));

      expect(find.textContaining('Mushaf 68'), findsOneWidget);
      expect(find.textContaining('sırada indi'), findsNothing);
    });

    testWidgets('son surede geçiş yerine tamamlama notu gösterir',
        (tester) async {
      await _pump(tester, SurahEndCard(
        current: _alak,
        nextSurah: null,
        showRevelationOrder: true,
        onTap: () {},
      ));

      expect(find.text('SIRADAKİ'), findsNothing);
      expect(find.text('Son inen sûreyi okudunuz'), findsOneWidget);
    });

    testWidgets('dokunmak geçişi tetikler', (tester) async {
      var tapped = false;
      await _pump(tester, SurahEndCard(
        current: _alak,
        nextSurah: _kalem,
        showRevelationOrder: true,
        onTap: () => tapped = true,
      ));

      await tester.tap(find.text('Kalem'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('eşiğe ulaşınca kart onay durumuna geçer', (tester) async {
      // Eşik altında: ilerleme halkası görünür, onay yok.
      await _pump(tester, SurahEndCard(
        current: _alak,
        nextSurah: _kalem,
        showRevelationOrder: true,
        pullProgress: 0.5,
        onTap: () {},
      ));
      expect(find.byIcon(Icons.check_rounded), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Eşikte: onay işareti belirir.
      await _pump(tester, SurahEndCard(
        current: _alak,
        nextSurah: _kalem,
        showRevelationOrder: true,
        pullProgress: 1,
        onTap: () {},
      ));
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('kaydırma başlamadan halka çizilmez', (tester) async {
      await _pump(tester, SurahEndCard(
        current: _alak,
        nextSurah: _kalem,
        showRevelationOrder: true,
        onTap: () {},
      ));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
