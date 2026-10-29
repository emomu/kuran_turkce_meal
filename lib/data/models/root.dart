/// Kelime kökü ve Kuran'daki geçişleri.
///
/// Veri, Quranic Arabic Corpus'un morfolojik çözümlemesinden türetilir ve
/// uygulama paketiyle birlikte `assets/data/roots.json` içinde gelir.
/// Kök sayısı 1651, köke bağlanan kelime sayısı ~50.000 olduğu için veri
/// SQLite'a değil belleğe alınır: kök arama kullanıcı yazarken sonuç
/// vermeli, her tuşta disk sorgusu yapmamalıdır.
library;

/// Kuran'da geçen tek bir kelime örneği.
///
/// Konum üçlüsü (sure, ayet, kelime sırası) ayet metnindeki kelimeye
/// doğrudan karşılık gelir; okuma ekranı bu sırayı kullanarak doğru kelimeyi
/// vurgular.
class RootWord {
  const RootWord({
    required this.surahNumber,
    required this.ayahNumber,
    required this.wordIndex,
    required this.arabic,
    required this.root,
    required this.lemma,
  });

  final int surahNumber;
  final int ayahNumber;

  /// Ayet içindeki kelime sırası. 0'dan başlar.
  final int wordIndex;

  /// Ayet metnindeki haliyle Arapça kelime (harekeli).
  final String arabic;

  /// Kelimenin kökü. Örn. "رسل".
  final String root;

  /// Sözlük biçimi. Örn. "رَسُول". Boş olabilir.
  final String lemma;

  factory RootWord.fromJson(Map<String, dynamic> json) => RootWord(
    surahNumber: json['s'] as int,
    ayahNumber: json['v'] as int,
    wordIndex: json['w'] as int,
    arabic: json['a'] as String,
    root: json['r'] as String,
    lemma: (json['l'] as String?) ?? '',
  );

  /// Paylaşım ve başlıklarda kullanılan referans. Örn. "2:255".
  String get reference => '$surahNumber:$ayahNumber';
}

/// Kökten türeyen bir kelime.
///
/// Kök tek başına soyuttur: "ك-ت-ب" harfleri kullanıcıya bir şey anlatmaz.
/// Ondan türeyen kelimeler (kitap, yazdı, yazıcı) kökün ne demek olduğunu
/// somutlaştırır.
class DerivedWord {
  const DerivedWord({
    required this.lemma,
    required this.count,
    required this.meaning,
    required this.kind,
  });

  /// Sözlük biçimi. Örn. "كِتاب".
  final String lemma;

  /// Bu kelimenin Kuran'da kaç kez geçtiği.
  final int count;

  /// Türkçe karşılık. Sözlükte bulunmayan kelimelerde boş kalır; o zaman
  /// [kind] etiketi tek bilgi kaynağıdır.
  final String meaning;

  /// Korpusun kelime türü etiketi: N, V, ACT_PCPL, PASS_PCPL, VN, ADJ, PN.
  /// Türkçeye çevirisi arayüz katmanında yapılır.
  final String kind;

  factory DerivedWord.fromJson(Map<String, dynamic> json) => DerivedWord(
    lemma: json['l'] as String,
    count: json['c'] as int,
    meaning: (json['m'] as String?) ?? '',
    kind: (json['p'] as String?) ?? '',
  );

  bool get hasMeaning => meaning.trim().isNotEmpty;
}

/// Bir kelime kökü.
class QuranRoot {
  const QuranRoot({
    required this.arabic,
    required this.normalized,
    required this.meaning,
    required this.count,
    required this.occurrences,
    required this.translitterations,
    required this.readings,
    required this.letters,
    this.derived = const [],
    this.surahDistribution = const [],
    this.verbForms = const [],
  });

  /// Arapça kök harfleri. Örn. "رسل".
  final String arabic;

  /// Hemze ve elif varyantları sadeleştirilmiş biçim — Arapça arama bunun
  /// üzerinden yapılır, böylece kullanıcı "الە" yazımını tutturmak zorunda
  /// kalmaz.
  final String normalized;

  /// Türkçe anlam(lar). Örn. "göndermek, elçi, peygamber".
  final String meaning;

  /// Kökün Kuran'daki toplam geçiş sayısı.
  final int count;

  /// [RootWord] listesindeki konumlar. Sıra mushaf sırasıdır.
  ///
  /// Kelimelerin kendisi değil indeksleri tutulur: aynı kelime nesnesi hem
  /// kök listesinden hem ayet aramasından erişilebilsin, bellekte iki kopya
  /// durmasın.
  final List<int> occurrences;

  /// Latin harfli iskelet yazımlar. Örn. "rsl". Kullanıcı sesli harfleri
  /// atlayarak arayabilir.
  final List<String> translitterations;

  /// Türkçe okunuşlar. Örn. "resul", "risale". En sık türev kelimelerden
  /// üretilir; kullanıcı bildiği kelimeyi yazarak köke ulaşır.
  final List<String> readings;

  /// Kökü oluşturan harfler — harf filtresi bu küme üzerinden tarar.
  final List<String> letters;

  /// Kökten türeyen kelimeler, sıklığa göre azalan. En çok 12 tane.
  final List<DerivedWord> derived;

  /// Kökün sure dağılımı: `(sure numarası, geçiş sayısı)` çiftleri, sure
  /// sırasında. Kökün Kuran'a nasıl yayıldığını gösteren şerit bundan
  /// çizilir.
  final List<(int, int)> surahDistribution;

  /// Fiil kalıbı (bab) dağılımı: `(kalıp, geçiş sayısı)`. Arapçada kalıp
  /// anlamı değiştirir — I "yapmak", II "yaptırmak", VII "yapılmak".
  /// Yalnızca fiil olarak geçen köklerde dolu.
  final List<(int, int)> verbForms;

  factory QuranRoot.fromJson(Map<String, dynamic> json) => QuranRoot(
    arabic: json['r'] as String,
    normalized: json['n'] as String,
    meaning: (json['m'] as String?) ?? '',
    count: json['c'] as int,
    occurrences: (json['o'] as List).cast<int>(),
    translitterations: (json['t'] as List).cast<String>(),
    readings: ((json['k'] as List?) ?? const []).cast<String>(),
    letters: (json['L'] as List).cast<String>(),
    derived: ((json['d'] as List?) ?? const [])
        .map((e) => DerivedWord.fromJson(e as Map<String, dynamic>))
        .toList(),
    surahDistribution: _pairs(json['u']),
    verbForms: _pairs(json['b']),
  );

  /// `[[sure, adet], ...]` biçimindeki JSON dizisini çiftlere çevirir.
  static List<(int, int)> _pairs(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final e in raw)
        if (e is List && e.length == 2) (e[0] as int, e[1] as int),
    ];
  }

  /// Anlamın ilk karşılığı — listelerde tek satırda gösterilir.
  String get primaryMeaning {
    if (meaning.isEmpty) return '';
    final comma = meaning.indexOf(',');
    return comma == -1 ? meaning : meaning.substring(0, comma);
  }

  bool get hasMeaning => meaning.trim().isNotEmpty;
}

/// Harf filtresindeki tek bir Arap harfi.
class ArabicLetter {
  const ArabicLetter({required this.letter, required this.name});

  /// Harfin kendisi. Örn. "ر".
  final String letter;

  /// Türkçe okunuş adı. Örn. "re".
  final String name;

  factory ArabicLetter.fromJson(Map<String, dynamic> json) => ArabicLetter(
    letter: json['a'] as String,
    name: json['n'] as String,
  );
}
