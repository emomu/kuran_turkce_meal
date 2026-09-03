import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Açık ve koyu tema tanımları.
///
/// Material bileşenleri kullanılır ama görsel dil iOS'a yakındır: gölge yerine
/// ince kenarlık, düşük yükseklik, sessiz geçişler. Bunun nedeni Material'ın
/// düzen ve erişilebilirlik altyapısının olgun olması; görsel katman ise
/// tamamen bu dosyadan kontrol edilir.
abstract final class AppTheme {
  static ThemeData get light => _build(
    brightness: Brightness.light,
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    surfaceSunken: AppColors.lightSurfaceSunken,
    ink: AppColors.lightInk,
    inkMuted: AppColors.lightInkMuted,
    inkFaint: AppColors.lightInkFaint,
    divider: AppColors.lightDivider,
    accent: AppColors.accentLight,
    onAccent: Colors.white,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceSunken: AppColors.darkSurfaceSunken,
    ink: AppColors.darkInk,
    inkMuted: AppColors.darkInkMuted,
    inkFaint: AppColors.darkInkFaint,
    divider: AppColors.darkDivider,
    accent: AppColors.accentDark,
    onAccent: AppColors.darkBackground,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceSunken,
    required Color ink,
    required Color inkMuted,
    required Color inkFaint,
    required Color divider,
    required Color accent,
    required Color onAccent,
  }) {
    final textTheme = AppTypography.textTheme(ink, inkMuted);
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      textTheme: textTheme,
      // Metin seçimi ve imleç vurgu rengini alır.
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: accent,
        onPrimary: onAccent,
        secondary: accent,
        onSecondary: onAccent,
        error: const Color(0xFFC0483C),
        onError: Colors.white,
        surface: surface,
        onSurface: ink,
        surfaceContainerLowest: background,
        surfaceContainerLow: surface,
        surfaceContainer: surfaceSunken,
        surfaceContainerHigh: surfaceSunken,
        outline: divider,
        outlineVariant: divider,
      ),
      dividerColor: divider,
      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 0.5,
        space: 0.5,
      ),
      // Sistem çubuğu ikonları temaya göre ters çevrilir.
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleMedium,
        iconTheme: IconThemeData(color: ink, size: 22),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      // Alt sekme çubuğu — arka planı ekranda ayrı bir katman gibi durmalı.
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accent,
        unselectedItemColor: inkFaint,
        selectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: textTheme.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: BorderSide(color: divider, width: 0.5),
        ),
      ),
      // Modal sayfalar — ayet eylem menüsü, ayar yaprakları.
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: inkFaint,
        dragHandleSize: const Size(36, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Radii.xl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        titleTextStyle: textTheme.titleMedium,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: inkMuted),
      ),
      // Arama alanı ve not girişi.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceSunken,
        hintStyle: textTheme.bodyMedium?.copyWith(color: inkFaint),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Insets.sm,
          vertical: Insets.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: inkMuted,
        textColor: ink,
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodySmall,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? accent
              : surfaceSunken,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : divider,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: surfaceSunken,
        thumbColor: Colors.white,
        overlayColor: accent.withValues(alpha: 0.12),
        trackHeight: 4,
      ),
      // Tüm platformlarda iOS tarzı yatay kaydırmalı sayfa geçişi.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }
}
