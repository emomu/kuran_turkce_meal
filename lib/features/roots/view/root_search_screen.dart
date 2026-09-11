import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../data/models/root.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/pressable.dart';
import '../providers/root_provider.dart';
import 'root_detail_screen.dart';

/// Kök arama ve harf filtresi.
///
/// Tek bir arama kutusu üç yazım biçimini birden karşılar (Türkçe anlam,
/// Türkçe okunuş, Arapça kök, latin iskelet). Ayrı bir mod seçtirilmedi:
/// kullanıcı ne bildiğini yazar, uygulama hangisi olduğunu kendisi anlar.
///
/// Harf filtresi arama kutusunun altında katlanabilir bir bölüm olarak durur.
/// Sürekli açık kalsaydı 29 harflik ızgara ekranın yarısını yer ve asıl iş
/// olan sonuç listesini aşağı iterdi.
class RootSearchScreen extends ConsumerStatefulWidget {
  const RootSearchScreen({super.key});

  @override
  ConsumerState<RootSearchScreen> createState() => _RootSearchScreenState();
}

class _RootSearchScreenState extends ConsumerState<RootSearchScreen> {
  final _controller = TextEditingController();
  bool _lettersExpanded = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rootData = ref.watch(rootDataProvider);
    final state = ref.watch(rootSearchProvider);
    final notifier = ref.read(rootSearchProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text('roots.searchTitle'.tr())),
      body: SafeArea(
        bottom: false,
        left: false,
        right: false,
        child: rootData.when(
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
                Text('roots.loading'.tr(), style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          error: (_, _) => EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'roots.unavailable'.tr(),
            message: 'roots.unavailableHint'.tr(),
          ),
          data: (repo) {
            if (repo.allRoots.isEmpty) {
              return EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'roots.unavailable'.tr(),
                message: 'roots.unavailableHint'.tr(),
              );
            }

            return Column(
              children: [
                Padding(
                  padding: centeredContentPadding(
                    context,
                    top: Insets.md,
                    bottom: Insets.sm,
                  ),
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    style: theme.textTheme.bodyLarge,
                    onChanged: notifier.updateQuery,
                    decoration: InputDecoration(
                      hintText: 'roots.searchHint'.tr(),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.4),
                      ),
                      suffixIcon: state.query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _controller.clear();
                                notifier.updateQuery('');
                              },
                            ),
                    ),
                  ),
                ),

                _LetterFilter(
                  letters: repo.letters,
                  selected: state.selectedLetters,
                  isExpanded: _lettersExpanded,
                  onToggleExpanded: () =>
                      setState(() => _lettersExpanded = !_lettersExpanded),
                  onToggleLetter: notifier.toggleLetter,
                  onClear: notifier.clearLetters,
                ),

                if (state.results.isNotEmpty)
                  Padding(
                    padding: centeredContentPadding(
                      context,
                      top: Insets.xs,
                      bottom: Insets.xs,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'roots.resultCount'.tr(
                          args: ['${state.results.length}'],
                        ),
                        style: theme.textTheme.labelMedium,
                      ),
                    ),
                  ),

                Expanded(child: _buildResults(context, state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context, RootSearchState state) {
    if (!state.isActive) {
      return EmptyState(
        icon: Icons.abc_rounded,
        title: 'roots.searchTitle'.tr(),
        message: 'roots.searchEmptyHint'.tr(),
      );
    }

    if (state.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'roots.noResults'.tr(),
        message: state.query.trim().isEmpty
            ? 'roots.letterFilterHint'.tr()
            : 'roots.noResultsFor'.tr(args: [state.query.trim()]),
      );
    }

    return ListView.separated(
      padding: centeredContentPadding(
        context,
        bottom: MediaQuery.paddingOf(context).bottom + Insets.lg,
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: state.results.length,
      separatorBuilder: (_, _) =>
          Divider(height: 1, color: Theme.of(context).dividerColor),
      itemBuilder: (context, index) => _RootRow(root: state.results[index]),
    );
  }
}

/// Sonuç listesindeki tek bir kök.
class _RootRow extends StatelessWidget {
  const _RootRow({required this.root});

  final QuranRoot root;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Pressable(
      scale: 0.99,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          // Detaydaki arama düğmesi buraya geri dönsün, yeni bir arama
          // ekranı itmesin; bkz. [RootDetailScreen.cameFromSearch].
          builder: (_) => RootDetailScreen(
            rootArabic: root.arabic,
            cameFromSearch: true,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Insets.sm),
        child: Row(
          children: [
            // Kök harfleri solda sabit genişlikte durur; liste dikey bir
            // hizada okunur.
            SizedBox(
              width: 76,
              child: Text(
                root.arabic,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 22,
                  height: 1.5,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(width: Insets.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (root.hasMeaning)
                    Text(
                      root.meaning,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  if (root.readings.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      root.readings.take(3).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: Insets.xs),
            Text(
              '${root.count}',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Arap harfleriyle kök daraltma.
///
/// Her harf Türkçe okunuş adıyla birlikte gösterilir ("ر re"); kullanıcı
/// Arap alfabesini bilmese de hangi harfi seçtiğini anlar. Seçim çoklu ve
/// VE mantığındadır: iki harf seçilirse ikisini birden içeren kökler kalır.
class _LetterFilter extends StatelessWidget {
  const _LetterFilter({
    required this.letters,
    required this.selected,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onToggleLetter,
    required this.onClear,
  });

  final List<ArabicLetter> letters;
  final Set<String> selected;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<String> onToggleLetter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (letters.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık satırı — dokunulunca ızgarayı açar/kapatır.
        Pressable(
          scale: 0.99,
          onTap: onToggleExpanded,
          child: Padding(
            padding: centeredContentPadding(
              context,
              top: Insets.xs,
              bottom: Insets.xs,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list_rounded,
                  size: 18,
                  color: selected.isEmpty
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                      : theme.colorScheme.primary,
                ),
                const SizedBox(width: Insets.xs),
                Text(
                  'roots.letterFilter'.tr(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: selected.isEmpty
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.primary,
                  ),
                ),
                if (selected.isNotEmpty) ...[
                  const SizedBox(width: Insets.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(Radii.pill),
                    ),
                    child: Text(
                      '${selected.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (selected.isNotEmpty)
                  Pressable(
                    scale: 0.95,
                    onTap: onClear,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Insets.xs,
                        vertical: Insets.xxs,
                      ),
                      child: Text(
                        'common.reset'.tr(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: Motion.fast,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),

        AnimatedSize(
          duration: Motion.normal,
          curve: Motion.standard,
          alignment: Alignment.topCenter,
          child: isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(bottom: Insets.sm),
                  // Harfler tek satırda yatay kaydırılır. Izgara düzeninde
                  // 29 harf altı satır kaplıyor ve sonuç listesini ekranın
                  // dışına itiyordu; şerit sabit yükseklikte kalır.
                  // Şeridin sağ ucu zemine karışır; devamı olduğu görünür.
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        theme.colorScheme.surface,
                        theme.colorScheme.surface,
                        theme.colorScheme.surface.withValues(alpha: 0),
                      ],
                      stops: const [0, 0.92, 1],
                    ).createShader(bounds),
                    blendMode: BlendMode.dstIn,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      // Harf şeridi bilerek tüm genişliği kullanır (yatay
                      // kaydırılır); yalnızca güvenli alan hesaba katılır.
                      padding: horizontalSafeGutter(context),
                      child: Row(
                        children: [
                          for (final letter in letters)
                            _LetterChip(
                              letter: letter,
                              isSelected: selected.contains(letter.letter),
                              onTap: () => onToggleLetter(letter.letter),
                            ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),

        Divider(height: 1, color: theme.dividerColor),
      ],
    );
  }
}

class _LetterChip extends StatelessWidget {
  const _LetterChip({
    required this.letter,
    required this.isSelected,
    required this.onTap,
  });

  final ArabicLetter letter;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Harf ve okunuş alt alta değil yan yana durur: iki satırlık kutular
    // ızgarayı ekranın yarısına çıkarıyordu. Yan yana dizilim hem şeridi
    // tek satıra indirir hem de okunuşu harfin karşılığı olarak okutur.
    return Pressable(
      scale: 0.94,
      hapticOnTap: true,
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.fast,
        curve: Motion.standard,
        margin: const EdgeInsets.only(right: Insets.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.sm,
          vertical: Insets.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              letter.letter,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 17,
                height: 1.2,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 5),
            // Türkçe okunuş — Arap alfabesini bilmeyen kullanıcı için.
            Text(
              letter.name,
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 0,
                color: isSelected
                    ? theme.colorScheme.onPrimary.withValues(alpha: 0.9)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
