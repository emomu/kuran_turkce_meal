import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_typography.dart';
import '../../../data/db/search_normalizer.dart';
import '../../../data/repositories/quran_repository.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/pressable.dart';
import '../providers/search_provider.dart';
import '../../../shared/widgets/tab_bar_inset.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../onboarding/providers/tour_provider.dart';
import '../../onboarding/widgets/coach_mark.dart';
import '../../onboarding/widgets/tour_host.dart';

/// Meal ve tefsir metninde arama.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  /// Tanıtımın işaret ettiği arama alanı.
  final _fieldKey = GlobalKey();

  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(searchProvider);

    // Arama dizini arayüz diliyle aynı olmalı; aksi halde İngilizce
    // arayüzde Türkçe sonuçlar çıkardı.
    ref.read(searchProvider.notifier).languageCode =
        context.locale.languageCode;

    return Scaffold(
      body: TourHost(
        tour: TourId.search,
        steps: _tourSteps,
        // Yatay güvenli alan aşağıdaki dolgularda ele alınıyor.
        child: SafeArea(
        bottom: false,
        left: false,
        right: false,
        child: Column(
          children: [
            Padding(
              // Arama alanı sonuç listesiyle aynı sütuna hizalanır.
              padding: centeredContentPadding(
                context,
                top: Insets.md,
                bottom: Insets.sm,
              ),
              child: TextField(
                key: _fieldKey,
                controller: _controller,
                focusNode: _focusNode,
                autofocus: false,
                textInputAction: TextInputAction.search,
                style: theme.textTheme.bodyLarge,
                onChanged: ref.read(searchProvider.notifier).updateQuery,
                decoration: InputDecoration(
                  hintText: 'search.hint'.tr(),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  suffixIcon: state.query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _controller.clear();
                            ref.read(searchProvider.notifier).clear();
                          },
                        ),
                ),
              ),
            ),

            // Sonuç sayısı — kullanıcı aramanın işe yarayıp yaramadığını
            // listeye bakmadan anlar.
            if (state.results.isNotEmpty)
              Padding(
                padding: centeredContentPadding(
                  context,
                  bottom: Insets.xs,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'search.resultCount'.tr(
                      args: ['${state.results.length}'],
                    ),
                    style: theme.textTheme.labelMedium,
                  ),
                ),
              ),

            Expanded(child: _buildBody(context, state)),
          ],
          ),
        ),
      ),
    );
  }

  /// Arama ekranının tanıtım adımları.
  ///
  /// İki adım yeter: nerede arandığı ve Türkçe karakterlerin sorun
  /// olmadığı. İkincisi kullanıcının kendi başına keşfetmesi zor —
  /// "adalet" yazıp sonuç alamadığını sanan kullanıcı aramayı bir daha
  /// denemez.
  List<TourStep> _tourSteps() {
    return [
      TourStep(
        targetKey: _fieldKey,
        icon: Icons.search_rounded,
        title: 'tour.search.fieldTitle'.tr(),
        body: 'tour.search.fieldBody'.tr(),
      ),
      TourStep(
        targetKey: _fieldKey,
        icon: Icons.abc_rounded,
        title: 'tour.search.turkishTitle'.tr(),
        body: 'tour.search.turkishBody'.tr(),
      ),
    ];
  }

  Widget _buildBody(BuildContext context, SearchState state) {
    if (!state.hasQuery) {
      return EmptyState(
        icon: Icons.search_rounded,
        title: 'search.title'.tr(),
        message: 'search.emptyHint'.tr(),
      );
    }

    if (state.isLoading && state.results.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (state.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'search.noResults'.tr(),
        message: 'search.noResultsFor'.tr(args: [state.query.trim()]),
      );
    }

    return ListView.separated(
      padding: centeredContentPadding(
        context,
        bottom: bottomInsetFor(context) + Insets.lg,
      ),
      // Klavye, listeye dokunulunca kapansın; kullanıcı sonucu okurken
      // ekranın yarısı klavye olmasın.
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: state.results.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        color: Theme.of(context).dividerColor,
      ),
      itemBuilder: (context, index) {
        final hit = state.results[index];
        return _SearchResultRow(
          hit: hit,
          query: state.query,
          onTap: () => context.push(
            '/sure/${hit.ayah.surahNumber}?ayet=${hit.ayah.ayahNumber}',
          ),
        );
      },
    );
  }
}

/// Tek bir arama sonucu. Eşleşen kelimeler kalın gösterilir.
class _SearchResultRow extends StatelessWidget {
  const _SearchResultRow({
    required this.hit,
    required this.query,
    required this.onTap,
  });

  final SearchHit hit;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Pressable(
      onTap: onTap,
      scale: 0.99,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Insets.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${hit.surahName} · ${hit.ayah.numberLabel}. ayet',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            _HighlightedText(
              text: hit.ayah.translationFor(context.locale.languageCode),
              query: query,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}

/// Eşleşen kelimeleri kalınlaştırarak metni çizer.
class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.query,
    required this.maxLines,
  });

  final String text;
  final String query;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final base = AppTypography.reading(
      fontSize: 15,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
      height: 1.5,
    );
    final emphasis = base.copyWith(
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurface,
    );

    final ranges = SearchNormalizer.matchRanges(text, query);
    if (ranges.isEmpty) {
      return Text(
        text,
        style: base,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Eşleşme metnin ilerisindeyse baştan kırpar ve eşleşmenin biraz
    // öncesinden başlatır; aksi halde kullanıcı aradığı kelimeyi göremezdi.
    const leadContext = 40;
    final firstMatch = ranges.first.$1;
    final offset = firstMatch > leadContext ? firstMatch - leadContext : 0;
    final visible = offset == 0 ? text : '…${text.substring(offset)}';
    final shift = offset == 0 ? 0 : offset - 1; // '…' bir karakter ekler

    final spans = <TextSpan>[];
    var cursor = 0;

    for (final (start, end) in ranges) {
      final s = start - shift;
      final e = end - shift;
      if (e <= 0 || s >= visible.length) continue;

      final safeStart = s.clamp(0, visible.length);
      final safeEnd = e.clamp(0, visible.length);
      if (safeStart < cursor) continue;

      if (safeStart > cursor) {
        spans.add(TextSpan(text: visible.substring(cursor, safeStart)));
      }
      spans.add(TextSpan(
        text: visible.substring(safeStart, safeEnd),
        style: emphasis,
      ));
      cursor = safeEnd;
    }

    if (cursor < visible.length) {
      spans.add(TextSpan(text: visible.substring(cursor)));
    }

    return Text.rich(
      TextSpan(style: base, children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
