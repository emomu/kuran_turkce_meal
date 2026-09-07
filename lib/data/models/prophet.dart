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
  });

  /// Kalıcı kimlik. Veri yeniden üretildiğinde değişmez; arayüz durumu ve
  /// gezinme buna bağlanabilir.
  final String id;

  final String name;
  final String nameEn;

  /// Adının geçtiği ayetlerin kimlikleri, iniş sırasına göre.
  final List<int> ayahIds;

  String nameFor(String languageCode) => languageCode == 'en' ? nameEn : name;

  int get ayahCount => ayahIds.length;

  factory Prophet.fromMap(Map<String, Object?> map) => Prophet(
    id: map['id']! as String,
    name: map['name']! as String,
    nameEn: map['name_en']! as String,
    ayahIds: (map['ayah_ids']! as List).cast<int>(),
  );
}
