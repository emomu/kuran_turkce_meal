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
import '../../../data/models/prophet.dart';
import '../../../data/models/surah.dart';
import '../../home/providers/home_provider.dart';
import '../../search/data/verse_reference.dart';
import '../data/assistant_intent.dart';
import '../data/assistant_message.dart';
import '../domain/answer_composer.dart';
import '../domain/intent_classifier.dart';

/// Bir cevapta gösterilen ayet sayısı.
///
/// Sohbet balonu bir listeye dönüşmemeli: üç ayet okunabilir, otuz ayet
/// kaydırılır. Gerisi "daha fazla" ile gelir.
const _pageSize = 3;

/// Arama katmanından çekilecek üst sınır.
const _searchLimit = 60;

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
  }
}

class AssistantNotifier extends StateNotifier<AssistantState> {
  AssistantNotifier(this._ref) : super(const AssistantState()) {
    _prepare();
  }

  final Ref _ref;
  final _conversation = _Conversation();

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

    final classifier = _classifier;
    if (classifier == null) {
      // Veri henüz yüklenmediyse bekle; kullanıcıya hata göstermek yerine
      // sorusunu karşılamak yeğdir.
      await _prepare();
    }

    state = state.copyWith(isThinking: true);

    final result = _classifier!.classify(
      question,
      hasPreviousResults: _conversation.hasResults,
    );

    final answer = await _answerFor(result.intent);

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
    ));
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
    }
  }

  /// Konu ve serbest arama.
  Future<ComposedAnswer> _topic(TopicIntent intent) async {
    final repo = _ref.read(quranRepositoryProvider);

    // Sözlükten gelen konu terimleri alternatiftir ve OR ile aranır;
    // kullanıcının kendi yazdığı kelimeler ise birlikte (AND) aranır.
    final hits = intent.isFromLexicon
        ? await repo.searchAny(
            intent.terms,
            languageCode: _languageCode,
            limit: _searchLimit,
          )
        : await repo.search(
            intent.query,
            languageCode: _languageCode,
            limit: _searchLimit,
          );

    _conversation
      ..reset()
      ..lastIntent = intent
      ..title = intent.topicLabel
      ..pool = hits
          .map((h) => AnswerAyah(ayah: h.ayah, surahName: h.surahName))
          .toList();

    final page = _conversation.nextPage();
    return _composer.topic(
      intent: intent,
      ayahs: page,
      totalFound: _conversation.pool.length,
      shownSoFar: _conversation.shown,
    );
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

  /// Peygamber sorusu.
  Future<ComposedAnswer> _prophet(ProphetIntent intent) async {
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
        ),
      _ => _composer.continuation(page),
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

  /// Sohbeti temizler.
  void clear() {
    _conversation.reset();
    state = state.copyWith(messages: const []);
  }

  void _append(AssistantMessage message) {
    state = state.copyWith(messages: [...state.messages, message]);
  }
}

final assistantProvider =
    StateNotifierProvider<AssistantNotifier, AssistantState>(
  (ref) => AssistantNotifier(ref),
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
