import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../settings/providers/preferences_provider.dart';

/// Okuma sırasında açılan hızlı ayarlar: punto, satır aralığı, Arapça metin,
/// tefsir gösterimi ve tema.
///
/// Ayarlar ekranındaki tam listeyi tekrar etmez — burada yalnızca okurken
/// değiştirilmek istenen şeyler var. Değişiklikler anında uygulanır, "kaydet"
/// düğmesi yoktur; kullanıcı sonucu yaprağın arkasında görür.
class ReaderSettingsSheet extends ConsumerWidget {
  const ReaderSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final prefs = ref.watch(preferencesProvider);
    final notifier = ref.read(preferencesProvider.notifier);

    // Yatayda yaprak ekrana sığmayabilir; `AdaptiveSheet` yüksekliği
    // sınırlar ve gerekirse içeriği kaydırılabilir yapar.
    return AdaptiveSheet(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: horizontalSafeGutter(
            context,
          ).copyWith(top: Insets.xs, bottom: Insets.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('reader.reading'.tr(), style: theme.textTheme.titleMedium),
              const SizedBox(height: Insets.md),

              // Punto. Kaydırıcının iki ucundaki harfler ölçeği görsel olarak
              // anlatır; sayı göstermeye gerek kalmaz.
              _SliderRow(
                minLabel: 'A',
                maxLabel: 'A',
                minLabelSize: 13,
                maxLabelSize: 21,
                value: prefs.fontScale,
                min: 0.8,
                max: 1.6,
                divisions: 8,
                onChanged: notifier.setFontScale,
              ),
              const SizedBox(height: Insets.xs),

              // Satır aralığı.
              _SliderRow(
                minIcon: Icons.density_small_rounded,
                maxIcon: Icons.density_medium_rounded,
                value: prefs.lineHeight,
                min: 1.4,
                max: 2.2,
                divisions: 8,
                onChanged: notifier.setLineHeight,
              ),
              const SizedBox(height: Insets.md),

              Divider(color: theme.dividerColor, height: 1),
              const SizedBox(height: Insets.xs),

              _SwitchRow(
                label: 'settings.showArabic'.tr(),
                value: prefs.showArabic,
                onChanged: notifier.setShowArabic,
              ),

              const SizedBox(height: Insets.xs),
              Divider(color: theme.dividerColor, height: 1),
              const SizedBox(height: Insets.md),

              _ThemeSelector(
                value: prefs.themeMode,
                onChanged: notifier.setThemeMode,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// İki uçta görsel ipucu bulunan kaydırıcı satırı.
class _SliderRow extends StatelessWidget {
  const _SliderRow({
    this.minLabel,
    this.maxLabel,
    this.minLabelSize,
    this.maxLabelSize,
    this.minIcon,
    this.maxIcon,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String? minLabel;
  final String? maxLabel;
  final double? minLabelSize;
  final double? maxLabelSize;
  final IconData? minIcon;
  final IconData? maxIcon;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hintColor = theme.colorScheme.onSurface.withValues(alpha: 0.45);

    Widget edge(String? label, double? size, IconData? icon) {
      if (icon != null) return Icon(icon, size: 18, color: hintColor);
      return SizedBox(
        width: 24,
        child: Text(
          label ?? '',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: size, color: hintColor),
        ),
      );
    }

    return Row(
      children: [
        edge(minLabel, minLabelSize, minIcon),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        edge(maxLabel, maxLabelSize, maxIcon),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.xxs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// Üç durumlu tema seçici: açık, koyu, sistem.
///
/// Segmentli düğme kullanıldı çünkü üç seçenek de aynı anda görünür olmalı;
/// açılır menü olsaydı kullanıcı mevcut seçimi görmek için dokunmak zorunda
/// kalırdı.
class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text('settings.appearanceLabel'.tr(), style: theme.textTheme.bodyLarge),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ThemeOption(
                icon: Icons.light_mode_rounded,
                isSelected: value == ThemeMode.light,
                onTap: () => onChanged(ThemeMode.light),
                tooltip: 'settings.light'.tr(),
              ),
              _ThemeOption(
                icon: Icons.dark_mode_rounded,
                isSelected: value == ThemeMode.dark,
                onTap: () => onChanged(ThemeMode.dark),
                tooltip: 'settings.dark'.tr(),
              ),
              _ThemeOption(
                icon: Icons.phone_iphone_rounded,
                isSelected: value == ThemeMode.system,
                onTap: () => onChanged(ThemeMode.system),
                tooltip: 'settings.system'.tr(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: Motion.fast,
          curve: Motion.standard,
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.sm,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(Radii.sm - 2),
          ),
          child: Icon(
            icon,
            size: 17,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}
