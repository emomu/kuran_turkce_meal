import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/pressable.dart';
import '../providers/bookmarks_provider.dart';
import '../../../shared/widgets/tab_bar_inset.dart';
import '../../../shared/widgets/responsive_layout.dart';

/// Kullanıcının yer imleri, notları ve vurguları.
class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tab = ref.watch(savedTabProvider);
    final entries = ref.watch(savedEntriesProvider(tab));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        left: false,
        right: false,
        child: Column(
          children: [
            Padding(
              // Başlık ve sekmeler alttaki listeyle aynı sütuna hizalanır.
              padding: centeredContentPadding(
                context,
                top: Insets.md,
                bottom: Insets.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('saved.title'.tr(), style: theme.textTheme.displaySmall),
                  const SizedBox(height: Insets.md),
                  _TabBar(
                    selected: tab,
                    onChanged: (value) =>
                        ref.read(savedTabProvider.notifier).state = value,
                  ),
                ],
              ),
            ),

            Expanded(
              // Sekme değişince içerik ani zıplamak yerine yumuşakça
              // değişir; göstergenin kayma hareketiyle aynı süreyi paylaşır.
              child: AnimatedSwitcher(
                duration: Motion.normal,
                switchInCurve: Motion.standard,
                switchOutCurve: Motion.standard,
                // Liste yüksekliği sekmeler arasında değiştiği için varsayılan
                // ölçek geçişi zıplama yaratır; sade bir solma daha sakin.
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: KeyedSubtree(
                  key: ValueKey(tab),
                  child: entries.when(
                    loading: () => const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (error, _) => EmptyState(
                      icon: Icons.error_outline_rounded,
                      title: 'common.loadFailed'.tr(),
                      message: '$error',
                    ),
                    data: (list) {
                      if (list.isEmpty) return _emptyFor(tab);

                      return ListView.separated(
                        padding: centeredContentPadding(
                          context,
                          bottom: bottomInsetFor(context) + Insets.lg,
                        ),
                        itemCount: list.length,
                        separatorBuilder: (_, _) =>
                            Divider(height: 1, color: theme.dividerColor),
                        itemBuilder: (context, index) {
                          final entry = list[index];
                          return _SavedRow(
                            entry: entry,
                            showNote: tab == SavedTab.notes,
                            onTap: () => context.push(
                              '/sure/${entry.ayah.surahNumber}'
                              '?ayet=${entry.ayah.ayahNumber}',
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyFor(SavedTab tab) => switch (tab) {
    SavedTab.bookmarks => EmptyState(
      icon: Icons.bookmark_outline_rounded,
      title: 'saved.noBookmarks'.tr(),
      message: 'saved.noBookmarksHint'.tr(),
    ),
    SavedTab.notes => EmptyState(
      icon: Icons.edit_note_rounded,
      title: 'saved.noNotes'.tr(),
      message: 'saved.noNotesHint'.tr(),
    ),
    SavedTab.highlights => EmptyState(
      icon: Icons.format_color_fill_rounded,
      title: 'saved.noHighlights'.tr(),
      message: 'saved.noHighlightsHint'.tr(),
    ),
  };
}

/// Segmentli sekme çubuğu.
///
/// Seçili sekmenin arkasındaki yüzey, sekmeler arasında *kayar*. Her segment
/// kendi rengini ayrı ayrı canlandırsaydı seçim bir yerde sönüp başka yerde
/// yanardı; kayan tek bir gösterge hareketin nereden nereye gittiğini
/// anlatır ve iOS'un segment kontrolüyle aynı dili konuşur.
class _TabBar extends StatelessWidget {
  const _TabBar({required this.selected, required this.onChanged});

  final SavedTab selected;
  final ValueChanged<SavedTab> onChanged;

  static const _tabs = SavedTab.values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = <SavedTab, String>{
      SavedTab.bookmarks: 'saved.bookmarks'.tr(),
      SavedTab.notes: 'saved.notes'.tr(),
      SavedTab.highlights: 'saved.highlights'.tr(),
    };
    final index = _tabs.indexOf(selected);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / _tabs.length;

          return Stack(
            children: [
              // Kayan gösterge. Metinlerin arkasında durur ve yalnızca
              // konumu değişir — genişliği sabit olduğu için hareket
              // tek eksende kalır ve göz takip edebilir.
              AnimatedAlign(
                duration: Motion.normal,
                curve: Motion.emphasized,
                alignment: Alignment(
                  // -1 sol, +1 sağ; segment sayısına göre normalize edilir.
                  _tabs.length == 1 ? 0 : (index / (_tabs.length - 1)) * 2 - 1,
                  0,
                ),
                child: Container(
                  width: segmentWidth,
                  height: 30,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final tab in _tabs)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (tab == selected) return;
                          HapticFeedback.selectionClick();
                          onChanged(tab);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(
                          height: 30,
                          child: Center(
                            // Renk ve kalınlık göstergeyle aynı sürede
                            // değişir; iki hareket tek hareket gibi okunur.
                            child: AnimatedDefaultTextStyle(
                              duration: Motion.normal,
                              curve: Motion.standard,
                              style: theme.textTheme.labelMedium!.copyWith(
                                fontWeight: FontWeight.w600,
                                color: tab == selected
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurface.withValues(
                                        alpha: 0.5,
                                      ),
                              ),
                              child: Text(
                                labels[tab]!,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Kaydedilmiş tek bir ayet satırı.
class _SavedRow extends StatelessWidget {
  const _SavedRow({
    required this.entry,
    required this.showNote,
    required this.onTap,
  });

  final SavedEntry entry;
  final bool showNote;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlight = entry.mark.highlightColor;

    return Pressable(
      onTap: onTap,
      scale: 0.99,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Insets.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vurgu rengi varsa solda ince bir şerit olarak görünür.
            if (highlight != null) ...[
              Container(
                width: 3,
                height: 38,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: Color(highlight),
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
              ),
              const SizedBox(width: Insets.sm),
            ],

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.surah.name} · ${entry.ayah.numberLabel}. ayet',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    entry.ayah.translationFor(context.locale.languageCode),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.reading(
                      fontSize: 15,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.85,
                      ),
                      height: 1.5,
                    ),
                  ),

                  // Notlar sekmesinde notun kendisi öne çıkar.
                  if (showNote && entry.mark.hasNote) ...[
                    const SizedBox(height: Insets.xs),
                    Container(
                      padding: const EdgeInsets.only(left: Insets.xs),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        entry.mark.note!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
