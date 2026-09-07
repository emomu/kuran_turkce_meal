@TestOn('mac-os')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/data/db/search_normalizer.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// FTS5 aramasının gerçek SQLite üzerinde çalıştığını doğrular.
///
/// Uygulamanın şemasını birebir kurar ve normalleştiricinin ürettiği sorguyu
/// aynı şekilde çalıştırır; böylece Türkçe karakter davranışı yalnızca Dart
/// tarafında değil, veritabanı tokenizer'ıyla birlikte sınanır.
void main() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;

  late Database db;

  setUp(() async {
    db = await factory.openDatabase(inMemoryDatabasePath);

    await db.execute('''
      CREATE TABLE ayahs (
        id INTEGER PRIMARY KEY,
        surah_number INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        translation TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE VIRTUAL TABLE ayahs_fts USING fts5 (
        search_text,
        content = '',
        tokenize = 'unicode61 remove_diacritics 2'
      )
    ''');

    Future<void> insert(int id, String translation) async {
      await db.insert('ayahs', {
        'id': id,
        'surah_number': 1,
        'ayah_number': id,
        'translation': translation,
      });
      await db.insert('ayahs_fts', {
        'rowid': id,
        'search_text': SearchNormalizer.normalize(translation),
      });
    }

    await insert(1, 'Allah âdil olandır ve adâleti emreder.');
    await insert(2, 'Rahmet ve merhamet sahibidir.');
    await insert(3, 'Işık karanlığı giderir.');
    await insert(4, 'Sabredenlere müjde ve sabır vardır.');
  });

  tearDown(() async => db.close());

  Future<List<int>> search(String query) async {
    final fts = SearchNormalizer.toFtsQuery(query);
    if (fts == null) return [];
    final rows = await db.rawQuery(
      '''
      SELECT a.id FROM ayahs_fts f
      JOIN ayahs a ON a.id = f.rowid
      WHERE ayahs_fts MATCH ?
      ORDER BY bm25(ayahs_fts), a.id
      ''',
      [fts],
    );
    return rows.map((r) => r['id']! as int).toList();
  }

  group('FTS5 araması', () {
    test('şapkasız sorgu şapkalı metni bulur', () async {
      expect(await search('adalet'), contains(1));
      expect(await search('adil'), contains(1));
    });

    test('büyük harfli Türkçe sorgu eşleşir', () async {
      // "IŞIK" -> "ışık" dönüşümü doğru yapılmazsa bu test kalır.
      expect(await search('IŞIK'), contains(3));
      expect(await search('ışık'), contains(3));
    });

    test('önek eşleşmesi çalışır', () async {
      expect(await search('rahm'), contains(2));
      expect(await search('sabred'), contains(4));
    });

    test('iki kelime AND ile bağlanır', () async {
      expect(await search('rahmet merhamet'), contains(2));
      // Biri eşleşip diğeri eşleşmezse sonuç dönmemeli.
      expect(await search('rahmet ışık'), isEmpty);
    });

    test('meal metninde geçen kelime bulunur', () async {
      expect(await search('sabır'), contains(4));
    });

    test('eşleşmeyen sorgu boş döner', () async {
      expect(await search('bulunmayankelime'), isEmpty);
    });

    test('özel karakterler sorguyu bozmaz', () async {
      // Kullanıcı tırnak veya yıldız yazarsa FTS sözdizim hatası vermemeli.
      expect(await search('"rahmet"'), contains(2));
      expect(await search('rahmet*'), contains(2));
    });

    test('Türkçe bağlaçlar sonucu boşaltmaz', () async {
      // "ve" ayet metninde tek başına token olarak geçse de geçmese de,
      // bağlaç yüzünden sonuç kaybolmamalı.
      expect(await search('rahmet ve merhamet'), contains(2));
      expect(await search('sabredenlere ile müjde'), contains(4));
    });

    test('FTS işleçleri terim olarak aranmaz', () async {
      expect(await search('rahmet AND'), contains(2));
      expect(await search('rahmet OR'), contains(2));
    });

    test('yalnızca bağlaçtan ibaret sorgu yine de aranır', () async {
      // Kullanıcı gerçekten "ve" kelimesini arıyorsa boş dönmemeli;
      // elenecek başka terim olmadığında bağlaç terim olarak kullanılır.
      expect(SearchNormalizer.toFtsQuery('ve'), isNotNull);
    });
  });
}
