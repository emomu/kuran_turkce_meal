import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../settings/providers/preferences_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/home_cards.dart';
import '../widgets/surah_row.dart';
import '../widgets/surah_search_field.dart';
import '../../../shared/widgets/tab_bar_inset.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../onboarding/providers/tour_provider.dart';
import '../../onboarding/widgets/coach_mark.dart';
import '../../onboarding/widgets/tour_host.dart';

/// Uygulamanın ana ekranı: kaldığı yer, günün ayeti ve sure listesi.
///
/// Tek bir kaydırma alanı kullanılır ([CustomScrollView]); kartlar ve liste
/// ayrı kaydırılsaydı ekran iki bölgeye ayrılır, uzun listede kartlara
/// dönmek zorlaşırdı.
/// Ana ekrandaki tanıtım turunun işaret ettiği öğeler.
///
/// Ana ekran tek örnektir (sekme dalının kökü) ve durumsuz bir
/// `ConsumerWidget`; anahtarlar bu yüzden dosya düzeyinde tutulur.
final _ayahOfDayKey = GlobalKey();
final _orderToggleKey = GlobalKey();
final _surahSearchKey = GlobalKey();

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final surahs = ref.watch(filteredSurahListProvider);
    final query = ref.watch(surahQueryProvider);
    final lastRead = ref.watch(lastReadProvider);
    final ayahOfDay = ref.watch(ayahOfTheDayProvider);
    final progress = ref.watch(surahProgressProvider);
    final sortByRevelation = ref.watch(
      preferencesProvider.select((p) => p.sortByRevelation),
    );

    return Scaffold(
      // Tur, sure listesi ve günün ayeti yerleşmeden başlamamalı; hedefler
      // ancak çizildikten sonra ölçülebilir.
      body: TourHost(
        tour: TourId.home,
        enabled: surahs.hasValue && ayahOfDay.hasValue,
        steps: _tourSteps,
        child: SafeArea(
        bottom: false,
        left: false,
        right: false,
        child: RefreshIndicator(
          // Aşağı çekince günün ayeti ve ilerleme yenilenir.
          onRefresh: () async {
            ref.invalidate(ayahOfTheDayProvider);
            ref.invalidate(lastReadProvider);
            ref.invalidate(surahProgressProvider);
          },
          child: CustomScrollView(
            // Kaydırmaya başlayınca klavye kapanır. Sure arama alanı listenin
            // içinde olduğu için kullanıcı yazdıktan sonra sonuçlara bakmak
            // istediğinde ilk hareketi kaydırmak oluyor; klavye açık kalsaydı
            // listenin yarısını örterdi. "Ara" sekmesi de aynı davranışta.
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                // Geniş/yatay ekranda içerik ortalanır; listeyle başlık
                // aynı sütuna oturur.
                padding: centeredContentPadding(context, top: Insets.md),
                sliver: SliverList.list(
                  children: [
                    Text('app.title'.tr(), style: theme.textTheme.displaySmall),
                    Text(
                      'app.subtitle'.tr(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: Insets.lg),

                    // "Devam et" kartı yalnızca okuma geçmişi varsa.
                    lastRead.maybeWhen(
                      data: (data) => data == null
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(
                                bottom: Insets.sm,
                              ),
                              child: ContinueReadingCard(
                                lastRead: data,
                                onTap: () => context.push(
                                  '/sure/${data.surah.number}'
                                  '?ayet=${data.ayahNumber}',
                                ),
                              ),
                            ),
                      orElse: () => const SizedBox.shrink(),
                    ),

                    ayahOfDay.maybeWhen(
                      data: (data) => data == null
                          ? const SizedBox.shrink()
                          : AyahOfTheDayCard(
                              key: _ayahOfDayKey,
                              data: data,
                              onTap: () => context.push(
                                '/sure/${data.surah.number}'
                                '?ayet=${data.ayah.ayahNumber}',
                              ),
                            ),
                      orElse: () => const SizedBox.shrink(),
                    ),

                    const SizedBox(height: Insets.lg),

                    // Liste başlığı ve sıralama düğmesi.
                    Row(
                      children: [
                        Text('home.surahs'.tr(), style: theme.textTheme.headlineSmall),
                        const Spacer(),
                        OrderToggle(
                          key: _orderToggleKey,
                          showRevelationOrder: sortByRevelation,
                          onChanged: ref
                              .read(preferencesProvider.notifier)
                              .setSortByRevelation,
                        ),
                      ],
                    ),
                    const SizedBox(height: Insets.sm),

                    // Sure süzme alanı. Başlığın hemen altında: kullanıcı
                    // listeye bakarken aradığını bulamazsa gözü buraya düşer.
                    SurahSearchField(key: _surahSearchKey),
                    const SizedBox(height: Insets.xs),
                  ],
                ),
              ),

              surahs.when(
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (error, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'home.surahsFailed'.tr(),
                    message: '$error',
                  ),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    // Arama sonuçsuz kaldıysa mesaj farklı: veri eksik değil,
                    // yalnızca bu ada uyan sure yok. İkisi aynı metni
                    // gösterseydi kullanıcı meal verisinin yüklenmediğini
                    // sanırdı.
                    final isSearching = query.trim().isNotEmpty;

                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: isSearching
                            ? Icons.search_off_rounded
                            : Icons.menu_book_outlined,
                        title: isSearching
                            ? 'home.noSurahMatch'.tr()
                            : 'home.noContent'.tr(),
                        message: isSearching
                            ? 'home.noSurahMatchHint'.tr(
                                namedArgs: {'query': query.trim()},
                              )
                            : 'home.noContentHint'.tr(),
                      ),
                    );
                  }

                  final progressMap = progress.valueOrNull ?? const {};

                  return SliverPadding(
                    padding: centeredContentPadding(
                      context,
                      bottom: bottomInsetFor(context) + Insets.lg,
                    ),
                    sliver: SliverList.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: theme.dividerColor,
                        indent: 46,
                      ),
                      itemBuilder: (context, index) {
                        final surah = list[index];
                        return SurahRow(
                          surah: surah,
                          showRevelationOrder: sortByRevelation,
                          lastReadAyah: progressMap[surah.number],
                          onTap: () => context.push('/sure/${surah.number}'),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  /// Ana ekranın tanıtım adımları.
  ///
  /// Günün ayeti ve "devam et" kartı koşullu çizilir (okuma geçmişi yoksa
  /// ya da içerik yüklenmediyse ekranda olmazlar). Hedefi ekranda olmayan
  /// adım listeye alınmaz; aksi halde tur boş bir yeri işaret ederdi.
  static List<TourStep> _tourSteps() {
    return [
      if (_ayahOfDayKey.currentContext != null)
        TourStep(
          targetKey: _ayahOfDayKey,
          icon: Icons.auto_awesome_outlined,
          title: 'tour.home.verseOfDayTitle'.tr(),
          body: 'tour.home.verseOfDayBody'.tr(),
        ),
      TourStep(
        targetKey: _orderToggleKey,
        shape: SpotlightShape.circle,
        icon: Icons.swap_vert_rounded,
        title: 'tour.home.orderTitle'.tr(),
        body: 'tour.home.orderBody'.tr(),
      ),
      TourStep(
        targetKey: _surahSearchKey,
        icon: Icons.search_rounded,
        title: 'tour.home.searchTitle'.tr(),
        body: 'tour.home.searchBody'.tr(),
      ),
    ];
  }
}
