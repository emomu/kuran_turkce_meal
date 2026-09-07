import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/ayah.dart';
import '../../../data/models/prophet.dart';
import '../../../data/models/surah.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../reader/view/reader_screen.dart';

/// Bir peygamberin anıldığı ayetler, iniş sırasına göre.
///
/// Mushaf sırası yerine iniş sırası kullanılır ve bu, ekranın bütün varlık
/// sebebi: bir kıssa Kur'an'a tek seferde girmez. Mûsâ kıssası önce kısa
/// değinmelerle başlar, sonraki yıllarda ayrıntılanır. Mushaf sırasıyla
/// okunduğunda bu gelişim görünmez — Bakara'daki uzun anlatım başa düşer,
/// oysa o sonradan inmiştir.
class ProphetAyahsScreen extends ConsumerWidget {
  const ProphetAyahsScreen({super.key, required this.prophetId});

  final String prophetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(prophetAyahsProvider(prophetId));

    return Scaffold(
      body: PopScope(
        canPop: canPopRoute(context),
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) popOrHome(context);
        },
        child: SafeArea(
          bottom: false,
          child: asyncData.when(
            loading: () => const Center(child: CupertinoStyleLoader()),
            error: (error, _) => EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'prophets.loadFailed'.tr(),
              message: '$error',
            ),
            data: (data) => _Body(data: data),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.data});

  final ProphetAyahs data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.locale.languageCode;

    return Column(
      children: [
        _AppBar(title: data.prophet.nameFor(lang)),
        Expanded(
          child: ListView.separated(
            padding: centeredContentPadding(
              context,
              maxWidth: ContentWidth.reading,
              top: Insets.xs,
              bottom: MediaQuery.paddingOf(context).bottom + Insets.xl,
            ),
            itemCount: data.entries.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: Insets.xs),
            itemBuilder: (context, index) {
              if (index == 0) return _Header(data: data);

              final entry = data.entries[index - 1];
              final previous =
                  index >= 2 ? data.entries[index - 2] : null;

              // Sure başlığı yalnızca sure değiştiğinde çizilir; aynı surenin
              // ardışık ayetleri tek blok gibi okunur.
              final showsSurahHeader =
                  previous == null ||
                  previous.surah.number != entry.surah.number;

              return _AyahEntry(
                entry: entry,
                showsSurahHeader: showsSurahHeader,
                theme: theme,
                lang: lang,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Liste başlığı: kaç ayet, hangi sureler arasında.
class _Header extends StatelessWidget {
  const _Header({required this.data});

  final ProphetAyahs data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.locale.languageCode;

    return Padding(
      padding: const EdgeInsets.only(top: Insets.md, bottom: Insets.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.prophet.nameFor(lang),
            style: theme.textTheme.displaySmall,
          ),
          const SizedBox(height: Insets.xxs),
          Text(
            'prophets.subtitle'.tr(
              namedArgs: {'count': '${data.entries.length}'},
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: Insets.sm),
          // Kronolojik okumanın ne anlama geldiği açıkça söylenir; kullanıcı
          // listeyi mushaf sırasında sanıp şaşırmasın.
          Container(
            padding: const EdgeInsets.all(Insets.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timeline_rounded,
                  size: 17,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: Insets.xs),
                Expanded(
                  child: Text(
                    'prophets.chronologicalNote'.tr(),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.md),
          Divider(color: theme.dividerColor, height: 1),
        ],
      ),
    );
  }
}

/// Listedeki tek bir ayet.
class _AyahEntry extends StatelessWidget {
  const _AyahEntry({
    required this.entry,
    required this.showsSurahHeader,
    required this.theme,
    required this.lang,
  });

  final ProphetAyahEntry entry;
  final bool showsSurahHeader;
  final ThemeData theme;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showsSurahHeader) ...[
          const SizedBox(height: Insets.md),
          Row(
            children: [
              Text(
                entry.surah.nameFor(lang),
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(width: Insets.xs),
              // İniş sırası rozeti: kronolojik akışın nerede olduğumuzu
              // gösteren tek işareti.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Insets.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Text(
                  'home.revealedNth'.tr(
                    args: ['${entry.surah.revelationOrder}'],
                  ),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.xs),
        ],
        Pressable(
          onTap: () => context.push(
            '/sure/${entry.ayah.surahNumber}?ayet=${entry.ayah.ayahNumber}',
          ),
          scale: 0.99,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Insets.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 34,
                  child: Text(
                    entry.ayah.numberLabel,
                    style: theme.textTheme.labelMedium,
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.ayah.translationFor(lang),
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
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

class _AppBar extends StatelessWidget {
  const _AppBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            onPressed: () => popOrHome(context),
            tooltip: 'common.back'.tr(),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

/// Ekranın verisi: peygamber ve ayetleri, sure künyeleriyle birlikte.
class ProphetAyahs {
  const ProphetAyahs({required this.prophet, required this.entries});

  final Prophet prophet;
  final List<ProphetAyahEntry> entries;
}

class ProphetAyahEntry {
  const ProphetAyahEntry({required this.ayah, required this.surah});

  final Ayah ayah;
  final Surah surah;
}

/// Bir peygamberin ayetlerini iniş sırasına göre yükler.
///
/// Ayet kimlikleri veri dosyasında zaten iniş sırasına dizili; burada yapılan
/// yalnızca metinleri çekip o sırayı korumak. Veritabanı `WHERE id IN (...)`
/// sorgusunu kendi sırasıyla döndürdüğü için sıralama elle yeniden kurulur.
final prophetAyahsProvider =
    FutureProvider.family<ProphetAyahs, String>((ref, prophetId) async {
  final repo = await ref.watch(prophetDataProvider.future);
  final prophet = repo.byId(prophetId);
  if (prophet == null) {
    throw StateError('$prophetId kimlikli peygamber bulunamadı');
  }

  final quran = ref.watch(quranRepositoryProvider);
  final ayahs = await quran.ayahsByIds(prophet.ayahIds);
  final byId = {for (final a in ayahs) a.id: a};

  // Sure künyeleri bir kez toplanır; her ayet için ayrı sorgu 500'e yakın
  // gidiş dönüş demek olurdu.
  final surahNumbers = ayahs.map((a) => a.surahNumber).toSet();
  final surahs = <int, Surah>{};
  for (final n in surahNumbers) {
    final s = await quran.surah(n);
    if (s != null) surahs[n] = s;
  }

  final entries = <ProphetAyahEntry>[];
  for (final id in prophet.ayahIds) {
    final ayah = byId[id];
    if (ayah == null) continue;
    final surah = surahs[ayah.surahNumber];
    if (surah == null) continue;
    entries.add(ProphetAyahEntry(ayah: ayah, surah: surah));
  }

  return ProphetAyahs(prophet: prophet, entries: entries);
});
