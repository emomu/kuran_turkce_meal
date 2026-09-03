// Meal, tefsir ve Arapça metni uygulamanın asset biçimine dönüştürür.
//
// Kullanım:
//   dart run tool/import_meal.dart --meal <dosya.json> [--meal-en <dosya.json>]
//                                  [--arapca <dosya.json>]
//                                  [--tefsir <dosya.json>]
//                                  [--tefsir-en <dosya.json>]
//
// Girdi biçimleri (ikisi de kabul edilir):
//   {"quran": [{"chapter": 1, "verse": 1, "text": "..."}, ...]}
//   [{"chapter": 1, "verse": 1, "text": "..."}, ...]
//
// Çıktı: assets/data/ayahs.json — uygulamanın beklediği düz biçim:
//   [{"id": 1, "surah_number": 1, "ayah_number": 1,
//     "translation": "...", "arabic": "...", "tafsir": "..."}, ...]
//
// TELİF UYARISI
// -------------
// Bu araç metnin kullanım hakkını denetlemez, yalnızca biçim dönüştürür.
// Meal ve tefsir metinleri telif korumasına tabi olabilir:
//
//   * Elmalılı Hamdi Yazır'ın ORİJİNAL 1935 metni kamu malıdır (vefat 1942).
//     Ancak yaygın dolaşan "Elmalılı" dosyalarının çoğu SADELEŞTİRİLMİŞTİR;
//     sadeleştirme yeni bir eser sayılır ve sadeleştirenin telifi altındadır.
//     Metnin gerçekten orijinal olup olmadığını doğrulayın.
//   * Diyanet, Esed, İslamoğlu, Öztürk, Bayraklı gibi çağdaş mealler için
//     hak sahibinden yazılı izin gerekir.
//   * Bir metnin GitHub'da veya başka bir sitede bulunuyor olması, onu
//     kullanma hakkı vermez.
//
// Kur'an'ın Arapça metni telif konusu değildir.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  final options = _parseArgs(args);
  if (options == null) {
    _printUsage();
    exit(64); // EX_USAGE
  }

  final surahs = await _loadSurahs();
  final translation = await _loadVerses(options.mealPath, 'meal');

  final translationEn = options.mealEnPath == null
      ? null
      : await _loadVerses(options.mealEnPath!, 'İngilizce meal');
  final arabic = options.arabicPath == null
      ? null
      : await _loadVerses(options.arabicPath!, 'Arapça metin');
  final tafsir = options.tafsirPath == null
      ? null
      : await _loadVerses(options.tafsirPath!, 'tefsir');
  final tafsirEn = options.tafsirEnPath == null
      ? null
      : await _loadVerses(options.tafsirEnPath!, 'İngilizce tefsir');

  _validate(translation, surahs, label: 'Meal');
  if (translationEn != null) {
    _validate(translationEn, surahs, label: 'İngilizce meal');
  }
  if (arabic != null) _validate(arabic, surahs, label: 'Arapça metin');

  final output = _build(
    surahs,
    translation,
    translationEn,
    arabic,
    tafsir,
    tafsirEn,
  );

  final file = File('assets/data/ayahs.json');
  await file.writeAsString(jsonEncode(output));

  final sizeMb = (await file.length()) / (1024 * 1024);
  stdout
    ..writeln('')
    ..writeln('✓ ${output.length} ayet yazıldı → ${file.path}')
    ..writeln('  Boyut: ${sizeMb.toStringAsFixed(1)} MB')
    ..writeln('  İngilizce meal: ${translationEn == null ? 'yok' : 'var'}')
    ..writeln('  Arapça metin: ${arabic == null ? 'yok' : 'var'}')
    ..writeln('  Tefsir: ${tafsir == null ? 'yok' : '${tafsir.length} ayette'}')
    ..writeln(
      '  İngilizce tefsir: '
      '${tafsirEn == null ? 'yok' : '${tafsirEn.length} ayette'}',
    )
    ..writeln('')
    ..writeln('Uygulamayı yeniden kurun; veritabanı ilk açılışta yeniden')
    ..writeln('oluşturulur (eski kurulumda silip yeniden yükleyin).');
}

/// Ayet anahtarı: (sure, ayet) çifti.
typedef VerseKey = (int surah, int ayah);

/// Sure künyesi — ayet sayısı doğrulaması ve global kimlik hesabı için.
typedef SurahInfo = ({int number, String name, int ayahCount});

class _Options {
  const _Options({
    required this.mealPath,
    this.mealEnPath,
    this.arabicPath,
    this.tafsirPath,
    this.tafsirEnPath,
  });

  final String mealPath;
  final String? mealEnPath;
  final String? arabicPath;
  final String? tafsirPath;
  final String? tafsirEnPath;
}

_Options? _parseArgs(List<String> args) {
  String? meal;
  String? mealEn;
  String? arabic;
  String? tafsir;
  String? tafsirEn;

  for (var i = 0; i < args.length; i++) {
    final next = i + 1 < args.length ? args[i + 1] : null;
    switch (args[i]) {
      case '--meal':
        meal = next;
        i++;
      case '--meal-en':
        mealEn = next;
        i++;
      case '--arapca' || '--arabic':
        arabic = next;
        i++;
      case '--tefsir' || '--tafsir':
        tafsir = next;
        i++;
      case '--tefsir-en' || '--tafsir-en':
        tafsirEn = next;
        i++;
    }
  }

  if (meal == null) return null;
  return _Options(
    mealPath: meal,
    mealEnPath: mealEn,
    arabicPath: arabic,
    tafsirPath: tafsir,
    tafsirEnPath: tafsirEn,
  );
}

void _printUsage() {
  stderr.writeln('''
Kullanım:
  dart run tool/import_meal.dart --meal <dosya.json> [seçenekler]

Seçenekler:
  --meal       <dosya>   Türkçe meal (zorunlu)
  --meal-en    <dosya>   İngilizce meal
  --arapca     <dosya>   Arapça orijinal metin
  --tefsir     <dosya>   Türkçe tefsir (her ayette olmak zorunda değil)
  --tefsir-en  <dosya>   İngilizce tefsir

Girdi biçimi:
  {"quran": [{"chapter": 1, "verse": 1, "text": "..."}]}
  veya doğrudan aynı yapıdaki bir dizi.
''');
}

/// Sure künyelerini uygulamanın kendi verisinden okur.
Future<List<SurahInfo>> _loadSurahs() async {
  final file = File('assets/data/surahs.json');
  if (!file.existsSync()) {
    stderr.writeln('HATA: assets/data/surahs.json bulunamadı.');
    exit(66); // EX_NOINPUT
  }

  final raw = jsonDecode(await file.readAsString()) as List;
  return [
    for (final s in raw.cast<Map<String, Object?>>())
      (
        number: s['number']! as int,
        name: s['name']! as String,
        ayahCount: s['ayah_count']! as int,
      ),
  ];
}

/// Bir kaynak dosyayı (sure, ayet) → metin haritasına çevirir.
Future<Map<VerseKey, String>> _loadVerses(String path, String label) async {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('HATA: $label dosyası bulunamadı: $path');
    exit(66);
  }

  final decoded = jsonDecode(await file.readAsString());

  // İki biçim de desteklenir: {"quran": [...]} ve doğrudan [...].
  final rows = switch (decoded) {
    {'quran': final List rows} => rows,
    final List rows => rows,
    _ => null,
  };

  if (rows == null) {
    stderr.writeln(
      'HATA: $label dosyası tanınmayan biçimde. Beklenen: '
      '{"quran": [...]} veya [...]',
    );
    exit(65); // EX_DATAERR
  }

  final result = <VerseKey, String>{};

  for (final row in rows.cast<Map<String, Object?>>()) {
    // Alan adları kaynaktan kaynağa değişebilir.
    final surah = (row['chapter'] ?? row['sure'] ?? row['surah']) as int?;
    final ayah = (row['verse'] ?? row['ayet'] ?? row['ayah']) as int?;
    final text = (row['text'] ?? row['metin'] ?? row['translation']) as String?;

    if (surah == null || ayah == null || text == null) continue;
    if (text.trim().isEmpty) continue;

    result[(surah, ayah)] = text.trim();
  }

  stdout.writeln('  $label: ${result.length} ayet okundu ($path)');
  return result;
}

/// Kaynağın 114 sure / 6236 ayet bütünlüğünü taşıdığını doğrular.
///
/// Eksik ayet uygulamada boş satır olarak görünürdü; içe aktarmadan önce
/// yakalamak gerekir.
void _validate(
  Map<VerseKey, String> verses,
  List<SurahInfo> surahs, {
  required String label,
}) {
  final missing = <String>[];

  for (final surah in surahs) {
    for (var ayah = 1; ayah <= surah.ayahCount; ayah++) {
      if (!verses.containsKey((surah.number, ayah))) {
        missing.add('${surah.name} $ayah');
      }
    }
  }

  if (missing.isEmpty) {
    stdout.writeln('  ✓ $label eksiksiz (6236 ayet)');
    return;
  }

  stderr
    ..writeln('')
    ..writeln('HATA: $label kaynağında ${missing.length} ayet eksik.')
    ..writeln('İlk eksikler: ${missing.take(8).join(', ')}');
  exit(65);
}

/// Uygulamanın beklediği düz kayıt listesini üretir.
///
/// Global kimlik (`id`) mushaf sırasına göre 1'den başlayarak artar; yer imi
/// ve okuma planı kayıtları bu kimliğe bağlandığı için sıralama sabittir.
List<Map<String, Object?>> _build(
  List<SurahInfo> surahs,
  Map<VerseKey, String> translation,
  Map<VerseKey, String>? translationEn,
  Map<VerseKey, String>? arabic,
  Map<VerseKey, String>? tafsir,
  Map<VerseKey, String>? tafsirEn,
) {
  final output = <Map<String, Object?>>[];
  var id = 1;
  var mergedCount = 0;

  for (final surah in surahs..sort((a, b) => a.number.compareTo(b.number))) {
    var ayah = 1;

    while (ayah <= surah.ayahCount) {
      final text = translation[(surah.number, ayah)]!;

      // Bazı meallerde çevirmen ardışık ayetleri tek cümlede karşılar ve
      // kaynak veri aynı metni her ayete kopyalar (örn. Alak 9-10,
      // Yâsîn 2-3). Aynı metni arka arkaya iki kez göstermek yerine
      // ayetler tek blokta birleştirilir; rozet aralığı belirtir.
      var last = ayah;
      while (last < surah.ayahCount &&
          translation[(surah.number, last + 1)] == text) {
        last++;
      }

      if (last > ayah) mergedCount += last - ayah;

      // Arapça metin ayet ayet ayrıdır; birleşik blokta hepsi alt alta
      // korunur, hiçbiri kaybolmaz.
      final arabicParts = arabic == null
          ? null
          : [
              for (var a = ayah; a <= last; a++)
                if (arabic[(surah.number, a)] case final t?) t,
            ];

      // Tefsir aralıktaki ilk bulunandan alınır.
      String? firstIn(Map<VerseKey, String>? source) {
        if (source == null) return null;
        for (var a = ayah; a <= last; a++) {
          final t = source[(surah.number, a)];
          if (t != null) return t;
        }
        return null;
      }

      final tafsirText = firstIn(tafsir);
      final tafsirEnText = firstIn(tafsirEn);

      // İngilizce meal, Türkçe birleştirmenin aynı aralığına uydurulur.
      // Aralıktaki parçalar farklıysa birleştirilir; aynıysa tek kopya
      // yazılır — kaynak veri birleşik ayetleri tekrarlamış olabilir.
      String? translationEnText;
      if (translationEn != null) {
        final parts = <String>[];
        for (var a = ayah; a <= last; a++) {
          final t = translationEn[(surah.number, a)];
          if (t != null && !parts.contains(t)) parts.add(t);
        }
        if (parts.isNotEmpty) translationEnText = parts.join(' ');
      }

      output.add({
        'id': id++,
        'surah_number': surah.number,
        'ayah_number': ayah,
        'end_ayah_number': last,
        'translation': text,
        if (translationEnText != null) 'translation_en': translationEnText,
        if (arabicParts != null && arabicParts.isNotEmpty)
          'arabic': arabicParts.join('\n'),
        if (tafsirText != null) 'tafsir': tafsirText,
        if (tafsirEnText != null) 'tafsir_en': tafsirEnText,
      });

      ayah = last + 1;
    }
  }

  if (mergedCount > 0) {
    stdout.writeln(
      '  ℹ $mergedCount ayet, meali aynı olduğu için önceki ayetle '
      'birleştirildi',
    );
  }

  return output;
}
