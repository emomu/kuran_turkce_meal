import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'search_normalizer.dart';

/// Uygulamanın yerel veritabanı katmanı.
///
/// Meal metni uygulama paketiyle birlikte JSON olarak gelir ve ilk açılışta
/// SQLite'a aktarılır. Aktarım tek seferliktir; sonraki açılışlarda doğrudan
/// veritabanı okunur. Böylece arama, yer imi ve okuma planı sorguları
/// internet olmadan da çalışır.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _fileName = 'kuran.db';

  /// Şema sürümü.
  ///
  /// Şema ya da paketlenen meal verisi değiştiğinde artırılır; eski
  /// kurulumlardaki veritabanı silinip yeniden oluşturulur. Artırılmazsa
  /// kullanıcı güncellemeden sonra eski veriyi görmeye devam eder.
  ///
  /// 2: İngilizce meal ve sure adları eklendi.
  static const _schemaVersion = 3;

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  /// Uygulamanın kullandığı SQLite motoru.
  ///
  /// Android'in sistem SQLite'ı cihazdan cihaza değişir ve pek çok cihazda
  /// FTS5 modülü olmadan derlenmiştir — arama dizini oluşturulamaz ve
  /// uygulama açılışta "no such module: fts5" ile durur. Bu yüzden platform
  /// kütüphanesi yerine uygulamayla birlikte paketlenen SQLite kullanılır
  /// (`sqlite3` paketi); sürüm ve derleme seçenekleri her cihazda aynıdır.
  ///
  /// Masaüstü ve testler zaten aynı FFI motorunu kullanıyordu; artık mobil de
  /// aynı motorla çalışıyor, yani testlerde geçen sorgu cihazda da geçiyor.
  /// Testlerin kendi motorunu ve dosya yolunu geçirebilmesi için.
  ///
  /// Verilmezse paketlenmiş SQLite ve uygulamanın belge dizini kullanılır.
  /// Yol da buradan geldiği için testler `path_provider` eklentisine —
  /// dolayısıyla bir platform kanalına — ihtiyaç duymaz.
  @visibleForTesting
  static DatabaseFactory? factoryOverride;

  @visibleForTesting
  static String? pathOverride;

  static DatabaseFactory get _factory {
    final override = factoryOverride;
    if (override != null) return override;

    sqfliteFfiInit();
    return databaseFactoryFfi;
  }

  /// Veritabanı dosyasının bulunacağı dizin.
  ///
  /// `getDatabasesPath()` sqflite'ın platform eklentisine bağlıdır; FFI
  /// motoruna geçince mobilde güvenilir bir yol döndürmez. Bunun yerine
  /// `path_provider` ile uygulamanın kendi belge dizini kullanılır — her
  /// platformda yazılabilir ve uygulama silinince birlikte temizlenir.
  Future<String> _databasesPath() async {
    final override = pathOverride;
    if (override != null) return override;

    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<Database> _open() async {
    final path = p.join(await _databasesPath(), _fileName);
    return _factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _schemaVersion,
        onConfigure: (db) async {
          // Yer imi silindiğinde bağlı kayıtların da temizlenmesi için.
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await _createSchema(db);
          await _seedFromAssets(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          // Meal metni ve şema paketle birlikte geldiği için taşıma yapmak
          // yerine yeniden kurulur. Kullanıcı verisi (yer imi, not, vurgu,
          // ilerleme) korunur; yalnızca içerik tabloları yenilenir.
          final marks = await db.query('ayah_marks');
          final progress = await db.query('reading_progress');
          final planProgress = await db.query('plan_progress');

          for (final table in [
            'ayahs_fts',
            'ayahs_fts_en',
            'ayah_marks',
            'reading_progress',
            'plan_progress',
            'ayahs',
            'surahs',
          ]) {
            await db.execute('DROP TABLE IF EXISTS $table');
          }

          await _createSchema(db);
          await _seedFromAssets(db);

          // Kullanıcı verisini geri yaz. Ayet kimlikleri mushaf sırasına göre
          // sabit olduğu için işaretler doğru ayetlere denk gelir.
          final batch = db.batch();
          for (final row in marks) {
            batch.insert(
              'ayah_marks',
              row,
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }
          for (final row in progress) {
            batch.insert(
              'reading_progress',
              row,
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }
          for (final row in planProgress) {
            batch.insert(
              'plan_progress',
              row,
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }
          await batch.commit(noResult: true);
        },
      ),
    );
  }

  Future<void> _createSchema(Database db) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE surahs (
        number            INTEGER PRIMARY KEY,
        name              TEXT    NOT NULL,
        name_en           TEXT,
        meaning           TEXT    NOT NULL,
        meaning_en        TEXT,
        revelation_order  INTEGER NOT NULL UNIQUE,
        revelation_place  TEXT    NOT NULL,
        ayah_count        INTEGER NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE ayahs (
        id            INTEGER PRIMARY KEY,
        surah_number  INTEGER NOT NULL REFERENCES surahs(number),
        ayah_number   INTEGER NOT NULL,
        -- Birleşik meal bloklarında aralığın son ayeti; tekil ayetlerde
        -- ayah_number ile aynıdır.
        end_ayah_number INTEGER NOT NULL,
        -- Meal metni dil başına ayrı sütunda tutulur. Satır başına bir dil
        -- yaklaşımı seçilseydi her sorgu bir WHERE koşulu daha taşır ve
        -- ayet sayısı ikiye katlanırdı.
        translation     TEXT    NOT NULL,
        translation_en  TEXT,
        arabic          TEXT,
        UNIQUE (surah_number, ayah_number)
      )
    ''');

    // Sure içi ayet çekimi okuma ekranının en sık sorgusu.
    batch.execute(
      'CREATE INDEX idx_ayahs_surah ON ayahs (surah_number, ayah_number)',
    );

    // Tam metin arama. `search_text` alanı normalize edilmiş metni tutar
    // (bkz. SearchNormalizer) — kullanıcı "adalet" yazınca "adâlet" de bulunur.
    // Arama dizini dil başına ayrıdır: tek dizinde birleştirilseydi Türkçe
    // arama İngilizce metinden de sonuç döndürürdü.
    batch.execute('''
      CREATE VIRTUAL TABLE ayahs_fts USING fts5 (
        search_text,
        content = '',
        tokenize = 'unicode61 remove_diacritics 2'
      )
    ''');

    batch.execute('''
      CREATE VIRTUAL TABLE ayahs_fts_en USING fts5 (
        search_text,
        content = '',
        tokenize = 'unicode61 remove_diacritics 2'
      )
    ''');

    batch.execute('''
      CREATE TABLE ayah_marks (
        ayah_id         INTEGER PRIMARY KEY REFERENCES ayahs(id),
        is_bookmarked   INTEGER NOT NULL DEFAULT 0,
        highlight_color INTEGER,
        note            TEXT,
        updated_at      INTEGER NOT NULL
      )
    ''');

    batch.execute(
      'CREATE INDEX idx_marks_bookmarked ON ayah_marks (is_bookmarked, updated_at DESC)',
    );

    // Okuma ilerlemesi: kullanıcının her surede en son gördüğü ayet.
    batch.execute('''
      CREATE TABLE reading_progress (
        surah_number   INTEGER PRIMARY KEY REFERENCES surahs(number),
        last_ayah      INTEGER NOT NULL,
        updated_at     INTEGER NOT NULL
      )
    ''');

    // Okuma planı ilerlemesi: tamamlanan günler.
    batch.execute('''
      CREATE TABLE plan_progress (
        plan_id      TEXT    NOT NULL,
        day_index    INTEGER NOT NULL,
        completed_at INTEGER NOT NULL,
        PRIMARY KEY (plan_id, day_index)
      )
    ''');

    await batch.commit(noResult: true);
  }

  /// Sure künyelerini ve meal metnini asset JSON dosyalarından aktarır.
  Future<void> _seedFromAssets(Database db) async {
    final surahJson = await rootBundle.loadString('assets/data/surahs.json');
    final surahs = (jsonDecode(surahJson) as List).cast<Map<String, Object?>>();

    final batch = db.batch();
    for (final s in surahs) {
      batch.insert('surahs', s);
    }
    await batch.commit(noResult: true);

    await _seedAyahs(db);
  }

  /// Ayet metnini aktarır.
  ///
  /// Dosya büyük olduğu için tek işlemde ve parçalı batch'lerle yazılır;
  /// aksi halde ilk açılış birkaç saniye donardı.
  Future<void> _seedAyahs(Database db) async {
    final String raw;
    try {
      raw = await rootBundle.loadString('assets/data/ayahs.json');
    } on FlutterError {
      // Meal dosyası henüz eklenmemişse şema boş kalır; uygulama açılır ve
      // içerik ekranları "meal yüklenmedi" durumunu gösterir.
      return;
    }

    final ayahs = (jsonDecode(raw) as List).cast<Map<String, Object?>>();

    await db.transaction((txn) async {
      var batch = txn.batch();
      var pending = 0;

      for (final a in ayahs) {
        final id = a['id']! as int;
        final translation = a['translation']! as String;
        final translationEn = a['translation_en'] as String?;

        batch.insert('ayahs', {
          'id': id,
          'surah_number': a['surah_number'],
          'ayah_number': a['ayah_number'],
          'end_ayah_number': a['end_ayah_number'] ?? a['ayah_number'],
          'translation': translation,
          'translation_en': translationEn,
          'arabic': a['arabic'],
        });

        // FTS satırı ayet id'siyle hizalanır (rowid = ayah id), böylece
        // arama sonucundan doğrudan ayete gidilir.
        batch.insert('ayahs_fts', {
          'rowid': id,
          'search_text': SearchNormalizer.normalize(translation),
        });

        if (translationEn != null) {
          batch.insert('ayahs_fts_en', {
            'rowid': id,
            'search_text': SearchNormalizer.normalize(translationEn),
          });
        }

        if (++pending >= 500) {
          await batch.commit(noResult: true);
          batch = txn.batch();
          pending = 0;
        }
      }

      if (pending > 0) await batch.commit(noResult: true);
    });
  }

  /// Meal verisinin yüklü olup olmadığını bildirir.
  Future<bool> hasContent() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ayahs'),
    );
    return (count ?? 0) > 0;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
