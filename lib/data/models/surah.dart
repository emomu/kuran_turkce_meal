/// Bir surenin künyesi.
///
/// Ayet metinleri burada tutulmaz; [Ayah] kayıtları ayrı sorgulanır. Böylece
/// sure listesi ekranı 114 kayıtla açılır, binlerce ayeti belleğe almaz.
class Surah {
  const Surah({
    required this.number,
    required this.name,
    this.nameEn,
    required this.meaning,
    this.meaningEn,
    required this.revelationOrder,
    required this.revelationPlace,
    required this.ayahCount,
  });

  /// Mushaf (resmi) sırasındaki numara. 1–114.
  final int number;

  /// Türkçe okunuşuyla sure adı. Örn. "Fâtiha".
  final String name;

  /// İngilizce yazımıyla sure adı. Örn. "Al-Fatihah".
  final String? nameEn;

  /// Adın Türkçe anlamı. Örn. "Açılış".
  final String meaning;

  /// Adın İngilizce anlamı. Örn. "The Opening".
  final String? meaningEn;

  /// Seçili dildeki sure adı.
  String nameFor(String languageCode) =>
      languageCode == 'en' ? (nameEn ?? name) : name;

  /// Seçili dildeki ad anlamı.
  String meaningFor(String languageCode) =>
      languageCode == 'en' ? (meaningEn ?? meaning) : meaning;

  /// İniş sırasındaki numara. 1–114.
  final int revelationOrder;

  /// İniş yeri.
  final RevelationPlace revelationPlace;

  /// Suredeki ayet sayısı.
  final int ayahCount;

  factory Surah.fromMap(Map<String, Object?> map) => Surah(
    number: map['number']! as int,
    name: map['name']! as String,
    nameEn: map['name_en'] as String?,
    meaning: map['meaning']! as String,
    meaningEn: map['meaning_en'] as String?,
    revelationOrder: map['revelation_order']! as int,
    revelationPlace: (map['revelation_place']! as String) == 'mekke'
        ? RevelationPlace.mekke
        : RevelationPlace.medine,
    ayahCount: map['ayah_count']! as int,
  );

  Map<String, Object?> toMap() => {
    'number': number,
    'name': name,
    'name_en': nameEn,
    'meaning': meaning,
    'meaning_en': meaningEn,
    'revelation_order': revelationOrder,
    'revelation_place': revelationPlace.name,
    'ayah_count': ayahCount,
  };
}

enum RevelationPlace {
  mekke,
  medine;

  /// Çeviri anahtarı; görünen metin arayüz dilinden gelir.
  String get labelKey => 'surahMeta.$name';
}
