import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_typography.dart';
import '../../assistant/view/widgets/assistant_fab.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../data/models/ayah.dart';
import '../../../data/models/surah.dart';
import '../../audio/providers/audio_provider.dart';
import '../../audio/providers/download_provider.dart';
import '../../audio/widgets/audio_download_sheet.dart';
import '../../audio/widgets/audio_player_bar.dart';
import '../../roots/view/root_detail_screen.dart';
import '../../roots/widgets/word_picker_sheet.dart';
import '../../settings/providers/preferences_provider.dart';
import '../providers/reader_provider.dart';
import '../widgets/ayah_actions_sheet.dart';
import '../widgets/ayah_tile.dart';
import '../widgets/note_editor_sheet.dart';
import '../widgets/reader_settings_sheet.dart';
import '../widgets/surah_end_card.dart';
import '../../onboarding/providers/tour_provider.dart';
import '../../onboarding/widgets/coach_mark.dart';
import '../../onboarding/widgets/tour_host.dart';

/// Bir surenin okuma ekranı.
///
/// [initialAyah] verilirse (aramadan, yer iminden veya bildirimden gelindiğinde)
/// liste o ayete konumlanır ve ayet kısa süre vurgulanır.
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.surahNumber, this.initialAyah});

  final int surahNumber;
  final int? initialAyah;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

/// Asistan düğmesinin liste sonunda bıraktığı pay.
///
/// Düğme 56pt; üstüne bir nefes eklenir. Bu pay olmadan son ayetin alt
/// satırları düğmenin altında kalıyor ve okunamıyordu.
const double _fabClearance = 72;

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final _itemScrollController = ItemScrollController();
  final _positionsListener = ItemPositionsListener.create();

  /// Ekranda gösterilen sure.
  ///
  /// Sure sonunda sıradakine geçilirken yeni bir ekran açılmaz, bu alan
  /// değiştirilir. Böylece gezinme yığını her surede bir katman şişmez ve
  /// kullanıcı geri tuşuna bastığında okumaya başladığı yere döner.
  late int _surahNumber = widget.surahNumber;

  /// Aramadan gelindiğinde geçici olarak vurgulanan ayet.
  int? _focusedAyahNumber;
  Timer? _focusTimer;

  /// İlerleme kaydını kısıtlamak için; her kaydırma karesinde veritabanına
  /// yazmak yerine kullanıcı durunca yazılır.
  Timer? _progressDebounce;

  /// Sure sonunda listeyi aşan kaydırma miktarı (piksel).
  ///
  /// Kullanıcı son ayeti geçip kaydırmayı sürdürdükçe artar; eşiğe
  /// ulaştığında sıradaki sureye geçilir. Bu, "kaydırınca sonraki sureye
  /// geç" mekaniğinin ölçüm tarafıdır.
  double _overscroll = 0;

  /// Geçişin tetikleneceği aşım eşiği.
  ///
  /// Kazara geçişi önleyecek kadar büyük, kullanıcıyı yormayacak kadar
  /// küçük seçildi; yaklaşık bir baş parmak hareketi kadar.
  static const _pullThreshold = 130.0;

  /// Kullanıcının parmağı ekranda mı.
  ///
  /// Geçiş yalnızca parmak kaldırıldığında tetiklenir. Aksi halde hızlı
  /// kaydırmanın ataleti eşiği kendiliğinden aşar ve kullanıcı istemeden
  /// arka arkaya sure atlar.
  bool _isDragging = false;

  /// Geçiş sırasında tekrar tetiklenmeyi engeller.
  bool _isAdvancing = false;

  /// Ses çalarken kullanıcı listeyi kendisi kaydırdı mı.
  ///
  /// Kaydırdıysa otomatik takip geçici olarak durur: kullanıcı başka bir ayete
  /// bakmak istemiştir ve liste onu zorla çalan ayete geri çekmemelidir.
  /// Takip, kullanıcı çubuktan yeni bir ayete geçtiğinde ya da çalan ayet
  /// yeniden görünür olduğunda kendiliğinden geri gelir.
  bool _userScrolledDuringAudio = false;

  /// Otomatik olarak kaydırılan son ayet. Aynı ayet için tekrar kaydırma
  /// isteği gönderilmesin diye tutulur.
  int? _lastAutoScrolledAyah;

  /// Şu an takip için kaydırma yapılıyor.
  ///
  /// `scrollTo` da sürükleme bildirimi üretir; bu bayrak olmasaydı otomatik
  /// kaydırma "kullanıcı kaydırdı" sayılır ve takip kendini ilk ayette
  /// kapatırdı.
  bool _isAutoScrolling = false;

  /// Kullanıcı kaydırmasından sonra takibi geri açan zamanlayıcı.
  Timer? _resumeFollowTimer;

  /// Tanıtım turunun işaret ettiği öğeler.
  ///
  /// İlk ayet karesi ve ayar düğmesi; turun delikleri bunların ekrandaki
  /// yerine göre açılır.
  final _firstAyahKey = GlobalKey();
  final _settingsButtonKey = GlobalKey();
  final _listenButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _focusedAyahNumber = widget.initialAyah;

    // Vurgu birkaç saniye sonra söner; kalıcı olsaydı kullanıcının kendi
    // vurgularıyla karışırdı.
    if (_focusedAyahNumber != null) {
      _focusTimer = Timer(const Duration(milliseconds: 2600), () {
        if (mounted) setState(() => _focusedAyahNumber = null);
      });
    }

    _positionsListener.itemPositions.addListener(_onScroll);
  }

  @override
  void dispose() {
    _positionsListener.itemPositions.removeListener(_onScroll);
    _focusTimer?.cancel();
    _progressDebounce?.cancel();
    _resumeFollowTimer?.cancel();
    super.dispose();
  }

  /// Okunan yeri kaydeder.
  ///
  /// Ölçüt, ekranda görünen *son* ayettir: kullanıcı bir ayeti gördüyse onu
  /// okumuş sayılır. İlk görünen ayet alınsaydı sure sonuna gelindiğinde bile
  /// ilerleme ekran yüksekliği kadar geride kalır, çubuk hiç dolmazdı.
  void _onScroll() {
    final positions = _positionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    // Ekranın altından taşanları saymayız; görünür son öğe alınır.
    final lastVisible = positions
        .where((p) => p.itemLeadingEdge < 1)
        .fold<int?>(
          null,
          (max, p) => max == null || p.index > max ? p.index : max,
        );

    if (lastVisible == null) return;

    _progressDebounce?.cancel();
    _progressDebounce = Timer(const Duration(milliseconds: 600), () {
      final ayahs = ref
          .read(readerDataProvider(_surahNumber))
          .valueOrNull
          ?.ayahs;
      if (ayahs == null || ayahs.isEmpty) return;

      // 0. indeks sure başlığı, 1..n ayet blokları, sonuncusu bitiş kartı.
      // Blok indeksi ayet numarasına eşit değildir: birleşik meallerde bir
      // blok birden çok ayeti kapsar (örn. Alak 15-16).
      final blockIndex = (lastVisible - 1).clamp(0, ayahs.length - 1);

      // Bloğun son ayeti kaydedilir; blok tamamen görünmüşse o ayete kadar
      // okunmuş demektir.
      final ayahNumber = ayahs[blockIndex].endAyahNumber;

      ref.read(saveProgressProvider)(_surahNumber, ayahNumber);
    });
  }

  /// Sure sonundaki taşma kaydırmasını izler.
  ///
  /// [ScrollablePositionedList] listenin sonuna gelindiğinde taşma bildirimi
  /// üretir; bu bildirimler toplanıp eşiğe ulaşınca sıradaki sureye geçilir.
  /// Kullanıcı parmağını eşiğe varmadan kaldırırsa sayaç sıfırlanır.
  bool _onScrollNotification(ScrollNotification notification) {
    if (_isAdvancing) return false;

    // Listenin sonundan ne kadar taşıldığını konumdan ölçer.
    //
    // `OverscrollNotification` kullanılmaz: yaylanan fizik (BouncingScroll)
    // sınırın ötesini normal kaydırma sayar ve o bildirimi üretmez. Konum
    // farkı ise her iki fizikte de doğru sonucu verir.
    double overscrollOf(ScrollMetrics m) =>
        (m.pixels - m.maxScrollExtent).clamp(0.0, double.infinity);

    switch (notification) {
      case ScrollStartNotification(:final dragDetails):
        // Sürükleme ayrıntısı varsa hareketi parmak başlattı; yoksa bu
        // atalet (fling) kaydırmasıdır.
        _isDragging = dragDetails != null;

        // Kullanıcı ses çalarken kendisi kaydırdıysa otomatik takip durur:
        // başka bir ayete bakmak istemiştir ve liste onu zorla çalan ayete
        // geri çekmemelidir.
        //
        // Takip kalıcı olarak kapanmaz — kullanıcı biraz sonra dinlemeye
        // döndüğünde metnin yine kendiliğinden akmasını bekler. Bu yüzden
        // parmak kaldırıldıktan bir süre sonra takip geri açılır
        // (bkz. [_resumeFollowTimer]).
        if (dragDetails != null &&
            !_isAutoScrolling &&
            ref.read(audioProvider).isActive) {
          _userScrolledDuringAudio = true;
          _resumeFollowTimer?.cancel();
        }

      // Taşma yalnızca parmak ekrandayken sayılır: hızlı kaydırmanın ataleti
      // de sınırı aşar ve sayılsaydı kullanıcı istemeden sure atlardı.
      case ScrollUpdateNotification(:final metrics, :final dragDetails):
        if (dragDetails == null) break;
        final pulled = overscrollOf(metrics);
        if (pulled != _overscroll) setState(() => _overscroll = pulled);

      // Parmak kaldırıldı: eşik aşıldıysa geçiş burada tetiklenir. Böylece
      // kullanıcı kaydırırken değil bıraktığında geçer — eşiğe varmadan
      // vazgeçme şansı olur.
      case ScrollEndNotification():
        final shouldAdvance = _isDragging && _overscroll >= _pullThreshold;
        _isDragging = false;

        // Kullanıcı kaydırmayı bıraktı: takip bir süre sonra geri gelir.
        // Süre, "baktım ve döndüm" ile "burayı okuyorum" arasını ayıracak
        // kadar uzun, kullanıcıyı bekletmeyecek kadar kısa seçildi.
        if (_userScrolledDuringAudio) {
          _resumeFollowTimer?.cancel();
          _resumeFollowTimer = Timer(const Duration(seconds: 6), () {
            if (!mounted) return;
            _userScrolledDuringAudio = false;
            // Takip yeniden açıldığında çalan ayete dönülür; aksi halde
            // kullanıcı sıradaki ayet gelene kadar eski yerde kalırdı.
            _lastAutoScrolledAyah = null;
            final audio = ref.read(audioProvider);
            if (audio.surahNumber != _surahNumber) return;
            final ayahs =
                ref.read(readerDataProvider(_surahNumber)).valueOrNull?.ayahs;
            if (ayahs == null) return;
            _followPlayingAyah(ayahs, audio.currentAyahNumber);
          });
        }
        if (shouldAdvance) {
          _advanceToNextSurah();
        } else if (_overscroll > 0) {
          setState(() => _overscroll = 0);
        }

      default:
        break;
    }

    return false;
  }

  /// Sıradaki sureye geçer.
  ///
  /// Yeni ekran açmak yerine mevcut ekranın suresi değiştirilir; liste başa
  /// sarılır. Böylece geri tuşu okumaya başlanan yere döner, her surede bir
  /// katman biriktirmez.
  Future<void> _advanceToNextSurah() async {
    if (_isAdvancing) return;

    final next = await ref.read(nextSurahProvider(_surahNumber).future);
    if (next == null || !mounted) return;

    // Geçiş hissedilir olsun; kullanıcı ekrana bakmadan da sure değiştiğini
    // anlar.
    HapticFeedback.mediumImpact();

    // Sureyi sonuna kadar okuyup çıkıldı: ilerleme tam sayılır. Kaydırma
    // ölçümüne bırakılsaydı son ayet ekranın altında kalabileceği için
    // çubuk %100'e ulaşmayabilirdi.
    final current = ref.read(readerDataProvider(_surahNumber)).valueOrNull;
    if (current != null) {
      _progressDebounce?.cancel();
      await ref.read(saveProgressProvider)(
        _surahNumber,
        current.surah.ayahCount,
      );
    }

    setState(() {
      _isAdvancing = true;
      _overscroll = 0;
    });

    // Liste yeni surenin başına konumlanır. Sıçrama yerine kısa bir kayma
    // kullanılır; kullanıcı sure değiştiğini görsün.
    if (_itemScrollController.isAttached) {
      await _itemScrollController.scrollTo(
        index: 0,
        duration: Motion.normal,
        curve: Motion.standard,
      );
    }

    if (!mounted) return;
    setState(() {
      _surahNumber = next.number;
      _focusedAyahNumber = null;
      _isAdvancing = false;
    });
  }

  /// Başlangıç ayetine konumlanma bir kez yapılır.
  ///
  /// Sonraki sureye geçildikten sonra tekrar tetiklenmemeli; aksi halde yeni
  /// surede eski ayet numarasına atlanırdı.
  bool _didScrollToInitial = false;

  /// Ayet numarasının listedeki karşılığını bulur.
  ///
  /// Ayet numarası doğrudan indeks olarak kullanılamaz. İki kayma vardır:
  ///
  ///  1. Listenin ilk öğesi sure başlığıdır; ayetler 1'den başlar.
  ///  2. Bazı meallerde çevirmen ardışık ayetleri tek blokta karşılar
  ///     (örn. Sâffât'ta 18 ayet birleşiktir). O surelerde blok sayısı ayet
  ///     sayısından azdır ve fark biriktikçe hedef ayet ekranın dışında
  ///     kalırdı — 200. ayet istenip 210. ayet gösterilmesinin sebebi buydu.
  ///
  /// Aranan numara bir bloğun içindeyse o bloğun indeksi döner.
  int? _indexOfAyah(List<Ayah> ayahs, int ayahNumber) {
    for (var i = 0; i < ayahs.length; i++) {
      final a = ayahs[i];
      if (ayahNumber >= a.ayahNumber && ayahNumber <= a.endAyahNumber) {
        return i + 1; // 0 = sure başlığı
      }
    }
    return null;
  }

  void _scrollToInitialAyah(List<Ayah> ayahs) {
    if (_didScrollToInitial) return;

    final target = widget.initialAyah;
    if (target == null) {
      _didScrollToInitial = true;
      return;
    }
    final index = _indexOfAyah(ayahs, target);
    if (index == null) {
      _didScrollToInitial = true;
      return;
    }
    _didScrollToInitial = true;

    // Liste çizildikten sonra konumlanır.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_itemScrollController.isAttached) return;
      _itemScrollController.scrollTo(
        index: index,
        duration: Motion.slow,
        curve: Motion.standard,
        alignment: 0.15,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(readerDataProvider(_surahNumber));
    final marks = ref.watch(surahMarksProvider(_surahNumber));
    final prefs = ref.watch(preferencesProvider);
    final nextSurah = ref.watch(nextSurahProvider(_surahNumber)).valueOrNull;
    final audio = ref.watch(audioProvider);

    // Çalan ayet değiştikçe liste onu takip eder.
    //
    // Dinleme `build` içinden değil buradan kurulur: takip listeyi
    // kaydırmak için `setState`e yakın bir iş yapar ve çizim sırasında
    // tetiklenirse aynı kare içinde ikinci bir düzen geçişi başlar. O
    // durumda `ScrollablePositionedList` iki liste birden canlı tutar ve
    // tur anahtarı (`_firstAyahKey`) aynı anda iki karede görünüp
    // "Multiple widgets used the same GlobalKey" hatası verir.
    ref.listen(audioProvider.select((a) => (a.surahNumber, a.currentAyahNumber)),
        (previous, next) {
      final (surahNumber, ayahNumber) = next;
      if (surahNumber != _surahNumber) return;
      final ayahs = ref.read(readerDataProvider(_surahNumber)).valueOrNull?.ayahs;
      if (ayahs == null) return;
      _followPlayingAyah(ayahs, ayahNumber);
    });

    // Araçtan/bildirimden doğrudan açıldığında geride yığın olmaz; sistem
    // geri jesti uygulamayı kapatmak yerine ana sayfaya dönsün (bkz.
    // [popOrHome]).
    return PopScope(
      canPop: canPopRoute(context),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) popOrHome(context);
      },
      child: Scaffold(
        // Asistan düğmesi okuma ekranında da durur: aklına takılan soruyu
        // okurken sormak, çıkıp bir sekmeye gitmekten doğal.
        //
        // Tilavet çubuğu burada `bottomNavigationBar` yuvasında değil, gövdenin
        // en altında duruyor (bkz. aşağıdaki `AudioPlayerBar`); `Scaffold` onu
        // hesaba katmadığı için düğme çalarken çubuğun üstüne biner. Pay bu
        // yüzden elle veriliyor.
        floatingActionButton: AssistantFab(
          bottomOffset: audio.surahNumber == _surahNumber && audio.isActive
              ? AudioPlayerBar.barHeight
              : 0,
        ),
        body: asyncData.when(
          loading: () => const Center(child: CupertinoStyleLoader()),
          error: (error, _) => _ReaderError(message: '$error'),
          data: (data) {
            _scrollToInitialAyah(data.ayahs);

            // Tanıtım turu ancak ayetler çizildikten sonra başlayabilir;
            // hedef karelerin ekrandaki yeri ondan önce ölçülemez.
            return TourHost(
              tour: TourId.reader,
              enabled: data.ayahs.isNotEmpty,
              steps: () => _tourSteps(context),
              child: SafeArea(
                bottom: false,
                left: false,
                right: false,
                child: Column(
                  children: [
                    _ReaderAppBar(
                      surah: data.surah,
                      settingsKey: _settingsButtonKey,
                      listenKey: _listenButtonKey,
                      onSettings: () => _openReaderSettings(context),
                      isAudioActive: audio.surahNumber == _surahNumber,
                      onListen: () => _startAudio(data.surah),
                    ),
                    Expanded(
                      child: NotificationListener<ScrollNotification>(
                        onNotification: _onScrollNotification,
                        child: ScrollablePositionedList.builder(
                          // Sure değiştiğinde liste yeniden kurulur; aksi halde
                          // önceki surenin kaydırma konumu taşınır ve kullanıcı
                          // yeni surenin ortasında açılırdı.
                          key: ValueKey(_surahNumber),
                          itemScrollController: _itemScrollController,
                          itemPositionsListener: _positionsListener,
                          // Taşma kaydırmasının ölçülebilmesi için sınırda
                          // yaylanan fizik gerekir; aksi halde liste sonunda
                          // hiç bildirim üretilmez.
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          // 0 = sure başlığı, 1..n = ayetler, son = bitiş kartı.
                          itemCount: data.ayahs.length + 2,
                          // Yatayda ayet metni tüm genişliğe yayılmaz; ortada
                          // konforlu bir satır genişliğinde kalır. Dolgu
                          // üzerinden kurulduğu için kaydırma alanı yine tüm
                          // ekranı kaplar ve kaydırma çubuğu kenarda durur.
                          padding: centeredContentPadding(
                            context,
                            maxWidth: ContentWidth.reading,
                            // Üst çubuk ile metin arasında nefes payı.
                            top: Insets.xs,
                            // Alt güvenli alan + nefes payı; son ayet çentiğin
                            // altında kalmasın. Asistan düğmesi de sağ altta
                            // duruyor: 56pt düğme + nefes kadar pay bırakılır,
                            // yoksa son ayetin son satırı düğmenin altında
                            // kalır ve okunamaz.
                            bottom:
                                MediaQuery.paddingOf(context).bottom +
                                Insets.xl +
                                _fabClearance,
                          ),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _SurahHeader(surah: data.surah);
                            }

                            // Listenin sonu: sure bitti, sıradakine geçiş kartı.
                            if (index == data.ayahs.length + 1) {
                              return SurahEndCard(
                                current: data.surah,
                                nextSurah: nextSurah,
                                showRevelationOrder: prefs.sortByRevelation,
                                pullProgress: _overscroll / _pullThreshold,
                                onTap: _advanceToNextSurah,
                              );
                            }

                            final ayah = data.ayahs[index - 1];

                            final tile = AyahTile(
                              ayah: ayah,
                              prefs: prefs,
                              mark: marks[ayah.id],
                              isFocused: _focusedAyahNumber == ayah.ayahNumber,
                              isPlaying: audio.isBlockActive(
                                ayah,
                                _surahNumber,
                              ),
                              onTap: () {},
                              onLongPress: () =>
                                  _openActions(context, ayah, data.surah),
                            );

                            // Tanıtım turu ilk ayeti işaret eder. Anahtar
                            // `AyahTile`'ın kendisine verilemez: o anahtar
                            // widget kimliğidir ve liste öğeleri geri
                            // dönüştürüp yeniden konumlandırdığı için ölçüm
                            // yanlış kareye denk gelir. Ölçüm için ayrı bir
                            // sarmalayıcı kullanılır.
                            if (index != 1) return tile;
                            return KeyedSubtree(
                              key: _firstAyahKey,
                              child: tile,
                            );
                          },
                        ),
                      ),
                    ),
                    // Tilavet çubuğu listenin altında, güvenli alanın
                    // üstünde durur. Listenin üzerine bindirilmedi: metnin
                    // son satırını kapatmasın, kullanıcı okuduğu yeri
                    // görebilsin.
                    AudioPlayerBar(surahNumber: _surahNumber),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Okuma ekranının tanıtım adımları.
  ///
  /// Sıra bilinçli: önce en çok kaçırılan jest (basılı tutma), sonra
  /// okuma konforunu değiştiren ayar, en sonda sure sonundaki geçiş.
  /// Kullanıcı ilk adımı görür görmez uygulamanın asıl gücünü öğrenmiş
  /// olur; kalanlar üstüne eklenir.
  List<TourStep> _tourSteps(BuildContext context) {
    return [
      TourStep(
        targetKey: _firstAyahKey,
        icon: Icons.touch_app_outlined,
        title: 'tour.reader.longPressTitle'.tr(),
        body: 'tour.reader.longPressBody'.tr(),
      ),
      TourStep(
        targetKey: _listenButtonKey,
        shape: SpotlightShape.circle,
        icon: Icons.headphones_rounded,
        title: 'tour.reader.listenTitle'.tr(),
        body: 'tour.reader.listenBody'.tr(),
      ),
      TourStep(
        targetKey: _settingsButtonKey,
        shape: SpotlightShape.circle,
        icon: Icons.text_fields_rounded,
        title: 'tour.reader.settingsTitle'.tr(),
        body: 'tour.reader.settingsBody'.tr(),
      ),
      TourStep(
        // Sure sonu kartı listenin en altında; kullanıcı oraya kaydırmadan
        // ölçülemez. Hedefsiz adım ekranın ortasında gösterilir.
        icon: Icons.swipe_up_rounded,
        title: 'tour.reader.endCardTitle'.tr(),
        body: 'tour.reader.endCardBody'.tr(),
      ),
    ];
  }

  /// Çalan ayeti ekranda tutar.
  ///
  /// Holy Bible tarzı takibin özü bu: kullanıcı hiçbir şeye dokunmadan
  /// okuduğu satır ekranda kalır.
  ///
  /// Kaydırma her ayette değil, çalan ayet ekranın rahat okuma alanından
  /// çıkmak üzereyken yapılır. Her ayette kaydırılsaydı metin sürekli
  /// kımıldar ve göz satırı takip edemezdi; hiç kaydırılmasaydı ses ekranın
  /// dışına taşardı.
  void _followPlayingAyah(List<Ayah> ayahs, int? playingAyah) {
    if (playingAyah == null) return;
    if (!ref.read(preferencesProvider).autoScrollWithAudio) return;
    if (_userScrolledDuringAudio) return;
    if (_lastAutoScrolledAyah == playingAyah) return;

    final index = _indexOfAyah(ayahs, playingAyah);
    if (index == null) return;

    _lastAutoScrolledAyah = playingAyah;

    // Ayet, ekranın rahat okuma kuşağında duruyorsa liste kımıldamaz.
    //
    // Kuşak üstten %10, alttan %65 ile sınırlı: ayet bu aralıktayken göz onu
    // zaten görüyor. Alt sınır ekranın dibi değil, çünkü ayet oraya
    // vardığında kaydırma başlamalı — dibe değene kadar beklenirse tilavet
    // görünmeyen bir satırdan devam eder.
    final positions = _positionsListener.itemPositions.value;
    final comfortable = positions.any(
      (p) =>
          p.index == index &&
          p.itemLeadingEdge >= 0.10 &&
          p.itemLeadingEdge <= 0.65,
    );
    if (comfortable) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_itemScrollController.isAttached) return;

      // Kaydırma başlarken kullanıcı kaydırma tespiti geçici olarak
      // susturulur: `scrollTo` da kaydırma bildirimi üretir ve o bildirim
      // kullanıcı hareketi sayılsaydı takip ilk ayette kendini kapatırdı.
      _isAutoScrolling = true;

      _itemScrollController
          .scrollTo(
            index: index,
            duration: Motion.slow,
            curve: Motion.standard,
            // Ayet ekranın üst üçte birine oturur: altında okunacak metin
            // kalır, kullanıcı sıradakini önceden görür.
            alignment: 0.25,
          )
          .whenComplete(() {
            if (mounted) _isAutoScrolling = false;
          });
    });
  }

  /// Sureyi baştan ya da belirli bir ayetten dinlemeye başlar.
  ///
  /// Ses dosyaları cihazda yoksa önce indirme onayı istenir. Sessizce
  /// indirilmez: indirme kullanıcının verisini harcar ve uygulamanın ağa
  /// çıktığı tek an burasıdır.
  Future<void> _startAudio(Surah surah, {int? fromAyah}) async {
    // Dosya kontrolü diskten okunur ve ekran açılır açılmaz bitmiş olmayabilir.
    // Beklenmeseydi indirilmiş bir surede bile indirme yaprağı açılırdı.
    final download = await ref
        .read(surahDownloadProvider(surah.number).notifier)
        .ensureLoaded();

    if (!mounted) return;

    if (!download.isReady) {
      // Yaprak indirmeyi kendi içinde yürütür ve ancak tamamlandığında
      // `true` döner. İndirme burada tekrarlanmaz; kullanıcı vazgeçtiyse
      // ya da indirme başarısız olduysa yaprak zaten durumu göstermiştir.
      final downloaded = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        // İndirme sürerken yaprağın kazara kapanmaması için dışarı dokunuşla
        // kapanmaz; vazgeçmek için açık bir "Vazgeç" düğmesi var.
        isDismissible: false,
        builder: (_) => AudioDownloadSheet(surah: surah),
      );

      if (downloaded != true || !mounted) return;
    }

    if (!mounted) return;

    // Yeni bir dinleme başlıyor: takip durumu sıfırlanır, aksi halde önceki
    // dinlemede kullanıcının yaptığı kaydırma takibi kapalı bırakırdı.
    setState(() {
      _userScrolledDuringAudio = false;
      _lastAutoScrolledAyah = null;
    });

    await ref.read(playSurahProvider)(surah.number, fromAyah: fromAyah);
  }

  void _openActions(BuildContext context, Ayah ayah, Surah surah) {
    final notifier = ref.read(surahMarksProvider(_surahNumber).notifier);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // Yaprak, işaretleri canlı izler: içeriden yapılan bir değişiklik
      // (örn. yer imi) yaprak kapanmadan da görünür hale gelir.
      builder: (sheetContext) => Consumer(
        builder: (context, sheetRef, _) => AyahActionsSheet(
          ayah: ayah,
          surahName: surah.name,
          mark: sheetRef.watch(surahMarksProvider(_surahNumber))[ayah.id],
          onToggleBookmark: () => notifier.toggleBookmark(ayah.id),
          onSetHighlight: (color) => notifier.setHighlight(ayah.id, color),
          onEditNote: () => _openNoteEditor(context, ayah, surah.name),
          onAnalyseRoots: () => _openWordPicker(context, ayah, surah.name),
          onListenFromHere: () =>
              _startAudio(surah, fromAyah: ayah.ayahNumber),
        ),
      ),
    );
  }

  /// Ayetin kelimelerini gösterir; seçilen kelimenin kök detayına götürür.
  ///
  /// Gezinme, yaprağın değil bu ekranın gezinginiyle yapılır: kelime
  /// seçildiğinde yaprak önce kapanır, kapanmış bir yaprağın context'i ise
  /// artık ağaçta değildir ve `Navigator.of` üzerinden gezinme başarısız
  /// olurdu.
  void _openWordPicker(BuildContext context, Ayah ayah, String surahName) {
    final navigator = Navigator.of(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => WordPickerSheet(
        ayah: ayah,
        surahName: surahName,
        onSelect: (word) => navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => RootDetailScreen(
              rootArabic: word.root,
              // Kullanıcı kendi ayetini listede bulabilsin.
              focusSurah: word.surahNumber,
              focusAyah: word.ayahNumber,
            ),
          ),
        ),
      ),
    );
  }

  void _openNoteEditor(BuildContext context, Ayah ayah, String surahName) {
    final notifier = ref.read(surahMarksProvider(_surahNumber).notifier);
    final existing = ref.read(surahMarksProvider(_surahNumber))[ayah.id]?.note;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => NoteEditorSheet(
        ayah: ayah,
        surahName: surahName,
        initialNote: existing,
        onSave: (note) => notifier.setNote(ayah.id, note),
      ),
    );
  }

  void _openReaderSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const ReaderSettingsSheet(),
    );
  }
}

/// Okuma ekranının üst çubuğu. Geri düğmesi, sure adı ve ayar düğmesi.
class _ReaderAppBar extends StatelessWidget {
  const _ReaderAppBar({
    required this.surah,
    required this.onSettings,
    required this.onListen,
    required this.isAudioActive,
    this.settingsKey,
    this.listenKey,
  });

  final Surah surah;
  final VoidCallback onSettings;

  /// Sureyi baştan dinlemeye başlar.
  final VoidCallback onListen;

  /// Bu surenin tilaveti şu an çalıyor mu. Çalıyorsa düğme vurgulanır ve
  /// kullanıcı sesin nereden geldiğini görür.
  final bool isAudioActive;

  /// Tanıtım turunun ayar düğmesini işaret edebilmesi için.
  final GlobalKey? settingsKey;

  /// Tanıtım turunun dinleme düğmesini işaret edebilmesi için.
  final GlobalKey? listenKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Çubuk tüm genişliği kaplar (metin gibi daraltılmaz) ama yatayda
    // düğmeler çentiğin altında kalmasın diye güvenli alan kadar içeri alınır.
    final safe = MediaQuery.paddingOf(context);

    return Container(
      height: 48,
      // Opak zemin: kaydırılan ayet metni çubuğun arkasından görünmemeli.
      color: theme.scaffoldBackgroundColor,
      padding: EdgeInsets.only(
        left: Insets.xs + safe.left,
        right: Insets.xs + safe.right,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
            onPressed: () => popOrHome(context),
            tooltip: 'common.back'.tr(),
          ),
          Expanded(
            child: Text(
              surah.nameFor(context.locale.languageCode),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall,
            ),
          ),
          IconButton(
            key: listenKey,
            icon: Icon(
              isAudioActive
                  ? Icons.headphones_rounded
                  : Icons.headphones_outlined,
              size: 21,
              color: isAudioActive ? theme.colorScheme.primary : null,
            ),
            onPressed: onListen,
            tooltip: 'audio.listen'.tr(),
          ),
          IconButton(
            key: settingsKey,
            icon: const Icon(Icons.text_fields_rounded, size: 21),
            onPressed: onSettings,
            tooltip: 'reader.settings'.tr(),
          ),
        ],
      ),
    );
  }
}

/// Listenin başındaki sure künyesi.
class _SurahHeader extends StatelessWidget {
  const _SurahHeader({required this.surah});
  final Surah surah;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: Insets.md, bottom: Insets.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            surah.nameFor(context.locale.languageCode),
            style: theme.textTheme.displaySmall,
          ),
          const SizedBox(height: Insets.xxs),
          Text(
            surah.meaningFor(context.locale.languageCode),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: Insets.sm),
          // Rozetler sabit bir satırda durmaz: dar ekranda, uzun çevirilerde
          // ve büyük sistem puntosunda üçü yan yana sığmıyor ve satır
          // taşıyordu. `Wrap` sığmayanı alt satıra indirir.
          Wrap(
            spacing: Insets.xs,
            runSpacing: Insets.xs,
            children: [
              _MetaChip(
                label: 'home.revealedNth'.tr(
                  args: ['${surah.revelationOrder}'],
                ),
              ),
              _MetaChip(label: surah.revelationPlace.labelKey.tr()),
              _MetaChip(
                label: 'common.verseCount'.tr(args: ['${surah.ayahCount}']),
              ),
            ],
          ),
          const SizedBox(height: Insets.lg),
          Divider(color: theme.dividerColor, height: 1),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.xs,
        vertical: Insets.xxs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Text(label, style: theme.textTheme.labelSmall),
    );
  }
}

/// Sade, dönen yükleme göstergesi.
class CupertinoStyleLoader extends StatelessWidget {
  const CupertinoStyleLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
      ),
    );
  }
}

class _ReaderError extends StatelessWidget {
  const _ReaderError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Insets.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 36,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
            ),
            const SizedBox(height: Insets.md),
            Text('reader.surahFailed'.tr(), style: theme.textTheme.titleMedium),
            const SizedBox(height: Insets.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
