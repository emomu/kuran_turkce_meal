import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../search/providers/search_provider.dart';
import '../../search/widgets/search_result_parts.dart';
import '../widgets/topic_app_bar.dart';

/// Bir sorgunun bütün meal sonuçları.
///
/// Keşfet'teki sonuç grubu ilk beşi gösterip kırpıyor; "Hepsini Gör" buraya
/// getirir. Ayrı bir ekran olması, gruplu görünümün okunabilir kalması
/// içindir: üç grup tam hâlde alt alta dizildiğinde kullanıcı ikinci grubu
/// görmek için yüzlerce ayet kaydırmak zorunda kalıyordu.
///
/// Ekranın kendi arama kutusu yok. Sorgu Keşfet'te yazıldı ve buraya
/// parametreyle geldi; ikinci bir kutu koymak aynı işi iki yerde yapmak
/// olurdu. Sorguyu değiştirmek isteyen geri döner.
class VerseSearchScreen extends ConsumerStatefulWidget {
  const VerseSearchScreen({super.key, required this.query});

  final String query;

  @override
  ConsumerState<VerseSearchScreen> createState() => _VerseSearchScreenState();
}

class _VerseSearchScreenState extends ConsumerState<VerseSearchScreen> {
  @override
  void initState() {
    super.initState();
    // Sorgu sağlayıcıda zaten duruyor olabilir (Keşfet'ten gelindiyse
    // duruyor), ama derin bağlantıyla doğrudan açılırsa durmuyor. Tazelemek
    // iki durumu da karşılar ve maliyeti bir sorgu.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(searchProvider.notifier).updateQuery(widget.query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final search = ref.watch(searchProvider);

    ref.read(searchProvider.notifier).languageCode =
        context.locale.languageCode;

    return Scaffold(
      body: PopScope(
        canPop: canPopRoute(context),
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) popOrHome(context);
        },
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              TopicAppBar(title: widget.query),
              Expanded(child: _buildBody(context, theme, search)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, SearchState search) {
    if (search.isLoading && search.results.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (search.results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'discover.noResults'.tr(),
        message: 'discover.noResultsFor'.tr(args: [widget.query]),
      );
    }

    return ListView.separated(
      padding: centeredContentPadding(
        context,
        maxWidth: ContentWidth.reading,
        top: Insets.xs,
        bottom: MediaQuery.paddingOf(context).bottom + Insets.xl,
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: search.results.length + 1,
      separatorBuilder: (_, index) => index == 0
          ? const SizedBox.shrink()
          : Divider(height: 1, color: theme.dividerColor),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(top: Insets.sm, bottom: Insets.sm),
            child: Text(
              'discover.verseResults'.tr(args: ['${search.results.length}']),
              style: theme.textTheme.labelMedium,
            ),
          );
        }

        final hit = search.results[index - 1];
        return SearchResultRow(
          hit: hit,
          query: widget.query,
          onTap: () => context.push(
            '/sure/${hit.ayah.surahNumber}?ayet=${hit.ayah.ayahNumber}',
          ),
        );
      },
    );
  }
}
