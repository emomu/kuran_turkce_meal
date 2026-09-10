/// Asistan sohbetinin durumu ve akışı.
///
/// Akış tek yönlüdür ve her adımı ayrı ayrı test edilebilir:
///
///     soru → IntentClassifier → niyet
///          → repository (mevcut veri katmanı)
///          → AnswerComposer → cevap metni
///          → ConversationState güncellenir
///
/// Hiçbir adımda ağ isteği yok, hiçbir adımda üretilmiş metin yok. Asistanın
/// söylediği her cümle ya bir şablondan ya bir ayetten gelir.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../data/models/ayah.dart';
import '../../../data/repositories/quran_repository.dart';
import '../../../data/models/prophet.dart';
import '../../../data/models/surah.dart';
import '../../bookmarks/providers/bookmarks_provider.dart';
import '../../home/providers/home_provider.dart';
import '../../reader/share/ayah_share.dart';
import '../../search/data/verse_reference.dart';
import '../data/assistant_history.dart';
import '../data/assistant_intent.dart';
import '../data/assistant_message.dart';
import '../data/assistant_stats.dart';
import '../domain/answer_composer.dart';
import '../domain/intent_classifier.dart';
import '../domain/result_ranker.dart';

/// Bir cevapta gösterilen ayet sayısı.
///
/// Sohbet balonu bir listeye dönüşmemeli: üç ayet okunabilir, otuz ayet
/// kaydırılır. Gerisi "daha fazla" ile gelir.
const _pageSize = 3;

/// Arama katmanından çekilecek üst sınır.
const _searchLimit = 60;

/// Düşünme göstergesinin en az ne kadar ekranda kalacağı.
///
/// Yerel arama milisaniyelerle ölçülür: gösterge belirdiği kareyi
/// tamamlamadan kaybolur ve geriye bir titreme kalır. Titreyen bir arayüz,
/// hiç gösterge olmamasından kötüdür.
///
/// Bu bekleme yapay bir yavaşlatma değil, bir alt sınır: arama daha uzun
/// sürerse hiçbir şey eklenmez, kısa sürerse gösterge okunacak kadar
/// kalır. Kullanıcının cevabı algılaması zaten bu mertebede sürüyor.
const _minThinkingTime = Duration(milliseconds: 420);

/// Çoklu konu cevabında her bölümde gösterilen ayet sayısı.
///
/// Tek konudan az: iki konu sorulduğunda ekranda altı ayet olur ve cevap
/// bir listeye dönerdi. İkişer ayet karşılaştırma için yeter.
const _multiPageSize = 2;

/// Bir arama denemesinin sonucu.
///
/// Yalnız ayetleri değil, hangi kelimelerle bulunduklarını da taşır:
/// sorgu gevşetildiyse kullanıcıya söylenmeli.
class _SearchOutcome {
  const _SearchOutcome({
    required this.ayahs,
    required this.usedTerms,
    this.narrowed = false,
  });

  final List<AnswerAyah> ayahs;

  /// Aramada gerçekten kullanılan kelimeler.
  final List<String> usedTerms;

  /// Sorgu gevşetildi mi (AND yerine OR, ya da tek kelime).
  final bool narrowed;
}

/// Sohbet durumu.
class AssistantState {
  const AssistantState({
    this.messages = const [],
    this.isThinking = false,
    this.isReady = false,
  });

  final List<AssistantMessage> messages;

  /// Asistan cevabı hazırlıyor.
  final bool isThinking;

  /// Veri katmanı yüklendi mi. Yüklenmeden soru alınmaz.
  final bool isReady;

  bool get isEmpty => messages.isEmpty;

  AssistantState copyWith({
    List<AssistantMessage>? messages,
    bool? isThinking,
    bool? isReady,
  }) =>
      AssistantState(
        messages: messages ?? this.messages,
        isThinking: isThinking ?? this.isThinking,
        isReady: isReady ?? this.isReady,
      );
}

/// Konuşmanın hatırladıkları.
///
/// Asistanı arama kutusundan ayıran şey. "Daha fazla" ya da "ikincisini aç"
/// gibi ifadeler ancak önceki cevaba bakılarak çözülebilir; bu sınıf o
/// bakışı mümkün kılar.
class _Conversation {
  /// Son soruda çözülen niyet.
  AssistantIntent? lastIntent;

  /// Son aramanın tüm sonuçları — gösterilmeyenler dahil.
  List<AnswerAyah> pool = const [];

  /// Havuzdan kaç tanesi gösterildi.
  int shown = 0;

  /// Sonuç sayfasının başlığı: "sabır", "Muhammed", "Bakara 255".
  String? title;

  /// Havuzu bulan kelimeler. Vurgulamada kullanılır: kullanıcı hangi
  /// kelimenin eşleştiğini görmeli.
  List<String> searchedWith = const [];

  bool get hasResults => pool.isNotEmpty;

  /// Sıradaki sayfayı verir ve sayacı ilerletir.
  List<AnswerAyah> nextPage() {
    if (shown >= pool.length) return const [];
    final end = (shown + _pageSize).clamp(0, pool.length);
    final page = pool.sublist(shown, end);
    shown = end;
    return page;
  }

  void reset() {
    lastIntent = null;
    pool = const [];
    shown = 0;
    title = null;
    searchedWith = const [];
  }
}

class AssistantNotifier extends StateNotifier<AssistantState> {
  AssistantNotifier(this._ref) : super(const AssistantState()) {
    _prepare();
  }

  final Ref _ref;
  final _conversation = _Conversation();

  late final AssistantHistory _history =
      AssistantHistory(_ref.read(sharedPreferencesProvider));

  late final AssistantStats _stats =
      AssistantStats(_ref.read(sharedPreferencesProvider));

  /// Cevap bestecisi. Dil değişince yenilenir — şablonlar dile gömülü
  /// olduğu için aynı besteci iki dile hizmet edemez.
  AnswerComposer _composer = AnswerComposer();

  IntentClassifier? _classifier;

  // Sınıflandırıcı dil değişiminde yeniden kurulur; veri bir kez yüklenip
  // burada tutulur ki her dil değişiminde asset'e dönülmesin.
  List<Surah>? _surahs;
  List<Prophet>? _prophets;

  int _nextId = 0;
  String _languageCode = 'tr';

  set languageCode(String code) {
    if (_languageCode == code) return;
    _languageCode = code;

    // Besteci ve sınıflandırıcı dili taşır: şablonlar ve tetikleyiciler
    // dile gömülüdür, aynı örnek iki dile hizmet edemez. Veri yeniden
    // yüklenmez; yalnızca dile bağlı parçalar kurulur.
    _composer = AnswerComposer(languageCode: code);
    _rebuildClassifier();

    // Eldeki sonuçlar önceki dilin arama dizininden geldi; yeni soruda
    // doğru dizin kullanılsın diye havuz boşaltılır.
    _conversation.reset();
  }

  /// Sınıflandırıcının ihtiyaç duyduğu veriyi yükler.
  ///
  /// Sure listesi ve peygamber verisi olmadan niyet çözülemez; ikisi de
  /// asset'ten gelir ve toplamı ~30 KB.
  Future<void> _prepare() async {
    final surahs = await _ref.read(surahListProvider.future);
    final prophetRepo = await _ref.read(prophetDataProvider.future);

    if (!mounted) return;
    _surahs = surahs;
    _prophets = prophetRepo.all;
    _rebuildClassifier();
    state = state.copyWith(isReady: true);

    // Geçmiş veri yüklendikten sonra geri konur: ayet metinleri
    // veritabanından tazelenecek ve sure adları dile göre kurulacak.
    await _restoreHistory();
  }

  /// Saklanan sohbeti geri yükler.
  ///
  /// Ayetler kimlikle saklandı; metinleri buradan tazelenir. Meal
  /// güncellenmişse kullanıcı yeni metni görür — eski bir kopyayı
  /// saklamış olsaydık, ekranda artık var olmayan bir çeviri kalırdı.
  Future<void> _restoreHistory() async {
    if (state.messages.isNotEmpty) return;

    final stored = _history.load();
    if (stored.isEmpty) return;

    // Bütün mesajların ayetleri tek sorguda çekilir; mesaj başına sorgu
    // atmak açılışı yavaşlatırdı.
    final ids = <int>{
      for (final m in stored) ...m.ayahIds,
      for (final m in stored) ...m.allAyahIds,
      for (final m in stored)
        for (final s in m.sections) ...s.ayahIds,
    };

    final byId = <int, AnswerAyah>{};
    if (ids.isNotEmpty) {
      final repo = _ref.read(quranRepositoryProvider);
      final ayahs = await repo.ayahsByIds(ids.toList());
      final surahs = await _ref.read(surahListProvider.future);
      final nameByNumber = {
        for (final s in surahs) s.number: s.nameFor(_languageCode),
      };

      for (final ayah in ayahs) {
        byId[ayah.id] = AnswerAyah(
          ayah: ayah,
          surahName: nameByNumber[ayah.surahNumber] ?? '',
        );
      }
    }

    if (!mounted) return;

    List<AnswerAyah> resolve(List<int> list) =>
        [for (final id in list) ?byId[id]];

    final restored = <AssistantMessage>[
      for (final m in stored)
        AssistantMessage(
          id: _nextId++,
          author: m.isUser ? MessageAuthor.user : MessageAuthor.assistant,
          text: m.text,
          ayahs: resolve(m.ayahIds),
          actions: const [],
          note: m.note,
          allAyahs: resolve(m.allAyahIds),
          resultTitle: m.resultTitle,
          highlightTerms: m.highlightTerms,
          sections: [
            for (final s in m.sections)
              AnswerSection(
                label: s.label,
                ayahs: resolve(s.ayahIds),
                totalFound: s.totalFound,
              ),
          ],
        ),
    ];

    // Son cevabın sonuç listesi konuşma belleğine geri konur: kullanıcı
    // uygulamayı yeniden açıp "daha fazla" diyebilmeli.
    for (final message in restored.reversed) {
      if (message.allAyahs.isEmpty) continue;
      _conversation
        ..pool = message.allAyahs
        ..shown = message.ayahs.length
        ..title = message.resultTitle;
      break;
    }

    state = state.copyWith(messages: restored);
  }

  /// Sohbeti cihaza yazar.
  ///
  /// Her mesajdan sonra çağrılır. Yazma küçüktür (kimlikler ve kısa
  /// metinler) ve beklenmez: kullanıcı cevabını görürken kayıt arkada
  /// tamamlanır.
  void _persist() {
    unawaited(_history.save([
      for (final m in state.messages)
        StoredMessage(
          isUser: m.isUser,
          text: m.text,
          ayahIds: [for (final a in m.ayahs) a.ayah.id],
          allAyahIds: [for (final a in m.allAyahs) a.ayah.id],
          note: m.note,
          resultTitle: m.resultTitle,
          highlightTerms: m.highlightTerms,
          sections: [
            for (final s in m.sections)
              StoredSection(
                label: s.label,
                ayahIds: [for (final a in s.ayahs) a.ayah.id],
                totalFound: s.totalFound,
              ),
          ],
        ),
    ]));
  }

  /// Sınıflandırıcıyı geçerli dille kurar.
  ///
  /// Veri yüklenmemişse bir şey yapmaz; [_prepare] bitince yeniden çağrılır.
  void _rebuildClassifier() {
    final surahs = _surahs;
    final prophets = _prophets;
    if (surahs == null || prophets == null) return;

    _classifier = IntentClassifier(
      surahs: surahs,
      prophets: prophets,
      foldName: foldSurahName,
      languageCode: _languageCode,
    );
  }

  /// Kullanıcının sorusunu işler.
  Future<void> ask(String raw) async {
    final question = raw.trim();
    if (question.isEmpty) return;

    _append(AssistantMessage(
      id: _nextId++,
      author: MessageAuthor.user,
      text: question,
    ));
    _persist();

    final classifier = _classifier;
    if (classifier == null) {
      // Veri henüz yüklenmediyse bekle; kullanıcıya hata göstermek yerine
      // sorusunu karşılamak yeğdir.
      await _prepare();
    }

    state = state.copyWith(isThinking: true);
    final startedAt = DateTime.now();

    final result = _classifier!.classify(
      question,
      hasPreviousResults: _conversation.hasResults,
    );

    final answer = await _answerFor(result.intent);

    // Karşılanamayan soru sayılır: sözlüğün hangi yöne büyümesi gerektiği
    // ancak böyle bilinir. Kayıt cihazda kalır, hiçbir yere gönderilmez.
    unawaited(_recordIfMissed(result, answer));

    // Gösterge okunacak kadar kalsın. Aramanın kendisi bu süreyi çoktan
    // aştıysa beklenmez — eklenen bir gecikme değil, bir alt sınır.
    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed < _minThinkingTime) {
      await Future<void>.delayed(_minThinkingTime - elapsed);
    }

    if (!mounted) return;
    state = state.copyWith(isThinking: false);
    _append(AssistantMessage(
      id: _nextId++,
      author: MessageAuthor.assistant,
      text: answer.text,
      ayahs: answer.ayahs,
      actions: answer.actions,
      note: answer.note,
      // Tüm sonuçlar mesajın kendisinde durur: "Tümünü gör" eski bir cevapta
      // da çalışsın, konuşma ilerledikçe listesi kaybolmasın.
      allAyahs: _conversation.pool,
      resultTitle: _conversation.title,
      sections: answer.sections,
      highlightTerms: answer.highlightTerms,
    ));

    _persist();
  }

  /// Soru karşılıksız kaldıysa kaydeder.
  ///
  /// Üç durum sayılır: anlaşılmayan soru, alan dışı sayılan soru ve
  /// niyeti çözülüp de arama sonuç vermeyen soru. Üçüncüsü en değerlisi —
  /// kullanıcı meşru bir şey sordu, asistan bulamadı.
  Future<void> _recordIfMissed(
    IntentResult result,
    ComposedAnswer answer,
  ) async {
    final kind = switch (result.intent) {
      OutOfScopeIntent(reason: OutOfScopeReason.unclear) => MissKind.unclear,
      OutOfScopeIntent(reason: OutOfScopeReason.offTopic) => MissKind.offTopic,
      // Fetva sorusu bir eksiklik değil, bilinçli bir sınır. Sayılmaz.
      OutOfScopeIntent() => null,
      TopicIntent() when answer.ayahs.isEmpty && answer.sections.isEmpty =>
        MissKind.emptyResult,
      MultiTopicIntent() when answer.sections.isEmpty => MissKind.emptyResult,
      _ => null,
    };

    if (kind == null) return;
    await _stats.recordMiss(result.normalizedQuery, kind);
  }

  /// Niyeti cevaba çevirir.
  Future<ComposedAnswer> _answerFor(AssistantIntent intent) async {
    switch (intent) {
      case GreetingIntent():
        _conversation.reset();
        return _composer.greeting();

      case HelpIntent():
        _conversation.reset();
        return _composer.help();

      case OutOfScopeIntent(:final reason):
        // Alan dışı sorular havuza dokunmaz: kullanıcı reddedilen bir
        // sorudan sonra "daha fazla" derse önceki konuya dönebilmeli.
        return _composer.outOfScope(reason);

      case MoreResultsIntent():
        return _moreResults();

      case OpenResultIntent(:final index):
        return _openResult(index);

      case ReferenceIntent():
        return _reference(intent);

      case ProphetIntent():
        return _prophet(intent);

      case SurahInfoIntent():
        _conversation.reset();
        _conversation.lastIntent = intent;
        return _composer.surahInfo(intent);

      case TopicIntent():
        return _topic(intent);

      case MultiTopicIntent(:final parts):
        return _multiTopic(parts);

      case SaveAyahIntent(:final index):
        return _saveAyah(index);

      case ShareAyahIntent(:final index):
        return _shareAyah(index);

      case SameSurahIntent():
        return _sameSurah();
    }
  }

  /// Konu ve serbest arama.
  Future<ComposedAnswer> _topic(TopicIntent intent) async {
    final found = await _searchFor(intent);

    _conversation
      ..reset()
      ..lastIntent = intent
      ..title = intent.topicLabel
      ..pool = found.ayahs
      ..searchedWith = found.usedTerms;

    final page = _conversation.nextPage();
    return _composer.topic(
      intent: intent,
      ayahs: page,
      totalFound: _conversation.pool.length,
      shownSoFar: _conversation.shown,
      // Not yalnızca sorgu gevşetildiyse düşülür; vurgu her zaman yapılır.
      narrowedTo: found.narrowed ? found.usedTerms : null,
      highlightTerms: found.usedTerms,
    );
  }

  /// Bir konu niyeti için arama yapar ve sonuçları sıralar.
  ///
  /// Serbest aramada geri çekilme uygulanır. Kullanıcının kelimeleri AND
  /// ile bağlanır ve bu doğrudur — iki kelime yazan ikisini birden içeren
  /// ayeti arar. Ama hiç sonuç çıkmazsa boş dönmek yerine gevşetilir:
  /// önce OR, sonra en ayırt edici tek kelime. Her adımda ne aradığımız
  /// kaydedilir, çünkü cevapta söylenecek.
  Future<_SearchOutcome> _searchFor(TopicIntent intent) async {
    final repo = _ref.read(quranRepositoryProvider);

    Future<List<AnswerAyah>> rank(List<SearchHit> hits, List<String> terms) async =>
        ResultRanker.rank(
          hits
              .map((h) => AnswerAyah(ayah: h.ayah, surahName: h.surahName))
              .toList(),
          terms: terms,
          languageCode: _languageCode,
        );

    // Sözlükten gelen konu: terimler zaten alternatif, geri çekilmeye
    // gerek yok.
    if (intent.isFromLexicon) {
      final hits = await repo.searchAny(
        intent.terms,
        languageCode: _languageCode,
        limit: _searchLimit,
      );
      return _SearchOutcome(
        ayahs: await rank(hits, intent.terms),
        usedTerms: intent.terms,
      );
    }

    final terms = intent.searchTerms.isEmpty
        ? [intent.query]
        : intent.searchTerms;

    // 1. Adım: kelimelerin hepsi (AND).
    final strict = await repo.search(
      terms.join(' '),
      languageCode: _languageCode,
      limit: _searchLimit,
    );
    if (strict.isNotEmpty) {
      return _SearchOutcome(
        ayahs: await rank(strict, terms),
        usedTerms: terms,
      );
    }

    // Tek kelimelik sorguda gevşetilecek bir şey yok.
    if (terms.length < 2) {
      return _SearchOutcome(ayahs: const [], usedTerms: terms);
    }

    // 2. Adım: kelimelerden herhangi biri (OR). Sonuçlar kaç kelimeyi
    //    birden içerdiklerine göre sıralanır, böylece gevşetme alakayı
    //    düşürmez — yalnızca eşiği indirir.
    final loose = await repo.searchAny(
      terms,
      languageCode: _languageCode,
      limit: _searchLimit,
    );
    if (loose.isNotEmpty) {
      return _SearchOutcome(
        ayahs: await rank(loose, terms),
        usedTerms: terms,
        narrowed: true,
      );
    }

    // 3. Adım: en uzun kelime. Uzunluk kaba ama işe yarar bir ayırt
    //    edicilik ölçüsü: "namaz" ile "kilmak" arasında ilki daha az
    //    ayette geçer ve konuyu daha iyi anlatır.
    final longest = [...terms]..sort((a, b) => b.length.compareTo(a.length));
    final single = await repo.search(
      longest.first,
      languageCode: _languageCode,
      limit: _searchLimit,
    );

    return _SearchOutcome(
      ayahs: await rank(single, [longest.first]),
      usedTerms: [longest.first],
      narrowed: single.isNotEmpty,
    );
  }

  /// Birden fazla konu soruldu: her biri ayrı ayrı aranır.
  ///
  /// Havuz birleşik tutulur ki "daha fazla" ikisinden de getirsin; cevap
  /// metni ise parçaları ayrı ayrı anar, çünkü kullanıcı ikisini
  /// karşılaştırmak için sordu.
  Future<ComposedAnswer> _multiTopic(List<AssistantIntent> parts) async {
    final sections = <AnswerSection>[];
    final pool = <AnswerAyah>[];
    final seen = <int>{};

    for (final part in parts) {
      switch (part) {
        case TopicIntent():
          final found = await _searchFor(part);
          sections.add(AnswerSection(
            label: part.topicLabel,
            ayahs: found.ayahs.take(_multiPageSize).toList(),
            totalFound: found.ayahs.length,
          ));
          for (final a in found.ayahs) {
            if (seen.add(a.ayah.id)) pool.add(a);
          }

        case ProphetIntent():
          final ordered = await _prophetAyahs(part);
          sections.add(AnswerSection(
            label: part.prophet.nameFor(_languageCode),
            ayahs: ordered.take(_multiPageSize).toList(),
            totalFound: ordered.length,
          ));
          for (final a in ordered) {
            if (seen.add(a.ayah.id)) pool.add(a);
          }

        default:
          break;
      }
    }

    final title = sections.map((s) => s.label).join(' · ');

    // Vurgu için her bölümün etiketi kullanılır: iki konu sorulduğunda
    // ikisinin de kelimeleri metinde işaretlenmeli.
    final terms = [for (final s in sections) s.label];

    _conversation
      ..reset()
      ..title = title
      ..pool = pool
      ..shown = sections.fold(0, (sum, s) => sum + s.ayahs.length)
      ..searchedWith = terms;

    return _composer.multiTopic(sections, highlightTerms: terms);
  }

  /// Bir ayeti kaydeder (yer imi).
  Future<ComposedAnswer> _saveAyah(int index) async {
    final target = _resultAt(index);
    if (target == null) return _composer.noSuchResult();

    final marks = _ref.read(marksRepositoryProvider);
    final mark = await marks.toggleBookmark(target.ayah.id);

    // Kaydedilenler ekranı bu listeyi izliyor; işaret değişince tazelenmeli.
    _ref.invalidate(savedEntriesProvider);

    return _composer.savedAyah(target, isSaved: mark.isBookmarked);
  }

  /// Bir ayeti paylaşır.
  Future<ComposedAnswer> _shareAyah(int index) async {
    final target = _resultAt(index);
    if (target == null) return _composer.noSuchResult();

    await AyahShare.text(
      ayah: target.ayah,
      surahName: target.surahName,
      languageCode: _languageCode,
    );

    return _composer.sharedAyah(target);
  }

  /// Son ayetin bulunduğu suredeki komşu ayetleri gösterir.
  ///
  /// Kullanıcı bir ayeti bağlamında okumak istiyor. Okuma ekranına atmak
  /// yerine öncesi ve sonrası burada gösterilir; sohbeti bırakmadan
  /// bağlamı görür.
  Future<ComposedAnswer> _sameSurah() async {
    final anchor = _resultAt(0);
    if (anchor == null) return _composer.noSuchResult();

    final repo = _ref.read(quranRepositoryProvider);
    final all = await repo.ayahsOfSurah(anchor.ayah.surahNumber);
    if (all.isEmpty) return _composer.noSuchResult();

    final at = all.indexWhere((a) => a.id == anchor.ayah.id);
    if (at < 0) return _composer.noSuchResult();

    // Ayetin iki yanından birer pencere. Kenarlarda pencere içeri kayar,
    // böylece ilk ayette de bağlam görünür.
    const window = 2;
    final start = (at - window).clamp(0, all.length);
    final end = (at + window + 1).clamp(0, all.length);

    final neighbours = [
      for (final ayah in all.sublist(start, end))
        AnswerAyah(ayah: ayah, surahName: anchor.surahName),
    ];

    _conversation
      ..reset()
      ..title = anchor.surahName
      ..pool = neighbours
      ..shown = neighbours.length;

    return _composer.sameSurah(
      anchor: anchor,
      ayahs: neighbours,
      surahNumber: anchor.ayah.surahNumber,
    );
  }

  /// Havuzdaki bir sonucu verir. -1 sonuncuyu ister.
  AnswerAyah? _resultAt(int index) {
    final pool = _conversation.pool;
    if (pool.isEmpty) return null;
    final i = index < 0 ? pool.length - 1 : index;
    if (i < 0 || i >= pool.length) return null;
    return pool[i];
  }

  /// Doğrudan ayet referansı.
  Future<ComposedAnswer> _reference(ReferenceIntent intent) async {
    final repo = _ref.read(quranRepositoryProvider);
    final ayahs = <AnswerAyah>[];

    if (intent.ayahNumber != null) {
      final list = await repo.ayahsOfSurah(intent.surah.number);
      // Birleşik meal bloklarında aranan numara bloğun ortasına düşebilir;
      // aralığı kapsayan blok doğru cevaptır.
      final match = list.where((a) =>
          intent.ayahNumber! >= a.ayahNumber &&
          intent.ayahNumber! <= a.endAyahNumber);
      if (match.isNotEmpty) {
        ayahs.add(AnswerAyah(
          ayah: match.first,
          surahName: intent.surah.nameFor(_languageCode),
        ));
      }
    }

    _conversation
      ..reset()
      ..lastIntent = intent
      ..title = intent.surah.nameFor(_languageCode)
      ..pool = ayahs
      ..shown = ayahs.length;

    return _composer.reference(intent: intent, ayahs: ayahs);
  }

  /// Bir peygamberin ayetlerini iniş sırasında verir.
  ///
  /// Hem tekil peygamber cevabı hem çoklu konu kullanır.
  Future<List<AnswerAyah>> _prophetAyahs(ProphetIntent intent) async {
    // Kıssa istendiyse kıssa listesi, aksi hâlde anılma listesi. Fark
    // Hz. Muhammed'de belirgin: 10 kıssa ayeti, 140 anılma.
    final ids = intent.wantsStory
        ? intent.prophet.ayahIds
        : intent.prophet.mentionIds;

    final ayahs = await _ref.read(quranRepositoryProvider).ayahsByIds(ids);
    final surahs = await _ref.read(surahListProvider.future);
    final nameByNumber = {
      for (final s in surahs) s.number: s.nameFor(_languageCode),
    };

    // `ayahsByIds` kimlik sırasına göre döner; kıssa akışı iniş sırasını
    // ister. Sıra veri dosyasında zaten iniş sırasına göre dizili olduğu
    // için kimlik listesindeki sıraya geri konur.
    final byId = {for (final a in ayahs) a.id: a};
    final ordered = <AnswerAyah>[];
    for (final id in ids) {
      final ayah = byId[id];
      if (ayah == null) continue;
      ordered.add(AnswerAyah(
        ayah: ayah,
        surahName: nameByNumber[ayah.surahNumber] ?? '',
      ));
    }
    return ordered;
  }

  /// Peygamber sorusu.
  Future<ComposedAnswer> _prophet(ProphetIntent intent) async {
    final ordered = await _prophetAyahs(intent);

    _conversation
      ..reset()
      ..lastIntent = intent
      ..title = intent.prophet.nameFor(_languageCode)
      ..pool = ordered;

    final page = _conversation.nextPage();
    return _composer.prophet(
      intent: intent,
      ayahs: page,
      totalFound: ordered.length,
      shownSoFar: _conversation.shown,
    );
  }

  /// "Daha fazla" istendi.
  Future<ComposedAnswer> _moreResults() async {
    final page = _conversation.nextPage();
    if (page.isEmpty) return _composer.noMoreResults();

    final intent = _conversation.lastIntent;
    final total = _conversation.pool.length;

    return switch (intent) {
      ProphetIntent() => _composer.prophet(
          intent: intent,
          ayahs: page,
          totalFound: total,
          shownSoFar: _conversation.shown,
        ),
      TopicIntent() => _composer.topic(
          intent: intent,
          ayahs: page,
          totalFound: total,
          shownSoFar: _conversation.shown,
          highlightTerms: _conversation.searchedWith,
        ),
      // Devam sayfasında vurgu korunur: kullanıcı ikinci sayfada da
      // hangi kelimenin eşleştiğini görmeli.
      _ => _composer.continuation(page, terms: _conversation.searchedWith),
    };
  }

  /// "İkincisini aç" gibi bir istek.
  Future<ComposedAnswer> _openResult(int index) async {
    final pool = _conversation.pool;
    if (pool.isEmpty) return _composer.noMoreResults();

    // -1 "sonuncusu" demek.
    final i = index < 0 ? pool.length - 1 : index;
    if (i < 0 || i >= pool.length) return _composer.noSuchResult();

    return _composer.openResult(pool[i]);
  }

  /// Sohbeti temizler. Cihazdaki kayıt da silinir.
  void clear() {
    _conversation.reset();
    state = state.copyWith(messages: const []);
    unawaited(_history.clear());
  }

  void _append(AssistantMessage message) {
    state = state.copyWith(messages: [...state.messages, message]);
  }
}

final assistantProvider =
    StateNotifierProvider<AssistantNotifier, AssistantState>(
  (ref) => AssistantNotifier(ref),
);

/// Karşılanamayan soruların cihazdaki kaydı.
///
/// Sözlüğü hangi yöne büyüteceğini söyleyen tek kaynak. Veri cihazda
/// kalır; bu sağlayıcı onu okumanın ve silmenin yolu.
final assistantStatsProvider = Provider<AssistantStats>(
  (ref) => AssistantStats(ref.watch(sharedPreferencesProvider)),
);

/// Asistanın açılışta gösterdiği örnek sorular.
///
/// Boş bir sohbet ekranı kullanıcıya ne sorabileceğini söylemez; bu liste
/// asistanın alanını göstererek ilk soruyu kolaylaştırır. Listedeki her
/// örnek gerçekten karşılanabilen bir sorudur — dokunan kullanıcı boş
/// cevapla karşılaşmamalı.
List<String> assistantSuggestionsFor(String languageCode) =>
    languageCode == 'en'
        ? const [
            'What does it say about patience?',
            'I am going through a hard time',
            'Al-Baqarah 255',
            'Muhammad',
            'How many verses in Al-Kahf?',
            'Kindness to parents',
          ]
        : const [
            'Sabır hakkında ne diyor?',
            'Zor zamandayım',
            'Bakara 255',
            'Muhammed',
            'Kehf kaç ayet?',
            'Anne babaya iyilik',
          ];

/// Ayet listesini cevap ayetine çevirir. Test ve yeniden kullanım için.
List<AnswerAyah> toAnswerAyahs(
  List<Ayah> ayahs,
  Map<int, String> surahNames,
) =>
    ayahs
        .map((a) => AnswerAyah(
              ayah: a,
              surahName: surahNames[a.surahNumber] ?? '',
            ))
        .toList();
