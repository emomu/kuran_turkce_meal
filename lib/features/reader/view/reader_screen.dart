import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../data/models/ayah.dart';
import '../../../data/models/surah.dart';
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

  /// Tanıtım turunun işaret ettiği öğeler.
  ///
  /// İlk ayet karesi ve ayar düğmesi; turun delikleri bunların ekrandaki
  /// yerine göre açılır.
  final _firstAyahKey = GlobalKey();
  final _settingsButtonKey = GlobalKey();

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

    // Araçtan/bildirimden doğrudan açıldığında geride yığın olmaz; sistem
    // geri jesti uygulamayı kapatmak yerine ana sayfaya dönsün (bkz.
    // [popOrHome]).
    return PopScope(
      canPop: canPopRoute(context),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) popOrHome(context);
      },
      child: Scaffold(
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
                      onSettings: () => _openReaderSettings(context),
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
                            // altında kalmasın.
                            bottom:
                                MediaQuery.paddingOf(context).bottom +
                                Insets.xl,
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
    this.settingsKey,
  });

  final Surah surah;
  final VoidCallback onSettings;

  /// Tanıtım turunun ayar düğmesini işaret edebilmesi için.
  final GlobalKey? settingsKey;

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
