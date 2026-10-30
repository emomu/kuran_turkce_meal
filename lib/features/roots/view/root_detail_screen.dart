import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../home/providers/home_provider.dart';
import '../../onboarding/providers/tour_provider.dart';
import '../../onboarding/widgets/coach_mark.dart';
import '../../onboarding/widgets/tour_host.dart';
import '../../../data/models/ayah.dart';
import '../../../data/models/root.dart';
import '../../../data/models/surah.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/pressable.dart';
import '../providers/root_provider.dart';
import '../widgets/root_highlight.dart';
import 'root_search_screen.dart';

/// Kök analizi turunun işaret ettiği öğeler.
///
/// Her ekran kendi anahtarlarını taşır. Dosya düzeyinde tek takım olduğunda
/// iki kök ekranı aynı anda ağaçta bulunabiliyordu (kök → ayet → kelime →
/// kök, ya da sayfa geçişi sırasında) ve Flutter "aynı GlobalKey birden çok
/// widget'ta" hatası veriyordu.
class _TourKeys {
  final header = GlobalKey();
  final analysis = GlobalKey();
  final occurrences = GlobalKey();
  final search = GlobalKey();
}

/// Bir kökün künyesi ve Kuran'daki tüm geçişleri.
///
/// Ekran iki bölümden oluşur: üstte kökün kimliği (harfleri, anlamı, kaç
/// yerde geçtiği), altında geçtiği ayetlerin listesi. Ayetler sanal listeyle
/// çizilir — bazı kökler 2851 yerde geçiyor, hepsini birden kurmak olmaz.
///
/// [focusSurah] ve [focusAyah] verilirse o ayet listenin başına alınır:
/// kullanıcı okuma ekranından bir kelimeye dokunarak geldiyse, kendi ayetini
/// yüzlerce satır arasında aramak zorunda kalmamalı.
class RootDetailScreen extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<RootDetailScreen> createState() => _RootDetailScreenState();
}

class _RootDetailScreenState extends ConsumerState<RootDetailScreen> {
  final _keys = _TourKeys();

  /// Kök arama ekranını açar — geride zaten bir tane varsa ona döner.
  ///
  /// Bu ekrana iki yoldan gelinir: kök aramadan bir kök seçilerek, ya da
  /// okuma ekranında bir kelimeye dokunularak. İlkinde arama zaten yığındadır
  /// ve yenisini itmek aynı ekranın ikinci bir kopyasını biriktirir:
  /// kullanıcı iki kez geri dediğinde biraz önce ayrıldığı arama ekranına
  /// yeniden düşer ve geri gitmiş gibi hissetmez.
  ///
  /// [RootDetailScreen.cameFromSearch] bu ayrımı çağıran tarafın
  /// bildirmesini sağlar; yığını yoklamak `Navigator` API'siyle güvenilir
  /// biçimde yapılamıyor (`popUntil` yalnızca eşleşene kadar kapatır, salt
  /// okunur gezmez).
  void _openSearch(BuildContext context) {
    // Aramadan gelindiyse geri dönmek yeterli: aynı ekranın ikinci kopyası
    // yığına binmez.
    if (widget.cameFromSearch) {
      Navigator.of(context).pop();
      return;
    }

    // Okuma ya da plan ekranından gelinmiş; geride arama yok, yeni açılır.
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const RootSearchScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(rootDetailProvider(widget.rootArabic));

    return Scaffold(
      appBar: AppBar(
        title: Text('roots.title'.tr()),
        actions: [
          IconButton(
            key: _keys.search,
            icon: const Icon(Icons.search_rounded, size: 21),
            tooltip: 'roots.searchTitle'.tr(),
            onPressed: () => _openSearch(context),
          ),
        ],
      ),
      body: detail.when(
        loading: () => const _Loading(),
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
              message: 'roots.noResultsFor'.tr(args: [widget.rootArabic]),
            );
          }
          // Tur ancak kök ve geçişleri çizildikten sonra başlayabilir.
          return TourHost(
            tour: TourId.roots,
            enabled: data.occurrences.isNotEmpty,
            steps: _tourSteps,
            child: _RootBody(
              detail: data,
              keys: _keys,
              focusSurah: widget.focusSurah,
              focusAyah: widget.focusAyah,
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
  List<TourStep> _tourSteps() {
    return [
      TourStep(
        targetKey: _keys.header,
        icon: Icons.account_tree_outlined,
        title: 'tour.roots.rootTitle'.tr(),
        body: 'tour.roots.rootBody'.tr(),
      ),
      // Çözümleme bölümü yalnızca verisi olan köklerde çizilir; bir kez
      // geçen köklerde türev listesi tek satır, fiil kalıbı hiç olmaz ve
      // bölüm hiç görünmez. Adım da o zaman atlanır — kullanıcıya ekranda
      // olmayan bir şey anlatılmaz.
      if (_keys.analysis.currentContext != null)
        TourStep(
          targetKey: _keys.analysis,
          icon: Icons.insights_outlined,
          title: 'tour.roots.analysisTitle'.tr(),
          body: 'tour.roots.analysisBody'.tr(),
        ),
      TourStep(
        targetKey: _keys.occurrences,
        icon: Icons.format_list_bulleted_rounded,
        title: 'tour.roots.occurrencesTitle'.tr(),
        body: 'tour.roots.occurrencesBody'.tr(),
      ),
      TourStep(
        targetKey: _keys.search,
        shape: SpotlightShape.circle,
        icon: Icons.search_rounded,
        title: 'tour.roots.searchTitle'.tr(),
        body: 'tour.roots.searchBody'.tr(),
      ),
    ];
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }
}

class _RootBody extends ConsumerWidget {
  const _RootBody({
    required this.detail,
    required this.keys,
    required this.focusSurah,
    required this.focusAyah,
  });

  final RootDetail detail;
  final _TourKeys keys;
  final int? focusSurah;
  final int? focusAyah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final root = detail.root;
    final verses = ref.watch(_rootVersesProvider(root.arabic));

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: KeyedSubtree(
            key: keys.header,
            child: _RootHeader(root: root),
          ),
        ),

        // Kökün künyesi ile geçiş listesi arasında kalan çözümleme
        // bölümleri. Hepsi veriye bağlı: veri yoksa bölüm hiç çizilmez,
        // boş başlık görünmez.
        if (_RootAnalysis.hasContent(root))
          SliverToBoxAdapter(
            child: KeyedSubtree(
              key: keys.analysis,
              child: _RootAnalysis(root: root),
            ),
          ),

        SliverPadding(
          padding: const EdgeInsets.only(top: Insets.xl),
          sliver: SliverToBoxAdapter(
            child: KeyedSubtree(
              key: keys.occurrences,
              child: _SectionTitle(
                'roots.occurrencesTitle'.tr(),
                // Üstteki "88 yerde geçiyor" kelime sayısı; liste ise ayet
                // ayet. Aynı ayette iki kez geçen kök tek satırdır, bu
                // yüzden iki sayı farklı — burada ayet sayısı açıkça yazılır.
                hint: verses.hasValue
                    ? 'roots.occurrencesCount'.tr(
                        args: ['${verses.value!.length}'],
                      )
                    : null,
              ),
            ),
          ),
        ),

        // Ayetler tek seferde, hepsi birden yüklenir. Satır satır yüklemek
        // her satırı önce boş sonra dolu çiziyordu; kaydırırken liste
        // zıplıyor, kaydırma çubuğu sürekli boy değiştiriyordu.
        //
        // Yüklenirken dönen bir gösterge konmaz: yükleme kısa sürüyor ve
        // kullanıcı o sırada zaten üstteki künyeyi okuyor; bir an görünüp
        // kaybolan gösterge yalnızca titreme yaratırdı.
        ...verses.when(
          loading: () => const [
            SliverToBoxAdapter(child: SizedBox(height: Insets.xxl)),
          ],
          error: (_, _) => const [],
          data: (list) => _occurrenceSlivers(context, list),
        ),
      ],
    );
  }

  List<Widget> _occurrenceSlivers(
    BuildContext context,
    List<_VerseOccurrence> all,
  ) {
    final bottom = MediaQuery.paddingOf(context).bottom + Insets.lg;
    final focusIndex = all.indexWhere(
      (v) => v.surahNumber == focusSurah && v.ayahNumber == focusAyah,
    );
    // Okuma ekranından gelinen ayet listenin başına alınır; listede yerinde
    // bırakılsaydı yüzlerce satırın arasında kalırdı. Ayrı bir kutuya
    // konmaz: diğer satırlarla aynı görünür, yalnızca küçük bir etiket
    // taşır. Kutulu hali listeden kopuk ve gereğinden ağır duruyordu.
    final ordered = focusIndex <= 0
        ? all
        : [
            all[focusIndex],
            ...all.take(focusIndex),
            ...all.skip(focusIndex + 1),
          ];

    return [
      SliverPadding(
        padding: centeredContentPadding(context, bottom: bottom),
        sliver: SliverList.separated(
          itemCount: ordered.length,
          separatorBuilder: (_, _) =>
              Divider(height: 1, color: Theme.of(context).dividerColor),
          itemBuilder: (context, index) => _OccurrenceRow(
            verse: ordered[index],
            isFocused: index == 0 && focusIndex != -1,
          ),
        ),
      ),
    ];
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
        children: [
          // Kök harfleri — ekranın en büyük öğesi, kimliği o taşır.
          Text(
            root.arabic,
            textDirection: TextDirection.rtl,
            // Kök harfleri arası boşluk verilmez: Arapça bitişik yazılır
            // ve letterSpacing harfleri birbirinden kopararak kökü
            // okunmaz hale getirir.
            style: AppTypography.arabic(
              fontSize: 38,
              height: 1.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: Insets.xs),

          if (root.hasMeaning) ...[
            Text(
              root.meaning,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: Insets.sm),
          ],

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.sm,
              vertical: Insets.xxs,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Radii.pill),
            ),
            child: Text(
              'roots.occurrences'.tr(args: ['${root.count}']),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),

          // Okunuşlar — kullanıcı kökü nasıl arayabileceğini burada görür.
          // Etiketsiz dururken ne oldukları anlaşılmıyordu.
          if (root.readings.isNotEmpty) ...[
            const SizedBox(height: Insets.md),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${'roots.readingsLabel'.tr()} '),
                  TextSpan(
                    text: root.readings.join(' · '),
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

/// Kökün çözümlemesi: türeyen kelimeler, fiil kalıpları, sure dağılımı.
///
/// Kök harfleri tek başına soyuttur. Bu bölümler kökün Kuran'daki hayatını
/// gösterir: hangi kelimelere dönüştüğü, hangi kalıplarda çekimlendiği,
/// nerelerde yoğunlaştığı.
///
/// Türeyen kelimeler ve fiil kalıpları yan yana iki küçük kartla açılır;
/// listeleri ayrı sayfadadır. Sayfada yalnızca dağılım şeridi açık durur.
/// Hepsi açıkken ayetlere ulaşmak için bir ekran boyu kaydırmak gerekiyordu;
/// oysa ekrana gelen kullanıcının çoğu ayetleri görmek istiyor.
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
    final tiles = <Widget>[
      if (root.derived.length > 1)
        _AnalysisTile(
          icon: Icons.account_tree_outlined,
          title: 'roots.derivedTitle'.tr(),
          subtitle: 'roots.wordCount'.tr(args: ['${root.derived.length}']),
          page: _DerivedWordsScreen(root: root),
        ),
      if (root.verbForms.length > 1)
        _AnalysisTile(
          icon: Icons.tune_rounded,
          title: 'roots.verbFormsTitle'.tr(),
          subtitle: 'roots.formCount'.tr(args: ['${root.verbForms.length}']),
          page: _VerbFormsScreen(root: root),
        ),
    ];
    final hasDistribution = root.surahDistribution.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (tiles.isNotEmpty) ...[
          const SizedBox(height: Insets.lg),
          Padding(
            padding: centeredContentPadding(context),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < tiles.length; i++) ...[
                    if (i > 0) const SizedBox(width: Insets.sm),
                    Expanded(child: tiles[i]),
                  ],
                ],
              ),
            ),
          ),
        ],
        if (hasDistribution) ...[
          const SizedBox(height: Insets.lg),
          _SurahDistribution(root: root),
        ],
      ],
    );
  }
}

/// Çözümleme sayfalarından birini açan küçük kart.
class _AnalysisTile extends StatelessWidget {
  const _AnalysisTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.page,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
        side: BorderSide(color: theme.dividerColor, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => page)),
        child: Padding(
          padding: const EdgeInsets.all(Insets.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: theme.colorScheme.primary),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: Insets.xs),
              Text(title, style: theme.textTheme.titleSmall),
              const SizedBox(height: Insets.xxs),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bölüm başlığı ve altındaki kısa açıklama.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.hint});

  final String text;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = hint;
    return Padding(
      padding: centeredContentPadding(context, bottom: Insets.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: theme.textTheme.titleSmall),
          if (note != null) ...[
            const SizedBox(height: Insets.xxs),
            Text(note, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// Arapça kelime, Türkçe başlık, alt bilgi ve sıklık satırı.
///
/// Türeyen kelimeler ve fiil kalıpları sayfaları aynı satırı paylaşır.
class _WordRow extends StatelessWidget {
  const _WordRow({
    required this.arabic,
    required this.title,
    required this.subtitle,
    required this.count,
  });

  /// Sol sütundaki Arapça kelime.
  final String arabic;
  final String title;
  final String? subtitle;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = subtitle;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.md),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            // Uzun kelimeler (اسْتَغْفَر) ve büyük yazı boyutunda sütun
            // taşmaz, kelime küçülür.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                arabic,
                textDirection: TextDirection.rtl,
                style: AppTypography.arabic(
                  fontSize: 22,
                  height: 1.5,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (note != null) ...[
                  const SizedBox(height: Insets.xxs),
                  Text(note, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          const SizedBox(width: Insets.sm),
          Text(
            'roots.formTimes'.tr(args: ['$count']),
            style: theme.textTheme.bodySmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Türeyen kelimenin satırı.
///
/// Türkçe karşılık sözlükte varsa başlık odur, tür etiketi alt satıra iner.
/// Yoksa tür etiketi ("ism-i fail") başlığa çıkar: "-" yazan bir başlık
/// kullanıcıya hiçbir şey söylemiyordu.
_WordRow _derivedRow(DerivedWord word) {
  final kind = _kindLabel(word.kind);
  final title = word.hasMeaning ? word.meaning : (kind ?? '—');
  return _WordRow(
    arabic: word.lemma,
    title: title,
    subtitle: word.hasMeaning ? kind : null,
    count: word.count,
  );
}

/// Korpusun tür etiketini Türkçeye çevirir.
///
/// Etiketler korpusun kendi kısaltmaları; veri ham tutulur ve çeviri
/// burada yapılır, böylece dil değiştiğinde veri yeniden üretilmez.
String? _kindLabel(String kind) => switch (kind) {
  'N' => 'roots.kindNoun'.tr(),
  'V' => 'roots.kindVerb'.tr(),
  'ADJ' => 'roots.kindAdjective'.tr(),
  'PN' => 'roots.kindProperNoun'.tr(),
  'ACT_PCPL' => 'roots.kindActiveParticiple'.tr(),
  'PASS_PCPL' => 'roots.kindPassiveParticiple'.tr(),
  'VN' => 'roots.kindVerbalNoun'.tr(),
  _ => null,
};

/// Çözümleme sayfalarının ortak iskeleti: başlık, kısa açıklama, satırlar.
class _AnalysisListScreen extends StatelessWidget {
  const _AnalysisListScreen({
    required this.title,
    required this.hint,
    required this.rows,
  });

  final String title;
  final String hint;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.separated(
        padding: centeredContentPadding(
          context,
          bottom: MediaQuery.paddingOf(context).bottom + Insets.md,
        ),
        itemCount: rows.length + 1,
        separatorBuilder: (_, index) => index == 0
            ? const SizedBox.shrink()
            : Divider(
                height: 1,
                indent: 96,
                color: theme.dividerColor.withValues(alpha: 0.5),
              ),
        itemBuilder: (context, index) => index == 0
            ? Padding(
                padding: const EdgeInsets.only(
                  top: Insets.xs,
                  bottom: Insets.sm,
                ),
                child: Text(hint, style: theme.textTheme.bodySmall),
              )
            : rows[index - 1],
      ),
    );
  }
}

/// Kökten türeyen kelimeler, sıklığa göre.
class _DerivedWordsScreen extends StatelessWidget {
  const _DerivedWordsScreen({required this.root});

  final QuranRoot root;

  @override
  Widget build(BuildContext context) {
    return _AnalysisListScreen(
      title: 'roots.derivedTitle'.tr(),
      hint: 'roots.derivedHint'.tr(),
      rows: [for (final word in root.derived) _derivedRow(word)],
    );
  }
}

/// Fiil kalıbı (bab) dağılımı.
///
/// Arapçada kök sabit kalır, kalıp anlamı değiştirir: aynı kökten I.
/// kalıpta "bildi", II. kalıpta "öğretti" çıkar. Kullanıcı aynı kökün
/// neden farklı anlamlara geldiğini burada görür.
///
/// Her satır kalıbın örnek fiilini ve kalıbın ne iş gördüğünü yazar.
/// Yalnızca "IV · 1 kez" yazan ilk sürüm Arapça bilmeyen biri için hiçbir
/// şey anlatmıyordu. Fiilin Türkçe karşılığı sözlükte varsa başlık odur;
/// yoksa kalıbın genel işlevi ("ettirme") başlığa çıkar.
class _VerbFormsScreen extends StatelessWidget {
  const _VerbFormsScreen({required this.root});

  final QuranRoot root;

  /// Kalıpların Arap gramerindeki alışılmış Roma rakamı gösterimi.
  static const _numerals = [
    '',
    'I',
    'II',
    'III',
    'IV',
    'V',
    'VI',
    'VII',
    'VIII',
    'IX',
    'X',
  ];

  @override
  Widget build(BuildContext context) {
    final forms = [
      for (final vf in root.verbForms)
        if (vf.form > 0 && vf.form < _numerals.length) vf,
    ]..sort((a, b) => b.count.compareTo(a.count));

    return _AnalysisListScreen(
      title: 'roots.verbFormsTitle'.tr(),
      hint: 'roots.verbFormsHint'.tr(),
      rows: [for (final vf in forms) _verbFormRow(vf, _numerals[vf.form])],
    );
  }

  static _WordRow _verbFormRow(VerbForm form, String numeral) {
    final role = 'roots.formRoles.${form.form}'.tr();
    final label = 'roots.formLabel'.tr(args: [numeral]);
    return _WordRow(
      // Kalıp yalnızca isimlerde geçiyorsa örnek fiil yok; yerine kalıp
      // numarası durur.
      arabic: form.lemma.isNotEmpty ? form.lemma : numeral,
      title: form.hasMeaning ? form.meaning : role,
      subtitle: form.hasMeaning ? '$label · $role' : label,
      count: form.count,
    );
  }
}

/// Kökün surelere dağılımı.
///
/// 114 sureyi tek şeritte gösterir: her sure bir sütun, yüksekliği o
/// suredeki geçiş sayısıyla orantılı. Kökün Kuran'ın neresinde
/// yoğunlaştığı tek bakışta görünür — "sabr" Bakara'da, "ilim" baştan
/// sona yayılmış gibi.
///
/// Şerit parmakla gezilir: çubuklar 3 piksel kadar ince, tek tek dokunmak
/// mümkün değil. Bu yüzden dokunulan nokta en yakın *geçişi olan* sureye
/// oturur ve parmak şerit üzerinde kaydırıldıkça seçim sureden sureye
/// atlar; her atlamada hafif bir titreşim verilir. Seçilen sure altta
/// adıyla yazılır. Hiçbir sure seçilmemişken en yoğun sure yazılır; en uzun
/// çubuğun hangi sure olduğu sorusu baştan cevaplanmış olur.
class _SurahDistribution extends ConsumerStatefulWidget {
  const _SurahDistribution({required this.root});

  final QuranRoot root;

  @override
  ConsumerState<_SurahDistribution> createState() => _SurahDistributionState();
}

class _SurahDistributionState extends ConsumerState<_SurahDistribution> {
  static const _surahCount = 114;

  int? _selected;

  /// Parmağın altındaki noktaya en yakın, kökün geçtiği sureyi seçer.
  void _select(Offset local, double width, Map<int, int> counts) {
    final raw = ((local.dx / width * _surahCount).floor() + 1).clamp(
      1,
      _surahCount,
    );
    int? nearest;
    for (var d = 0; d < _surahCount && nearest == null; d++) {
      if (counts.containsKey(raw - d)) {
        nearest = raw - d;
      } else if (counts.containsKey(raw + d)) {
        nearest = raw + d;
      }
    }
    if (nearest == null || nearest == _selected) return;
    HapticFeedback.selectionClick();
    setState(() => _selected = nearest);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final root = widget.root;
    final counts = {for (final (s, c) in root.surahDistribution) s: c};
    final topEntry = counts.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    final top = topEntry.value;

    final names = <int, String>{
      for (final s in ref.watch(surahListProvider).valueOrNull ?? <Surah>[])
        s.number: s.nameFor(context.locale.languageCode),
    };
    String nameOf(int n) => names[n] ?? '$n';

    final selected = _selected;
    // Seçim yalnızca geçişi olan surelere oturduğu için seçili surenin
    // sayısı her zaman dolu.
    final caption = selected == null
        ? 'roots.distributionTop'.tr(
            args: [nameOf(topEntry.key), '${topEntry.value}'],
          )
        : 'roots.distributionSelected'.tr(
            args: [nameOf(selected), '${counts[selected]}'],
          );

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
          child: Semantics(
            label: caption,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => _select(d.localPosition, width, counts),
                  onHorizontalDragStart: (d) =>
                      _select(d.localPosition, width, counts),
                  onHorizontalDragUpdate: (d) =>
                      _select(d.localPosition, width, counts),
                  // Dokunma alanı çubukların üstüne ve altına taşar: 44
                  // piksellik şeridi parmakla tutturmak zordu.
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Insets.sm),
                    child: SizedBox(
                      height: 44,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var surah = 1; surah <= _surahCount; surah++)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 0.5,
                                ),
                                child: _DistributionBar(
                                  // Geçmediği surelerde de ince bir iz
                                  // bırakılır: şerit 114 sureyi temsil eder,
                                  // boşluk bırakmak ölçeği okunmaz yapardı.
                                  ratio: (counts[surah] ?? 0) / top,
                                  color: surah == selected
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.primary,
                                  emptyColor: surah == selected
                                      ? theme.colorScheme.onSurfaceVariant
                                      : theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: centeredContentPadding(context),
          child: ExcludeSemantics(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: caption,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  // Şeridin gezilebildiği görünür değil; kullanıcı bir kez
                  // denedikten sonra ipucu kaybolur.
                  if (selected == null)
                    TextSpan(text: '\n${'roots.distributionScrub'.tr()}'),
                ],
              ),
              style: theme.textTheme.bodySmall,
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
class _OccurrenceRow extends StatelessWidget {
  const _OccurrenceRow({required this.verse, required this.isFocused});

  final _VerseOccurrence verse;
  final bool isFocused;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
    );

    return Pressable(
      scale: 0.99,
      onTap: () =>
          context.push('/sure/${verse.surahNumber}?ayet=${verse.ayahNumber}'),
      child: Padding(
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
                  '${verse.surah.nameFor(context.locale.languageCode)}'
                  ' · ${verse.ayahNumber}',
                  style: labelStyle,
                ),
                if (isFocused) ...[
                  const SizedBox(width: Insets.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Insets.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(Radii.pill),
                    ),
                    child: Text(
                      'roots.focusedVerse'.tr(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                // Bu ayette kökün hangi kelime olarak göründüğü.
                Flexible(
                  child: Text(
                    verse.words.first.arabic,
                    textDirection: TextDirection.rtl,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.arabic(
                      fontSize: 17,
                      height: 1.6,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.65,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.xs),
            // Arapça metin, kökün geçtiği kelime(ler) vurgulu. Karşılaştırmanın
            // asıl değeri burada: kullanıcı aynı kökün farklı ayetlerde hangi
            // kalıba girdiğini görür.
            if (verse.arabicLine != null) ...[
              HighlightedArabic(
                text: verse.arabicLine!,
                highlightIndexes: {for (final w in verse.words) w.wordIndex},
                fontSize: 19,
              ),
              const SizedBox(height: Insets.xs),
            ],
            // Meal düz metin olarak çizilir. Arapça kelime ile meal kelimesi
            // arasında güvenilir bir hizalama verisi yok: çevirmen cümleyi
            // yeniden kurar, kelime sırası korunmaz. Tahmine dayalı
            // vurgulama denendi (kök anlamı eşleştirme %52, sinirsel
            // hizalama %63 isabet) ve ikisi de kabul edilir bulunmadı —
            // yanlış kelimeyi işaretlemek, hiç işaretlememekten kötüdür.
            // Kökün hangi kelime olduğu yukarıdaki Arapça metinde kesin
            // olarak gösterilir.
            Text(
              verse.ayah.translationFor(context.locale.languageCode),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.reading(
                fontSize: 15,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kökün geçtiği bir ayet ve o ayette kökten gelen kelimeler.
class _VerseOccurrence {
  const _VerseOccurrence({
    required this.words,
    required this.surah,
    required this.ayah,
    required this.arabicLine,
  });

  /// Bu ayette kökün geçtiği kelimeler. Bir kök aynı ayette birden çok kez
  /// geçebilir; hepsi birden vurgulanır.
  final List<RootWord> words;
  final Surah surah;
  final Ayah ayah;

  /// Ayetin Arapça satırı. Ayrı tutulur çünkü birleşik meal bloklarında
  /// [Ayah.arabic] birden çok ayetin metnini satır başıyla ayrılmış olarak
  /// taşır; kök vurgusu tek bir ayetin kelimeleriyle hizalanmalıdır.
  final String? arabicLine;

  int get surahNumber => words.first.surahNumber;
  int get ayahNumber => words.first.ayahNumber;
}

/// Kökün geçtiği bütün ayetler, mushaf sırasında, tek seferde.
///
/// Her sure veritabanından bir kez okunur; en yaygın kökte bile en fazla
/// 114 sorgu. Satır satır tembel yüklemeye göre biraz daha uzun sürer ama
/// liste bir kez ve tam boyutuyla çizilir.
final _rootVersesProvider =
    FutureProvider.family<List<_VerseOccurrence>, String>((
      ref,
      rootArabic,
    ) async {
      final detail = await ref.watch(rootDetailProvider(rootArabic).future);
      if (detail == null) return const [];
      final repo = ref.watch(quranRepositoryProvider);

      final grouped = <(int, int), List<RootWord>>{};
      for (final w in detail.occurrences) {
        grouped.putIfAbsent((w.surahNumber, w.ayahNumber), () => []).add(w);
      }

      final surahs = <int, (Surah?, List<Ayah>)>{};
      final result = <_VerseOccurrence>[];
      for (final MapEntry(key: (s, v), value: words) in grouped.entries) {
        final (surah, ayahs) = surahs[s] ??= (
          await repo.surah(s),
          await repo.ayahsOfSurah(s),
        );
        if (surah == null) continue;

        // Birleşik meal bloklarında aranan ayet numarası bloğun içinde
        // kalabilir.
        for (final a in ayahs) {
          if (v < a.ayahNumber || v > a.endAyahNumber) continue;
          String? line;
          final arabic = a.arabic;
          if (arabic != null) {
            final lines = arabic.split('\n');
            final offset = v - a.ayahNumber;
            line = offset < lines.length ? lines[offset] : lines.first;
          }
          result.add(
            _VerseOccurrence(
              words: words,
              surah: surah,
              ayah: a,
              arabicLine: line,
            ),
          );
          break;
        }
      }
      return result;
    });
