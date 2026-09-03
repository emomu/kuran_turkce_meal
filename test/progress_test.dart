@TestOn('mac-os')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/data/models/ayah.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Okuma ekranındaki blok→ayet dönüşümünün aynısı.
///
/// Liste indeksi ayet numarasına eşit değildir: birleşik meallerde bir blok
/// birden çok ayeti kapsar, sonraki bloklar kayar.
int ayahNumberForBlock(List<Ayah> ayahs, int listIndex) {
  final blockIndex = (listIndex - 1).clamp(0, ayahs.length - 1);
  return ayahs[blockIndex].endAyahNumber;
}

void main() {
  // Alak'ın yapısı: 15-16 birleşik, diğerleri tekil.
  final ayahs = <Ayah>[
    for (var n = 1; n <= 14; n++)
      Ayah(id: n, surahNumber: 96, ayahNumber: n, translation: '$n'),
    const Ayah(
      id: 15,
      surahNumber: 96,
      ayahNumber: 15,
      endAyahNumber: 16,
      translation: '15-16',
    ),
    for (var n = 17; n <= 19; n++)
      Ayah(id: n, surahNumber: 96, ayahNumber: n, translation: '$n'),
  ];

  group('İlerleme ayet numarası', () {
    test('birleşik blok öncesinde indeks ile numara örtüşür', () {
      // Liste indeksi 1 = ilk ayet.
      expect(ayahNumberForBlock(ayahs, 1), 1);
      expect(ayahNumberForBlock(ayahs, 14), 14);
    });

    test('birleşik blokta aralığın son ayeti kaydedilir', () {
      // 15. blok 15-16'yı kapsar; ikisi de okunmuş sayılır.
      expect(ayahNumberForBlock(ayahs, 15), 16);
    });

    test('birleşik bloktan sonra kayma telafi edilir', () {
      // Liste indeksi 16 artık 17. ayete denk gelir — ham indeks
      // kullanılsaydı 16 kaydedilir, ilerleme geride kalırdı.
      expect(ayahNumberForBlock(ayahs, 16), 17);
      expect(ayahNumberForBlock(ayahs, 18), 19);
    });

    test('son blok surenin son ayetini verir', () {
      expect(ayahNumberForBlock(ayahs, ayahs.length), 19);
    });

    test('bitiş kartı indeksi son ayete sabitlenir', () {
      // Liste sonundaki geçiş kartı (indeks = ayahs.length + 1) taşmaya
      // yol açmamalı.
      expect(ayahNumberForBlock(ayahs, ayahs.length + 1), 19);
    });

    test('başlık indeksi ilk ayete sabitlenir', () {
      expect(ayahNumberForBlock(ayahs, 0), 1);
    });
  });

  group('İlerleme kaydı', () {
    sqfliteFfiInit();
    late Database db;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await db.execute('''
        CREATE TABLE reading_progress (
          surah_number INTEGER PRIMARY KEY,
          last_ayah INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
    });

    tearDown(() async => db.close());

    Future<void> save(int surah, int ayah) => db.insert(
          'reading_progress',
          {
            'surah_number': surah,
            'last_ayah': ayah,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

    Future<int?> read(int surah) async {
      final rows = await db.query('reading_progress',
          where: 'surah_number = ?', whereArgs: [surah]);
      return rows.isEmpty ? null : rows.first['last_ayah'] as int;
    }

    test('aynı sureye tekrar yazınca üzerine yazılır', () async {
      await save(96, 5);
      await save(96, 12);
      expect(await read(96), 12);
    });

    test('sure sonuna kadar okunduğunda tam sayı kaydedilir', () async {
      // Geçiş sırasında surenin ayet sayısı kaydedilir; ilerleme %100 olur.
      await save(96, 19);
      expect(await read(96), 19);
    });
  });
}
