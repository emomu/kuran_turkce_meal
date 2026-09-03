import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/plan_schedule.dart';

/// Okuma ilerlemesi: kullanıcının nerede kaldığı ve plan takibi.
class ProgressRepository {
  ProgressRepository(this._db, this._prefs);
  final AppDatabase _db;

  /// Plan başlangıç tarihleri burada tutulur, veritabanında değil.
  ///
  /// plan_progress tablosunun birincil anahtarı (plan_id, day_index); plan
  /// başına tek bir tarih için oraya sahte bir day_index (0 gibi) yazmak
  /// gerekirdi ve o satır "tamamlanmış gün" sayan her sorguyu bozardı.
  /// Ayrı tablo açmak ise şema sürümünü yükseltmeyi gerektiriyor; oysa
  /// saklanan şey tek bir skaler tercih — SharedPreferences tam olarak
  /// bunun için var ve uygulama açılışında zaten senkron çözülmüş durumda.
  final SharedPreferences _prefs;

  /// Sureyi okurken kalınan yeri kaydeder.
  ///
  /// Okuma ekranı kaydırıldıkça çağrılır, bu yüzden ucuz olmalı: tek satırlık
  /// upsert yapar.
  Future<void> saveProgress(int surahNumber, int ayahNumber) async {
    final db = await _db.database;
    await db.insert('reading_progress', {
      'surah_number': surahNumber,
      'last_ayah': ayahNumber,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Kullanıcının en son okuduğu yeri döndürür — ana ekrandaki
  /// "Kaldığın yerden devam et" kartı için.
  Future<({int surahNumber, int ayahNumber})?> lastRead() async {
    final db = await _db.database;
    final rows = await db.query(
      'reading_progress',
      orderBy: 'updated_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return (
      surahNumber: rows.first['surah_number']! as int,
      ayahNumber: rows.first['last_ayah']! as int,
    );
  }

  Future<int?> progressInSurah(int surahNumber) async {
    final db = await _db.database;
    final rows = await db.query(
      'reading_progress',
      where: 'surah_number = ?',
      whereArgs: [surahNumber],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['last_ayah'] as int;
  }

  /// Okunmaya başlanmış tüm surelerin ilerlemesi.
  Future<Map<int, int>> allProgress() async {
    final db = await _db.database;
    final rows = await db.query('reading_progress');
    return {
      for (final row in rows)
        row['surah_number']! as int: row['last_ayah']! as int,
    };
  }

  // -------------------------------------------------------- Okuma planları

  /// Bir planda tamamlanmış gün numaralarını döndürür.
  Future<Set<int>> completedDays(String planId) async {
    final db = await _db.database;
    final rows = await db.query(
      'plan_progress',
      columns: ['day_index'],
      where: 'plan_id = ?',
      whereArgs: [planId],
    );
    return rows.map((r) => r['day_index']! as int).toSet();
  }

  /// Tamamlanmış günleri tamamlanma zamanlarıyla döndürür.
  ///
  /// `completed_at` sütunu markDayComplete tarafından zaten yazılıyordu ama
  /// hiç okunmuyordu; seri hesabı için gereken tek veri bu.
  Future<List<({int dayIndex, DateTime completedAt})>> completionDates(
    String planId,
  ) async {
    final db = await _db.database;
    final rows = await db.query(
      'plan_progress',
      columns: ['day_index', 'completed_at'],
      where: 'plan_id = ?',
      whereArgs: [planId],
      orderBy: 'completed_at ASC',
    );
    return [
      for (final row in rows)
        (
          dayIndex: row['day_index']! as int,
          completedAt: DateTime.fromMillisecondsSinceEpoch(
            row['completed_at']! as int,
          ),
        ),
    ];
  }

  Future<void> markDayComplete(String planId, int dayIndex) async {
    final db = await _db.database;
    await db.insert('plan_progress', {
      'plan_id': planId,
      'day_index': dayIndex,
      'completed_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> markDayIncomplete(String planId, int dayIndex) async {
    final db = await _db.database;
    await db.delete(
      'plan_progress',
      where: 'plan_id = ? AND day_index = ?',
      whereArgs: [planId, dayIndex],
    );
  }

  /// Bir planın kaç günü tamamlandığı.
  Future<int> completedDayCount(String planId) async {
    final db = await _db.database;
    return Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM plan_progress WHERE plan_id = ?',
            [planId],
          ),
        ) ??
        0;
  }

  /// Kullanıcının en son ilerleme kaydettiği plan.
  ///
  /// Uygulamada "aktif plan" diye bir seçim yok — kullanıcı istediği planla
  /// istediği zaman ilgilenebilir. Ana ekran aracının tek bir plan göstermesi
  /// gerektiği için en son dokunulan plan aktif sayılır: kullanıcının şu an
  /// hangi planla ilgilendiğini gösteren en iyi işaret, en son tamamladığı
  /// gündür.
  ///
  /// Hiç gün tamamlanmamışsa null döner; araç o durumda kendi boş halini
  /// gösterir.
  Future<String?> mostRecentPlanId() async {
    final db = await _db.database;
    final rows = await db.query(
      'plan_progress',
      columns: ['plan_id'],
      orderBy: 'completed_at DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['plan_id'] as String?;
  }

  /// Bir planda bugün gün tamamlanıp tamamlanmadığı.
  ///
  /// Seri aracının halkasını doldurmak için kullanılır. Seri hesabının
  /// kendisi tamamlanma tarihlerinden türetiliyor ama araç yalnızca "bugün
  /// yapıldı mı" bilgisine ihtiyaç duyuyor; tüm tarihleri çekip elemek
  /// yerine tek sayım sorgusu yeterli.
  Future<bool> hasCompletionOn(String planId, DateTime day) async {
    final db = await _db.database;
    final start = startOfDay(day).millisecondsSinceEpoch;
    final end = startOfDay(day).add(const Duration(days: 1))
        .millisecondsSinceEpoch;

    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM plan_progress '
        'WHERE plan_id = ? AND completed_at >= ? AND completed_at < ?',
        [planId, start, end],
      ),
    );
    return (count ?? 0) > 0;
  }

  // ------------------------------------------------ Plan başlangıç tarihi

  static String _startDateKey(String planId) => 'plan_start_$planId';

  /// Planın başlangıç tarihi. Plan hiç başlatılmadıysa null.
  DateTime? planStartDate(String planId) {
    final millis = _prefs.getInt(_startDateKey(planId));
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  /// Başlangıç tarihini yazar. Gün başına indirgenir: saat bilgisi
  /// saklansaydı takvim günü hesabı kaydedilen saate göre kayardı.
  Future<void> setPlanStartDate(String planId, DateTime date) {
    return _prefs.setInt(
      _startDateKey(planId),
      startOfDay(date).millisecondsSinceEpoch,
    );
  }

  /// Plan daha önce başlatılmadıysa başlangıcı [date] yapar.
  ///
  /// İlk gün tamamlandığında çağrılır: kullanıcıyı "planı başlat" diye ayrı
  /// bir düğmeye zorlamadan takvim bağı kurulur. Zaten başlatılmış planın
  /// tarihi korunur, yoksa her tamamlama geçmişi sıfırlardı.
  Future<void> ensurePlanStarted(String planId, DateTime date) async {
    if (_prefs.containsKey(_startDateKey(planId))) return;
    await setPlanStartDate(planId, date);
  }

  Future<void> clearPlanStartDate(String planId) {
    return _prefs.remove(_startDateKey(planId));
  }
}
