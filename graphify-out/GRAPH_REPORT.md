# Graph Report - kuran_turkce_meal  (2026-09-07)

## Corpus Check
- 181 files · ~689,376 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 2416 nodes · 3619 edges · 132 communities (121 shown, 7 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 73 edges (avg confidence: 0.87)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `5b02b1c4`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- lib/features (home, reader, search, plans, bookmarks, settings)
- app_colors.dart
- search_provider.dart
- preferences_provider.dart
- import_meal.dart
- pressable.dart
- reader_screen.dart
- bookmarks_provider.dart
- app_typography.dart
- _
- ayah_actions_sheet.dart
- search_screen.dart
- reader_settings_sheet.dart
- AppDelegate
- reader_provider.dart
- ayah.dart
- settings_screen.dart
- quran_repository.dart
- prophet_ayahs_screen.dart
- WidgetData.kt
- screens_smoke_test.dart
- app_database.dart
- ayah_tile.dart
- home_widget_keys.dart
- plan_detail_screen.dart
- surah_end_card.dart
- app_router.dart
- note_editor_test.dart
- note_editor_sheet.dart
- app_providers.dart
- audio_repository.dart
- marks_repository.dart
- responsive_layout.dart
- package:flutter/material.dart
- preferencesProvider
- progress_repository.dart
- package:easy_localization/easy_localization.dart
- app_shell.dart
- audio_provider.dart
- word_picker_sheet.dart
- download_provider.dart
- surah.dart
- StatelessWidget
- WidgetStrings
- package:kuran_turkce_meal/core/theme/app_theme.dart
- Android Density Bucket Ladder
- helpers/localized_app.dart
- ayah_card_render_test.dart
- root_detail_screen.dart
- coach_mark.dart
- root_search_screen.dart
- plan_reader_screen.dart
- package:flutter_riverpod/flutter_riverpod.dart
- App Store Marketing Icon (1024x1024, Flutter Logo)
- iOS Launch Image (2x)
- iPhone Spotlight Icon 40pt @3x (120x120)
- WidgetLaunch.kt
- Notification Icon 20pt @2x
- Settings Icon 29pt @2x
- iPad Home Screen Icon 76pt @2x
- root_repository.dart
- plan_reader_provider.dart
- root_provider.dart
- root.dart
- tour_host.dart
- _
- build_roots.py
- reading_plan.dart
- plan_schedule.dart
- build_privacy_html.dart
- ayah_card.dart
- main.dart
- reader_advance_test.dart
- Mağaza Yayın Bilgileri
- package:flutter/services.dart
- bookmarks_screen.dart
- home_widget_data.dart
- Color
- splash_screen.dart
- ../../../shared/widgets/responsive_layout.dart
- static const
- prophet_repository.dart
- ayah_card_renderer.dart
- VoidCallback?
- screens_preview.dart
- localized_app.dart
- empty_state.dart
- CLAUDE.md
- State
- prophet_data_test.dart
- ContinueReadingWidget
- daily_ayah_notifications.dart
- build_prophets.py
- home_widget_service.dart
- package:flutter_test/flutter_test.dart
- reciter.dart
- Planlar bölümü — geliştirme promptları
- StreakEntry
- home_widget_sync.dart
- ContinueEntry
- audio_ui_test.dart
- WidgetMidnightRefresh.kt
- DailyAyahEntry
- ayah_share.dart
- List
- app_theme.dart
- ReaderPreferences
- ContinueReadingWidgetProvider
- StreakWidgetProvider
- home_cards.dart
- search_integration_test.dart
- return
- root_highlight.dart
- int?
- SharedPreferences
- String?
- Widget
- tour_provider.dart
- reader_preferences.dart
- home_provider.dart
- app_shell_test.dart
- selectedReciterProvider
- build
- state_sync_test.dart
- ayah_actions_test.dart
- StateNotifier
- widget_back_navigation_test.dart
- ConsumerStatefulWidget

## God Nodes (most connected - your core abstractions)
1. `_` - 43 edges
2. `_` - 31 edges
3. `WidgetStrings` - 22 edges
4. `preferencesProvider` - 14 edges
5. `StreakEntry` - 13 edges
6. `ContinueEntry` - 12 edges
7. `DailyAyahEntry` - 11 edges
8. `WidgetStore` - 10 edges
9. `Surah` - 10 edges
10. `audioProvider` - 10 edges

## Surprising Connections (you probably didn't know these)
- `Türkçe Arama Normalleştiricisi` --semantically_similar_to--> `easy_localization ^3.0.8`  [INFERRED] [semantically similar]
  README.md → pubspec.yaml
- `Tamamen Çevrimdışı, Hesapsız Çalışma` --semantically_similar_to--> `publish_to: none (Private Package)`  [INFERRED] [semantically similar]
  README.md → pubspec.yaml
- `SharedPreferences Tercih Deposu` --references--> `shared_preferences ^2.5.5`  [INFERRED]
  README.md → pubspec.yaml
- `SQLite Veritabanı (Ayet + Kullanıcı Verisi)` --conceptually_related_to--> `path_provider ^2.1.6`  [INFERRED]
  README.md → pubspec.yaml
- `SQLite Veritabanı (Ayet + Kullanıcı Verisi)` --references--> `sqflite ^2.4.2+1`  [INFERRED]
  README.md → pubspec.yaml

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **ic_launcher Density Variant Set (one logical asset, five rasterizations)** — android_app_src_main_res_mipmap_mdpi_ic_launcher_icon, android_app_src_main_res_mipmap_hdpi_ic_launcher_icon, android_app_src_main_res_mipmap_xhdpi_ic_launcher_icon, android_app_src_main_res_mipmap_xxhdpi_ic_launcher_icon, android_app_src_main_res_mipmap_xxxhdpi_ic_launcher_icon [EXTRACTED 1.00]
- **iPad App Icon Family (all iPad idiom slots)** — ios_runner_assets_xcassets_appiconset_icon_app_20x20_1x_ipad_notification_icon, ios_runner_assets_xcassets_appiconset_icon_app_20x20_2x_notification_icon, ios_runner_assets_xcassets_appiconset_icon_app_29x29_1x_settings_icon, ios_runner_assets_xcassets_appiconset_icon_app_29x29_2x_settings_icon, ios_runner_assets_xcassets_appiconset_icon_app_40x40_1x_ipad_spotlight_icon, ios_runner_assets_xcassets_appiconset_icon_app_40x40_2x_spotlight_icon, ios_runner_assets_xcassets_appiconset_icon_app_76x76_1x_ipad_home_screen_icon, ios_runner_assets_xcassets_appiconset_icon_app_76x76_2x_ipad_home_screen_icon, ios_runner_assets_xcassets_appiconset_icon_app_83_5x83_5_2x_ipad_pro_home_screen_icon [EXTRACTED 1.00]
- **iPhone App Icon Family (all iPhone idiom slots)** — ios_runner_assets_xcassets_appiconset_icon_app_20x20_2x_notification_icon, ios_runner_assets_xcassets_appiconset_icon_app_20x20_3x_iphone_notification_icon, ios_runner_assets_xcassets_appiconset_icon_app_29x29_2x_settings_icon, ios_runner_assets_xcassets_appiconset_icon_app_29x29_3x_settings_icon, ios_runner_assets_xcassets_appiconset_icon_app_40x40_2x_spotlight_icon, ios_runner_assets_xcassets_appiconset_icon_app_40x40_3x_iphone_spotlight_icon, ios_runner_assets_xcassets_appiconset_icon_app_60x60_2x_iphone_home_screen_icon, ios_runner_assets_xcassets_appiconset_icon_app_60x60_3x_iphone_home_screen_icon [EXTRACTED 1.00]
- **Cihaz İçi Veri Kalıcılığı Akışı** — readme_ayahs_json_asset, readme_sqlite_database, readme_shared_preferences_store, readme_repository_query_layer, readme_offline_first_no_account [EXTRACTED 1.00]
- **Uzun Okuma Odaklı Tasarım Sistemi** — readme_design_color_palette, readme_design_typography, readme_design_motion, readme_design_accessibility, readme_reading_settings [EXTRACTED 1.00]
- **Türkçe Arama Boru Hattı** — readme_fts5_full_text_search, readme_turkish_search_normalizer, readme_sqlite_database, readme_lib_features_layer [EXTRACTED 1.00]
- **All App Icons Render the Same Default Flutter Logo Artwork** — ios_runner_assets_xcassets_appiconset_icon_app_1024x1024_1x_flutter_logo_marketing_icon, ios_runner_assets_xcassets_appiconset_icon_app_60x60_3x_iphone_home_screen_icon, ios_runner_assets_xcassets_appiconset_icon_app_76x76_2x_ipad_home_screen_icon, ios_runner_assets_xcassets_appiconset_icon_app_83_5x83_5_2x_ipad_pro_home_screen_icon, ios_runner_assets_xcassets_appiconset_icon_app_1024x1024_1x_default_flutter_branding [INFERRED 0.95]
- **iOS LaunchImage Scale-Variant Asset Set** — ios_runner_assets_xcassets_launchimage_imageset_launchimage_1x, ios_runner_assets_xcassets_launchimage_imageset_launchimage_2x, ios_runner_assets_xcassets_launchimage_imageset_launchimage_3x, ios_runner_assets_xcassets_launchimage_imageset_launchimage_scale_variant_set [INFERRED 0.95]

## Communities (132 total, 7 thin omitted)

### Community 0 - "lib/features (home, reader, search, plans, bookmarks, settings)"
Cohesion: 0.05
Nodes (51): Dart Analyzer Yapılandırması, tool/** Analiz Dışı Bırakma, iOS Launch Screen Assets, Flutter Asset Bildirimi (assets/data, assets/translations), easy_localization ^3.0.8, flutter_lints ^6.0.0 (dev), flutter_riverpod ^2.6.1, go_router ^17.5.0 (+43 more)

### Community 1 - "app_colors.dart"
Cohesion: 0.08
Nodes (23): accentDark, accentLight, AppColors, darkBackground, darkDivider, darkInk, darkInkFaint, darkInkMuted (+15 more)

### Community 2 - "search_provider.dart"
Cohesion: 0.07
Nodes (27): ../../../data/models/prophet.dart, ../data/verse_reference.dart, ayahNumber, clear, copyWith, _debounce, dispose, hasQuery (+19 more)

### Community 3 - "preferences_provider.dart"
Cohesion: 0.08
Nodes (24): _kAutoScrollWithAudio, _kDailyAyahEnabled, _kDailyAyahHour, _kDailyAyahMinute, _kFontScale, _kLineHeight, _kPlaybackSpeed, _kReciterId (+16 more)

### Community 4 - "import_meal.dart"
Cohesion: 0.06
Nodes (32): arabic, arabicPath, b, _build, decoded, file, id, _loadSurahs (+24 more)

### Community 5 - "pressable.dart"
Cohesion: 0.13
Nodes (14): BorderRadius?, borderRadius, build, child, createState, _handleLongPress, _handleTap, hapticOnTap (+6 more)

### Community 6 - "reader_screen.dart"
Cohesion: 0.05
Nodes (41): createState, _didScrollToInitial, dispose, _firstAyahKey, _focusedAyahNumber, _focusTimer, _indexOfAyah, initialAyah (+33 more)

### Community 7 - "bookmarks_provider.dart"
Cohesion: 0.13
Nodes (16): core/providers/app_providers.dart, Surah, ayah, ayahById, ayahs, mark, marks, marksRepo (+8 more)

### Community 8 - "app_typography.dart"
Cohesion: 0.07
Nodes (26): AppTypography, emphasized, fast, Insets, lg, md, Motion, normal (+18 more)

### Community 9 - "_"
Cohesion: 0.06
Nodes (40): _, _buildDays, bySurah, calculateStreak, completed, completions, days, endAyah (+32 more)

### Community 10 - "ayah_actions_sheet.dart"
Cohesion: 0.08
Nodes (24): _ActionRow, ayah, AyahActionsSheet, build, color, _ColorDot, _HighlightPicker, icon (+16 more)

### Community 11 - "search_screen.dart"
Cohesion: 0.05
Nodes (47): ../../../data/models/reading_plan.dart, GlobalKey?, PlanOrder, _ayahOfDayKey, _orderToggleKey, _surahSearchKey, _tourSteps, badgeKey (+39 more)

### Community 12 - "reader_settings_sheet.dart"
Cohesion: 0.09
Nodes (21): double?, divisions, icon, isSelected, label, max, maxIcon, maxLabel (+13 more)

### Community 13 - "AppDelegate"
Cohesion: 0.10
Nodes (15): Flutter, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, FlutterSceneDelegate, AppDelegate, Any, Bool (+7 more)

### Community 14 - "reader_provider.dart"
Cohesion: 0.11
Nodes (18): ../../bookmarks/providers/bookmarks_provider.dart, ../../home/providers/home_provider.dart, _apply, ayahs, byRevelation, call, _load, quran (+10 more)

### Community 15 - "ayah.dart"
Cohesion: 0.12
Nodes (15): arabic, Ayah, ayahNumber, endAyahNumber, fromMap, id, isRange, numberLabel (+7 more)

### Community 16 - "settings_screen.dart"
Cohesion: 0.05
Nodes (38): ../../audio/providers/download_provider.dart, ../../audio/widgets/audio_download_sheet.dart, children, _confirmReset, createState, displayValue, divisions, initState (+30 more)

### Community 17 - "quran_repository.dart"
Cohesion: 0.10
Nodes (19): ../db/search_normalizer.dart, ayah, ayahById, ayahOfTheDay, ayahPoolFrom, ayahRange, ayahsByIds, ayahsOfSurah (+11 more)

### Community 18 - "prophet_ayahs_screen.dart"
Cohesion: 0.07
Nodes (28): _AppBar, ayah, _AyahEntry, ayahs, _Body, build, byId, data (+20 more)

### Community 19 - "WidgetData.kt"
Cohesion: 0.11
Nodes (12): DailyAyahTileService, DailyAyahWidgetProvider, AppWidgetManager, AppWidgetProvider, Context, IntArray, Intent, SharedPreferences (+4 more)

### Community 20 - "screens_smoke_test.dart"
Cohesion: 0.05
Nodes (37): AnimatedAlign, AnimatedDefaultTextStyle, Brightness, package:kuran_turkce_meal/core/theme/app_typography.dart, package:kuran_turkce_meal/features/bookmarks/providers/bookmarks_provider.dart, package:kuran_turkce_meal/features/bookmarks/view/bookmarks_screen.dart, package:kuran_turkce_meal/features/plans/view/plans_screen.dart, package:kuran_turkce_meal/features/settings/providers/preferences_provider.dart (+29 more)

### Community 21 - "app_database.dart"
Cohesion: 0.11
Nodes (18): async, close, _createSchema, _databasesPath, _db, factoryOverride, _fileName, hasContent (+10 more)

### Community 22 - "ayah_tile.dart"
Cohesion: 0.11
Nodes (17): ../../../data/models/reader_preferences.dart, ../../../data/models/user_marks.dart, ayah, _AyahHeader, AyahTile, build, highlightColor, isFocused (+9 more)

### Community 23 - "home_widget_keys.dart"
Cohesion: 0.07
Nodes (28): androidContinueProvider, androidDailyAyahProvider, androidStreakProvider, continueAyahLabel, continuePercent, continueRoute, continueSurahName, dailyAyahDayNumber (+20 more)

### Community 24 - "plan_detail_screen.dart"
Cohesion: 0.09
Nodes (23): ../../core/theme/app_typography.dart, ../../../data/models/plan_schedule.dart, ReadingStreak, color, completedDays, completions, day, _DayRow (+15 more)

### Community 25 - "surah_end_card.dart"
Cohesion: 0.08
Nodes (25): ../../../data/models/surah.dart, build, fraction, lastReadAyah, onTap, _ProgressBar, showRevelationOrder, _subtitle (+17 more)

### Community 26 - "app_router.dart"
Cohesion: 0.08
Nodes (24): app_shell.dart, ../../features/bookmarks/view/bookmarks_screen.dart, ../../features/home/view/home_screen.dart, ../../features/legal/data/legal_texts.dart, ../../features/legal/view/legal_document_screen.dart, ../../features/plans/view/plan_detail_screen.dart, ../../features/plans/view/plans_screen.dart, ../../features/prophets/view/prophet_ayahs_screen.dart (+16 more)

### Community 27 - "note_editor_test.dart"
Cohesion: 0.13
Nodes (13): AnimatedOpacity, CircularProgressIndicator, package:kuran_turkce_meal/features/plans/widgets/plan_day_end_card.dart, package:kuran_turkce_meal/features/reader/widgets/note_editor_sheet.dart, ayah, ensureInitialized, main, pumpEditor (+5 more)

### Community 28 - "note_editor_sheet.dart"
Cohesion: 0.11
Nodes (18): FocusNode, ayah, build, _confirmDelete, _controller, createState, dispose, enabled (+10 more)

### Community 29 - "app_providers.dart"
Cohesion: 0.10
Nodes (19): ../../data/db/app_database.dart, ../../data/repositories/audio_repository.dart, ../../data/repositories/marks_repository.dart, ../../data/repositories/progress_repository.dart, ../../data/repositories/prophet_repository.dart, ../../../data/repositories/quran_repository.dart, ../../data/repositories/root_repository.dart, databaseProvider (+11 more)

### Community 30 - "audio_repository.dart"
Cohesion: 0.06
Nodes (35): Client, Directory, Exception, File, AudioDownloadException, AudioRepository, _client, _concurrency (+27 more)

### Community 31 - "marks_repository.dart"
Cohesion: 0.12
Nodes (16): ../db/app_database.dart, AppDatabase, bookmarks, _db, highlights, mark, marksForIds, marksForSurah (+8 more)

### Community 32 - "responsive_layout.dart"
Cohesion: 0.07
Nodes (27): AdaptiveSheet, available, bottom, Breakpoints, build, centeredContentPadding, child, compact (+19 more)

### Community 33 - "package:flutter/material.dart"
Cohesion: 0.08
Nodes (26): Container, Directionality, bottomInsetFor, package:flutter/material.dart, package:kuran_turkce_meal/core/notifications/daily_ayah_notifications.dart, package:kuran_turkce_meal/data/models/reader_preferences.dart, package:kuran_turkce_meal/data/models/user_marks.dart, package:kuran_turkce_meal/features/reader/share/ayah_card.dart (+18 more)

### Community 34 - "preferencesProvider"
Cohesion: 0.12
Nodes (23): audioProvider, playingSurahProvider, playSurahProvider, AudioPlayerBar, _Bar, build, _isDayPlaying, nextSurahProvider (+15 more)

### Community 35 - "progress_repository.dart"
Cohesion: 0.11
Nodes (17): allProgress, clearPlanStartDate, completedDayCount, completedDays, _db, ensurePlanStarted, hasCompletionOn, markDayComplete (+9 more)

### Community 36 - "package:easy_localization/easy_localization.dart"
Cohesion: 0.17
Nodes (11): applyBottomSafeArea, _ControlButton, icon, isLoading, isPlaying, onTap, _PlayButton, semanticLabel (+3 more)

### Community 37 - "app_shell.dart"
Cohesion: 0.10
Nodes (20): Animation, ../../features/audio/widgets/audio_player_bar.dart, get, barHeight, build, _buildTab, _controller, createState (+12 more)

### Community 38 - "audio_provider.dart"
Cohesion: 0.06
Nodes (35): AudioPlayer, _attachPlayer, call, currentAyahNumber, dispose, _ensureSession, errorMessage, _finish (+27 more)

### Community 39 - "word_picker_sheet.dart"
Cohesion: 0.14
Nodes (14): ../../../data/models/root.dart, AnalysedWord, verseWordsProvider, ayah, build, entry, _Message, onSelect (+6 more)

### Community 40 - "download_provider.dart"
Cohesion: 0.12
Nodes (16): ../../../data/models/reciter.dart, byId, cancel, _cancelled, delete, download, ensureLoaded, id (+8 more)

### Community 41 - "surah.dart"
Cohesion: 0.12
Nodes (15): ayahCount, fromMap, labelKey, meaning, meaningEn, meaningFor, medine, name (+7 more)

### Community 42 - "StatelessWidget"
Cohesion: 0.06
Nodes (37): audio_download_sheet.dart, ../../../data/models/audio_download.dart, download, _Failure, formatBytes, label, mb, message (+29 more)

### Community 43 - "WidgetStrings"
Cohesion: 0.10
Nodes (21): Foundation, Any, Bool, Date, Int, String, todayDayNumber(), WidgetKeys (+13 more)

### Community 44 - "package:kuran_turkce_meal/core/theme/app_theme.dart"
Cohesion: 0.10
Nodes (19): package:kuran_turkce_meal/core/theme/app_theme.dart, package:kuran_turkce_meal/data/models/surah.dart, package:kuran_turkce_meal/features/home/widgets/home_cards.dart, package:kuran_turkce_meal/features/reader/widgets/surah_end_card.dart, ensureInitialized, main, _surah, _alak (+11 more)

### Community 45 - "Android Density Bucket Ladder"
Cohesion: 0.39
Nodes (8): App Launcher Icon (hdpi, 72x72), Android Density Bucket Ladder, App Launcher Icon (mdpi, 48x48), Missing Adaptive Icon Configuration, App Launcher Icon (xhdpi, 96x96), App Launcher Icon (xxhdpi, 144x144), Unreplaced Flutter Default Branding, App Launcher Icon (xxxhdpi, 192x192)

### Community 46 - "helpers/localized_app.dart"
Cohesion: 0.09
Nodes (23): helpers/localized_app.dart, RootRepository, package:kuran_turkce_meal/data/repositories/root_repository.dart, package:kuran_turkce_meal/features/roots/view/root_detail_screen.dart, package:kuran_turkce_meal/features/roots/view/root_search_screen.dart, package:kuran_turkce_meal/features/roots/widgets/root_highlight.dart, package:kuran_turkce_meal/features/roots/widgets/word_picker_sheet.dart, ensureInitialized (+15 more)

### Community 47 - "ayah_card_render_test.dart"
Cohesion: 0.15
Nodes (12): await, BuildContext, context, done, future, main, pumpWidget, _render (+4 more)

### Community 48 - "root_detail_screen.dart"
Cohesion: 0.08
Nodes (29): ConsumerWidget, AppShell, PlansScreen, rootDetailProvider, ayahs, build, detail, focusAyah (+21 more)

### Community 49 - "coach_mark.dart"
Cohesion: 0.05
Nodes (38): CustomPainter, body, build, _controller, createState, dispose, _fade, _finish (+30 more)

### Community 50 - "root_search_screen.dart"
Cohesion: 0.10
Nodes (20): ArabicLetter, _buildResults, _controller, createState, dispose, isExpanded, isSelected, letter (+12 more)

### Community 51 - "plan_reader_screen.dart"
Cohesion: 0.05
Nodes (45): ../../audio/providers/audio_provider.dart, ../../audio/widgets/audio_player_bar.dart, ../../audio/widgets/day_download_sheet.dart, planDayMarksProvider, planDayReadingProvider, _advanceToNextDay, build, _buildList (+37 more)

### Community 52 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.09
Nodes (25): CustomPaint, main, package:flutter_riverpod/flutter_riverpod.dart, package:kuran_turkce_meal/core/providers/app_providers.dart, package:kuran_turkce_meal/features/home/providers/home_provider.dart, package:kuran_turkce_meal/features/onboarding/providers/tour_provider.dart, package:kuran_turkce_meal/features/onboarding/widgets/coach_mark.dart, package:kuran_turkce_meal/features/onboarding/widgets/tour_host.dart (+17 more)

### Community 53 - "App Store Marketing Icon (1024x1024, Flutter Logo)"
Cohesion: 0.50
Nodes (5): Default Flutter Logo Branding (Uncustomized App Icon), App Store Marketing Icon (1024x1024, Flutter Logo), Multi-Resolution Raster Icon Strategy, iPhone Notification Icon 20pt @3x, iPhone Home Screen Icon 60pt @3x

### Community 54 - "iOS Launch Image (2x)"
Cohesion: 0.80
Nodes (5): iOS Launch Image (1x), iOS Launch Image (2x), iOS Launch Image (3x), Unbranded Default Launch Screen, iOS @1x/@2x/@3x Scale Variant Asset Pattern

### Community 55 - "iPhone Spotlight Icon 40pt @3x (120x120)"
Cohesion: 0.50
Nodes (4): Spotlight Icon 40pt @2x, iPhone Spotlight Icon 40pt @3x (120x120), iPhone Home Screen Icon 60pt @2x (120x120), iPad Home Screen Icon 76pt @1x

### Community 56 - "WidgetLaunch.kt"
Cohesion: 0.35
Nodes (6): MainActivity, Context, Intent, PendingIntent, WidgetLaunch, AudioServiceActivity

### Community 57 - "Notification Icon 20pt @2x"
Cohesion: 0.67
Nodes (3): iPad Notification Icon 20pt @1x, Notification Icon 20pt @2x, iPad Spotlight Icon 40pt @1x

### Community 58 - "Settings Icon 29pt @2x"
Cohesion: 0.67
Nodes (3): Settings Icon 29pt @1x, Settings Icon 29pt @2x, Settings Icon 29pt @3x

### Community 64 - "root_repository.dart"
Cohesion: 0.08
Nodes (23): allRoots, _arabicPattern, _assetPath, byLetters, _byRoot, _byVerse, ensureLoaded, isLoaded (+15 more)

### Community 65 - "plan_reader_provider.dart"
Cohesion: 0.09
Nodes (22): _apply, ayahs, byNumber, day, dayIndex, days, isEmpty, _load (+14 more)

### Community 66 - "root_provider.dart"
Cohesion: 0.10
Nodes (20): clear, clearLetters, copyWith, isActive, isEmpty, meaning, occurrences, query (+12 more)

### Community 67 - "root.dart"
Cohesion: 0.10
Nodes (20): arabic, ayahNumber, count, fromJson, hasMeaning, lemma, letter, letters (+12 more)

### Community 68 - "tour_host.dart"
Cohesion: 0.10
Nodes (21): coach_mark.dart, tourProvider, build, child, createState, didChangeDependencies, didUpdateWidget, dispose (+13 more)

### Community 69 - "_"
Cohesion: 0.07
Nodes (29): _, amaçlıdır, audioInfo, _audioInfoEn, _audioInfoTr, contactEmail, have, lastUpdated (+21 more)

### Community 70 - "build_roots.py"
Cohesion: 0.17
Nodes (18): align(), load_lemma_tr(), load_morphology(), load_tr_dict(), main(), normalize_letters(), Harekeli lemmayı kabaca Türkçe okunuşa çevirir. Uzun ünlüler ayrıca ele alınır:…, Kökün olası latin yazımlarını üretir. 'rsl', 'rasul' değil — iskelet. (+10 more)

### Community 71 - "reading_plan.dart"
Cohesion: 0.04
Nodes (45): int get, ayahCount, ayahIds, fromMap, id, name, nameEn, nameFor (+37 more)

### Community 72 - "plan_schedule.dart"
Cohesion: 0.04
Nodes (45): bool get, DateTime, AudioDownloadStatus, completedAyahs, copyWith, errorMessage, hasFailed, isDownloading (+37 more)

### Community 73 - "build_privacy_html.dart"
Cohesion: 0.13
Nodes (14): , ../lib/features/legal/data/legal_texts.dart, buffer, charset, escaped, html, _inline, lang (+6 more)

### Community 74 - "ayah_card.dart"
Cohesion: 0.11
Nodes (18): Color get, _accent, appName, arabic, _arabicFontSize, AyahCard, _background, build (+10 more)

### Community 75 - "main.dart"
Cohesion: 0.08
Nodes (25): core/notifications/daily_ayah_notifications.dart, core/router/app_router.dart, core/theme/app_theme.dart, core/widgets_bridge/home_widget_service.dart, core/widgets_bridge/home_widget_sync.dart, features/settings/providers/preferences_provider.dart, homeWidgetSyncProvider, createState (+17 more)

### Community 76 - "reader_advance_test.dart"
Cohesion: 0.14
Nodes (13): ScrollController, ScrollNotification, advanceCount, _AdvanceDecider, controller, decider, handle, isDragging (+5 more)

### Community 77 - "Mağaza Yayın Bilgileri"
Cohesion: 0.14
Nodes (13): Alt başlık (App Store — en fazla 30 karakter), Anahtar kelimeler (App Store — en fazla 100 karakter), App Store Connect — App Privacy, Ekran görüntüsü listesi, Gizlilik formu cevapları, Gizlilik politikası bağlantısı, Google Play — Data safety, İnceleme notu (App Review Notes) (+5 more)

### Community 78 - "package:flutter/services.dart"
Cohesion: 0.15
Nodes (13): dart:convert, PlanDayMarksNotifier, SurahMarksNotifier, Map, package:flutter/services.dart, ayahCountByNumber, ensureInitialized, main (+5 more)

### Community 79 - "bookmarks_screen.dart"
Cohesion: 0.14
Nodes (13): SavedEntry, SavedTab, _emptyFor, entry, onChanged, onTap, _SavedRow, selected (+5 more)

### Community 80 - "home_widget_data.dart"
Cohesion: 0.08
Nodes (24): androidPackage, ayahLabel, continueReading, ContinueReadingWidgetData, current, dailyAyah, dailyAyahPool, DailyAyahWidgetData (+16 more)

### Community 81 - "Color"
Cohesion: 0.22
Nodes (12): ColorScheme, ContinueWidgetView, .body, .homeScreen, .lockScreenRectangular, .progressBar, .homeScreen, .homeScreen (+4 more)

### Community 82 - "splash_screen.dart"
Cohesion: 0.13
Nodes (14): AnimationController, ../../../core/theme/app_colors.dart, build, _controller, createState, dispose, _goNext, _holdTimer (+6 more)

### Community 83 - "../../../shared/widgets/responsive_layout.dart"
Cohesion: 0.22
Nodes (8): body, _bodyStyle, build, _inline, LegalDocumentScreen, _render, title, ../../../shared/widgets/responsive_layout.dart

### Community 84 - "static const"
Cohesion: 0.25
Nodes (7): _diacriticFolding, normalize, SearchNormalizer, _stopWords, toFtsQuery, _turkishLowercase, static const

### Community 85 - "prophet_repository.dart"
Cohesion: 0.15
Nodes (12): Future, all, _assetPath, byId, byName, ensureLoaded, isLoaded, _load (+4 more)

### Community 86 - "ayah_card_renderer.dart"
Cohesion: 0.20
Nodes (9): dart:async, dart:typed_data, dart:ui, AyahCardRenderer, _capture, _paintedBoundary, _renderTimeout, toPng (+1 more)

### Community 87 - "VoidCallback?"
Cohesion: 0.18
Nodes (10): PlanDay, build, _CompletedBadge, day, isCompleted, nextDay, onContinue, PlanDayEndCard (+2 more)

### Community 88 - "screens_preview.dart"
Cohesion: 0.25
Nodes (8): ThemeMode, build, createState, main, _mode, prefs, _Preview, _PreviewState

### Community 89 - "localized_app.dart"
Cohesion: 0.22
Nodes (8): static int, ensureInitialized, _instance, pump, reset, TestApp, wrap, wrapRouter

### Community 90 - "empty_state.dart"
Cohesion: 0.25
Nodes (7): IconData, action, build, EmptyState, icon, message, title

### Community 92 - "State"
Cohesion: 0.23
Nodes (13): _NavItem, _NavItemState, CoachMarkOverlay, _CoachMarkOverlayState, NoteEditorSheet, _NoteEditorSheetState, SplashScreen, _SplashScreenState (+5 more)

### Community 93 - "prophet_data_test.dart"
Cohesion: 0.25
Nodes (7): package:kuran_turkce_meal/data/models/prophet.dart, package:kuran_turkce_meal/data/repositories/prophet_repository.dart, ayahsById, ensureInitialized, main, prophets, surahs

### Community 94 - "ContinueReadingWidget"
Cohesion: 0.11
Nodes (22): ContinueReadingWidget, .body, .supportedFamilies, WidgetConfiguration, WidgetFamily, DailyAyahWidget, .body, .supportedFamilies (+14 more)

### Community 95 - "daily_ayah_notifications.dart"
Cohesion: 0.12
Nodes (15): cancel, _channelId, DailyAyahNotifications, init, _initialized, initialRoute, instance, _nextInstanceOf (+7 more)

### Community 96 - "build_prophets.py"
Cohesion: 0.47
Nodes (5): build_regex(), load(), main(), Ad varyantlarını tek bir kelime-sınırlı desende birleştirir., Meal metninden peygamber-ayet eşleştirmesi üretir. Kullanım: python3…

### Community 97 - "home_widget_service.dart"
Cohesion: 0.13
Nodes (14): @visibleForTesting, home_widget_keys.dart, HomeWidgetService, init, _initialized, instance, launchRoute, listenForClicks (+6 more)

### Community 98 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.08
Nodes (25): package:flutter_test/flutter_test.dart, package:kuran_turkce_meal/data/models/plan_schedule.dart, package:kuran_turkce_meal/data/models/reading_plan.dart, package:kuran_turkce_meal/features/legal/data/legal_texts.dart, package:kuran_turkce_meal/features/legal/view/legal_document_screen.dart, package:kuran_turkce_meal/features/plans/providers/plans_provider.dart, package:kuran_turkce_meal/features/plans/view/plan_detail_screen.dart, package:kuran_turkce_meal/features/plans/widgets/streak_summary.dart (+17 more)

### Community 99 - "reciter.dart"
Cohesion: 0.15
Nodes (12): all, approximateBytesPerAyah, baseUrl, byId, estimatedBytesFor, fallback, fileName, id (+4 more)

### Community 100 - "Planlar bölümü — geliştirme promptları"
Cohesion: 0.22
Nodes (8): Ortak bağlam (her promptun başına ekleyin), Planlar bölümü — geliştirme promptları, PROMPT 1 — Seri (streak) ve aylık takvim görünümü, PROMPT 2 — Plan başlangıç tarihi ve "bugün kaçıncı gün", PROMPT 3 — Plan hatırlatma bildirimi, PROMPT 4 — Gün içi kısmi ilerleme, PROMPT 5 — Esnek plan süresi, Sıra neden böyle

### Community 101 - "StreakEntry"
Cohesion: 0.19
Nodes (13): StreakEntry, StreakProvider, StreakWidgetView, .body, .lockScreenCircular, .lockScreenRectangular, Bool, Context (+5 more)

### Community 102 - "home_widget_sync.dart"
Cohesion: 0.14
Nodes (13): home_widget_data.dart, home_widget_service.dart, _collect, _continueReading, _dailyAyahPool, HomeWidgetSync, _inFlight, _ref (+5 more)

### Community 103 - "ContinueEntry"
Cohesion: 0.24
Nodes (10): ContinueEntry, ContinueProvider, Context, Date, Int, String, Timeline, Void (+2 more)

### Community 104 - "audio_ui_test.dart"
Cohesion: 0.09
Nodes (20): package:kuran_turkce_meal/data/models/audio_download.dart, package:kuran_turkce_meal/data/models/ayah.dart, package:kuran_turkce_meal/features/audio/providers/audio_provider.dart, package:kuran_turkce_meal/features/audio/widgets/audio_download_sheet.dart, package:kuran_turkce_meal/features/audio/widgets/audio_player_bar.dart, main, _range, _single (+12 more)

### Community 105 - "WidgetMidnightRefresh.kt"
Cohesion: 0.40
Nodes (6): Context, Intent, PendingIntent, WidgetMidnightRefresh, WidgetMidnightRefreshReceiver, BroadcastReceiver

### Community 106 - "DailyAyahEntry"
Cohesion: 0.21
Nodes (12): DailyAyahEntry, DailyAyahProvider, DailyAyahWidgetView, .body, .lockScreenRectangular, .routePath, Bool, Context (+4 more)

### Community 107 - "ayah_share.dart"
Cohesion: 0.20
Nodes (9): ayah_card.dart, ayah_card_renderer.dart, ../../../data/models/ayah.dart, AyahShare, card, _format, text, package:path_provider/path_provider.dart (+1 more)

### Community 108 - "List"
Cohesion: 0.15
Nodes (11): List, package:kuran_turkce_meal/features/search/data/verse_reference.dart, ensureInitialized, main, parse, resolve, surahs, main (+3 more)

### Community 109 - "app_theme.dart"
Cohesion: 0.25
Nodes (7): app_colors.dart, app_typography.dart, AppTheme, _build, dark, light, static ThemeData get

### Community 111 - "ContinueReadingWidgetProvider"
Cohesion: 0.42
Nodes (5): ContinueReadingWidgetProvider, AppWidgetManager, AppWidgetProvider, Context, IntArray

### Community 112 - "StreakWidgetProvider"
Cohesion: 0.42
Nodes (5): AppWidgetManager, AppWidgetProvider, Context, IntArray, StreakWidgetProvider

### Community 113 - "home_cards.dart"
Cohesion: 0.15
Nodes (12): AyahWithSurah, LastRead, AyahOfTheDayCard, build, ContinueReadingCard, data, lastRead, onChanged (+4 more)

### Community 114 - "search_integration_test.dart"
Cohesion: 0.22
Nodes (7): Database, package:kuran_turkce_meal/data/db/search_normalizer.dart, db, factory, main, search, main

### Community 115 - "return"
Cohesion: 0.33
Nodes (5): return, _block, entries, main, started

### Community 116 - "root_highlight.dart"
Cohesion: 0.17
Nodes (11): TourNotifier, build, fontSize, HighlightedArabic, highlightIndexes, _roundTanween, splitWords, _tanweenTail (+3 more)

### Community 121 - "tour_provider.dart"
Cohesion: 0.25
Nodes (7): hasSeen, markSeen, _prefs, _read, resetAll, storageKey, TourId

### Community 122 - "reader_preferences.dart"
Cohesion: 0.11
Nodes (17): double get, arabicFontSize, autoScrollWithAudio, copyWith, dailyAyahEnabled, dailyAyahHour, dailyAyahMinute, dailyAyahTime (+9 more)

### Community 123 - "home_provider.dart"
Cohesion: 0.08
Nodes (33): AsyncValue, ConsumerState, ../../../data/db/search_normalizer.dart, ayah, ayahNumber, ayahOfTheDayProvider, filteredSurahListProvider, fraction (+25 more)

### Community 124 - "app_shell_test.dart"
Cohesion: 0.20
Nodes (8): AnimatedContainer, package:kuran_turkce_meal/core/router/app_shell.dart, package:kuran_turkce_meal/shared/widgets/tab_bar_inset.dart, ensureInitialized, main, pumpShell, insetIn, main

### Community 125 - "selectedReciterProvider"
Cohesion: 0.39
Nodes (9): ayahSetDownloadProvider, isOnMobileDataProvider, missingAyahCountProvider, selectedReciterProvider, surahDownloadProvider, AudioDownloadSheet, build, build (+1 more)

### Community 126 - "build"
Cohesion: 0.22
Nodes (10): audioRepositoryProvider, downloadedSizeProvider, downloadedSurahsProvider, build, _confirmDeleteAll, _DownloadedAudioTile, Route /gizlilik, Route /kaynaklar (+2 more)

### Community 127 - "state_sync_test.dart"
Cohesion: 0.09
Nodes (20): dart:io, ProgressRepository, package:kuran_turkce_meal/data/db/app_database.dart, package:kuran_turkce_meal/data/repositories/progress_repository.dart, package:kuran_turkce_meal/features/splash/view/splash_screen.dart, package:lottie/lottie.dart, package:path/path.dart, package:sqflite_common_ffi/sqflite_ffi.dart (+12 more)

### Community 130 - "ayah_actions_test.dart"
Cohesion: 0.29
Nodes (6): package:kuran_turkce_meal/core/theme/app_colors.dart, package:kuran_turkce_meal/features/reader/widgets/ayah_actions_sheet.dart, _ayah, ensureInitialized, main, _pump

### Community 131 - "StateNotifier"
Cohesion: 0.31
Nodes (9): AudioDownload, AudioNotifier, AudioState, AyahSetDownloadNotifier, SurahDownloadNotifier, SearchNotifier, SearchState, StateNotifier (+1 more)

### Community 132 - "widget_back_navigation_test.dart"
Cohesion: 0.18
Nodes (9): package:kuran_turkce_meal/core/router/app_router.dart, package:kuran_turkce_meal/core/widgets_bridge/home_widget_data.dart, package:kuran_turkce_meal/core/widgets_bridge/home_widget_keys.dart, package:kuran_turkce_meal/core/widgets_bridge/home_widget_service.dart, Route /sure/2?ayet=255, main, buildRouter, main (+1 more)

### Community 134 - "ConsumerStatefulWidget"
Cohesion: 0.18
Nodes (12): ConsumerStatefulWidget, rootDataProvider, _openDay, _openWordPicker, _openWordPicker, ReaderScreen, rootSearchProvider, build (+4 more)

## Ambiguous Edges - Review These
- `iOS Launch Screen Assets` → `Sıcak Kırık Ton Renk Paleti`  [AMBIGUOUS]
  ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md · relation: conceptually_related_to
- `App Launcher Icon (xhdpi, 96x96)` → `Missing Adaptive Icon Configuration`  [AMBIGUOUS]
  android/app/src/main/res/mipmap-xhdpi/ic_launcher.png · relation: rationale_for

## Knowledge Gaps
- **1422 isolated node(s):** `context`, `result`, `done`, `future`, `main` (+1417 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1659 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `iOS Launch Screen Assets` and `Sıcak Kırık Ton Renk Paleti`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `App Launcher Icon (xhdpi, 96x96)` and `Missing Adaptive Icon Configuration`?**
  _Edge tagged AMBIGUOUS (relation: rationale_for) - confidence is low._
- **Why does `_` connect `_` to `home_widget_sync.dart`, `bookmarks_provider.dart`, `search_screen.dart`, `return`, `package:flutter_riverpod/flutter_riverpod.dart`, `plan_detail_screen.dart`, `surah_end_card.dart`?**
  _High betweenness centrality (0.029) - this node is a cross-community bridge._
- **What connects `context`, `result`, `done` to the rest of the system?**
  _1422 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `lib/features (home, reader, search, plans, bookmarks, settings)` be split into smaller, more focused modules?**
  _Cohesion score 0.05254901960784314 - nodes in this community are weakly interconnected._
- **Should `app_colors.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.08333333333333333 - nodes in this community are weakly interconnected._
- **Should `search_provider.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.07142857142857142 - nodes in this community are weakly interconnected._