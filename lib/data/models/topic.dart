/// Fihristteki bir konu ve o konunun ayetleri.
///
/// Peygamber kıssalarıyla aynı işi yapar — bir başlık altında ayet toplar —
/// ama iki yerde ondan ayrılır:
///
/// Sıralama mushaf sırasıdır. Kıssada iniş sırası anlatının geliştiğini
/// gösterir ve ekranın varlık sebebidir; fihristte böyle bir gelişim yoktur.
/// "Miras hükümleri"ne bakan kullanıcı Nisâ'yı beklediği yerde arar.
///
/// Liste iki bölümlüdür. İlk [coreCount] ayet kürasyonla seçilmiştir: o
/// konuyu kuran ayetler. Gerisi meal metninde terim taramasından gelir ve
/// isabetli olsa da ikincildir. Ayrım [core] ve [scanned] ile okunur;
/// arayüz ikisinin arasına bir sınır çizebilir.
class Topic {
  const Topic({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.categoryId,
    required this.ayahIds,
    required this.coreCount,
    required this.relatedIds,
  });

  /// Kalıcı kimlik. Veri yeniden üretildiğinde değişmez; gezinme buna
  /// bağlanır (`/fihrist/sabir`).
  final String id;

  final String name;
  final String nameEn;

  /// Bağlı olduğu bölüm ([TopicCategory.id]).
  final String categoryId;

  /// Konunun ayetleri, mushaf sırasına göre.
  ///
  /// İlk [coreCount] tanesi çekirdektir; ikisi de kendi içinde sıralıdır.
  final List<int> ayahIds;

  /// Kürasyonla seçilmiş ayet sayısı.
  ///
  /// Üretim aracı bunu yazar. Arayüz "bu konuyu kuran ayetler" ile "konuyla
  /// ilgili diğer ayetler" arasındaki sınırı buradan bilir — sınır olmasaydı
  /// kullanıcı taramadan gelen ikincil bir ayeti konunun merkezi sanabilirdi.
  final int coreCount;

  /// Fihristte "ilgili konular" olarak gösterilen konu kimlikleri.
  ///
  /// Üretimde karşılıklı hâle getirilir: bir yönden gidilen bağdan geri de
  /// dönülebilir.
  final List<String> relatedIds;

  String nameFor(String languageCode) => languageCode == 'en' ? nameEn : name;

  int get ayahCount => ayahIds.length;

  /// Kürasyonla seçilmiş ayetler. Listenin başında dururlar.
  List<int> get core => ayahIds.take(coreCount).toList();

  /// Taramadan gelen ayetler. Çekirdeğin ardından gelirler.
  List<int> get scanned => ayahIds.skip(coreCount).toList();

  /// Çekirdeğin ötesinde ayet var mı.
  ///
  /// Arayüz ayırıcıyı buna bakarak çizer; taramadan hiç ayet gelmemiş bir
  /// konuda boş bir başlık görünmesin.
  bool get hasScanned => ayahIds.length > coreCount;

  factory Topic.fromMap(Map<String, Object?> map) => Topic(
    id: map['id']! as String,
    name: map['name']! as String,
    nameEn: map['name_en']! as String,
    categoryId: map['category']! as String,
    ayahIds: (map['ayah_ids']! as List).cast<int>(),
    coreCount: map['core_count']! as int,
    relatedIds: (map['related'] as List?)?.cast<String>() ?? const [],
  );
}

/// Fihristin bölümü: konuları gruplayan başlık.
///
/// Ayrı bir tür, çünkü bölümün sırası veride tutulur ve arayüz onu korumak
/// zorundadır. Konuları kategori kimliğine göre gruplayıp alfabetik dizmek
/// "Ahiret"i "İbadet"in önüne alırdı; fihrist inançtan başlayıp gündelik
/// hâllere inen bir sıra izler.
class TopicCategory {
  const TopicCategory({
    required this.id,
    required this.name,
    required this.nameEn,
  });

  final String id;
  final String name;
  final String nameEn;

  String nameFor(String languageCode) => languageCode == 'en' ? nameEn : name;

  factory TopicCategory.fromMap(Map<String, Object?> map) => TopicCategory(
    id: map['id']! as String,
    name: map['name']! as String,
    nameEn: map['name_en']! as String,
  );
}
