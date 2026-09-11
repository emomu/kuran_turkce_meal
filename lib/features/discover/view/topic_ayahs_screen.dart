import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/ayah.dart';
import '../../../data/models/surah.dart';
import '../../../data/models/topic.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../reader/view/reader_screen.dart';
import '../widgets/topic_app_bar.dart';

/// Bir konunun ayetleri, mushaf sırasına göre.
///
/// Kıssa ekranı iniş sırasını kullanır çünkü orada anlatının geliştiğini
/// göstermek ekranın varlık sebebidir. Fihristte böyle bir gelişim yoktur:
/// "miras hükümleri"ne bakan kullanıcı Nisâ'yı beklediği yerde arar. Bu yüzden
/// burada mushaf sırası korunur.
///
/// Liste iki bölümlüdür ve ayrım kullanıcıya açıkça söylenir. Üstteki ayetler
/// kürasyonla seçilmiştir — "bu konuyu kuran ayetler". Alttakiler meal
/// metninde terim taramasından gelir; isabetli olsalar da aynı ağırlıkta
/// değiller. Ayrım söylenmeseydi kullanıcı taramadan gelen ikincil bir ayeti
/// konunun merkezi sanabilirdi ve fihrist verdiği sözü tutmamış olurdu.
class TopicAyahsScreen extends ConsumerWidget {
  const TopicAyahsScreen({super.key, required this.topicId});

  final String topicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(topicAyahsProvider(topicId));

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
              title: 'discover.loadFailed'.tr(),
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

  final TopicAyahs data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.locale.languageCode;

    // Liste düz bir öğe dizisine çevrilir: başlık, ayetler, aradaki bölüm
    // başlıkları ve sondaki ilgili konular tek bir kaydırma içinde akar.
    final items = data._buildItems();

    return Column(
      children: [
        TopicAppBar(title: data.topic.nameFor(lang)),
        Expanded(
          child: ListView.builder(
            padding: centeredContentPadding(
              context,
              maxWidth: ContentWidth.reading,
              top: Insets.xs,
              bottom: MediaQuery.paddingOf(context).bottom + Insets.xl,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) => switch (items[index]) {
              _HeaderItem() => _Header(data: data),
              _SectionItem(:final labelKey, :final noteKey) => _SectionHeading(
                labelKey: labelKey,
                noteKey: noteKey,
              ),
              _AyahItem(:final entry, :final showsSurahHeader) => _AyahEntry(
                entry: entry,
                showsSurahHeader: showsSurahHeader,
                theme: theme,
                lang: lang,
              ),
              _RelatedItem(:final topics) => _RelatedTopics(topics: topics),
            },
          ),
        ),
      ],
    );
  }
}

/// Liste başlığı: konu adı ve kaç ayet.
class _Header extends StatelessWidget {
  const _Header({required this.data});

  final TopicAyahs data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.locale.languageCode;

    return Padding(
      padding: const EdgeInsets.only(top: Insets.md, bottom: Insets.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.topic.nameFor(lang), style: theme.textTheme.displaySmall),
          const SizedBox(height: Insets.xxs),
          Text(
            'discover.ayahCount'.tr(args: ['${data.entries.length}']),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

/// Çekirdek ve tarama bölümlerinin başlığı.
class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.labelKey, this.noteKey});

  final String labelKey;

  /// Bölümün altına yazılan açıklama. Yalnızca tarama bölümünde vardır:
  /// o ayetlerin nereden geldiğini söylemek bir gereklilik, kürasyonlu
  /// bölümde ise söylenecek bir şey yok.
  final String? noteKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: Insets.lg, bottom: Insets.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: theme.dividerColor, height: 1),
          const SizedBox(height: Insets.md),
          Text(
            labelKey.tr(),
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          if (noteKey != null) ...[
            const SizedBox(height: Insets.xxs),
            Text(
              noteKey!.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
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

  final TopicAyahEntry entry;
  final bool showsSurahHeader;
  final ThemeData theme;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sure başlığı yalnızca sure değiştiğinde çizilir; aynı surenin
        // ardışık ayetleri tek blok gibi okunur.
        if (showsSurahHeader) ...[
          const SizedBox(height: Insets.md),
          Text(entry.surah.nameFor(lang), style: theme.textTheme.titleSmall),
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

/// Listenin sonundaki ilgili konular.
///
/// Fihristin gezilebilir olmasının yolu bu: kullanıcı "sabır"dan "tevekkül"e,
/// oradan "kader"e geçebilmeli. Bağlar üretimde karşılıklı hâle getirilir,
/// yani her yoldan geri dönülebilir.
class _RelatedTopics extends StatelessWidget {
  const _RelatedTopics({required this.topics});

  final List<Topic> topics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.locale.languageCode;

    return Padding(
      padding: const EdgeInsets.only(top: Insets.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: theme.dividerColor, height: 1),
          const SizedBox(height: Insets.md),
          Text(
            'discover.relatedTitle'.tr(),
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: Insets.sm),
          Wrap(
            spacing: Insets.xs,
            runSpacing: Insets.xs,
            children: [
              for (final t in topics)
                Pressable(
                  // Aynı rotaya `push` edilir: kullanıcı geri tuşuyla
                  // geldiği konuya döner. `go` olsaydı yığın sıfırlanır ve
                  // konudan konuya gezinme geri dönülemez hâle gelirdi.
                  onTap: () => context.push('/fihrist/${t.id}'),
                  borderRadius: BorderRadius.circular(Radii.pill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Insets.sm,
                      vertical: Insets.xs,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(Radii.pill),
                    ),
                    child: Text(
                      t.nameFor(lang),
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Listedeki öğe türleri.
///
/// Ayrı türler, çünkü liste tek bir dizi olmalı ama içinde dört farklı şey
/// var. İndeks aritmetiğiyle ("0. öğe başlık, coreCount+1. öğe bölüm...")
/// kurulsaydı her yeni bölüm bütün hesabı kaydırırdı.
sealed class _Item {
  const _Item();
}

class _HeaderItem extends _Item {
  const _HeaderItem();
}

class _SectionItem extends _Item {
  const _SectionItem({required this.labelKey, this.noteKey});
  final String labelKey;
  final String? noteKey;
}

class _AyahItem extends _Item {
  const _AyahItem({required this.entry, required this.showsSurahHeader});
  final TopicAyahEntry entry;
  final bool showsSurahHeader;
}

class _RelatedItem extends _Item {
  const _RelatedItem({required this.topics});
  final List<Topic> topics;
}

/// Ekranın verisi: konu, ayetleri ve ilgili konular.
class TopicAyahs {
  const TopicAyahs({
    required this.topic,
    required this.entries,
    required this.coreCount,
    required this.related,
  });

  final Topic topic;
  final List<TopicAyahEntry> entries;

  /// Kaç ayetin kürasyonlu olduğu.
  ///
  /// [Topic.coreCount] ile aynı değil: veritabanında bulunamayan bir ayet
  /// listeden düşer ve sınır kayar. Bu yüzden yükleme sırasında yeniden
  /// sayılır.
  final int coreCount;

  final List<Topic> related;

  /// Listenin öğelerini kurar.
  ///
  /// Sure başlığı kararı burada verilir, çizim sırasında değil: bölüm
  /// başlığından hemen sonraki ayet, aynı surede olsa bile kendi başlığını
  /// almalı — yoksa tarama bölümü suresi belirsiz bir ayetle başlar.
  List<_Item> _buildItems() {
    final items = <_Item>[const _HeaderItem()];

    for (var i = 0; i < entries.length; i++) {
      final isSectionStart = i == 0 || i == coreCount;

      if (i == 0) {
        items.add(const _SectionItem(labelKey: 'discover.coreHeading'));
      } else if (i == coreCount) {
        items.add(
          const _SectionItem(
            labelKey: 'discover.scannedHeading',
            noteKey: 'discover.scannedNote',
          ),
        );
      }

      final previous = i > 0 ? entries[i - 1] : null;
      items.add(
        _AyahItem(
          entry: entries[i],
          showsSurahHeader:
              isSectionStart ||
              previous == null ||
              previous.surah.number != entries[i].surah.number,
        ),
      );
    }

    if (related.isNotEmpty) items.add(_RelatedItem(topics: related));
    return items;
  }
}

class TopicAyahEntry {
  const TopicAyahEntry({required this.ayah, required this.surah});

  final Ayah ayah;
  final Surah surah;
}

/// Bir konunun ayetlerini mushaf sırasına göre yükler.
///
/// Ayet kimlikleri veri dosyasında zaten mushaf sırasına dizili ve çekirdek
/// öne alınmış; burada yapılan yalnızca metinleri çekip o sırayı korumak.
/// Veritabanı `WHERE id IN (...)` sorgusunu kendi sırasıyla döndürdüğü için
/// sıralama elle yeniden kurulur.
final topicAyahsProvider = FutureProvider.family<TopicAyahs, String>((
  ref,
  topicId,
) async {
  final repo = await ref.watch(topicDataProvider.future);
  final topic = repo.byId(topicId);
  if (topic == null) {
    throw StateError('$topicId kimlikli konu bulunamadı');
  }

  final quran = ref.watch(quranRepositoryProvider);
  final ayahs = await quran.ayahsByIds(topic.ayahIds);
  final byId = {for (final a in ayahs) a.id: a};

  // Sure künyeleri bir kez toplanır; her ayet için ayrı sorgu yüzlerce
  // gidiş dönüş demek olurdu.
  final surahNumbers = ayahs.map((a) => a.surahNumber).toSet();
  final surahs = <int, Surah>{};
  for (final n in surahNumbers) {
    final s = await quran.surah(n);
    if (s != null) surahs[n] = s;
  }

  final entries = <TopicAyahEntry>[];
  var coreCount = 0;

  for (var i = 0; i < topic.ayahIds.length; i++) {
    final ayah = byId[topic.ayahIds[i]];
    if (ayah == null) continue;
    final surah = surahs[ayah.surahNumber];
    if (surah == null) continue;

    entries.add(TopicAyahEntry(ayah: ayah, surah: surah));
    // Sınır düşen ayetlerle birlikte kayar; bu yüzden eklendikçe sayılır.
    if (i < topic.coreCount) coreCount++;
  }

  return TopicAyahs(
    topic: topic,
    entries: entries,
    coreCount: coreCount,
    related: repo.relatedTo(topic),
  );
});
