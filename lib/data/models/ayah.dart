/// Tek bir ayet: Türkçe meal ve opsiyonel Arapça metin.
class Ayah {
  const Ayah({
    required this.id,
    required this.surahNumber,
    required this.ayahNumber,
    required this.translation,
    int? endAyahNumber,
    this.translationEn,
    this.arabic,
  }) : endAyahNumber = endAyahNumber ?? ayahNumber;

  /// Global ayet kimliği. Mushaf sırasına göre 1'den başlar (toplam 6236).
  /// Yer imi ve not kayıtları bu kimliğe bağlanır.
  final int id;

  final int surahNumber;

  /// Sure içindeki ayet numarası. 1'den başlar.
  ///
  /// Birleşik meal bloklarında (bkz. [endAyahNumber]) bu, aralığın ilk
  /// ayetidir.
  final int ayahNumber;

  /// Türkçe meal metni.
  final String translation;

  /// İngilizce meal metni. Veri yüklenmemişse null.
  final String? translationEn;

  /// Arapça orijinal metin. Ayarlardan gösterimi açılabilir.
  final String? arabic;

  /// Seçili dildeki meal metni.
  ///
  /// İngilizce istenip veri yoksa Türkçeye düşer: ekranda boş satır
  /// göstermektense mevcut metni göstermek yeğdir.
  String translationFor(String languageCode) =>
      languageCode == 'en' ? (translationEn ?? translation) : translation;

  /// Birleşik meal bloğunun son ayet numarası.
  ///
  /// Bazı meallerde çevirmen ardışık ayetleri tek cümlede karşılar (örn.
  /// Alak 9-10, Yâsîn 2-3). Bu durumda ayetler tek blokta gösterilir ve
  /// rozet aralığı belirtir. Tekil ayetlerde [ayahNumber] ile aynıdır.
  final int endAyahNumber;

  /// Bu blok birden fazla ayeti kapsıyor mu.
  bool get isRange => endAyahNumber > ayahNumber;

  /// Rozet ve başlıklarda gösterilen numara. Örn. "9" veya "9-10".
  String get numberLabel =>
      isRange ? '$ayahNumber-$endAyahNumber' : '$ayahNumber';

  /// Paylaşım ve başlıklarda kullanılan referans. Örn. "2:255", "96:9-10".
  String get reference => '$surahNumber:$numberLabel';

  factory Ayah.fromMap(Map<String, Object?> map) => Ayah(
    id: map['id']! as int,
    surahNumber: map['surah_number']! as int,
    ayahNumber: map['ayah_number']! as int,
    endAyahNumber: map['end_ayah_number'] as int?,
    translation: map['translation']! as String,
    translationEn: map['translation_en'] as String?,
    arabic: map['arabic'] as String?,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'surah_number': surahNumber,
    'ayah_number': ayahNumber,
    'end_ayah_number': endAyahNumber,
    'translation': translation,
    'translation_en': translationEn,
    'arabic': arabic,
  };
}
