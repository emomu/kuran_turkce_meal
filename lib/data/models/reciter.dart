/// Tilaveti okuyan kari.
///
/// Ses dosyaları uygulamayla paketlenmez; kullanıcı istediği sureyi indirir.
/// Tam Kur'an tek karide 128 kbps'de ~800 MB tutar ve uygulama boyutu bunu
/// kaldıramaz. Bu yüzden kari künyesi yalnızca dosyaların nereden indirileceğini
/// ve cihazda nereye yazılacağını tarif eder.
class Reciter {
  const Reciter({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.approximateBytesPerAyah,
  });

  /// Dosya sisteminde klasör adı olarak kullanılır; bu yüzden ASCII ve
  /// boşluksuz tutulur.
  final String id;

  /// Kullanıcıya gösterilen ad. Çeviri dosyasına konmadı: kari adları özel
  /// isimdir, arayüz dili değişince değişmezler.
  final String name;

  /// Ayet dosyalarının bulunduğu kök adres. Sonunda eğik çizgi bulunur.
  final String baseUrl;

  /// Bir ayetin ortalama dosya boyutu.
  ///
  /// İndirme onayında kullanıcıya "bu sure ne kadar yer tutacak" denilebilmesi
  /// için gerekir. Gerçek boyut ayetin uzunluğuna göre değişir; buradaki değer
  /// tüm mushaf üzerinden alınmış ortalamadır ve tahmini birkaç megabayt
  /// şaşabilir. Kullanıcı kararını verirken bu doğruluk yeterli — indirme
  /// başlamadan önce ağa sorup gerçek boyutu öğrenmek 286 ek istek demekti.
  final int approximateBytesPerAyah;

  /// Bir ayetin dosya adı: sure ve ayet numarası üçer haneye tamamlanır.
  ///
  /// Örn. Bakara 255 -> `002255.mp3`. Bu şema EveryAyah arşivinin tamamında
  /// aynıdır; kari değişse de dosya adı değişmez, yalnızca kök adres değişir.
  static String fileName(int surahNumber, int ayahNumber) {
    final surah = surahNumber.toString().padLeft(3, '0');
    final ayah = ayahNumber.toString().padLeft(3, '0');
    return '$surah$ayah.mp3';
  }

  /// Bir ayetin indirme adresi.
  String urlFor(int surahNumber, int ayahNumber) =>
      '$baseUrl${fileName(surahNumber, ayahNumber)}';

  /// Bir surenin tahmini indirme boyutu (bayt).
  int estimatedBytesFor(int ayahCount) => ayahCount * approximateBytesPerAyah;

  /// Uygulamanın tanıdığı kariler.
  ///
  /// Liste bilinçli olarak kısa: her kari ayrı bir indirme demek ve kullanıcı
  /// aynı sureyi iki kez indirmek istemez. Tanınmışlıkla üslup çeşitliliği
  /// arasında denge gözetilerek seçildiler — murattal (düz, öğrenmeye uygun)
  /// okuyuşlar önceliklendirildi.
  static const all = <Reciter>[
    Reciter(
      id: 'alafasy',
      name: 'Mishary Rashid Alafasy',
      baseUrl: 'https://everyayah.com/data/Alafasy_128kbps/',
      approximateBytesPerAyah: 135000,
    ),
    Reciter(
      id: 'husary',
      name: 'Mahmoud Khalil Al-Husary',
      baseUrl: 'https://everyayah.com/data/Husary_128kbps/',
      approximateBytesPerAyah: 150000,
    ),
    Reciter(
      id: 'abdulbasit',
      name: 'Abdul Basit Abdus-Samad',
      baseUrl: 'https://everyayah.com/data/Abdul_Basit_Murattal_192kbps/',
      approximateBytesPerAyah: 205000,
    ),
    Reciter(
      id: 'sudais',
      name: 'Abdurrahman As-Sudais',
      baseUrl: 'https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/',
      approximateBytesPerAyah: 195000,
    ),
    Reciter(
      id: 'minshawi',
      name: 'Mohamed Siddiq El-Minshawi',
      baseUrl: 'https://everyayah.com/data/Minshawy_Murattal_128kbps/',
      approximateBytesPerAyah: 140000,
    ),
  ];

  /// Varsayılan kari. En yaygın dinlenen ve kayıt kalitesi en tutarlı olan.
  ///
  /// [all] listesinin ilk öğesiyle aynı; sabit bağlamda `first` çağrılamadığı
  /// için ayrıca yazıldı.
  static const Reciter fallback = Reciter(
    id: 'alafasy',
    name: 'Mishary Rashid Alafasy',
    baseUrl: 'https://everyayah.com/data/Alafasy_128kbps/',
    approximateBytesPerAyah: 135000,
  );

  /// Kimliğe karşılık gelen kari; tanınmayan kimlikte varsayılana düşer.
  ///
  /// Kayıtlı tercih, listeden kaldırılmış bir kariyi gösteriyor olabilir
  /// (uygulama güncellenmiştir). O durumda hata vermek yerine varsayılanla
  /// devam etmek doğru: kullanıcı sesin çalmamasını değil, sesin çalmasını
  /// bekler.
  static Reciter byId(String? id) {
    if (id == null) return fallback;
    for (final reciter in all) {
      if (reciter.id == id) return reciter;
    }
    return fallback;
  }
}
