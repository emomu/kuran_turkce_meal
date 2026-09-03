import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/user_marks.dart';

/// Kullanıcının ayetlere iliştirdiği işaretler: yer imi, vurgu rengi, not.
///
/// Yazma işlemleri her zaman yerel veritabanına yapılır; Firebase senkronu
/// bunun üstünde ayrı bir katman olarak çalışır (bkz. SyncService). Böylece
/// internet yokken de işaretleme çalışır.
class MarksRepository {
  MarksRepository(this._db);
  final AppDatabase _db;

  /// Bir surenin ayetlerine ait tüm işaretleri tek sorguda çeker.
  ///
  /// Okuma ekranı açılırken çağrılır; ayet başına ayrı sorgu atmak yerine
  /// tek seferde alınıp bellekte haritalanır.
  Future<Map<int, AyahMark>> marksForSurah(int surahNumber) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT m.* FROM ayah_marks m
      JOIN ayahs a ON a.id = m.ayah_id
      WHERE a.surah_number = ?
      ''',
      [surahNumber],
    );
    return {
      for (final row in rows)
        row['ayah_id']! as int: AyahMark.fromMap(row),
    };
  }

  /// Verilen kimliklerdeki işaretleri tek sorguda çeker.
  ///
  /// Okuma planı günleri mushafta bitişik olmayan ayetleri kapsayabilir
  /// (iniş sırası), bu yüzden aralık değil liste sorgulanır.
  Future<Map<int, AyahMark>> marksForIds(List<int> ids) async {
    if (ids.isEmpty) return const {};
    final db = await _db.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await db.query(
      'ayah_marks',
      where: 'ayah_id IN ($placeholders)',
      whereArgs: ids,
    );
    return {
      for (final row in rows)
        row['ayah_id']! as int: AyahMark.fromMap(row),
    };
  }

  Future<AyahMark?> mark(int ayahId) async {
    final db = await _db.database;
    final rows = await db.query(
      'ayah_marks',
      where: 'ayah_id = ?',
      whereArgs: [ayahId],
      limit: 1,
    );
    return rows.isEmpty ? null : AyahMark.fromMap(rows.first);
  }

  /// İşareti kaydeder. Üç alanın da boşaldığı kayıt tablodan silinir —
  /// kullanıcı yer imini kaldırdığında ölü satır bırakmamak için.
  Future<void> save(AyahMark mark) async {
    final db = await _db.database;
    if (mark.isEmpty) {
      await db.delete(
        'ayah_marks',
        where: 'ayah_id = ?',
        whereArgs: [mark.ayahId],
      );
      return;
    }
    await db.insert(
      'ayah_marks',
      mark.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Yer imi durumunu tersine çevirir ve yeni durumu döndürür.
  Future<AyahMark> toggleBookmark(int ayahId) async {
    final existing = await mark(ayahId) ??
        AyahMark(ayahId: ayahId, updatedAt: DateTime.now());
    final updated = existing.copyWith(isBookmarked: !existing.isBookmarked);
    await save(updated);
    return updated;
  }

  /// Vurgu rengini ayarlar. [color] null verilirse vurgu kaldırılır.
  Future<AyahMark> setHighlight(int ayahId, int? color) async {
    final existing = await mark(ayahId) ??
        AyahMark(ayahId: ayahId, updatedAt: DateTime.now());
    final updated = existing.copyWith(highlightColor: () => color);
    await save(updated);
    return updated;
  }

  /// Notu kaydeder. Boş metin verilirse not silinir.
  Future<AyahMark> setNote(int ayahId, String? note) async {
    final existing = await mark(ayahId) ??
        AyahMark(ayahId: ayahId, updatedAt: DateTime.now());
    final trimmed = note?.trim();
    final updated = existing.copyWith(
      note: () => (trimmed == null || trimmed.isEmpty) ? null : trimmed,
    );
    await save(updated);
    return updated;
  }

  /// Yer imli ayetleri, en son işaretlenen başta olacak şekilde döndürür.
  Future<List<AyahMark>> bookmarks() async {
    final db = await _db.database;
    final rows = await db.query(
      'ayah_marks',
      where: 'is_bookmarked = 1',
      orderBy: 'updated_at DESC',
    );
    return rows.map(AyahMark.fromMap).toList();
  }

  /// Not içeren ayetleri döndürür.
  Future<List<AyahMark>> notes() async {
    final db = await _db.database;
    final rows = await db.query(
      'ayah_marks',
      where: "note IS NOT NULL AND TRIM(note) != ''",
      orderBy: 'updated_at DESC',
    );
    return rows.map(AyahMark.fromMap).toList();
  }

  /// Vurgulanmış ayetleri döndürür.
  Future<List<AyahMark>> highlights() async {
    final db = await _db.database;
    final rows = await db.query(
      'ayah_marks',
      where: 'highlight_color IS NOT NULL',
      orderBy: 'updated_at DESC',
    );
    return rows.map(AyahMark.fromMap).toList();
  }
}
