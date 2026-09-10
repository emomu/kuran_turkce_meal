import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_typography.dart';
import '../../../data/db/search_normalizer.dart';
import '../../../data/models/prophet.dart';
import '../../../data/repositories/quran_repository.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/pressable.dart';
import '../providers/search_provider.dart';
import '../widgets/search_suggestion_marquee.dart';
import '../../../shared/widgets/tab_bar_inset.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../onboarding/providers/tour_provider.dart';
import '../../onboarding/widgets/coach_mark.dart';
import '../../onboarding/widgets/tour_host.dart';

/// Meal metninde arama.
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

  /// Arama alanı odakta mı.
  ///
  /// Öneri şeridi yalnızca odaktayken görünür: kullanıcı yazmaya hazır
  /// olduğu anda ne yazabileceğini gösterir. Boş ekranda sürekli durması
  /// hem alanı yer hem de sorulmadan cevap vermek gibi olurdu.
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_isFocused == _focusNode.hasFocus) return;
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Şeritten seçilen öneriyi arama kutusuna yazar ve aramayı başlatır.
  void _applySuggestion(String text) {
    _controller.text = text;
    _controller.selection =
        TextSelection.collapsed(offset: text.length);
    ref.read(searchProvider.notifier).updateQuery(text);
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

            // Öneri şeridi: alan odaktayken ve sorgu boşken görünür.
            // Kullanıcı yazmaya başlayınca kaybolur — o noktada örneklere
            // değil sonuçlara yer gerekir.
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              // `query.isEmpty` değil `!hasQuery`: arama iki karakterden
              // önce başlamıyor, o yüzden tek harf yazan kullanıcıda şerit
              // de durmalı. Aksi hâlde "a" yazınca şerit kayboluyor ama
              // sonuç da gelmiyordu ve ekran bomboş kalıyordu.
              child: _isFocused && !state.hasQuery
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: Insets.sm),
                      child: SearchSuggestionMarquee(
                        languageCode: context.locale.languageCode,
                        onPick: _applySuggestion,
                      ),
                    )
                  : const SizedBox(width: double.infinity),
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
      // Kıssa araması alanın kendisini işaret eder: kart ancak bir peygamber
      // adı yazıldığında beliriyor ve tur çalışırken ekranda olmuyor.
      TourStep(
        targetKey: _fieldKey,
        icon: Icons.timeline_rounded,
        title: 'tour.search.prophetsTitle'.tr(),
        body: 'tour.search.prophetsBody'.tr(),
      ),
    ];
  }

  Widget _buildBody(BuildContext context, SearchState state) {
    if (!state.hasQuery) {
      // Şerit görünürken boş durum gizlenir: ikisi de aynı şeyi söylüyor
      // ve alt alta gelince ekran dolup taşıyor. Şeridin göründüğü koşulun
      // aynısı burada da geçerli olmalı, yoksa tek harf yazan kullanıcıda
      // ikisi birden kaybolup ekran boş kalır.
      if (_isFocused) return const SizedBox.shrink();

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

    final reference = state.reference;
    final prophet = state.prophet;

    // Kartlar listenin öğesi olarak değil, üstünde ayrı bloklar olarak durur:
    // bunlar arama sonucu değil, doğrudan gidilecek yerler. Sonuçlarla aynı
    // listede olsalardı ayırıcı çizgiler ikisini eşitler ve kullanıcı aradaki
    // farkı görmezdi.
    final cardCount = (reference == null ? 0 : 1) + (prophet == null ? 0 : 1);

    return ListView.separated(
      padding: centeredContentPadding(
        context,
        bottom: bottomInsetFor(context) + Insets.lg,
      ),
      // Klavye, listeye dokunulunca kapansın; kullanıcı sonucu okurken
      // ekranın yarısı klavye olmasın.
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: state.results.length + cardCount,
      separatorBuilder: (_, index) {
        // Kartların arasına ve kart ile ilk sonuç arasına çizgi konmaz;
        // kartlar kendi yüzeylerinde duruyor ve çizgi onları listeye
        // yapıştırırdı.
        if (index < cardCount) return const SizedBox(height: Insets.xs);
        return Divider(height: 1, color: Theme.of(context).dividerColor);
      },
      itemBuilder: (context, index) {
        if (index < cardCount) {
          // Referans kartı önce gelir: "2:255" yazan kullanıcının niyeti
          // bir peygamber adı yazandan daha kesindir.
          final isReferenceSlot = reference != null && index == 0;

          if (isReferenceSlot) {
            return _ReferenceCard(
              reference: reference,
              onTap: () => context.push(
                reference.ayahNumber == null
                    ? '/sure/${reference.surah.number}'
                    : '/sure/${reference.surah.number}'
                          '?ayet=${reference.ayahNumber}',
              ),
            );
          }

          return _ProphetCard(
            prophet: prophet!,
            onTap: () => context.push('/kissa/${prophet.id}'),
          );
        }

        final hit = state.results[index - cardCount];
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

/// Sorgunun çözüldüğü ayete/sureye doğrudan giden kart.
///
/// "2:255" ya da "bakara 255" yazan kullanıcı arama yapmıyor, bir yere
/// gitmek istiyor. Bu kart o niyeti karşılar ve arama sonuçlarının önünde
/// durur; tam metin sonuçları altında kalmaya devam eder, çünkü "nur" gibi
/// sorgularda kullanıcı ikisini de kastediyor olabilir.
class _ReferenceCard extends StatelessWidget {
  const _ReferenceCard({required this.reference, required this.onTap});

  final ReferenceHit reference;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.locale.languageCode;

    return Pressable(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: Insets.xs),
        padding: const EdgeInsets.all(Insets.sm + 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Row(
          children: [
            Icon(
              Icons.my_location_rounded,
              size: 19,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: Insets.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    reference.ayahNumber == null
                        ? 'search.goToSurah'.tr(
                            namedArgs: {
                              'surah': reference.surah.nameFor(lang),
                            },
                          )
                        : 'search.goToAyah'.tr(
                            namedArgs: {
                              'surah': reference.surah.nameFor(lang),
                              'verse': '${reference.ayahNumber}',
                            },
                          ),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'search.goToHint'.tr(),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bir peygamberin anıldığı ayetlere götüren kart.
///
/// "mûsâ" yazan kullanıcı çoğunlukla kelimenin geçtiği ayetleri değil,
/// kıssayı arıyor. Kart o niyeti karşılar; tam metin sonuçları altında
/// durmaya devam eder.
class _ProphetCard extends StatelessWidget {
  const _ProphetCard({required this.prophet, required this.onTap});

  final Prophet prophet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.locale.languageCode;

    return Pressable(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: Insets.xs),
        padding: const EdgeInsets.all(Insets.sm + 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Row(
          children: [
            Icon(
              Icons.timeline_rounded,
              size: 19,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: Insets.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'prophets.searchCard'.tr(
                      namedArgs: {'name': prophet.nameFor(lang)},
                    ),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    // Hz. Muhammed'de iki sayı ayrışır: kıssası 10 ayet ama
                    // adı ve ona yönelen hitaplar 140 ayette geçer. Kullanıcı
                    // adını arattığında beklediği sayı ikincisidir; kart
                    // yalnızca kıssayı söylerse arama eksik görünür.
                    prophet.hasSeparateMentions
                        ? 'prophets.searchCardMentions'.tr(
                            namedArgs: {
                              'count': '${prophet.mentionCount}',
                              'story': '${prophet.ayahCount}',
                            },
                          )
                        : 'prophets.searchCardHint'.tr(
                            namedArgs: {'count': '${prophet.ayahCount}'},
                          ),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
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
