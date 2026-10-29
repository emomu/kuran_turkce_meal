import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../onboarding/providers/tour_provider.dart';
import '../../onboarding/widgets/coach_mark.dart';
import '../../onboarding/widgets/tour_host.dart';
import '../../../data/models/ayah.dart';
import '../../../data/models/root.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/pressable.dart';
import '../providers/root_provider.dart';
import '../widgets/root_highlight.dart';
import 'root_search_screen.dart';

/// Bir kökün künyesi ve Kuran'daki tüm geçişleri.
///
/// Ekran iki bölümden oluşur: üstte kökün kimliği (harfleri, anlamı, kaç
/// yerde geçtiği), altında geçtiği ayetlerin listesi. Ayetler sanal listeyle
/// çizilir — bazı kökler 2851 yerde geçiyor, hepsini birden kurmak olmaz.
///
/// [focusWord] verilirse o ayet açılışta vurgulanır: kullanıcı okuma
/// ekranından bir kelimeye dokunarak geldiyse, kendi ayetini listede
/// bulabilmelidir.
/// Kök analizi turunun işaret ettiği öğeler.
///
/// Ekran durumsuz bir `ConsumerWidget`; anahtarlar dosya düzeyinde tutulur.
final _rootHeaderKey = GlobalKey();
final _analysisKey = GlobalKey();
final _occurrencesKey = GlobalKey();
final _rootSearchKey = GlobalKey();

class RootDetailScreen extends ConsumerWidget {
  const RootDetailScreen({
    super.key,
    required this.rootArabic,
    this.focusSurah,
    this.focusAyah,
    this.cameFromSearch = false,
  });

  final String rootArabic;
  final int? focusSurah;
  final int? focusAyah;

  /// Bu ekrana kök arama ekranından gelinip gelinmediği.
  ///
  /// Üst çubuktaki arama düğmesinin davranışını belirler: aramadan
  /// gelindiyse düğme geri döner, gelinmediyse aramayı yeni açar. Bkz.
  /// [_openSearch].
  final bool cameFromSearch;

  /// Kök arama ekranını açar — geride zaten bir tane varsa ona döner.
  ///
  /// Bu ekrana iki yoldan gelinir: kök aramadan bir kök seçilerek, ya da
  /// okuma ekranında bir kelimeye dokunularak. İlkinde arama zaten yığındadır
  /// ve yenisini itmek aynı ekranın ikinci bir kopyasını biriktirir:
  /// kullanıcı iki kez geri dediğinde biraz önce ayrıldığı arama ekranına
  /// yeniden düşer ve geri gitmiş gibi hissetmez.
  ///
  /// [cameFromSearch] bu ayrımı çağıran tarafın bildirmesini sağlar; yığını
  /// yoklamak `Navigator` API'siyle güvenilir biçimde yapılamıyor
  /// (`popUntil` yalnızca eşleşene kadar kapatır, salt okunur gezmez).
  void _openSearch(BuildContext context) {
    // Aramadan gelindiyse geri dönmek yeterli: aynı ekranın ikinci kopyası
    // yığına binmez.
    if (cameFromSearch) {
      Navigator.of(context).pop();
      return;
    }

    // Okuma ya da plan ekranından gelinmiş; geride arama yok, yeni açılır.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const RootSearchScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(rootDetailProvider(rootArabic));

    return Scaffold(
      appBar: AppBar(
        title: Text('roots.title'.tr()),
        actions: [
          IconButton(
            key: _rootSearchKey,
            icon: const Icon(Icons.search_rounded, size: 21),
            tooltip: 'roots.searchTitle'.tr(),
            onPressed: () => _openSearch(context),
          ),
        ],
      ),
      body: detail.when(
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(height: Insets.md),
              Text(
                'roots.loading'.tr(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        error: (_, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'roots.unavailable'.tr(),
          message: 'roots.unavailableHint'.tr(),
        ),
        data: (data) {
          if (data == null) {
            return EmptyState(
              icon: Icons.search_off_rounded,
              title: 'roots.noResults'.tr(),
              message: 'roots.noResultsFor'.tr(args: [rootArabic]),
            );
          }
          // Tur ancak kök ve geçişleri çizildikten sonra başlayabilir.
          return TourHost(
            tour: TourId.roots,
            enabled: data.occurrences.isNotEmpty,
            steps: _tourSteps,
            child: _RootBody(
              detail: data,
              focusSurah: focusSurah,
              focusAyah: focusAyah,
            ),
          );
        },
      ),
    );
  }

  /// Kök analizi ekranının tanıtım adımları.
  ///
  /// Kök kavramı uygulamanın en az bilinen parçası: kullanıcı Arapça
  /// bilmiyorsa ekranda ne gördüğünü anlamayabilir. Bu yüzden önce kökün
  /// ne olduğu anlatılır, sonra listenin ne gösterdiği.
  static List<TourStep> _tourSteps() {
    return [
      TourStep(
        targetKey: _rootHeaderKey,
        icon: Icons.account_tree_outlined,
        title: 'tour.roots.rootTitle'.tr(),
        body: 'tour.roots.rootBody'.tr(),
      ),
      // Çözümleme bölümü yalnızca verisi olan köklerde çizilir; bir kez
      // geçen köklerde türev listesi tek satır, fiil kalıbı hiç olmaz ve
      // bölüm hiç görünmez. Adım da o zaman atlanır — kullanıcıya ekranda
      // olmayan bir şey anlatılmaz.
      if (_analysisKey.currentContext != null)
        TourStep(
          targetKey: _analysisKey,
          icon: Icons.insights_outlined,
          title: 'tour.roots.analysisTitle'.tr(),
          body: 'tour.roots.analysisBody'.tr(),
        ),
      TourStep(
        targetKey: _occurrencesKey,
        icon: Icons.format_list_bulleted_rounded,
        title: 'tour.roots.occurrencesTitle'.tr(),
        body: 'tour.roots.occurrencesBody'.tr(),
      ),
      TourStep(
        targetKey: _rootSearchKey,
        shape: SpotlightShape.circle,
        icon: Icons.search_rounded,
        title: 'tour.roots.searchTitle'.tr(),
        body: 'tour.roots.searchBody'.tr(),
      ),
    ];
  }
}

class _RootBody extends ConsumerWidget {
  const _RootBody({
    required this.detail,
    required this.focusSurah,
    required this.focusAyah,
  });

  final RootDetail detail;
  final int? focusSurah;
  final int? focusAyah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final root = detail.root;
    // Aynı ayette kök birden çok kez geçebilir; ayet listede bir kez görünür,
    // geçen kelimelerin hepsi o satırda vurgulanır.
    final verses = _groupByVerse(detail.occurrences);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: KeyedSubtree(key: _rootHeaderKey, child: _RootHeader(root: root)),
        ),

        // Kökün künyesi ile geçiş listesi arasında kalan çözümleme
        // bölümleri. Hepsi veriye bağlı: veri yoksa bölüm hiç çizilmez,
        // boş başlık görünmez.
        if (_RootAnalysis.hasContent(root))
          SliverToBoxAdapter(
            child: KeyedSubtree(
              key: _analysisKey,
              child: _RootAnalysis(root: root),
            ),
          ),

        SliverPadding(
          padding: centeredContentPadding(
            context,
            top: Insets.lg,
            bottom: Insets.xs,
          ),
          sliver: SliverToBoxAdapter(
            child: Text(
              key: _occurrencesKey,
              'roots.occurrencesTitle'.tr(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
            ),
          ),
        ),

        SliverPadding(
          padding: centeredContentPadding(
            context,
            bottom: MediaQuery.paddingOf(context).bottom + Insets.lg,
          ),
          sliver: SliverList.separated(
            itemCount: verses.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: Theme.of(context).dividerColor),
            itemBuilder: (context, index) {
              final verse = verses[index];
              return _OccurrenceRow(
                word: verse.first,
                root: root,
                highlightIndexes: {for (final w in verse) w.wordIndex},
                isFocused: verse.first.surahNumber == focusSurah &&
                    verse.first.ayahNumber == focusAyah,
              );
            },
          ),
        ),
      ],
    );
  }

  /// Geçişleri ayet birimine indirger, mushaf sırasını korur.
  static List<List<RootWord>> _groupByVerse(List<RootWord> words) {
    final grouped = <(int, int), List<RootWord>>{};
    for (final w in words) {
      grouped.putIfAbsent((w.surahNumber, w.ayahNumber), () => []).add(w);
    }
    return grouped.values.toList(growable: false);
  }
}

/// Kökün künyesi: harfleri, anlamı, geçiş sayısı.
class _RootHeader extends StatelessWidget {
  const _RootHeader({required this.root});

  final QuranRoot root;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      // Alt çizgi ekranın iki kenarına kadar uzanır; içerik ise yatayda
      // listeyle aynı sütuna hizalanır.
      padding: centeredContentPadding(
        context,
        top: Insets.xs,
        bottom: Insets.lg,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kök harfleri — ekranın en büyük öğesi, kimliği o taşır.
          Center(
            child: Text(
              root.arabic,
              textDirection: TextDirection.rtl,
              // Kök harfleri arası boşluk verilmez: Arapça bitişik yazılır
              // ve letterSpacing harfleri birbirinden kopararak kökü
              // okunmaz hale getirir.
              style: AppTypography.arabic(
                fontSize: 44,
                height: 1.5,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: Insets.xs),

          if (root.hasMeaning) ...[
            Center(
              child: Text(
                root.meaning,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
            const SizedBox(height: Insets.sm),
          ],

          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Insets.sm,
                vertical: Insets.xxs,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
              child: Text(
                'roots.occurrences'.tr(args: ['${root.count}']),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Okunuşlar — kullanıcı kökü nasıl arayabileceğini burada görür.
          if (root.readings.isNotEmpty) ...[
            const SizedBox(height: Insets.md),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: Insets.xs,
              runSpacing: Insets.xxs,
              children: [
                for (final reading in root.readings)
                  Text(
                    reading,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Kökün çözümlemesi: türeyen kelimeler, sure dağılımı, fiil kalıpları.
///
/// Kök harfleri tek başına soyuttur. Bu bölümler kökün Kuran'daki hayatını
/// gösterir: hangi kelimelere dönüştüğü, nerelerde yoğunlaştığı, hangi
/// kalıplarda çekimlendiği.
///
/// Her bölüm kendi verisi varsa çizilir. Veri Quranic Arabic Corpus'tan
/// gelir ve her kökte eşit zengin değildir — bir kere geçen köklerde
/// türev listesi tek satır, fiil kalıbı hiç olmayabilir.
class _RootAnalysis extends StatelessWidget {
  const _RootAnalysis({required this.root});

  final QuranRoot root;

  /// Bölümün çizilecek bir şeyi var mı.
  ///
  /// Çağıran taraf bunu önceden sorar: boş bir widget'ı ağaca koymak
  /// yerine hiç koymamak, tanıtım turunun o adımı atlayabilmesi için
  /// gerekir — tur hedefin ağaçta olup olmadığına bakar.
  static bool hasContent(QuranRoot root) =>
      root.derived.length > 1 ||
      root.verbForms.length > 1 ||
      root.surahDistribution.length > 1;

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      if (root.derived.length > 1) _DerivedWords(root: root),
      if (root.verbForms.length > 1) _VerbForms(root: root),
      if (root.surahDistribution.length > 1) _SurahDistribution(root: root),
    ];
    if (sections.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final section in sections) ...[
          const SizedBox(height: Insets.lg),
          section,
        ],
      ],
    );
  }
}

/// Bölüm başlığı — geçiş listesinin başlığıyla aynı biçimde.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.hint});

  final String text;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = hint;
    return Padding(
      padding: centeredContentPadding(context, bottom: Insets.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: Insets.xxs),
            Text(
              note,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Kökten türeyen kelimeler, sıklığa göre.
///
/// Her satır bir kelime: Arapça biçimi, ne olduğu (isim/fiil/ism-i fail)
/// ve kaç kez geçtiği. Türkçe karşılık sözlükte varsa yazılır; yoksa tür
/// etiketi tek başına da kelimenin ne olduğunu anlatır.
class _DerivedWords extends StatelessWidget {
  const _DerivedWords({required this.root});

  final QuranRoot root;

  /// Korpusun tür etiketini Türkçeye çevirir.
  ///
  /// Etiketler korpusun kendi kısaltmaları; veri ham tutulur ve çeviri
  /// burada yapılır, böylece dil değiştiğinde veri yeniden üretilmez.
  static String? _kindLabel(String kind) => switch (kind) {
        'N' => 'roots.kindNoun'.tr(),
        'V' => 'roots.kindVerb'.tr(),
        'ADJ' => 'roots.kindAdjective'.tr(),
        'PN' => 'roots.kindProperNoun'.tr(),
        'ACT_PCPL' => 'roots.kindActiveParticiple'.tr(),
        'PASS_PCPL' => 'roots.kindPassiveParticiple'.tr(),
        'VN' => 'roots.kindVerbalNoun'.tr(),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // En sık türev ölçek olur: çubuklar ona göre oranlanır, böylece
    // baskın kelime ile seyrek olan arasındaki fark görünür.
    final top = root.derived.first.count;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle('roots.derivedTitle'.tr(), hint: 'roots.derivedHint'.tr()),
        for (final word in root.derived)
          Padding(
            padding: centeredContentPadding(context, bottom: Insets.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 104,
                  child: Text(
                    word.lemma,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: AppTypography.arabic(
                      fontSize: 19,
                      height: 1.6,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: Insets.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        [
                          if (word.hasMeaning) word.meaning,
                          if (_kindLabel(word.kind) case final label?)
                            word.hasMeaning ? '($label)' : label,
                        ].join(' '),
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: Insets.xxs),
                      // Sıklık çubuğu: sayıyı okumadan da oran görünür.
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(Radii.pill),
                              child: LinearProgressIndicator(
                                value: word.count / top,
                                minHeight: 4,
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                              ),
                            ),
                          ),
                          const SizedBox(width: Insets.sm),
                          Text(
                            '${word.count}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Fiil kalıbı (bab) dağılımı.
///
/// Arapçada kök sabit kalır, kalıp anlamı değiştirir: aynı kökten I.
/// kalıpta "bildi", II. kalıpta "öğretti" çıkar. Kullanıcı aynı kökün
/// neden farklı anlamlara geldiğini burada görür.
class _VerbForms extends StatelessWidget {
  const _VerbForms({required this.root});

  final QuranRoot root;

  /// Kalıpların Arap gramerindeki alışılmış Roma rakamı gösterimi.
  static const _numerals = [
    '', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final forms = [...root.verbForms]..sort((a, b) => b.$2.compareTo(a.$2));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          'roots.verbFormsTitle'.tr(),
          hint: 'roots.verbFormsHint'.tr(),
        ),
        Padding(
          padding: centeredContentPadding(context),
          child: Wrap(
            spacing: Insets.sm,
            runSpacing: Insets.xs,
            children: [
              for (final (form, count) in forms)
                if (form > 0 && form < _numerals.length)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Insets.sm,
                      vertical: Insets.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(Radii.pill),
                    ),
                    child: Text(
                      '${_numerals[form]} · '
                      '${'roots.formTimes'.tr(args: ['$count'])}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Kökün surelere dağılımı.
///
/// 114 sureyi tek şeritte gösterir: her sure bir sütun, yüksekliği o
/// suredeki geçiş sayısıyla orantılı. Kökün Kuran'ın neresinde
/// yoğunlaştığı tek bakışta görünür — "sabr" Bakara'da, "ilim" baştan
/// sona yayılmış gibi.
class _SurahDistribution extends StatelessWidget {
  const _SurahDistribution({required this.root});

  final QuranRoot root;

  static const _surahCount = 114;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counts = {for (final (s, c) in root.surahDistribution) s: c};
    final top = counts.values.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          'roots.distributionTitle'.tr(),
          hint: 'roots.distributionHint'.tr(
            args: ['${root.surahDistribution.length}'],
          ),
        ),
        Padding(
          padding: centeredContentPadding(context),
          child: SizedBox(
            height: 44,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var surah = 1; surah <= _surahCount; surah++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0.5),
                      child: _DistributionBar(
                        // Geçmediği surelerde de ince bir iz bırakılır:
                        // şerit 114 sureyi temsil eder, boşluk bırakmak
                        // ölçeği okunmaz hale getirirdi.
                        ratio: (counts[surah] ?? 0) / top,
                        color: theme.colorScheme.primary,
                        emptyColor: theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Dağılım şeridindeki tek sure sütunu.
class _DistributionBar extends StatelessWidget {
  const _DistributionBar({
    required this.ratio,
    required this.color,
    required this.emptyColor,
  });

  final double ratio;
  final Color color;
  final Color emptyColor;

  @override
  Widget build(BuildContext context) {
    // Geçişi olan en seyrek sure bile görünür kalsın diye taban yükseklik
    // verilir; yalnızca orana bırakılsaydı tek geçişli sureler çizilmezdi.
    final height = ratio == 0 ? 2.0 : 2 + ratio * 42;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: ratio == 0 ? emptyColor : color,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

/// Kökün geçtiği tek bir ayet.
///
/// Ayet metni tembel yüklenir: liste binlerce satır olabilir, hepsinin mealini
/// baştan çekmek gereksiz. Satır göründüğünde metni ister.
class _OccurrenceRow extends ConsumerWidget {
  const _OccurrenceRow({
    required this.word,
    required this.root,
    required this.isFocused,
    required this.highlightIndexes,
  });

  final RootWord word;
  final QuranRoot root;
  final bool isFocused;

  /// Bu ayette kökün geçtiği tüm kelime sıraları. Bir kök aynı ayette
  /// birden çok kez geçebilir; hepsi birden vurgulanır.
  final Set<int> highlightIndexes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ayah = ref.watch(
      _occurrenceAyahProvider((word.surahNumber, word.ayahNumber)),
    );

    return Pressable(
      scale: 0.99,
      onTap: () => context.push(
        '/sure/${word.surahNumber}?ayet=${word.ayahNumber}',
      ),
      child: AnimatedContainer(
        duration: Motion.normal,
        curve: Motion.standard,
        decoration: BoxDecoration(
          color: isFocused
              ? theme.colorScheme.primary.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: Insets.sm,
          horizontal: Insets.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  ayah.value?.$2 ?? '${word.surahNumber}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  ' · ${word.ayahNumber}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Bu ayette kökün hangi kelime olarak göründüğü.
                Flexible(
                  child: Text(
                    word.arabic,
                    textDirection: TextDirection.rtl,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.arabic(
                      fontSize: 17,
                      height: 1.6,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.65),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.xs),
            ayah.when(
              loading: () => const SizedBox(height: 20),
              error: (_, _) => const SizedBox.shrink(),
              data: (value) {
                if (value == null) return const SizedBox.shrink();
                final verseArabic = value.$3;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Arapça metin, kökün geçtiği kelime(ler) vurgulu.
                    // Karşılaştırmanın asıl değeri burada: kullanıcı aynı
                    // kökün farklı ayetlerde hangi kalıba girdiğini görür.
                    if (verseArabic != null) ...[
                      HighlightedArabic(
                        text: verseArabic,
                        highlightIndexes: highlightIndexes,
                        fontSize: 19,
                      ),
                      const SizedBox(height: Insets.xs),
                    ],
                    // Meal düz metin olarak çizilir. Arapça kelime ile meal
                    // kelimesi arasında güvenilir bir hizalama verisi yok:
                    // çevirmen cümleyi yeniden kurar, kelime sırası korunmaz.
                    // Tahmine dayalı vurgulama denendi (kök anlamı eşleştirme
                    // %52, sinirsel hizalama %63 isabet) ve ikisi de kabul
                    // edilir bulunmadı — yanlış kelimeyi işaretlemek, hiç
                    // işaretlememekten kötüdür. Kökün hangi kelime olduğu
                    // yukarıdaki Arapça metinde kesin olarak gösterilir.
                    Text(
                      value.$1.translationFor(context.locale.languageCode),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.reading(
                        fontSize: 15,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.85),
                        height: 1.5,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Bir ayeti, sure adını ve o ayetin Arapça satırını getirir.
///
/// Üçüncü alan ayrı tutulur çünkü birleşik meal bloklarında [Ayah.arabic]
/// birden çok ayetin metnini satır başıyla ayrılmış olarak taşır; kök
/// vurgusu tek bir ayetin kelimeleriyle hizalanmalıdır.
final _occurrenceAyahProvider =
    FutureProvider.family<(Ayah, String, String?)?, (int, int)>(
        (ref, key) async {
  final repo = ref.watch(quranRepositoryProvider);
  final surah = await repo.surah(key.$1);
  if (surah == null) return null;
  final ayahs = await repo.ayahsOfSurah(key.$1);

  // Birleşik meal bloklarında aranan ayet numarası bloğun içinde kalabilir.
  for (final a in ayahs) {
    if (key.$2 >= a.ayahNumber && key.$2 <= a.endAyahNumber) {
      String? line;
      final arabic = a.arabic;
      if (arabic != null) {
        final lines = arabic.split('\n');
        final offset = key.$2 - a.ayahNumber;
        line = offset < lines.length ? lines[offset] : lines.first;
      }
      return (a, surah.name, line);
    }
  }
  return null;
});
