/// Meal aramasının sonuç parçaları.
///
/// Bu parçalar iki yerde çiziliyor: Keşfet sekmesinin birleşik arama listesi
/// ve asistanın sonuç ekranı. Ekranın kendi dosyasında private kaldıkları
/// sürece ikinci kullanıcı onları kopyalamak zorunda kalıyordu.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../data/db/search_normalizer.dart';
import '../../../data/models/prophet.dart';
import '../../../data/repositories/quran_repository.dart';
import '../../../shared/widgets/pressable.dart';
import '../providers/search_provider.dart';


/// Sorgunun çözüldüğü ayete/sureye doğrudan giden kart.
///
/// "2:255" ya da "bakara 255" yazan kullanıcı arama yapmıyor, bir yere
/// gitmek istiyor. Bu kart o niyeti karşılar ve arama sonuçlarının önünde
/// durur; tam metin sonuçları altında kalmaya devam eder, çünkü "nur" gibi
/// sorgularda kullanıcı ikisini de kastediyor olabilir.
class ReferenceCard extends StatelessWidget {
  const ReferenceCard({
    super.key,
    required this.reference,
    required this.onTap,
  });

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
class ProphetCard extends StatelessWidget {
  const ProphetCard({super.key, required this.prophet, required this.onTap});

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
class SearchResultRow extends StatelessWidget {
  const SearchResultRow({
    super.key,
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
            HighlightedText(
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
class HighlightedText extends StatelessWidget {
  const HighlightedText({
    super.key,
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
