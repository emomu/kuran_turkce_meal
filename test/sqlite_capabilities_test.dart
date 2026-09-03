import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Uygulamanın kullandığı SQLite motorunun yetenekleri.
///
/// Bu testler bir regresyon içindir: uygulama önce Android'in sistem
/// SQLite'ını kullanıyordu ve pek çok cihazda FTS5 modülü derlenmemiş
/// olduğu için açılışta "no such module: fts5" hatasıyla duruyordu. Motor
/// paketlenmiş SQLite'a alındı; aşağıdaki testler o motorun arama dizinini
/// gerçekten kurabildiğini doğrular.
void main() {
  setUpAll(sqfliteFfiInit);

  test('FTS5 modülü mevcut ve sanal tablo kurulabiliyor', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);

    // app_database.dart içindeki şemanın birebir aynısı.
    await db.execute('''
      CREATE VIRTUAL TABLE ayahs_fts USING fts5 (
        search_text,
        content = '',
        tokenize = 'unicode61 remove_diacritics 2'
      )
    ''');

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE name = 'ayahs_fts'",
    );
    expect(tables, hasLength(1));
  });

  test('bm25 sıralaması ve MATCH sorgusu çalışıyor', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);

    await db.execute('''
      CREATE VIRTUAL TABLE ayahs_fts USING fts5 (
        search_text,
        content = '',
        tokenize = 'unicode61 remove_diacritics 2'
      )
    ''');

    await db.insert('ayahs_fts', {'rowid': 1, 'search_text': 'rahman rahim'});
    await db.insert('ayahs_fts', {'rowid': 2, 'search_text': 'alemlerin rabbi'});

    // Sorgu quran_repository.dart'takiyle aynı biçimde kurulur.
    final rows = await db.rawQuery(
      'SELECT rowid FROM ayahs_fts WHERE ayahs_fts MATCH ? '
      'ORDER BY bm25(ayahs_fts)',
      ['rahman*'],
    );

    expect(rows, hasLength(1));
    expect(rows.first['rowid'], 1);
  });

  test('unicode61 belirteçleyicisi aksanları eşitler', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);

    await db.execute('''
      CREATE VIRTUAL TABLE t USING fts5 (
        txt,
        tokenize = 'unicode61 remove_diacritics 2'
      )
    ''');
    await db.insert('t', {'txt': 'adâlet'});

    // Aksansız arama aksanlı metni bulmalı — Türkçe aramanın dayandığı
    // davranış budur.
    final rows = await db.rawQuery(
      'SELECT rowid FROM t WHERE t MATCH ?',
      ['adalet'],
    );
    expect(rows, hasLength(1));
  });
}
