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
    Topic(
      id: 'hac',
      label: 'hac ve umre',
      labelEn: 'pilgrimage',
      triggers: ['hac', 'hacca', 'umre', 'kabe', 'tavaf', 'ihram',
                 'safa merve', 'arafat'],
      terms: ['hacc', 'kabe', 'beyt', 'tavaf', 'safa', 'merve', 'ihram'],
      termsEn: ['pilgrim', 'kaaba', 'sacred house', 'marwah'],
      triggersEn: ['hajj', 'umrah', 'pilgrimage', 'kaaba', 'tawaf'],
    ),
    Topic(
      id: 'faiz',
      label: 'faiz ve ticaret',
      labelEn: 'usury and trade',
      triggers: ['faiz', 'riba', 'tefeci', 'ticaret', 'alışveriş yaparken',
                 'kazanç', 'ölçü tartı', 'terazi'],
      terms: ['faiz', 'riba', 'ticaret', 'alışveriş', 'ölçü', 'tartı',
              'terazi', 'eksik ölç'],
      termsEn: ['usury', 'interest', 'trade', 'measure', 'balance', 'scale'],
      triggersEn: ['usury', 'interest', 'riba', 'trade', 'commerce',
                   'weights and measures'],
    ),
    Topic(
      id: 'kibir',
      label: 'kibir ve tevazu',
      labelEn: 'pride and humility',
      triggers: ['kibir', 'kibirli', 'gurur', 'büyüklenmek', 'tevazu',
                 'alçakgönüllü', 'kendini beğenmek'],
      terms: ['kibir', 'kibirlen', 'büyüklük tasla', 'böbürlen', 'övün',
              'şımar'],
      termsEn: ['arrogan', 'pride', 'boast', 'humble', 'humility'],
      triggersEn: ['pride', 'arrogance', 'humility', 'humble', 'boasting'],
    ),
    Topic(
      id: 'giybet',
      label: 'gıybet ve iftira',
      labelEn: 'backbiting and slander',
      triggers: ['gıybet', 'dedikodu', 'iftira', 'arkadan konuşmak',
                 'çekiştirmek', 'kara çalmak', 'lakap takmak'],
      terms: ['çekiştir', 'iftira', 'dedikodu', 'alay', 'lakap', 'zan'],
      termsEn: ['backbit', 'slander', 'gossip', 'mock', 'suspicion'],
      triggersEn: ['backbiting', 'gossip', 'slander', 'mocking others'],
    ),
    Topic(
      id: 'yemin',
      label: 'söz ve ahde vefa',
      labelEn: 'oaths and promises',
      triggers: ['yemin', 'söz vermek', 'ahit', 'ahde vefa', 'sözünde durmak',
                 'anlaşma', 'emanet'],
      terms: ['yemin', 'ahd', 'söz', 'emanet', 'anlaşma', 'sözleşme'],
      termsEn: ['oath', 'covenant', 'promise', 'trust', 'pledge'],
      triggersEn: ['oath', 'promise', 'covenant', 'keeping your word',
                   'trust'],
    ),
    Topic(
      id: 'yetim',
      label: 'yetim hakkı',
      labelEn: 'orphans',
      triggers: ['yetim', 'yetimler', 'öksüz', 'kimsesiz çocuk'],
      terms: ['yetim', 'öksüz'],
      termsEn: ['orphan'],
      triggersEn: ['orphan', 'orphans'],
    ),
    Topic(
      id: 'kadin',
      label: 'kadın ve hakları',
      labelEn: 'women',
      triggers: ['kadın', 'kadınlar', 'kadın hakları', 'hanım', 'eş hakkı',
                 'kız çocuğu'],
      terms: ['kadın', 'hanım', 'kız', 'eş', 'ana', 'mehir'],
      termsEn: ['women', 'woman', 'wife', 'daughter', 'mother'],
      triggersEn: ['women', 'woman', 'rights of women', 'daughters'],
    ),
    Topic(
      id: 'yaratilis',
      label: 'yaratılış ve tabiat',
      labelEn: 'creation and nature',
      triggers: ['yaratılış', 'kainat', 'evren', 'gökyüzü', 'yıldızlar',
                 'tabiat', 'doğa', 'dünyanın yaratılışı', 'gece gündüz'],
      terms: ['yarat', 'gökler', 'yer', 'yıldız', 'güneş', 'ay', 'gece',
              'gündüz', 'yağmur', 'deniz'],
      termsEn: ['creat', 'heaven', 'earth', 'star', 'sun', 'moon', 'night',
                'day', 'rain', 'sea'],
      triggersEn: ['creation', 'universe', 'nature', 'sky', 'stars',
                   'how was the world created'],
    ),
    Topic(
      id: 'rizik',
      label: 'rızık ve mal',
      labelEn: 'provision and wealth',
      triggers: ['rızık', 'rizik', 'nafaka', 'geçim', 'mal', 'zenginlik',
                 'servet', 'para', 'fakirlik'],
      terms: ['rızık', 'rızkı', 'mal', 'servet', 'zengin', 'fakir',
              'nimet', 'geçim'],
      termsEn: ['provision', 'sustenance', 'wealth', 'rich', 'poor',
                'bounty'],
      triggersEn: ['provision', 'sustenance', 'wealth', 'money', 'poverty',
                   'livelihood'],
    ),
    Topic(
      id: 'kader',
      label: 'kader ve takdir',
      labelEn: 'destiny',
      triggers: ['kader', 'kaza kader', 'takdir', 'alın yazısı',
                 'her şey yazılmış mı', 'irade'],
      terms: ['takdir', 'yaz', 'levh', 'ecel', 'dile'],
      termsEn: ['decree', 'destin', 'ordain', 'appointed term', 'will'],
      triggersEn: ['destiny', 'fate', 'predestination', 'decree'],
    ),
    Topic(
      id: 'melekler',
      label: 'melekler',
      labelEn: 'angels',
      triggers: ['melek', 'melekler', 'cebrail', 'mikail', 'israfil',
                 'azrail', 'kiramen katibin'],
      terms: ['melek', 'cebrail', 'ruh', 'kâtip', 'koruyucu'],
      termsEn: ['angel', 'gabriel', 'spirit', 'guardian'],
      triggersEn: ['angel', 'angels', 'gabriel'],
    ),
    Topic(
      id: 'seytan',
      label: 'şeytan ve vesvese',
      labelEn: 'satan and whispers',
      triggers: ['şeytan', 'iblis', 'vesvese', 'şeytanın vesvesesi',
                 'kötü düşünceler', 'ayartma'],
      terms: ['şeytan', 'iblis', 'vesvese', 'aldat', 'saptır', 'düşman'],
      termsEn: ['satan', 'devil', 'whisper', 'deceive', 'astray'],
      triggersEn: ['satan', 'devil', 'whispers', 'temptation', 'evil thoughts'],
    ),
    Topic(
      id: 'hicret',
      label: 'hicret ve göç',
      labelEn: 'migration',
      triggers: ['hicret', 'göç', 'muhacir', 'ensar', 'yurdundan çıkmak',
                 'sığınmak'],
      terms: ['hicret', 'göç', 'yurt', 'muhacir', 'sığın', 'çıkarıl'],
      termsEn: ['migrat', 'emigrat', 'homes', 'refuge', 'expelled'],
      triggersEn: ['migration', 'hijrah', 'refugee', 'emigrants'],
    ),
    Topic(
      id: 'yonetim',
      label: 'yönetim ve danışma',
      labelEn: 'governance and consultation',
      triggers: ['yönetim', 'danışma', 'şura', 'istişare', 'emanet ehline',
                 'yönetici', 'idare'],
      terms: ['şura', 'danış', 'emanet', 'hüküm', 'idare'],
      termsEn: ['consult', 'counsel', 'authority', 'trust', 'rule'],
      triggersEn: ['governance', 'consultation', 'leadership', 'authority'],
    ),
    Topic(
      id: 'tevekkul',
      label: 'tevekkül ve güven',
      labelEn: 'trust in God',
      triggers: ['tevekkül', 'tevekkul', 'allaha güvenmek', 'dayanmak',
                 'teslimiyet', 'kendimi bırakmak'],
      terms: ['tevekkül', 'güven', 'dayan', 'vekil', 'teslim'],
      termsEn: ['trust', 'rely', 'disposer of affairs', 'submit'],
      triggersEn: ['trust in god', 'reliance', 'tawakkul', 'submission'],
    ),
    Topic(
      id: 'ihlas',
      label: 'ihlas ve riya',
      labelEn: 'sincerity and showing off',
      triggers: ['ihlas', 'samimiyet', 'riya', 'gösteriş', 'içten olmak',
                 'gösteriş için yapmak'],
      terms: ['ihlas', 'halis', 'samimi', 'gösteriş', 'riya', 'içten'],
      termsEn: ['sincer', 'show off', 'ostentation', 'purely'],
      triggersEn: ['sincerity', 'showing off', 'riya', 'hypocrisy in worship'],
    ),
    Topic(
      id: 'merhamet',
      label: 'merhamet ve affetme',
      labelEn: 'mercy and forgiveness',
      triggers: ['merhamet', 'şefkat', 'affetmek', 'bağışlamak',
                 'birini affetmek', 'kin tutmamak', 'acımak'],
      terms: ['merhamet', 'rahmet', 'affet', 'bağışla', 'şefkat', 'acı'],
      termsEn: ['merc', 'compassion', 'forgiv', 'pardon', 'kind'],
      triggersEn: ['mercy', 'compassion', 'forgiving others', 'forgiveness'],
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
    Topic(
      id: 'issizlik',
      label: 'iş ve geçim kaygısı',
      labelEn: 'work and livelihood worry',
      triggers: ['işsizim', 'işimi kaybettim', 'iş bulamıyorum',
                 'geçinemiyorum', 'param yok', 'maddi sıkıntı',
                 'geçim derdi'],
      terms: ['rızık', 'genişlet', 'darlık', 'sabr', 'kolaylık', 'nimet'],
      termsEn: ['provision', 'sustenance', 'ease', 'patien', 'bounty'],
      triggersEn: ['i lost my job', 'unemployed', 'cannot find work',
                   'financial trouble', 'money problems'],
      isSituational: true,
    ),
    Topic(
      id: 'borc_bunalimi',
      label: 'borç yükü',
      labelEn: 'debt burden',
      triggers: ['borcum var', 'borç içindeyim', 'borçlarım', 'kredi',
                 'borcumu ödeyemiyorum'],
      terms: ['borç', 'borçlu', 'darlık', 'bağışla', 'kolaylık', 'sadaka'],
      termsEn: ['debt', 'ease', 'charity', 'repay'],
      triggersEn: ['i am in debt', 'debt', 'cannot pay my debt'],
      isSituational: true,
    ),
    Topic(
      id: 'bosanma',
      label: 'evlilik sorunu ve ayrılık',
      labelEn: 'marriage trouble and separation',
      triggers: ['boşanma', 'boşanıyorum', 'eşimle sorun', 'ayrılık',
                 'evliliğim bitiyor', 'eşimle geçinemiyorum'],
      terms: ['boşan', 'ayrıl', 'iyilikle', 'geçim', 'barış', 'eş'],
      termsEn: ['divorc', 'separat', 'kindness', 'reconcil', 'spouse'],
      triggersEn: ['divorce', 'marriage problems', 'separating from my wife',
                   'my marriage is failing'],
      isSituational: true,
    ),
    Topic(
      id: 'cocuk',
      label: 'çocuk yetiştirme',
      labelEn: 'raising children',
      triggers: ['çocuğum', 'çocuk yetiştirmek', 'evlat', 'çocuklarım',
                 'evladım beni üzüyor', 'anne olmak', 'baba olmak'],
      terms: ['evlat', 'çocuk', 'nesil', 'zürriyet', 'emzir', 'terbiye'],
      termsEn: ['children', 'offspring', 'child', 'descendants'],
      triggersEn: ['my child', 'raising children', 'parenting',
                   'being a parent'],
      isSituational: true,
    ),
    Topic(
      id: 'basarisizlik',
      label: 'başarısızlık ve sınav',
      labelEn: 'failure and tests',
      triggers: ['başarısız oldum', 'sınavı kaybettim', 'sınav',
                 'başaramadım', 'kaybettim', 'yenildim', 'hayal kırıklığı'],
      terms: ['imtihan', 'dene', 'sına', 'sabr', 'kolaylık', 'zorluk'],
      termsEn: ['trial', 'test', 'patien', 'ease', 'hardship'],
      triggersEn: ['i failed', 'failure', 'i failed my exam',
                   'i did not succeed', 'disappointed'],
      isSituational: true,
    ),
    Topic(
      id: 'uykusuzluk',
      label: 'huzursuzluk ve uykusuzluk',
      labelEn: 'restlessness',
      triggers: ['uyuyamıyorum', 'uykusuzluk', 'huzursuzum', 'içim daralıyor',
                 'rahat edemiyorum', 'kalbim sıkışıyor'],
      terms: ['huzur', 'sükûn', 'kalpler', 'yatış', 'güven', 'uyku'],
      termsEn: ['tranquil', 'peace', 'heart', 'rest', 'sleep'],
      triggersEn: ['i cannot sleep', 'insomnia', 'restless', 'no peace'],
      isSituational: true,
    ),
    Topic(
      id: 'kiskancli',
      label: 'kıskançlık ve haset',
      labelEn: 'envy',
      triggers: ['kıskanıyorum', 'kıskançlık', 'haset', 'çekemiyorum',
                 'başkasının malı'],
      terms: ['haset', 'kıskan', 'göz dik', 'imren', 'nimet'],
      termsEn: ['envy', 'envier', 'covet', 'jealous'],
      triggersEn: ['i am jealous', 'envy', 'jealousy', 'i covet'],
      isSituational: true,
    ),
    Topic(
      id: 'bagimlilik',
      label: 'kötü alışkanlık',
      labelEn: 'bad habits',
      triggers: ['bağımlılık', 'içki', 'alkol', 'kumar', 'sigara',
                 'kötü alışkanlık', 'bırakamıyorum', 'kendimi tutamıyorum'],
      terms: ['içki', 'şarap', 'kumar', 'sakın', 'pislik', 'nefis'],
      termsEn: ['intoxicant', 'wine', 'gambl', 'abomination', 'avoid'],
      triggersEn: ['addiction', 'alcohol', 'gambling', 'bad habit',
                   'i cannot quit'],
      isSituational: true,
    ),
    Topic(
      id: 'haksizlik',
      label: 'haksızlığa uğramak',
      labelEn: 'being wronged',
      triggers: ['bana haksızlık yapıldı', 'zulme uğradım', 'hakkım yendi',
                 'haksızlık', 'zulüm gördüm', 'kimse beni dinlemiyor'],
      terms: ['zulüm', 'zalim', 'haksızlığa', 'zulme uğra', 'adalet'],
      termsEn: ['wrong', 'oppress', 'injustice', 'justice', 'tyrann'],
      triggersEn: ['i was wronged', 'injustice', 'oppressed', 'unfair'],
      isSituational: true,
    ),
    Topic(
      id: 'sukran_hissi',
      label: 'iyi bir haber',
      labelEn: 'good news',
      triggers: ['çok mutluyum', 'iyi bir haber aldım', 'sevinçliyim',
                 'işlerim yolunda', 'müjde aldım', 'kazandım'],
      terms: ['şükr', 'nimet', 'müjde', 'sevin', 'lütuf', 'fazl'],
      termsEn: ['grateful', 'thank', 'bounty', 'good tidings', 'rejoice'],
      triggersEn: ['i am happy', 'good news', 'i am grateful',
                   'things are going well'],
      isSituational: true,
    ),
    Topic(
      id: 'gurbet',
      label: 'gurbet ve uzakta olmak',
      labelEn: 'being far from home',
      triggers: ['gurbetteyim', 'memleketimden uzaktayım', 'yabancı ülkede',
                 'evimi özledim', 'ailemden uzaktayım'],
      terms: ['yolcu', 'sefer', 'yeryüzünde', 'yurt', 'göç', 'yol'],
      termsEn: ['travel', 'journey', 'homes', 'wayfarer', 'land'],
      triggersEn: ['i am far from home', 'homesick', 'living abroad'],
      isSituational: true,
    ),
    Topic(
      id: 'yasli',
      label: 'yaşlılık',
      labelEn: 'old age',
      triggers: ['yaşlandım', 'yaşlılık', 'ihtiyarladım', 'gücüm kalmadı',
                 'ömrüm geçti'],
      terms: ['ihtiyarl', 'yaşlı', 'ömür', 'güçsüz', 'ecel'],
      termsEn: ['old age', 'aged', 'weak', 'lifetime'],
      triggersEn: ['i am getting old', 'old age', 'growing old'],
      isSituational: true,
    ),
    Topic(
      id: 'karar',
      label: 'karar verememek',
      labelEn: 'indecision',
      triggers: ['karar veremiyorum', 'ne yapacağımı bilmiyorum', 'kararsızım',
                 'yol ayrımındayım', 'seçim yapmalıyım', 'şaşırdım kaldım'],
      terms: ['danış', 'tevekkül', 'doğru yol', 'hidayet', 'hayır', 'bil'],
      termsEn: ['consult', 'guidance', 'right path', 'trust', 'know'],
      triggersEn: ['i cannot decide', 'indecision', 'what should i do',
                   'at a crossroads'],
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
