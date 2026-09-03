import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../db/search_normalizer.dart';
import '../models/ayah.dart';
import '../models/surah.dart';

/// Sure ve ayet metnine erişim. Salt okunur — bu veriler kullanıcı tarafından
/// değiştirilmez.
class QuranRepository {
  QuranRepository(this._db);
  final AppDatabase _db;

  /// Tüm sureleri künyeleriyle döndürür.
  ///
  /// [byRevelation] true ise iniş sırasına, değilse mushaf sırasına göre
  /// sıralanır. Uygulamanın varsayılanı iniş sırasıdır.
  Future<List<Surah>> surahs({required bool byRevelation}) async {
    final db = await _db.database;
    final rows = await db.query(
      'surahs',
      orderBy: byRevelation ? 'revelation_order ASC' : 'number ASC',
    );
    return rows.map(Surah.fromMap).toList();
  }

  Future<Surah?> surah(int number) async {
    final db = await _db.database;
    final rows = await db.query(
      'surahs',
      where: 'number = ?',
      whereArgs: [number],
      limit: 1,
    );
    return rows.isEmpty ? null : Surah.fromMap(rows.first);
  }

  /// Okuma akışında bir sonraki sureyi döndürür.
  ///
  /// Sıralama kullanıcının aktif tercihini izler: iniş sırası açıkken
  /// kronolojik olarak sonraki sure, mushaf sırasındayken bir sonraki mushaf
  /// numarası gelir. Son surede null döner.
  Future<Surah?> nextSurah(
    int currentNumber, {
    required bool byRevelation,
  }) async {
    final db = await _db.database;
    final orderColumn = byRevelation ? 'revelation_order' : 'number';

    // Mevcut surenin sıra değerini bul, ondan büyük ilk sureyi getir.
    final rows = await db.rawQuery(
      '''
      SELECT * FROM surahs
      WHERE $orderColumn > (
        SELECT $orderColumn FROM surahs WHERE number = ?
      )
      ORDER BY $orderColumn ASC
      LIMIT 1
      ''',
      [currentNumber],
    );

    return rows.isEmpty ? null : Surah.fromMap(rows.first);
  }

  /// Bir surenin tüm ayetlerini sırayla döndürür.
  Future<List<Ayah>> ayahsOfSurah(int surahNumber) async {
    final db = await _db.database;
    final rows = await db.query(
      'ayahs',
      where: 'surah_number = ?',
      whereArgs: [surahNumber],
      orderBy: 'ayah_number ASC',
    );
    return rows.map(Ayah.fromMap).toList();
  }

  /// Plan bölmesi için hafif ayet dizini: kimlik, sure ve ayet numarası.
  ///
  /// Ayetlerin tam metnini çekmeden sıralama kurmak gerekir; plan ekranı
  /// yalnızca aralık etiketi ve gidilecek konumla ilgilenir. 6179 satırın
  /// metniyle birlikte yüklenmesi gereksiz bellek ve süre maliyeti olurdu.
  Future<List<({int id, int surahNumber, int ayahNumber})>>
      ayahIndex() async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT id, surah_number, ayah_number
      FROM ayahs
      ORDER BY id ASC
      ''',
    );

    return [
      for (final r in rows)
        (
          id: r['id']! as int,
          surahNumber: r['surah_number']! as int,
          ayahNumber: r['ayah_number']! as int,
        ),
    ];
  }

  Future<Ayah?> ayahById(int id) async {
    final db = await _db.database;
    final rows = await db.query(
      'ayahs',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Ayah.fromMap(rows.first);
  }

  /// Verilen kimliklerdeki ayetleri tek sorguda çeker.
  ///
  /// Yer imi listesi ve okuma planı ekranları çok sayıda ayeti birden ister;
  /// tek tek sorgulamak N+1 problemine yol açardı.
  Future<List<Ayah>> ayahsByIds(List<int> ids) async {
    if (ids.isEmpty) return const [];
    final db = await _db.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await db.rawQuery(
      'SELECT * FROM ayahs WHERE id IN ($placeholders) ORDER BY id ASC',
      ids,
    );
    return rows.map(Ayah.fromMap).toList();
  }

  /// Bir ayet aralığını döndürür — okuma planı günlerinde kullanılır.
  Future<List<Ayah>> ayahRange(int startId, int endId) async {
    final db = await _db.database;
    final rows = await db.query(
      'ayahs',
      where: 'id BETWEEN ? AND ?',
      whereArgs: [startId, endId],
      orderBy: 'id ASC',
    );
    return rows.map(Ayah.fromMap).toList();
  }

  /// Meal ve tefsir metninde tam metin araması yapar.
  ///
  /// FTS5 sanal tablosu kullanılır; 6236 ayet üzerinde sonuç anında döner.
  /// [limit] arayüzün bir seferde göstereceğinden fazlasını çekmemek için.
  /// [languageCode] hangi dilin dizininde aranacağını belirler; kullanıcı
  /// arayüzü İngilizceyken Türkçe metinde sonuç çıkması kafa karıştırırdı.
  Future<List<SearchHit>> search(
    String query, {
    String languageCode = 'tr',
    int limit = 60,
  }) async {
    final ftsQuery = SearchNormalizer.toFtsQuery(query);
    if (ftsQuery == null) return const [];

    final db = await _db.database;
    final isEnglish = languageCode == 'en';
    final ftsTable = isEnglish ? 'ayahs_fts_en' : 'ayahs_fts';
    final nameColumn = isEnglish ? 'COALESCE(s.name_en, s.name)' : 's.name';

    // FTS tablosunun rowid'si ayet kimliğiyle aynı; doğrudan JOIN edilir.
    // bm25() alaka sıralaması verir — daha küçük değer daha alakalı.
    final rows = await db.rawQuery(
      '''
      SELECT a.*, $nameColumn AS surah_name
      FROM $ftsTable f
      JOIN ayahs  a ON a.id = f.rowid
      JOIN surahs s ON s.number = a.surah_number
      WHERE $ftsTable MATCH ?
      ORDER BY bm25($ftsTable), a.id
      LIMIT ?
      ''',
      [ftsQuery, limit],
    );

    return rows
        .map((r) => SearchHit(
              ayah: Ayah.fromMap(r),
              surahName: r['surah_name']! as String,
            ))
        .toList();
  }

  /// Günün ayeti.
  ///
  /// Tarihten türetilen sabit bir tohumla seçilir: aynı gün içinde uygulama
  /// kaç kez açılırsa açılsın aynı ayet gösterilir, ertesi gün değişir.
  /// Rastgele seçim yerine bu yöntem tercih edildi çünkü kullanıcı gün içinde
  /// gördüğü ayete geri dönebilmeli.
  Future<Ayah?> ayahOfTheDay(DateTime date) async {
    final db = await _db.database;

    final total = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ayahs'),
    );
    if (total == null || total == 0) return null;

    // Gün sayısını doğrusal olmayan bir çarpanla dağıtır; ardışık günlerde
    // komşu ayetlerin gelmesini engeller.
    final dayNumber = DateTime(date.year, date.month, date.day)
            .millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
    final offset = (dayNumber * 2654435761) % total;

    final rows = await db.query('ayahs', limit: 1, offset: offset);
    return rows.isEmpty ? null : Ayah.fromMap(rows.first);
  }

  /// Günün ayetinden başlayarak [count] adet ayet döndürür.
  ///
  /// Ana ekran aracının "yenile" düğmesi için: araç veritabanına erişemediği
  /// için gösterebileceği ayetlerin önceden yazılmış olması gerekir.
  ///
  /// Seçim `ayahOfTheDay` ile aynı tohumdan türetilir; ilk öğe her zaman
  /// günün ayetidir, sonrakiler onu izleyen günlerin ayetleri. Rastgele
  /// seçmek yerine bu yöntem tercih edildi: kullanıcı araçta ileri gittikçe
  /// aslında sonraki günlerin ayetlerini görür, yani gördüğü hiçbir ayet
  /// "kaybolmaz", ertesi gün araçta zaten karşısına çıkar.
  Future<List<Ayah>> ayahPoolFrom(DateTime date, {required int count}) async {
    if (count <= 0) return const [];

    final db = await _db.database;

    final total = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ayahs'),
    );
    if (total == null || total == 0) return const [];

    final startDay = DateTime(date.year, date.month, date.day)
            .millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;

    final ayahs = <Ayah>[];
    for (var step = 0; step < count; step++) {
      final offset = ((startDay + step) * 2654435761) % total;
      final rows = await db.query('ayahs', limit: 1, offset: offset);
      if (rows.isNotEmpty) ayahs.add(Ayah.fromMap(rows.first));
    }
    return ayahs;
  }

  /// Toplam ayet sayısı — ilerleme yüzdeleri için.
  Future<int> totalAyahCount() async {
    final db = await _db.database;
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM ayahs'),
        ) ??
        0;
  }
}

/// Arama sonucu: ayet ve ait olduğu surenin adı.
class SearchHit {
  const SearchHit({required this.ayah, required this.surahName});
  final Ayah ayah;
  final String surahName;
}
