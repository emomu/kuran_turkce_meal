/// Konu sözlüğü: kullanıcının kelimeleriyle mealin kelimeleri arasındaki köprü.
///
/// Tam metin araması kelime eşleşmesi yapar. Kullanıcı "zor zamanlarda ne
/// yapmalıyım" yazdığında mealde "zor zaman" geçmez — "sabır", "sıkıntı",
/// "darlık" geçer. Bu sözlük aradaki mesafeyi kapatır: soruyu tanır, arama
/// terimlerine çevirir.
///
/// Bir dil modelinin yerini tutmaz ama karşılığında kesindir: hangi sorunun
/// hangi terimlere gideceği burada yazılıdır, denetlenebilir ve düzeltilebilir.
/// Modelin "neden böyle dedi" sorusunun cevabı yoktur; burada vardır.
///
/// GENİŞLETME
/// ----------
/// Yeni konu eklemek bir girdi yazmaktır. `triggers` kullanıcının yazabileceği
/// biçimler, `terms` mealde geçen karşılıklar. Terimler OR ile aranır, bu
/// yüzden geniş tutulabilir; tetikleyiciler ise dar olmalı, yoksa alakasız
/// sorular konuya bağlanır.
library;

/// Tek bir konu: kullanıcının dilinden mealin diline eşleme.
class Topic {
  const Topic({
    required this.id,
    required this.label,
    required this.labelEn,
    required this.triggers,
    required this.terms,
    required this.termsEn,
    this.triggersEn = const [],
    this.isSituational = false,
  });

  final String id;

  /// Cevapta anılan ad: "sabır".
  final String label;
  final String labelEn;

  /// Kullanıcının yazabileceği biçimler. Normalleştirilmiş (şapkasız, küçük)
  /// hâlde yazılır; eşleştirme de normalleştirilmiş metinde yapılır.
  final List<String> triggers;

  /// Mealde aranacak Türkçe terimler. OR ile bağlanır.
  final List<String> terms;

  /// Mealde aranacak İngilizce terimler.
  final List<String> termsEn;

  /// Kullanıcının İngilizce yazabileceği biçimler.
  ///
  /// [triggers] ile aynı kurala tabi: normalleştirilmiş hâlde yazılır.
  /// Boş bırakılırsa konu yalnızca Türkçe sorularla bulunur.
  final List<String> triggersEn;

  /// Bu konu bir durum mu anlatıyor ("zorlanıyorum") yoksa kavram mı
  /// ("sabır"). Cevabın açılışı buna göre değişir.
  final bool isSituational;

  List<String> termsFor(String languageCode) =>
      languageCode == 'en' ? termsEn : terms;

  String labelFor(String languageCode) =>
      languageCode == 'en' ? labelEn : label;
}

/// Uygulamanın tanıdığı konular.
abstract final class TopicLexicon {
  /// Kavram konuları: kullanıcı doğrudan konuyu adıyla sorar.
  static const concepts = <Topic>[
    Topic(
      id: 'sabir',
      label: 'sabır',
      labelEn: 'patience',
      triggers: ['sabır', 'sabretmek', 'sabırlı', 'dayanmak', 'tahammül'],
      terms: ['sabr', 'sabred', 'sabırl', 'katlan'],
      termsEn: ['patien', 'perseve', 'steadfast', 'endure'],
      triggersEn: ['patience', 'patient', 'endure', 'persevere', 'be steadfast'],
    ),
    Topic(
      id: 'namaz',
      label: 'namaz',
      labelEn: 'prayer',
      triggers: ['namaz', 'salat', 'kılmak', 'ibadet vakti'],
      terms: ['namaz', 'rüku', 'secde'],
      termsEn: ['prayer', 'pray', 'bow', 'prostrat'],
      triggersEn: ['prayer', 'pray', 'salah', 'worship time'],
    ),
    Topic(
      id: 'zekat',
      label: 'zekât ve infak',
      labelEn: 'charity',
      triggers: ['zekat', 'infak', 'sadaka', 'yardım etmek', 'vermek'],
      terms: ['zekat', 'infak', 'sadaka', 'harca'],
      termsEn: ['charit', 'alms', 'spend', 'give'],
      triggersEn: ['charity', 'alms', 'zakat', 'giving', 'donate'],
    ),
    Topic(
      id: 'oruc',
      label: 'oruç',
      labelEn: 'fasting',
      triggers: ['oruç', 'ramazan', 'ramadan'],
      terms: ['oruç', 'ramazan'],
      termsEn: ['fast', 'ramadan'],
      triggersEn: ['fasting', 'fast', 'ramadan'],
    ),
    Topic(
      id: 'adalet',
      label: 'adalet',
      labelEn: 'justice',
      triggers: ['adalet', 'adil', 'hak', 'hakkaniyet', 'zulüm'],
      terms: ['adalet', 'adil', 'zulm', 'zalim', 'insaf'],
      termsEn: ['justice', 'just', 'oppress', 'wrong'],
      triggersEn: ['justice', 'just', 'fair', 'injustice', 'oppression'],
    ),
    Topic(
      id: 'tovbe',
      label: 'tövbe ve bağışlanma',
      labelEn: 'repentance',
      triggers: ['tövbe', 'pişmanlık', 'bağışlanma', 'af', 'günah',
                 'affetmek', 'mağfiret'],
      terms: ['tövbe', 'bağışla', 'affed', 'mağfiret', 'günah'],
      termsEn: ['repent', 'forgiv', 'pardon', 'sin'],
      triggersEn: ['repentance', 'repent', 'forgiveness', 'sin', 'pardon'],
    ),
    Topic(
      id: 'sukur',
      label: 'şükür',
      labelEn: 'gratitude',
      triggers: ['şükür', 'şükretmek', 'nimet', 'minnettarlık'],
      terms: ['şükr', 'şükred', 'nimet', 'hamd'],
      termsEn: ['thank', 'gratef', 'grace', 'favour'],
      triggersEn: ['gratitude', 'thankful', 'grateful', 'blessing'],
    ),
    Topic(
      id: 'anne_baba',
      label: 'anne babaya iyilik',
      labelEn: 'parents',
      triggers: ['anne', 'baba', 'ebeveyn', 'anne baba', 'aile'],
      terms: ['ana baba', 'anne', 'baba', 'akraba'],
      termsEn: ['parent', 'mother', 'father', 'kin'],
      triggersEn: ['parents', 'mother', 'father', 'family'],
    ),
    Topic(
      id: 'borc',
      label: 'borç ve alışveriş',
      labelEn: 'debt and trade',
      triggers: ['borç', 'alışveriş', 'ticaret', 'faiz', 'riba', 'ödünç'],
      terms: ['borç', 'alışveriş', 'ticaret', 'faiz', 'riba', 'ödünç'],
      termsEn: ['debt', 'trade', 'usury', 'interest', 'loan'],
      triggersEn: ['debt', 'trade', 'usury', 'interest', 'loan', 'business'],
    ),
    Topic(
      id: 'olum',
      label: 'ölüm ve âhiret',
      labelEn: 'death and the hereafter',
      triggers: ['ölüm', 'ahiret', 'kıyamet', 'diriltilmek', 'mahşer',
                 'öldükten sonra'],
      terms: ['ölüm', 'ahiret', 'kıyamet', 'diril'],
      termsEn: ['death', 'hereafter', 'resurrect', 'judgement'],
      triggersEn: ['death', 'hereafter', 'afterlife', 'resurrection', 'judgment day'],
    ),
    Topic(
      id: 'cennet',
      label: 'cennet',
      labelEn: 'paradise',
      triggers: ['cennet', 'firdevs', 'huri'],
      terms: ['cennet', 'firdevs', 'naim', 'bahçe'],
      termsEn: ['paradise', 'garden', 'bliss'],
      triggersEn: ['paradise', 'heaven', 'garden'],
    ),
    Topic(
      id: 'cehennem',
      label: 'cehennem',
      labelEn: 'hell',
      triggers: ['cehennem', 'ateşi', 'azap'],
      terms: ['cehennem', 'ateş', 'azap'],
      termsEn: ['hell', 'fire', 'torment', 'punish'],
      triggersEn: ['hell', 'hellfire', 'torment'],
    ),
    Topic(
      id: 'tevhid',
      label: 'Allah\'ın birliği',
      labelEn: 'the oneness of God',
      triggers: ['tevhid', 'allahın birliği', 'şirk', 'ortak koşmak',
                 'allah kimdir', 'allah nedir'],
      terms: ['ortak koş', 'şirk', 'tek ilah', 'ondan başka'],
      termsEn: ['associate', 'partner', 'no god but', 'one god'],
      triggersEn: ['oneness', 'tawhid', 'monotheism', 'who is god', 'what is god'],
    ),
    Topic(
      id: 'ilim',
      label: 'ilim ve akıl',
      labelEn: 'knowledge and reason',
      triggers: ['ilim', 'bilgi', 'akıl', 'düşünmek', 'öğrenmek', 'okumak'],
      terms: ['ilim', 'akled', 'düşün', 'akıl'],
      termsEn: ['knowledg', 'reason', 'reflect', 'understand'],
      triggersEn: ['knowledge', 'reason', 'think', 'learn', 'read', 'wisdom'],
    ),
    Topic(
      id: 'dogruluk',
      label: 'doğruluk ve yalan',
      labelEn: 'truthfulness',
      triggers: ['doğruluk', 'yalan', 'dürüstlük', 'sadakat', 'iftira'],
      terms: ['doğru', 'yalan', 'sadık', 'iftira', 'dürüst'],
      termsEn: ['truth', 'lie', 'false', 'slander'],
      triggersEn: ['truthfulness', 'truth', 'lying', 'lie', 'honesty', 'slander'],
    ),
    Topic(
      id: 'komsu',
      label: 'komşuluk ve yetim hakkı',
      labelEn: 'neighbours and orphans',
      triggers: ['komşu', 'yetim', 'öksüz', 'kimsesiz', 'yoksul', 'fakir'],
      terms: ['komşu', 'yetim', 'yoksul', 'miskin', 'fakir'],
      termsEn: ['neighbour', 'orphan', 'poor', 'needy'],
      triggersEn: ['neighbour', 'neighbor', 'orphan', 'poor', 'needy'],
    ),
    Topic(
      id: 'dua',
      label: 'dua',
      labelEn: 'supplication',
      triggers: ['dua', 'yakarmak', 'istemek', 'dua etmek'],
      terms: ['dua', 'yalvar', 'çağır', 'niyaz'],
      termsEn: ['suppli', 'call upon', 'pray to', 'invoke'],
      triggersEn: ['supplication', 'invoke', 'call upon god', 'asking god'],
    ),
    Topic(
      id: 'kuran',
      label: 'Kur\'an',
      labelEn: 'the Qur\'an',
      triggers: ['kuran', 'kitap', 'vahiy', 'indirilen'],
      terms: ['kuran', 'vahy', 'kitap'],
      termsEn: ['quran', 'book', 'revelat', 'sent down'],
      triggersEn: ['quran', 'scripture', 'revelation', 'the book'],
    ),
    Topic(
      id: 'evlilik',
      label: 'evlilik ve aile',
      triggers: ['evlilik', 'nikah', 'eş', 'kadın', 'boşanma', 'evlenmek'],
      labelEn: 'marriage and family',
      terms: ['nikah', 'zevce', 'boşan', 'evlen'],
      termsEn: ['marri', 'spouse', 'wife', 'divorc'],
      triggersEn: ['marriage', 'marry', 'spouse', 'wife', 'divorce', 'women'],
    ),
    Topic(
      id: 'savas',
      label: 'savaş ve barış',
      labelEn: 'war and peace',
      triggers: ['savaş', 'barış', 'cihad', 'harp', 'düşman'],
      terms: ['savaş', 'barış', 'cihad', 'düşman'],
      termsEn: ['fight', 'peace', 'war', 'enemy'],
      triggersEn: ['war', 'peace', 'fighting', 'jihad', 'enemy'],
    ),
  ];

  /// Durum konuları: kullanıcı kendi hâlini anlatır, konu adı vermez.
  ///
  /// "Zor zamanlarda ne yapmalıyım" bir bilgi sorusu değil; kullanıcı dayanak
  /// arıyor. Cevap da ona göre açılır.
  static const situations = <Topic>[
    Topic(
      id: 'zorluk',
      label: 'zorluk ve sıkıntı',
      labelEn: 'hardship',
      triggers: ['zor zaman', 'zorlanıyorum', 'sıkıntı', 'zor durumda',
                 'bunaldım', 'çok zor', 'dara düştüm', 'başım dertte',
                 'zorluk çekiyorum'],
      terms: ['sabr', 'sıkıntı', 'darlık', 'kolaylık', 'güçlük'],
      termsEn: ['hardship', 'ease', 'patien', 'relief'],
      triggersEn: ['hard time', 'struggling', 'difficulty', 'i am struggling',
                   'going through a hard time', 'overwhelmed'],
      isSituational: true,
    ),
    Topic(
      id: 'uzuntu',
      label: 'üzüntü ve keder',
      labelEn: 'sorrow',
      triggers: ['üzgünüm', 'üzüntü', 'kederliyim', 'mutsuzum', 'ağlıyorum',
                 'moralim bozuk', 'çok üzgünüm'],
      terms: ['üzül', 'üzüntü', 'keder', 'mahzun', 'korkma'],
      termsEn: ['griev', 'sorrow', 'sad', 'do not grieve'],
      triggersEn: ['i am sad', 'sadness', 'sorrow', 'grief', 'feeling down', 'crying'],
      isSituational: true,
    ),
    Topic(
      id: 'korku',
      label: 'korku ve endişe',
      labelEn: 'fear and anxiety',
      triggers: ['korkuyorum', 'korku', 'endişe', 'kaygı', 'tedirginim',
                 'gelecek korkusu', 'ölüm korkusu'],
      terms: ['korkma', 'korku', 'güven', 'emin ol'],
      termsEn: ['fear', 'afraid', 'secur', 'trust'],
      triggersEn: ['i am afraid', 'fear', 'anxiety', 'anxious', 'worried', 'scared'],
      isSituational: true,
    ),
    Topic(
      id: 'yalnizlik',
      label: 'yalnızlık',
      labelEn: 'loneliness',
      triggers: ['yalnızım', 'yalnızlık', 'kimsem yok', 'terk edildim'],
      terms: ['yalnız', 'beraber', 'yakın', 'dost', 'veli'],
      termsEn: ['alone', 'with you', 'near', 'protector'],
      triggersEn: ['i am lonely', 'loneliness', 'i have no one', 'abandoned'],
      isSituational: true,
    ),
    Topic(
      id: 'pismanlik',
      label: 'pişmanlık',
      labelEn: 'regret',
      triggers: ['pişmanım', 'hata yaptım', 'günah işledim',
                 'kendimi affedemiyorum', 'çok pişmanım'],
      terms: ['tövbe', 'bağışla', 'affed', 'mağfiret', 'ümit kesme'],
      termsEn: ['repent', 'forgiv', 'despair', 'mercy'],
      triggersEn: ['i regret', 'regret', 'i made a mistake', 'i sinned', 'guilt'],
      isSituational: true,
    ),
    Topic(
      id: 'sukran',
      label: 'şükran',
      labelEn: 'thankfulness',
      triggers: ['mutluyum', 'sevinçliyim', 'iyi haber aldım',
                 'nasıl şükredeceğim'],
      terms: ['şükr', 'nimet', 'hamd', 'şükred'],
      termsEn: ['thank', 'favour', 'praise', 'bless'],
      triggersEn: ['i am happy', 'good news', 'how do i give thanks', 'blessed'],
      isSituational: true,
    ),
    Topic(
      id: 'hastalik',
      label: 'hastalık ve şifa',
      labelEn: 'illness and healing',
      triggers: ['hastayım', 'hastalık', 'şifa', 'ağrılarım var',
                 'iyileşmek'],
      terms: ['şifa', 'hasta', 'deva', 'iyileştir'],
      termsEn: ['heal', 'cure', 'sick', 'ailment'],
      triggersEn: ['i am ill', 'illness', 'sick', 'healing', 'cure'],
      isSituational: true,
    ),
    Topic(
      id: 'ofke',
      label: 'öfke',
      labelEn: 'anger',
      triggers: ['sinirliyim', 'öfke', 'kızgınım', 'öfkeliyim',
                 'öfkemi tutamıyorum'],
      terms: ['öfke', 'gazab', 'kızgın', 'yumuşak', 'affed'],
      termsEn: ['anger', 'rage', 'pardon', 'restrain'],
      triggersEn: ['i am angry', 'anger', 'rage', 'furious', 'lost my temper'],
      isSituational: true,
    ),
  ];

  /// Tüm konular tek listede.
  static List<Topic> get all => [...concepts, ...situations];

  /// Kimliğe göre konu.
  static Topic? byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }
}
