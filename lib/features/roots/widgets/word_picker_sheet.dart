import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../data/models/ayah.dart';
import '../../../data/models/root.dart';
import '../providers/root_provider.dart';

/// Bir ayetin kelimelerini gösterir; seçilen kelimenin köküne götürür.
///
/// Kelimeler ızgara yerine tam genişlik satırlar halinde dizilir: her satırda
/// Arapça kelime, kökü ve Türkçe karşılığı yan yana durur. Izgara düzeninde
/// anlam metni sığmıyordu ve yaprak içeriğe göre daralıp ekranın ortasında
/// asılı kalıyordu.
///
/// Kökü olmayan kelimeler (edat, zamir) listeye hiç girmez — dokunulabilir
/// görünüp bir yere götürmemeleri kullanıcıyı yanıltırdı.
class WordPickerSheet extends ConsumerWidget {
  const WordPickerSheet({
    super.key,
    required this.ayah,
    required this.surahName,
    required this.onSelect,
  });

  final Ayah ayah;
  final String surahName;
  final ValueChanged<RootWord> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Birleşik meal bloklarında ilk ayetin kelimeleri çözümlenir; blok
    // birden çok ayeti kapsasa da kök analizi ayet birimiyle çalışır.
    final words = ref.watch(
      verseWordsProvider((ayah.surahNumber, ayah.ayahNumber)),
    );

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        // Yaprak her zaman ekran genişliğini kaplar; içeriğe göre daralması
        // modal'ı ortada asılı bir kutu gibi gösteriyordu.
        //
        // Yükseklik ekranın yarısıyla sınırlıdır: Bakara 170 gibi uzun
        // ayetlerde kelime sayısı yirmiyi aşıyor ve liste tüm ekranı
        // kaplayıp altındaki ayeti tamamen örtüyordu. Kullanıcı hangi ayet
        // üzerinde çalıştığını görebilmeli; liste kendi içinde kaydırılır.
        constraints: BoxConstraints(
          minWidth: double.infinity,
          maxHeight: MediaQuery.sizeOf(context).height * 0.55,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: horizontalSafeGutter(context).copyWith(
                top: Insets.xs,
                bottom: Insets.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$surahName · ${ayah.numberLabel}. ayet',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: Insets.xxs),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'roots.wordPickHint'.tr(),
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      // Kelime sayısı — liste kaydırılabilir olduğunda
                      // kullanıcı ne kadarını gördüğünü bilir.
                      if (words.valueOrNull case final list?
                          when list.length > 6)
                        Text(
                          'roots.wordCount'.tr(args: ['${list.length}']),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.45),
                            letterSpacing: 0,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            Flexible(
              child: words.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: Insets.xl),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (_, _) => _Message(text: 'roots.unavailable'.tr()),
                data: (list) {
                  if (list.isEmpty) {
                    return _Message(text: 'roots.noWords'.tr());
                  }
                  return ListView.separated(
                    // Az kelimeli ayetlerde yaprak içeriğe göre kısalır;
                    // uzun ayetlerde üstteki yükseklik sınırına dayanır ve
                    // liste kendi içinde kaydırılır.
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: Insets.md),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      indent: Insets.screenGutter,
                      endIndent: Insets.screenGutter,
                      color: theme.dividerColor,
                    ),
                    itemBuilder: (context, index) {
                      final entry = list[index];
                      return _WordRow(
                        entry: entry,
                        onTap: () {
                          // Önce yaprak kapanır, sonra seçim bildirilir.
                          // Çağıran taraf gezinmeyi kendi ekranının
                          // gezingeniyle yapar; bu yüzden yaprağın kapanmış
                          // olması sorun çıkarmaz.
                          Navigator.of(context).pop();
                          onSelect(entry.word);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Insets.screenGutter,
        0,
        Insets.screenGutter,
        Insets.lg,
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

/// Tek bir kelime satırı: Arapça kelime, kökü ve Türkçe karşılığı.
class _WordRow extends StatelessWidget {
  const _WordRow({required this.entry, required this.onTap});

  final AnalysedWord entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        // Dokunma alanı en az 44pt yüksekliğinde tutulur (Apple HIG).
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.screenGutter,
          vertical: Insets.sm,
        ),
        child: Row(
          children: [
            // Arapça kelime solda sabit genişlikte; satırlar dikey hizada
            // okunur, kelime uzunluğu düzeni kaydırmaz.
            SizedBox(
              width: 116,
              child: Text(
                entry.word.arabic,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 22,
                  height: 1.7,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Türkçe karşılık — kullanıcının asıl aradığı bilgi.
                  if (entry.meaning.isNotEmpty)
                    Text(
                      entry.meaning,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        entry.word.root,
                        textDirection: TextDirection.rtl,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (entry.root != null) ...[
                        const SizedBox(width: Insets.xs),
                        Text(
                          'roots.occurrences'.tr(
                            args: ['${entry.root!.count}'],
                          ),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.4),
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
            ),
          ],
        ),
      ),
    );
  }
}
