import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/repositories/topic_repository.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/tab_bar_inset.dart';
import '../../onboarding/providers/tour_provider.dart';
import '../../onboarding/widgets/coach_mark.dart';
import '../../onboarding/widgets/tour_host.dart';
import '../../search/data/verse_reference.dart';
import '../../search/providers/search_provider.dart';
import '../../search/widgets/search_result_parts.dart';
import '../../search/widgets/search_suggestion_marquee.dart';
import '../widgets/discover_entry_card.dart';
import '../widgets/filter_chips.dart';
import '../widgets/topic_card.dart';

/// Keşfet: Kur'an'a hem konudan hem kelimeden girmenin yolu.
///
/// Bu sekme eskiden yalnızca bir arama kutusuydu. Arama, ne aradığını bilen
/// kullanıcıya hizmet eder; bilmeyene boş bir ekran gösterir. Fihrist tersini
/// yapar — kullanıcı neyin var olduğunu görür ve oradan seçer.
///
/// TEK KUTU
/// --------
/// Konu ve metin araması ayrı ekranlara bölünmedi: kullanıcı "sabır" yazarken
/// bunun bir fihrist konusu mu yoksa mealde geçen bir kelime mi olduğunu
/// bilmek zorunda değil. Tek kutu ikisini de arar ve sonuçları gruplayıp
/// niyet kesinliğine göre sıralar.
///
/// ÜÇ HÂL
/// ------
/// Ekran tek seferde tek iş yapar; ikisi birden görünseydi ne gezilebilir ne
/// okunabilir olurdu.
///
///   * **Gezinme** — kutu boş ve odak dışında: çip şeridi ve konu ızgarası.
///   * **Odak** — kutuya dokunuldu ama henüz yazılmadı: yalnızca öneriler.
///     Izgara burada gizlenir. Kullanıcı yazmaya hazırdır ve arkadaki elli
///     altı kart, klavyenin üstünde kalan dar şeritte gürültüden başka bir
///     şey değildir.
///   * **Arama** — bir şey yazıldı: gruplu sonuçlar.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  /// Tanıtımın işaret ettiği arama alanı.
  final _fieldKey = GlobalKey();

  /// Tanıtımın işaret ettiği konu ızgarası.
  final _gridKey = GlobalKey();

  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  /// Arama alanı odakta mı.
  ///
  /// Öneri şeridi yalnızca odaktayken görünür. Sürekli durması yalnızca yer
  /// meselesi değil: şerit sonsuz bir kayma animasyonu çalıştırıyor ve
  /// ekranda kaldığı sürece kare istemeye devam ediyor.
  bool _isFocused = false;

  /// Kutuya yazılanın ham hâli.
  ///
  /// Meal araması [searchProvider] içinde 250 ms geciktiriliyor; konu
  /// filtresi ise gecikmez. Fihrist bellekte 56 kayıt ve filtreleme
  /// anlıktır — geciktirmek kullanıcıyı sebepsiz bekletirdi.
  String _query = '';

  /// Seçili bölüm çipi. 0 "Tümü".
  int _categoryIndex = 0;

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

  void _onQueryChanged(String value) {
    ref.read(searchProvider.notifier).updateQuery(value);
    if (_query == value) return;
    setState(() => _query = value);
  }

  void _clear() {
    _controller.clear();
    ref.read(searchProvider.notifier).clear();
    setState(() => _query = '');
  }

  /// Öneri şeridinden seçilen metni kutuya yazar.
  void _applySuggestion(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.collapsed(offset: text.length);
    _onQueryChanged(text);
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(topicDataProvider);

    // Arama dizini arayüz diliyle aynı olmalı; aksi halde İngilizce
    // arayüzde Türkçe sonuçlar çıkardı.
    ref.read(searchProvider.notifier).languageCode =
        context.locale.languageCode;

    return Scaffold(
      body: TourHost(
        tour: TourId.search,
        steps: _tourSteps,
        child: SafeArea(
          bottom: false,
          left: false,
          right: false,
          child: asyncData.when(
            loading: () => const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (error, _) => EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'discover.loadFailed'.tr(),
              message: '$error',
            ),
            data: (repo) => _Body(
              repo: repo,
              fieldKey: _fieldKey,
              gridKey: _gridKey,
              controller: _controller,
              focusNode: _focusNode,
              query: _query,
              isFocused: _isFocused,
              categoryIndex: _categoryIndex,
              onQueryChanged: _onQueryChanged,
              onClear: _clear,
              onSuggestion: _applySuggestion,
              onCategorySelected: (i) => setState(() => _categoryIndex = i),
            ),
          ),
        ),
      ),
    );
  }

  /// Keşfet'in tanıtım adımları.
  ///
  /// İkisi de kullanıcının kendi başına keşfetmesi zor olan şeyler: kutunun
  /// hem konu hem metin araması yaptığı, ve Türkçe karakterlerin sorun
  /// olmadığı. İkincisi olmadan "adalet" yazıp sonuç alamadığını sanan
  /// kullanıcı aramayı bir daha denemiyordu.
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
      // Fihrist adımı ızgarayı işaret eder: tur çalışırken kutu boş ve odak
      // dışında olduğu için ızgara ekranda duruyor, gösterilecek bir şey var.
      TourStep(
        targetKey: _gridKey,
        icon: Icons.grid_view_rounded,
        title: 'tour.search.topicsTitle'.tr(),
        body: 'tour.search.topicsBody'.tr(),
      ),
    ];
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.repo,
    required this.fieldKey,
    required this.gridKey,
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.isFocused,
    required this.categoryIndex,
    required this.onQueryChanged,
    required this.onClear,
    required this.onSuggestion,
    required this.onCategorySelected,
  });

  final TopicRepository repo;
  final GlobalKey fieldKey;
  final GlobalKey gridKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String query;
  final bool isFocused;
  final int categoryIndex;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;
  final ValueChanged<String> onSuggestion;
  final ValueChanged<int> onCategorySelected;

  bool get _isSearching => query.trim().isNotEmpty;

  /// Kutu odakta ama boş: kullanıcı yazmaya hazırlanıyor.
  bool get _isPicking => isFocused && !_isSearching;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: centeredContentPadding(context, top: Insets.md),
          sliver: SliverToBoxAdapter(
            child: _Header(
              fieldKey: fieldKey,
              controller: controller,
              focusNode: focusNode,
              hasQuery: _isSearching,
              isFocused: isFocused,
              onChanged: onQueryChanged,
              onClear: onClear,
            ),
          ),
        ),

        // Öneri şeridi kendi sliver'ında ve dolgusuz: kenardan kenara akar.
        // Başlığın içinde olduğu sürece onun yatay dolgusunu miras alıyor ve
        // iki yandan kesilmiş görünüyordu — oysa şeridin bütün fikri,
        // çiplerin ekranın dışından gelip dışına gitmesi.
        //
        // Alan odaktayken ve sorgu boşken görünür. Odak koşulu ayrıca
        // şeridin sonsuz kayma animasyonunu ekranda gereksiz yere çalışır
        // hâlde tutmamayı sağlar.
        if (_isPicking)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: Insets.sm),
              child: SearchSuggestionMarquee(
                languageCode: context.locale.languageCode,
                onPick: onSuggestion,
              ),
            ),
          ),
        if (_isSearching)
          ..._resultSlivers(context, theme, ref)
        else if (_isPicking)
          // Odak hâli: şeridin altına bir şey konmaz. Boş kalan yer kasıtlı —
          // klavye zaten ekranın yarısını alıyor ve kalanı doldurmak
          // kullanıcıyı yazmaktan alıkoyar.
          const SliverFillRemaining(hasScrollBody: false, child: SizedBox())
        else
          ..._browseSlivers(context, theme),
      ],
    );
  }

  // ------------------------------------------------------------- Gezinme

  /// Fihrist hâli: giriş kartları, çip şeridi, konu ızgarası.
  List<Widget> _browseSlivers(BuildContext context, ThemeData theme) {
    final lang = context.locale.languageCode;
    final categories = repo.categories;

    // 0 "Tümü"; çip sırası bölüm sırasının bir fazlası.
    final selected = categoryIndex == 0
        ? null
        : categories[categoryIndex - 1].id;
    final topics = selected == null ? repo.all : repo.inCategory(selected);

    return [
      SliverPadding(
        padding: centeredContentPadding(context, top: Insets.lg),
        sliver: const SliverToBoxAdapter(child: _EntryCards()),
      ),
      SliverPadding(
        padding: centeredContentPadding(context, top: Insets.lg),
        sliver: SliverToBoxAdapter(
          child: FilterChips(
            labels: [
              'discover.all'.tr(),
              for (final c in categories) c.nameFor(lang),
            ],
            selectedIndex: categoryIndex,
            onSelected: onCategorySelected,
          ),
        ),
      ),
      SliverPadding(
        padding: centeredContentPadding(
          context,
          top: Insets.md,
          bottom: bottomInsetFor(context) + Insets.lg,
        ),
        sliver: SliverGrid(
          gridDelegate: _gridDelegate(context),
          delegate: SliverChildBuilderDelegate(
            (context, i) => TopicCard(
              // Tanıtım ilk kartı işaret eder, ızgaranın tamamını değil.
              // `SliverGrid` bir kutu değil ve tanıtımın ölçümü `RenderBox`
              // bekliyor; ızgarayı bir sliver sarmalayıcıyla işaretlemek
              // orada çökerdi. Tek kart da anlatılanı gösteriyor: kullanıcı
              // vurgulanan karta bakıp altındakilerin aynı şey olduğunu
              // görüyor.
              key: i == 0 ? gridKey : null,
              topic: topics[i],
              onTap: () => context.push('/fihrist/${topics[i].id}'),
            ),
            childCount: topics.length,
          ),
        ),
      ),
    ];
  }

  /// Izgara ölçüsü.
  ///
  /// Sütun sayısı genişlikten türetilir, sabit değil: telefonda iki, tablette
  /// ve yatayda üç. Sabit ikiyle tablette kartlar avuç içi kadar genişliyor ve
  /// ızgara iki dev bloğa dönüşüyordu.
  SliverGridDelegate _gridDelegate(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= Breakpoints.compact ? 3 : 2;

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      mainAxisSpacing: Insets.xs,
      crossAxisSpacing: Insets.xs,
      // En/boy oranı kartın iki satırlık başlığı ve sayaç satırını alacak
      // kadar. Daha yassı kartlarda "Yaratılış ve Kâinat" gibi uzun adlar
      // üç noktaya düşüyordu.
      childAspectRatio: 1.65,
    );
  }

  // ------------------------------------------------------------- Sonuçlar

  /// Arama hâli: gruplu sonuçlar.
  ///
  /// Sıra niyet kesinliğine göredir. Referans kartı en üstte, çünkü "2:255"
  /// yazan kullanıcı aramıyor, bir yere gidiyor. Konular meal sonuçlarının
  /// üstünde, çünkü "sabır" yazan çoğunlukla kelimenin elli sekiz geçişini
  /// değil konuyu istiyor.
  ///
  /// Her grup kırpılır ve "Hepsini Gör" ile açılır: üç grup tam hâlde alt
  /// alta dizildiğinde kullanıcı ikinci grubu görmek için yüzlerce ayet
  /// kaydırmak zorunda kalıyordu.
  List<Widget> _resultSlivers(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
  ) {
    final search = ref.watch(searchProvider);
    final topics = repo.search(query, fold: foldSurahName);
    final reference = search.reference;
    final prophet = search.prophet;

    final hasAnything =
        reference != null ||
        prophet != null ||
        topics.isNotEmpty ||
        search.results.isNotEmpty;

    // Meal araması iki karakterden önce başlamıyor; o aralıkta yalnızca konu
    // filtresi çalışır ve yükleniyorken "sonuç yok" demek yanlış olurdu.
    if (!hasAnything) {
      if (search.isLoading) {
        return [
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ];
      }
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.search_off_rounded,
            title: 'discover.noResults'.tr(),
            message: 'discover.noResultsFor'.tr(args: [query.trim()]),
          ),
        ),
      ];
    }

    const topicPreview = 4;
    const versePreview = 5;

    return [
      if (reference != null)
        SliverPadding(
          padding: centeredContentPadding(context, top: Insets.lg),
          sliver: SliverToBoxAdapter(
            child: ReferenceCard(
              reference: reference,
              onTap: () => context.push(
                reference.ayahNumber == null
                    ? '/sure/${reference.surah.number}'
                    : '/sure/${reference.surah.number}'
                          '?ayet=${reference.ayahNumber}',
              ),
            ),
          ),
        ),

      // Konular ızgarada çizilir, listede değil: gezinme hâlindeki kartla
      // aynı şey aranıyor ve iki ayrı biçimde göstermek kullanıcıyı
      // "bunlar farklı şeyler mi" diye düşündürürdü.
      if (topics.isNotEmpty) ...[
        _GroupHeading(
          label: 'discover.topicResults'.tr(),
          count: topics.length,
          shownCount: topicPreview,
          onSeeAll: () {
            // Aramayı temizlemek gezinme hâline döndürür ve orada bütün
            // konular zaten ızgarada duruyor.
            onClear();
          },
        ),
        SliverPadding(
          padding: centeredContentPadding(context, top: Insets.sm),
          sliver: SliverGrid(
            gridDelegate: _gridDelegate(context),
            delegate: SliverChildBuilderDelegate(
              (context, i) => TopicCard(
                topic: topics[i],
                onTap: () => context.push('/fihrist/${topics[i].id}'),
              ),
              childCount: topics.length.clamp(0, topicPreview),
            ),
          ),
        ),
      ],

      if (prophet != null) ...[
        _GroupHeading(label: 'discover.prophetResults'.tr()),
        SliverPadding(
          padding: centeredContentPadding(context, top: Insets.sm),
          sliver: SliverToBoxAdapter(
            child: ProphetCard(
              prophet: prophet,
              onTap: () => context.push('/kissa/${prophet.id}'),
            ),
          ),
        ),
      ],

      if (search.results.isNotEmpty) ...[
        _GroupHeading(
          label: 'discover.verseResults'.tr(args: ['${search.results.length}']),
          count: search.results.length,
          shownCount: versePreview,
          onSeeAll: () => context.push(
            '/ayet-arama?q=${Uri.encodeComponent(query.trim())}',
          ),
        ),
        SliverPadding(
          padding: centeredContentPadding(context, top: Insets.xs),
          sliver: SliverList.separated(
            itemCount: search.results.length.clamp(0, versePreview),
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: theme.dividerColor),
            itemBuilder: (context, i) {
              final hit = search.results[i];
              return SearchResultRow(
                hit: hit,
                query: query,
                onTap: () => context.push(
                  '/sure/${hit.ayah.surahNumber}'
                  '?ayet=${hit.ayah.ayahNumber}',
                ),
              );
            },
          ),
        ),
      ],

      SliverToBoxAdapter(
        child: SizedBox(height: bottomInsetFor(context) + Insets.lg),
      ),
    ];
  }
}

/// Sonuç grubunun başlığı ve "Hepsini Gör" bağlantısı.
///
/// Bağlantı yalnızca kırpılmış gruplarda görünür: gösterilen her şeyken
/// "hepsini gör" demek kullanıcıyı aynı yere göndermek olurdu.
class _GroupHeading extends StatelessWidget {
  const _GroupHeading({
    required this.label,
    this.count,
    this.shownCount,
    this.onSeeAll,
  });

  final String label;
  final int? count;
  final int? shownCount;
  final VoidCallback? onSeeAll;

  bool get _isClipped =>
      count != null && shownCount != null && count! > shownCount!;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverPadding(
      padding: centeredContentPadding(context, top: Insets.xl),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
            if (_isClipped && onSeeAll != null)
              TextButton(
                onPressed: onSeeAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Insets.xs,
                    vertical: 0,
                  ),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'discover.seeAll'.tr(),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 17,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.fieldKey,
    required this.controller,
    required this.focusNode,
    required this.hasQuery,
    required this.isFocused,
    required this.onChanged,
    required this.onClear,
  });

  final GlobalKey fieldKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasQuery;
  final bool isFocused;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık yalnızca gezinme hâlinde durur. Odaklanıldığı anda da
        // çekilir: klavye ekranın yarısını aldıktan sonra kalan dar şeritte
        // 60pt'lik bir başlık, önerilerin yerini yiyordu.
        AnimatedSize(
          duration: Motion.normal,
          curve: Motion.standard,
          child: hasQuery || isFocused
              ? const SizedBox(width: double.infinity)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'discover.title'.tr(),
                      style: theme.textTheme.displaySmall,
                    ),
                    const SizedBox(height: Insets.xxs),
                    Text(
                      'discover.subtitle'.tr(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.55,
                        ),
                      ),
                    ),
                    const SizedBox(height: Insets.md),
                  ],
                ),
        ),
        TextField(
          key: fieldKey,
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'discover.searchHint'.tr(),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            suffixIcon: hasQuery
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: onClear,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

/// Fihristin dışındaki iki giriş yolu.
///
/// Mealde arama artık burada değil: kutunun kendisi onu yapıyor. Ayrı bir
/// kart olarak durması, kullanıcıyı zaten önündeki şey için başka bir ekrana
/// göndermek olurdu.
class _EntryCards extends ConsumerWidget {
  const _EntryCards();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sayılar veriden okunur; yüklenmemişse kart sayısız çizilir ve veri
    // gelince yerine oturur. İki satırlık bir sayı için ekranı bekletmenin
    // karşılığı yok — kök verisi birkaç yüz KB ve ilk açılışta gecikiyor.
    final prophets = ref.watch(prophetDataProvider).valueOrNull;
    final roots = ref.watch(rootDataProvider).valueOrNull;

    return Row(
      children: [
        Expanded(
          child: DiscoverEntryCard(
            // Kişi ikonu: kıssaların konusu olaylar değil, insanlar.
            // `timeline` denenmişti ama bir borsa grafiği gibi okunuyordu.
            icon: Icons.groups_2_rounded,
            title: 'discover.prophetsTitle'.tr(),
            count: prophets == null
                ? ''
                : 'discover.prophetsSubtitle'.tr(
                    args: ['${prophets.all.length}'],
                  ),
            hint: 'discover.prophetsHint'.tr(),
            onTap: () => context.push('/kissalar'),
          ),
        ),
        const SizedBox(width: Insets.xs),
        Expanded(
          child: DiscoverEntryCard(
            // Bir kökten dallanan kelimeler: hesap ağacı ikonu bu ilişkiyi
            // `abc`'den daha iyi anlatıyor.
            icon: Icons.account_tree_rounded,
            title: 'discover.rootsTitle'.tr(),
            count: roots == null
                ? ''
                : 'discover.rootsSubtitle'.tr(
                    args: ['${roots.allRoots.length}'],
                  ),
            hint: 'discover.rootsHint'.tr(),
            onTap: () => context.push('/kokler'),
          ),
        ),
      ],
    );
  }
}
