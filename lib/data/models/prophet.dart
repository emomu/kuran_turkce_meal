/// Kur'an'da adı anılan bir peygamber ve geçtiği ayetler.
///
/// Ayet kimlikleri iniş sırasına göre dizilidir: kullanıcı bir kıssayı
/// mushaf sırasıyla değil, indiği sırayla okur. Bu, uygulamanın iniş sırasına
/// göre okuma anlayışının kıssalara uygulanmış hâli — Mûsâ kıssasının önce
/// hangi surede, hangi ayrıntıyla anlatıldığı, sonra nasıl genişlediği
/// görünür olur.
class Prophet {
  const Prophet({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.ayahIds,
    List<int>? mentionIds,
  }) : mentionIds = mentionIds ?? ayahIds;

  /// Kalıcı kimlik. Veri yeniden üretildiğinde değişmez; arayüz durumu ve
  /// gezinme buna bağlanabilir.
  final String id;

  final String name;
  final String nameEn;

  /// Kıssasının anlatıldığı ayetlerin kimlikleri, iniş sırasına göre.
  ///
  /// Kıssa ekranı bunu okur. Kendisine hitap edilen ayetler buraya girmez:
  /// "Ey Muhammed! Sana soruyorlar" bir kıssa değil, bir hitaptır.
  final List<int> ayahIds;

  /// Anıldığı tüm ayetler — adı geçenler ve ona seslenilenler, iniş sırasına
  /// göre.
  ///
  /// Arama ve asistan bunu okur. Kur'an Hz. Muhammed'e çoğunlukla adıyla
  /// değil sıfatıyla seslenir ("Ey Peygamber", "Ey Rasûl"); mealde bu
  /// hitaplar "(Ey Muhammed)" diye açılır. Kullanıcı adını arattığında bu
  /// ayetleri de görmeli — kıssa listesi tek başına 10 sonuç döndürüyordu,
  /// gerçek sayı 140.
  ///
  /// Diğer peygamberlerde [ayahIds] ile aynıdır; veri dosyasında alan yoksa
  /// oraya düşer.
  final List<int> mentionIds;

  String nameFor(String languageCode) => languageCode == 'en' ? nameEn : name;

  int get ayahCount => ayahIds.length;

  /// Anıldığı ayet sayısı. Arama ve asistan bu sayıyı gösterir.
  int get mentionCount => mentionIds.length;

  /// Kıssa listesi anılma listesinden dar mı.
  ///
  /// Yalnızca Hz. Muhammed'de doğrudur; arayüz "kıssası" yerine "anıldığı
  /// ayetler" demeyi buna bakarak seçer.
  bool get hasSeparateMentions => mentionIds.length != ayahIds.length;

  factory Prophet.fromMap(Map<String, Object?> map) => Prophet(
    id: map['id']! as String,
    name: map['name']! as String,
    nameEn: map['name_en']! as String,
    ayahIds: (map['ayah_ids']! as List).cast<int>(),
    mentionIds: (map['mention_ids'] as List?)?.cast<int>(),
  );
}
