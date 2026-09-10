/// Kullanıcının sorusunu bir niyete indirger.
///
/// Sıralama önemlidir ve rastgele değil: dar kalıplardan geniş olanlara doğru
/// gidilir. "2:255" hem referans hem konu araması gibi görünebilir; referans
/// önce denendiği için doğru olan kazanır. En sonda kalan "hiçbirine
/// uymadı" hâli alan dışı sayılır.
///
/// ALAN SINIRI
/// -----------
/// Asistanın "yalnızca Kur'an" sözünü tutan yer burası. Sınırı bir dil
/// modeline prompt ile söylemek güvenilmez; burada ise kod karar verir:
/// bir soru tanınmış bir niyete oturmuyorsa cevap üreten katmana hiç
/// ulaşmaz. Jailbreak edilecek bir talimat yok — reddetme, üretimin
/// önündedir.
library;

import '../../../data/db/search_normalizer.dart';
import '../../../data/models/prophet.dart';
import '../../../data/models/surah.dart';
import '../../search/data/verse_reference.dart';
import '../data/assistant_intent.dart';
import '../data/topic_lexicon.dart';

/// Soru → niyet dönüşümü. Saf fonksiyon: aynı girdi hep aynı çıktıyı verir.
class IntentClassifier {
  const IntentClassifier({
    required this.surahs,
    required this.prophets,
    required this.foldName,
    this.languageCode = 'tr',
  });

  final List<Surah> surahs;
  final List<Prophet> prophets;

  /// Arayüz dili. Konu etiketleri ve arama terimleri buna göre seçilir;
  /// İngilizce arayüzde İngilizce tetikleyiciler de tanınır.
  final String languageCode;

  bool get _en => languageCode == 'en';

  /// Ad karşılaştırma biçimi. Arama tarafıyla aynı katlamayı kullanmak için
  /// dışarıdan verilir — "musa" da "Mûsâ"yı bulmalı.
  final String Function(String) foldName;

  /// Fetva isteyen kalıplar.
  ///
  /// Asistan hüküm vermez ve veremez: elinde meal var, fıkıh yok. "Caiz mi"
  /// sorusuna ayet göstermek, o ayeti hükümmüş gibi sunmak olurdu. Bu tür
  /// sorular ilgili ayetlere yönlendirilir ama cevap hüküm içermez.
  static const _rulingPatterns = <String>[
    'haram mı', 'helal mi', 'caiz mi', 'günah mı', 'sevap mı',
    'farz mı', 'vacip mi', 'sünnet mi', 'mekruh mu',
    'fetva', 'hükmü ne', 'hükmü nedir', 'dinen', 'sakıncası var mı',
    // İngilizce karşılıkları. Aynı listede tutuluyor: kullanıcı arayüz
    // dilinden bağımsız olarak iki dilde de sorabilir.
    'is it haram', 'is it halal', 'is it permissible', 'is it a sin',
    'is it allowed', 'fatwa', 'ruling on', 'what is the ruling',
  ];

  /// Kur'an alanının açıkça dışında kalan kalıplar.
  ///
  /// Kapının ilk denetimi. Liste kısa tutuldu: amaç her alan dışı soruyu
  /// listelemek değil — o zaten mümkün değil — sık gelenleri erken elemek.
  /// Asıl sınır, hiçbir niyete oturmayan sorunun reddedilmesiyle çizilir.
  static const _offTopicPatterns = <String>[
    'hava durumu', 'hava nasıl', 'saat kaç', 'bugün günlerden',
    'kod yaz', 'python', 'javascript', 'kaç para', 'dolar', 'euro',
    'maç skoru', 'kim kazandı', 'film öner', 'şarkı', 'yemek tarifi',
    'nasıl gidilir', 'telefon numarası', 'hesapla',
    'weather', 'what time is it', 'write code', 'stock price',
    'exchange rate', 'match score', 'who won', 'recommend a movie',
    'recipe', 'phone number', 'calculate',
  ];

  /// Yardım isteyen kalıplar.
  static const _helpPatterns = <String>[
    'ne yapabilirsin', 'neler yapabilirsin', 'yardım', 'nasıl kullanılır',
    'ne sorabilirim', 'kimsin', 'nesin', 'ne işe yararsın',
    'what can you do', 'what can i ask', 'how do i use', 'who are you',
    'what are you', 'help',
  ];

  /// Selamlama.
  static const _greetingPatterns = <String>[
    'selam', 'merhaba', 'selamün aleyküm', 'esselamü aleyküm', 'günaydın',
    'iyi akşamlar', 'iyi günler', 'hey', 'alo',
    'hello', 'hi', 'hey there', 'good morning', 'good evening',
    'salam', 'peace be upon you', 'assalamu alaikum',
  ];

  /// Devam isteyen kalıplar.
  static const _morePatterns = <String>[
    'daha', 'daha fazla', 'devam', 'devamı', 'başka', 'başkaları',
    'diğerleri', 'gerisi', 'daha var mı',
    'more', 'show more', 'next', 'continue', 'others', 'any more',
  ];

  /// Kıssa isteyen kalıplar. Anılma listesi yerine kıssa akışını seçtirir.
  static const _storyPatterns = <String>[
    'kıssa', 'kıssası', 'hikaye', 'hikayesi', 'öyküsü', 'hayatı',
    'başından geçen',
    'story', 'his story', 'the story of', 'life of', 'narrative',
  ];

  /// Sorguyu sınıflandırır.
  ///
  /// [hasPreviousResults] önceki cevapta ayet olup olmadığı. Takip
  /// ifadeleri ("daha fazla") ancak dayanacak bir sonuç varsa anlamlıdır.
  IntentResult classify(String raw, {bool hasPreviousResults = false}) {
    final normalized = SearchNormalizer.normalize(raw).trim();
    final compact = _stripPunctuation(normalized);

    IntentResult wrap(AssistantIntent intent) =>
        IntentResult(intent: intent, normalizedQuery: compact);

    if (compact.isEmpty) {
      return wrap(const OutOfScopeIntent(OutOfScopeReason.unclear));
    }

    // 1. Takip ifadeleri. Önceki sonuca dayandıkları için en önce bakılır:
    //    "daha fazla" tek başına bir konu araması gibi görünür ve yanlış
    //    dala girerdi.
    if (hasPreviousResults) {
      if (_matchesAny(compact, _morePatterns, exact: true)) {
        return wrap(const MoreResultsIntent());
      }
      final ordinal = _parseOrdinal(compact);
      if (ordinal != null) return wrap(OpenResultIntent(ordinal));
    }

    // 2. Selamlama ve yardım. Kısa ve kesin kalıplar.
    if (_matchesAny(compact, _greetingPatterns, exact: true)) {
      return wrap(const GreetingIntent());
    }
    if (_matchesAny(compact, _helpPatterns)) {
      return wrap(const HelpIntent());
    }

    // 3. Alan dışı. Cevap üreten hiçbir katmana ulaşmadan burada durur.
    if (_matchesAny(compact, _offTopicPatterns)) {
      return wrap(const OutOfScopeIntent(OutOfScopeReason.offTopic));
    }

    // 4. Ayet referansı ve peygamber adı. Sıraları basit değil, çünkü altı
    //    ad ikisine birden ait: Yûnus, Hûd, Yûsuf, İbrâhim, Muhammed, Nûh
    //    hem birer sure hem birer peygamberdir.
    //
    //    Ayrım niyete bakılarak yapılır. Ayet numarası yazan kullanıcı bir
    //    yere gitmek ister ("Muhammed 5"), yazmayan ise kişiyi sorar
    //    ("Muhammed") — ve beklediği 38 ayetlik sure künyesi değil, adının
    //    geçtiği 140 ayettir. Sureye gitmek isterse cevaptaki eylem oraya
    //    götürür; tersi mümkün değildi, o yüzden bu yön seçildi.
    final reference = _resolveReference(raw);
    final prophet = _resolveProphet(compact);

    if (reference != null && reference.ayahNumber != null) {
      return wrap(reference);
    }
    if (prophet != null) {
      return wrap(ProphetIntent(
        prophet: prophet.prophet,
        wantsStory: prophet.wantsStory,
        sameNameSurah: reference?.surah,
      ));
    }
    if (reference != null) return wrap(reference);

    // 6. Sure künyesi: "kehf kaç ayet", "bakara nerede indi".
    final surahInfo = _resolveSurahInfo(compact);
    if (surahInfo != null) return wrap(surahInfo);

    // 7. Fetva sorusu. Konudan önce bakılır: "faiz haram mı" hem hüküm
    //    sorusu hem borç konusudur; hüküm uyarısı öncelikli.
    if (_matchesAny(compact, _rulingPatterns)) {
      return wrap(const OutOfScopeIntent(OutOfScopeReason.religiousRuling));
    }

    // 8. Durum ve konu sözlüğü. Durumlar önce denenir: "zor zamandayım"
    //    hem durum hem "zor" kelimesiyle konu araması olabilir.
    final situation = _resolveTopic(compact, TopicLexicon.situations);
    if (situation != null) return wrap(situation);

    final concept = _resolveTopic(compact, TopicLexicon.concepts);
    if (concept != null) return wrap(concept);

    // 9. Serbest arama. Sözlükte yoksa da kullanıcının kelimeleri mealde
    //    geçiyor olabilir; arama katmanı karar verir. Buraya düşen sorgu
    //    hiç sonuç getirmezse cevap "bulamadım" olur — uydurma değil.
    if (_looksSearchable(compact)) {
      return wrap(TopicIntent(query: raw.trim(), topicLabel: raw.trim()));
    }

    return wrap(const OutOfScopeIntent(OutOfScopeReason.unclear));
  }

  /// Sorgu bir ayet referansına çözülüyor mu.
  ReferenceIntent? _resolveReference(String raw) {
    final parsed = parseVerseReference(
      raw,
      resolveSurahName: _surahNumberByName,
    );
    if (parsed == null) return null;

    final matches = surahs.where((s) => s.number == parsed.surahNumber);
    if (matches.isEmpty) return null;

    final surah = matches.first;
    final ayahNumber = parsed.ayahNumber;
    // Sure sınırının dışındaki numara referans sayılmaz; kullanıcıyı var
    // olmayan bir ayete göndermektense aramaya bırakmak yeğdir.
    if (ayahNumber != null && ayahNumber > surah.ayahCount) return null;

    return ReferenceIntent(surah: surah, ayahNumber: ayahNumber);
  }

  /// Sorguda bir peygamber adı geçiyor mu.
  ///
  /// Tam eşleşme aranmaz: "yusuf kimdir" ya da "muhammed hakkında" gibi
  /// cümlelerde ad kelimelerden biridir.
  ProphetIntent? _resolveProphet(String compact) {
    final words = compact.split(RegExp(r'\s+'));
    final wantsStory = _matchesAny(compact, _storyPatterns);

    for (final word in words) {
      if (word.length < 3) continue;
      for (final p in prophets) {
        if (foldName(p.name) == word || foldName(p.nameEn) == word) {
          return ProphetIntent(prophet: p, wantsStory: wantsStory);
        }
      }
    }
    return null;
  }

  /// Sorgu bir sure künyesi soruyor mu.
  SurahInfoIntent? _resolveSurahInfo(String compact) {
    final facet = _parseSurahFacet(compact);
    if (facet == null) return null;

    // Künye sorusu var; hangi sure sorulduğunu bul.
    final words = compact.split(RegExp(r'\s+'));
    for (final word in words) {
      if (word.length < 3) continue;
      final number = _surahNumberByName(word);
      if (number == null) continue;
      final matches = surahs.where((s) => s.number == number);
      if (matches.isEmpty) continue;
      return SurahInfoIntent(surah: matches.first, facet: facet);
    }
    return null;
  }

  /// Künye sorusunun hangi yanı istediği.
  SurahFacet? _parseSurahFacet(String compact) {
    bool has(List<String> patterns) =>
        patterns.any((p) => compact.contains(p));

    if (has(const [
      'kaç ayet', 'ayet sayısı',
      'how many verses', 'verse count',
    ])) {
      return SurahFacet.ayahCount;
    }
    if (has(const [
      'nerede indi', 'mekki mi', 'medeni mi', 'mekke mi',
      'where was it revealed', 'meccan or medinan', 'is it meccan',
      'is it medinan', 'where revealed',
    ])) {
      return SurahFacet.revelationPlace;
    }
    if (has(const [
      'kaçıncı sure', 'kaçıncı sırada', 'iniş sırası',
      'revelation order', 'what order', 'which number',
    ])) {
      return SurahFacet.revelationOrder;
    }
    if (has(const [
      'ne demek', 'anlamı', 'ne anlama',
      'what does it mean', 'meaning of', 'name mean',
    ])) {
      return SurahFacet.meaning;
    }
    if (has(const [
      'suresi hakkında', 'suresi nedir', 'hakkında bilgi',
      'about surah', 'tell me about', 'information about',
    ])) {
      return SurahFacet.overview;
    }
    return null;
  }

  /// Sorgu sözlükteki bir konuya oturuyor mu.
  ///
  /// En uzun tetikleyici kazanır: "olum korkusu" hem "korku" hem "olum"
  /// konusuna değer; uzun olan daha belirlidir.
  TopicIntent? _resolveTopic(String compact, List<Topic> topics) {
    Topic? best;
    var bestLength = 0;

    for (final topic in topics) {
      // İngilizce arayüzde her iki tetikleyici kümesi de denenir: kullanıcı
      // arayüzü İngilizce yapmış olsa da "sabır" yazabilir, ya da tersi.
      // Yanlış eşleşme riski yok — iki dilin tetikleyicileri ayrık.
      final triggers = _en
          ? [...topic.triggersEn, ...topic.triggers]
          : [...topic.triggers, ...topic.triggersEn];

      for (final trigger in triggers) {
        if (!_containsWord(compact, trigger)) continue;
        if (trigger.length > bestLength) {
          best = topic;
          bestLength = trigger.length;
        }
      }
    }

    if (best == null) return null;
    final label = best.labelFor(languageCode);
    return TopicIntent(
      query: label,
      topicLabel: label,
      terms: best.termsFor(languageCode),
      isSituational: best.isSituational,
    );
  }

  /// Sorgu serbest aramaya değer mi.
  ///
  /// Tek harfli girdiler ve yalnızca rakamdan oluşanlar elenir; geri kalan
  /// aramaya gider. Cömert davranılır çünkü mealde geçen her kelime meşru
  /// bir sorgudur ve sözlük hepsini kapsayamaz.
  bool _looksSearchable(String compact) {
    if (compact.length < 3) return false;
    if (RegExp(r'^[0-9\s]+$').hasMatch(compact)) return false;
    return true;
  }

  /// "ikincisini aç", "3." gibi sıra ifadelerini indise çevirir.
  int? _parseOrdinal(String compact) {
    const words = <String, int>{
      'birinci': 0, 'ilk': 0, 'birincisi': 0, 'birincisini': 0,
      'ikinci': 1, 'ikincisi': 1, 'ikincisini': 1,
      'üçüncü': 2, 'üçüncüsü': 2, 'üçüncüsünü': 2,
      'dördüncü': 3, 'dördüncüsü': 3, 'dördüncüsünü': 3,
      'beşinci': 4, 'beşincisi': 4, 'beşincisini': 4,
      'sonuncu': -1, 'sonuncusu': -1, 'sonuncusunu': -1,
      'first': 0, 'second': 1, 'third': 2, 'fourth': 3, 'fifth': 4,
      'last': -1,
    };

    for (final entry in words.entries) {
      if (_containsWord(compact, entry.key)) return entry.value;
    }

    // "2. ayeti ac" / "2 nolu"
    final numeric = RegExp(r'^(\d{1,2})\s*(\.|nolu|numarali)?\s*'
            r'(ayet|sonuc|siradaki|verse|result)?\s*'
            r'(ac|goster|getir|open|show)?$')
        .firstMatch(compact);
    if (numeric != null) {
      final n = int.tryParse(numeric.group(1)!);
      if (n != null && n >= 1 && n <= 20) return n - 1;
    }
    return null;
  }

  /// Yazılan adı sure numarasına çevirir.
  int? _surahNumberByName(String name) {
    final needle = foldName(name);
    if (needle.length < 2) return null;

    for (final s in surahs) {
      final candidates = [s.name, s.nameEn ?? '', s.meaning, s.meaningEn ?? '']
          .map(foldName);
      if (candidates.any((c) => c == needle)) return s.number;
    }

    for (final s in surahs) {
      final candidates = [s.name, s.nameEn ?? ''].map(foldName);
      if (candidates.any((c) => c.isNotEmpty && c.startsWith(needle))) {
        return s.number;
      }
    }
    return null;
  }

  /// Noktalama temizliği. Eşleştirme kalıpları noktalamasız yazılır.
  static String _stripPunctuation(String input) => input
      .replaceAll(RegExp('[?!.,;:()\\[\\]{}"\'’‘]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// Kalıplardan biri metinde geçiyor mu.
  ///
  /// [exact] verilirse metnin tamamı kalıba eşit olmalıdır: "daha" takip
  /// ifadesidir ama "daha fazla sabir" bir konu sorusudur.
  static bool _matchesAny(
    String text,
    List<String> patterns, {
    bool exact = false,
  }) {
    for (final p in patterns) {
      if (exact ? text == p : text.contains(p)) return true;
    }
    return false;
  }

  /// Kelime sınırına saygılı içerme.
  ///
  /// Düz `contains` "es" tetikleyicisini "beş" içinde bulurdu. Türkçe
  /// harflerde `\b` güvenilir çalışmadığı için sınır elle denetlenir.
  static bool _containsWord(String text, String needle) {
    if (needle.contains(' ')) return text.contains(needle);

    var from = 0;
    while (true) {
      final i = text.indexOf(needle, from);
      if (i < 0) return false;

      final beforeOk = i == 0 || !_isWordChar(text[i - 1]);
      final end = i + needle.length;
      // Sonda ek olabilir ("sabirla", "namazi"); son sınır aranmaz.
      if (beforeOk) return true;
      from = end;
    }
  }

  static bool _isWordChar(String ch) =>
      RegExp(r'[0-9a-zçğıöşüâîû]').hasMatch(ch);
}
