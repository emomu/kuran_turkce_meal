import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../core/theme/app_typography.dart';
import '../../../data/models/ayah.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../reader/widgets/ayah_actions_sheet.dart';
import '../../reader/widgets/ayah_tile.dart';
import '../../reader/widgets/note_editor_sheet.dart';
import '../../reader/widgets/reader_settings_sheet.dart';
import '../../roots/view/root_detail_screen.dart';
import '../../roots/widgets/word_picker_sheet.dart';
import '../../settings/providers/preferences_provider.dart';
import '../providers/plan_reader_provider.dart';
import '../providers/plans_provider.dart';
import '../widgets/plan_day_end_card.dart';

/// Bir plan gününün okuma ekranı.
///
/// Sure okuma ekranından ayrılır çünkü burada okuma birimi sure değil *gün
/// aralığıdır*: bir gün surenin ortasında başlayıp başka bir surenin
/// ortasında bitebilir. Kullanıcı 1. güne dokunduğunda Alak'ın tamamını
/// değil, yalnızca o güne düşen ayetleri görmeli.
///
/// Sonuna gelindiğinde sıradaki güne geçilir — sure okuma ekranındaki
/// "kaydırarak devam et" mekaniğinin plan karşılığı.
class PlanReaderScreen extends ConsumerStatefulWidget {
  const PlanReaderScreen({
    super.key,
    required this.planId,
    required this.dayIndex,
  });

  final String planId;
  final int dayIndex;

  @override
  ConsumerState<PlanReaderScreen> createState() => _PlanReaderScreenState();
}

class _PlanReaderScreenState extends ConsumerState<PlanReaderScreen> {
  final _itemScrollController = ItemScrollController();
  final _positionsListener = ItemPositionsListener.create();

  /// Ekranda gösterilen gün.
  ///
  /// Sıradaki güne geçilirken yeni ekran açılmaz, bu alan değişir. Böylece
  /// geri tuşu plan listesine döner, her günde bir katman biriktirmez.
  late int _dayIndex = widget.dayIndex;

  /// Listenin sonundan taşan kaydırma miktarı (piksel).
  double _overscroll = 0;

  /// Geçişin tetikleneceği aşım eşiği. Sure okuma ekranıyla aynı değer;
  /// iki ekran arasında his tutarlı kalmalı.
  static const _pullThreshold = 130.0;

  bool _isDragging = false;
  bool _isAdvancing = false;

  /// Bu ekranda tamamlandı olarak işaretlenen günler.
  ///
  /// Aynı gün için tekrar tekrar veritabanına yazmayı önler; kullanıcı sona
  /// inip yukarı çıkıp tekrar inebilir.
  final _markedDays = <int>{};

  @override
  void initState() {
    super.initState();
    _positionsListener.itemPositions.addListener(_onPositionsChanged);
  }

  @override
  void dispose() {
    _positionsListener.itemPositions.removeListener(_onPositionsChanged);
    super.dispose();
  }

  /// Gün sonuna inildiğinde günü tamamlandı olarak işaretler.
  ///
  /// Kullanıcıdan ayrıca bir onay istenmez: listenin sonunu görmek zaten
  /// okumanın bittiği anlamına gelir. Ölçüt kartın *tamamen* görünmesidir;
  /// yalnızca kenarı belirdiğinde işaretlemek, kullanıcı hızla kaydırıp
  /// geri döndüğünde yanlış olurdu.
  void _onPositionsChanged() {
    if (_markedDays.contains(_dayIndex)) return;

    final reading =
        ref.read(planDayReadingProvider((widget.planId, _dayIndex))).valueOrNull;
    if (reading == null) return;

    // Ölçüt: gün sonu kartının *alt kenarı* ekrana girmiş olmalı. Yalnızca
    // üst kenarına bakmak, kart daha görünür görünmez tetikliyordu; kullanıcı
    // günün son ayetlerini okumadan tamamlandı sayılıyordu.
    final endCardIndex = reading.ayahs.length + 1;
    final reachedEnd = _positionsListener.itemPositions.value.any(
      (p) => p.index == endCardIndex && p.itemTrailingEdge <= 1.02,
    );
    if (!reachedEnd) return;

    setState(() => _markedDays.add(_dayIndex));

    // Zaten işaretliyse veritabanına dokunma.
    if (reading.day.isCompleted) return;
    ref.read(planActionsProvider).toggleDay(widget.planId, _dayIndex, false);
  }

  /// Sıradaki güne geçer.
  Future<void> _advanceToNextDay(PlanDayReading reading) async {
    if (_isAdvancing) return;
    final next = reading.nextDay;
    if (next == null) return;

    setState(() {
      _isAdvancing = true;
      _overscroll = 0;
    });

    HapticFeedback.mediumImpact();

    if (_itemScrollController.isAttached) {
      await _itemScrollController.scrollTo(
        index: 0,
        duration: Motion.normal,
        curve: Motion.standard,
      );
    }

    if (!mounted) return;
    setState(() {
      _dayIndex = next.index;
      _isAdvancing = false;
    });
  }

  /// Sure okuma ekranındaki taşma ölçümünün aynısı.
  bool _onScrollNotification(ScrollNotification notification) {
    if (_isAdvancing) return false;

    double overscrollOf(ScrollMetrics m) =>
        (m.pixels - m.maxScrollExtent).clamp(0.0, double.infinity);

    switch (notification) {
      case ScrollStartNotification(:final dragDetails):
        _isDragging = dragDetails != null;

      case ScrollUpdateNotification(:final metrics, :final dragDetails):
        if (dragDetails == null) break;
        final pulled = overscrollOf(metrics);
        if (pulled != _overscroll) setState(() => _overscroll = pulled);

      case ScrollEndNotification():
        final shouldAdvance = _isDragging && _overscroll >= _pullThreshold;
        _isDragging = false;
        if (shouldAdvance) {
          final reading = ref
              .read(planDayReadingProvider((widget.planId, _dayIndex)))
              .valueOrNull;
          if (reading != null) _advanceToNextDay(reading);
        } else if (_overscroll > 0) {
          setState(() => _overscroll = 0);
        }

      default:
        break;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final asyncReading =
        ref.watch(planDayReadingProvider((widget.planId, _dayIndex)));
    final prefs = ref.watch(preferencesProvider);

    return Scaffold(
      body: asyncReading.when(
        loading: () => const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (error, _) => Center(
          child: EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'common.loadFailed'.tr(),
            message: '$error',
          ),
        ),
        data: (reading) {
          if (reading.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.menu_book_outlined,
                title: 'common.loadFailed'.tr(),
                message: 'home.noContent'.tr(),
              ),
            );
          }

          // Yatay güvenli alan liste dolgusunda ve çubukta ele alınıyor.
          return SafeArea(
            bottom: false,
            left: false,
            right: false,
            child: Column(
              children: [
                _PlanReaderAppBar(
                  reading: reading,
                  onSettings: () => _openReaderSettings(context),
                ),
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _onScrollNotification,
                    child: _buildList(context, reading, prefs),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    PlanDayReading reading,
    dynamic prefs,
  ) {
    final ayahs = reading.ayahs;
    final marks = ref.watch(planDayMarksProvider((widget.planId, _dayIndex)));
    // Rozet, bu oturumda işaretlenen günü hemen gösterir; veritabanı yazımını
    // ve sağlayıcı tazelemesini beklemez.
    final isCompleted =
        _markedDays.contains(_dayIndex) || reading.day.isCompleted;

    return ScrollablePositionedList.builder(
      itemScrollController: _itemScrollController,
      itemPositionsListener: _positionsListener,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      // 0 = gün başlığı, 1..n = ayetler, son = gün sonu kartı.
      itemCount: ayahs.length + 2,
      // Okuma ekranıyla aynı kural: yatayda metin ortalanır ve konforlu
      // satır genişliğinde kalır.
      padding: centeredContentPadding(
        context,
        maxWidth: ContentWidth.reading,
        top: Insets.xs,
        bottom: MediaQuery.paddingOf(context).bottom + Insets.xl,
      ),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _PlanDayHeader(reading: reading);
        }

        if (index == ayahs.length + 1) {
          return PlanDayEndCard(
            day: reading.day,
            nextDay: reading.nextDay,
            isCompleted: isCompleted,
            pullProgress: _overscroll / _pullThreshold,
            onContinue: () => _advanceToNextDay(reading),
          );
        }

        final ayah = ayahs[index - 1];
        final previous = index >= 2 ? ayahs[index - 2] : null;
        // Gün birden çok sureye yayılıyorsa sure değiştiğinde başlık çizilir;
        // aksi halde kullanıcı hangi sureyi okuduğunu kaybeder.
        final showSurahHeader = reading.spansMultipleSurahs &&
            (previous == null || previous.surahNumber != ayah.surahNumber);

        final surahName =
            reading.surahsByNumber[ayah.surahNumber]?.nameFor(
                  context.locale.languageCode,
                ) ??
                '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showSurahHeader) _InlineSurahHeader(name: surahName),
            AyahTile(
              ayah: ayah,
              prefs: prefs,
              mark: marks[ayah.id],
              onTap: () {
              },
              onLongPress: () => _openActions(context, ayah, surahName),
            ),
          ],
        );
      },
    );
  }

  void _openActions(BuildContext context, Ayah ayah, String surahName) {
    final notifier =
        ref.read(planDayMarksProvider((widget.planId, _dayIndex)).notifier);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Consumer(
        builder: (context, sheetRef, _) => AyahActionsSheet(
          ayah: ayah,
          surahName: surahName,
          mark: sheetRef.watch(
            planDayMarksProvider((widget.planId, _dayIndex)),
          )[ayah.id],
          onToggleBookmark: () => notifier.toggleBookmark(ayah.id),
          onSetHighlight: (color) => notifier.setHighlight(ayah.id, color),
          onEditNote: () => _openNoteEditor(context, ayah, surahName),
          onAnalyseRoots: () => _openWordPicker(context, ayah, surahName),
        ),
      ),
    );
  }

  void _openNoteEditor(BuildContext context, Ayah ayah, String surahName) {
    final notifier =
        ref.read(planDayMarksProvider((widget.planId, _dayIndex)).notifier);
    final existing = ref
        .read(planDayMarksProvider((widget.planId, _dayIndex)))[ayah.id]
        ?.note;

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


  /// Kelime seçimi. Gezingen yaprak açılmadan önce alınır; yaprak kapandıktan
  /// sonra kendi context'i ağaçta olmaz.
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
              focusSurah: word.surahNumber,
              focusAyah: word.ayahNumber,
            ),
          ),
        ),
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

/// Plan okuma ekranının üst çubuğu.
///
/// Sure adı yerine gün numarası ve aralık gösterilir: kullanıcı burada bir
/// sure değil planın bir gününü okuyor.
class _PlanReaderAppBar extends StatelessWidget {
  const _PlanReaderAppBar({required this.reading, required this.onSettings});

  final PlanDayReading reading;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Yatayda düğmeler çentiğin altında kalmasın.
    final safe = MediaQuery.paddingOf(context);

    return Container(
      height: 48,
      color: theme.scaffoldBackgroundColor,
      padding: EdgeInsets.only(
        left: Insets.xs + safe.left,
        right: Insets.xs + safe.right,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'common.back'.tr(),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'plans.dayNumber'.tr(args: ['${reading.day.index}']),
                  style: theme.textTheme.labelSmall,
                ),
                Text(
                  reading.day.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.text_fields_rounded, size: 21),
            onPressed: onSettings,
            tooltip: 'reader.settings'.tr(),
          ),
        ],
      ),
    );
  }
}

/// Gün başlığı — listenin ilk öğesi.
class _PlanDayHeader extends StatelessWidget {
  const _PlanDayHeader({required this.reading});

  final PlanDayReading reading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(
        top: Insets.md,
        bottom: Insets.lg,
      ),
      child: Column(
        children: [
          Text(
            reading.day.label,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: Insets.xs),
          Text(
            'common.verseCount'.tr(args: ['${reading.ayahs.length}']),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: Insets.md),
          Divider(color: theme.dividerColor, height: 1),
        ],
      ),
    );
  }
}

/// Gün birden çok sureye yayıldığında araya giren sure adı.
class _InlineSurahHeader extends StatelessWidget {
  const _InlineSurahHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: Insets.lg, bottom: Insets.xs),
      child: Row(
        children: [
          Expanded(child: Divider(color: theme.dividerColor, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Insets.sm),
            child: Text(
              name,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Expanded(child: Divider(color: theme.dividerColor, height: 1)),
        ],
      ),
    );
  }
}
