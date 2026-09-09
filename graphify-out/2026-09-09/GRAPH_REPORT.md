# Graph Report - kuran_turkce_meal  (2026-09-09)

## Corpus Check
- 226 files · ~725,290 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 2720 nodes · 4142 edges · 151 communities (141 shown, 6 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 95 edges (avg confidence: 0.87)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `f8e88f1b`
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
- package:flutter_riverpod/flutter_riverpod.dart
- reader_settings_sheet.dart
- AppDelegate
- reader_provider.dart
- ayah.dart
- StatelessWidget
- quran_repository.dart
- prophet_ayahs_screen.dart
- WidgetData.kt
- search_screen.dart
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
- helpers/localized_app.dart
- reader_preferences.dart
- progress_repository.dart
- audio_player_bar.dart
- app_shell.dart
- audio_provider.dart
- donate_screen.dart
- download_provider.dart
- surah.dart
- audio_download_sheet.dart
- WidgetStore
- package:kuran_turkce_meal/core/theme/app_theme.dart
- Android Density Bucket Ladder
- root_screens_test.dart
- ayah_card_render_test.dart
- root_detail_screen.dart
- coach_mark.dart
- root_search_screen.dart
- plan_reader_screen.dart
- reader_tour_test.dart
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
- donation_provider.dart
- home_widget_data.dart
- Color
- splash_screen.dart
- ../../../shared/widgets/responsive_layout.dart
- root_navigation_test.dart
- prophet_repository.dart
- static const
- Icons.jsx
- widget_back_navigation_test.dart
- screens_smoke_test.dart
- package.json
- CLAUDE.md
- screens_preview.dart
- prophet_data_test.dart
- StreakWidgetView
- daily_ayah_notifications.dart
- build_prophets.py
- home_widget_service.dart
- package:flutter_test/flutter_test.dart
- verse_reference.dart
- Planlar bölümü — geliştirme promptları
- StreakEntry
- word_picker_sheet.dart
- ContinueEntry
- audio_ui_test.dart
- WidgetMidnightRefresh.kt
- DailyAyahEntry
- ayah_share.dart
- List
- app_theme.dart
- donation_links.dart
- ContinueReadingWidgetProvider
- StreakWidgetProvider
- surah_search_field.dart
- day_download_sheet.dart
- return
- root_highlight.dart
- int?
- SharedPreferences
- String?
- Widget
- core/providers/app_providers.dart
- prophet.dart
- home_provider.dart
- package:flutter/material.dart
- package:shared_preferences/shared_preferences.dart
- deploy
- donation_reminder.dart
- user_marks.dart
- DailyAyahWidget
- bool get
- StateNotifier
- reciter.dart
- surah_row.dart
- ConsumerState
- @visibleForTesting
- home_cards.dart
- preferencesProvider
- Kur'an Meal — tanıtım sitesi
- WidgetStrings
- notification_bootstrap_test.dart
- selectedReciterProvider
- .oxlintrc.json
- VoidCallback?
- splash_test.dart
- App Store Connect — Türkçe metinler
- build
- theme_test.dart
- HomeScreen
- tourProvider
- BookmarksScreen

## God Nodes (most connected - your core abstractions)
1. `_` - 43 edges
2. `_` - 33 edges
3. `WidgetStrings` - 22 edges
4. `preferencesProvider` - 16 edges
5. `StreakEntry` - 13 edges
6. `useDemoStore` - 13 edges
7. `ContinueEntry` - 12 edges
8. `donationProvider` - 12 edges
9. `DailyAyahEntry` - 11 edges
10. `WidgetStore` - 10 edges

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

## Communities (151 total, 6 thin omitted)

### Community 0 - "lib/features (home, reader, search, plans, bookmarks, settings)"
Cohesion: 0.05
Nodes (51): Dart Analyzer Yapılandırması, tool/** Analiz Dışı Bırakma, iOS Launch Screen Assets, Flutter Asset Bildirimi (assets/data, assets/translations), easy_localization ^3.0.8, flutter_lints ^6.0.0 (dev), flutter_riverpod ^2.6.1, go_router ^17.5.0 (+43 more)

### Community 1 - "app_colors.dart"
Cohesion: 0.08
Nodes (23): accentDark, accentLight, AppColors, darkBackground, darkDivider, darkInk, darkInkFaint, darkInkMuted (+15 more)

### Community 2 - "search_provider.dart"
Cohesion: 0.07
Nodes (27): ../data/verse_reference.dart, ayahNumber, clear, copyWith, _debounce, dispose, hasQuery, hasReference (+19 more)

### Community 3 - "preferences_provider.dart"
Cohesion: 0.08
Nodes (24): _kAutoScrollWithAudio, _kDailyAyahEnabled, _kDailyAyahHour, _kDailyAyahMinute, _kFontScale, _kLineHeight, _kPlaybackSpeed, _kReciterId (+16 more)

### Community 4 - "import_meal.dart"
Cohesion: 0.06
Nodes (32): arabic, arabicPath, b, _build, decoded, file, id, _loadSurahs (+24 more)

### Community 5 - "pressable.dart"
Cohesion: 0.12
Nodes (16): BorderRadius?, borderRadius, build, child, createState, _handleLongPress, _handleTap, hapticOnTap (+8 more)

### Community 6 - "reader_screen.dart"
Cohesion: 0.04
Nodes (47): ../../audio/widgets/audio_download_sheet.dart, createState, CupertinoStyleLoader, _didScrollToInitial, dispose, _firstAyahKey, _focusedAyahNumber, _focusTimer (+39 more)

### Community 7 - "bookmarks_provider.dart"
Cohesion: 0.14
Nodes (13): ../../../data/models/user_marks.dart, ayah, ayahById, ayahs, mark, marks, marksRepo, quran (+5 more)

### Community 8 - "app_typography.dart"
Cohesion: 0.07
Nodes (26): AppTypography, emphasized, fast, Insets, lg, md, Motion, normal (+18 more)

### Community 9 - "_"
Cohesion: 0.07
Nodes (38): _, _buildDays, bySurah, calculateStreak, completed, completions, days, endAyah (+30 more)

### Community 10 - "ayah_actions_sheet.dart"
Cohesion: 0.08
Nodes (24): _ActionRow, ayah, AyahActionsSheet, build, color, _ColorDot, _HighlightPicker, icon (+16 more)

### Community 11 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.06
Nodes (39): ../../core/theme/app_typography.dart, ../../donate/providers/donation_provider.dart, ../../donate/widgets/donation_card.dart, GlobalKey?, _emptyFor, entry, onChanged, onTap (+31 more)

### Community 12 - "reader_settings_sheet.dart"
Cohesion: 0.07
Nodes (28): double?, IconData, divisions, icon, isSelected, label, max, maxIcon (+20 more)

### Community 13 - "AppDelegate"
Cohesion: 0.10
Nodes (15): Flutter, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, FlutterSceneDelegate, AppDelegate, Any, Bool (+7 more)

### Community 14 - "reader_provider.dart"
Cohesion: 0.08
Nodes (30): ../../bookmarks/providers/bookmarks_provider.dart, ../../home/providers/home_provider.dart, playSurahProvider, _apply, ayahs, byRevelation, call, _load (+22 more)

### Community 15 - "ayah.dart"
Cohesion: 0.12
Nodes (15): arabic, Ayah, ayahNumber, endAyahNumber, fromMap, id, isRange, numberLabel (+7 more)

### Community 16 - "StatelessWidget"
Cohesion: 0.06
Nodes (41): ../../donate/data/donation_links.dart, ../../donate/widgets/support_banner.dart, _ActionTile, children, _confirmReset, createState, displayValue, divisions (+33 more)

### Community 17 - "quran_repository.dart"
Cohesion: 0.11
Nodes (18): ../db/search_normalizer.dart, ayah, ayahById, ayahOfTheDay, ayahPoolFrom, ayahRange, ayahsByIds, ayahsOfSurah (+10 more)

### Community 18 - "prophet_ayahs_screen.dart"
Cohesion: 0.08
Nodes (27): _AppBar, ayah, _AyahEntry, ayahs, _Body, build, byId, data (+19 more)

### Community 19 - "WidgetData.kt"
Cohesion: 0.11
Nodes (12): DailyAyahTileService, DailyAyahWidgetProvider, AppWidgetManager, AppWidgetProvider, Context, IntArray, Intent, SharedPreferences (+4 more)

### Community 20 - "search_screen.dart"
Cohesion: 0.09
Nodes (21): ../../../data/models/prophet.dart, ReferenceHit, _buildBody, _controller, createState, dispose, _fieldKey, _focusNode (+13 more)

### Community 21 - "app_database.dart"
Cohesion: 0.11
Nodes (18): async, close, _createSchema, _databasesPath, _db, factoryOverride, _fileName, hasContent (+10 more)

### Community 22 - "ayah_tile.dart"
Cohesion: 0.11
Nodes (18): ../../../data/models/reader_preferences.dart, ReaderPreferences, ayah, _AyahHeader, AyahTile, build, highlightColor, isFocused (+10 more)

### Community 23 - "home_widget_keys.dart"
Cohesion: 0.07
Nodes (28): androidContinueProvider, androidDailyAyahProvider, androidStreakProvider, continueAyahLabel, continuePercent, continueRoute, continueSurahName, dailyAyahDayNumber (+20 more)

### Community 24 - "plan_detail_screen.dart"
Cohesion: 0.06
Nodes (35): ../../../data/models/plan_schedule.dart, ../../../data/models/reading_plan.dart, home_widget_service.dart, _collect, _continueReading, _dailyAyahPool, HomeWidgetSync, _inFlight (+27 more)

### Community 25 - "surah_end_card.dart"
Cohesion: 0.13
Nodes (14): build, _CompletionNote, current, isReady, lang, next, nextSurah, _NextSurahTile (+6 more)

### Community 26 - "app_router.dart"
Cohesion: 0.08
Nodes (25): app_shell.dart, ../../features/bookmarks/view/bookmarks_screen.dart, ../../features/donate/view/donate_screen.dart, ../../features/home/view/home_screen.dart, ../../features/legal/data/legal_texts.dart, ../../features/legal/view/legal_document_screen.dart, ../../features/plans/view/plan_detail_screen.dart, ../../features/plans/view/plans_screen.dart (+17 more)

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
Nodes (34): Client, Directory, Exception, File, AudioDownloadException, AudioRepository, _client, _concurrency (+26 more)

### Community 31 - "marks_repository.dart"
Cohesion: 0.12
Nodes (16): ../db/app_database.dart, AppDatabase, bookmarks, _db, highlights, mark, marksForIds, marksForSurah (+8 more)

### Community 32 - "responsive_layout.dart"
Cohesion: 0.07
Nodes (27): AdaptiveSheet, available, bottom, Breakpoints, build, centeredContentPadding, child, compact (+19 more)

### Community 33 - "helpers/localized_app.dart"
Cohesion: 0.08
Nodes (29): Container, Directionality, helpers/localized_app.dart, package:kuran_turkce_meal/core/notifications/daily_ayah_notifications.dart, package:kuran_turkce_meal/data/models/reader_preferences.dart, package:kuran_turkce_meal/data/models/user_marks.dart, package:kuran_turkce_meal/features/reader/share/ayah_card.dart, package:kuran_turkce_meal/features/reader/widgets/ayah_tile.dart (+21 more)

### Community 34 - "reader_preferences.dart"
Cohesion: 0.11
Nodes (17): double get, arabicFontSize, autoScrollWithAudio, copyWith, dailyAyahEnabled, dailyAyahHour, dailyAyahMinute, dailyAyahTime (+9 more)

### Community 35 - "progress_repository.dart"
Cohesion: 0.11
Nodes (17): allProgress, clearPlanStartDate, completedDayCount, completedDays, _db, ensurePlanStarted, hasCompletionOn, markDayComplete (+9 more)

### Community 36 - "audio_player_bar.dart"
Cohesion: 0.14
Nodes (16): audioProvider, playingSurahProvider, applyBottomSafeArea, AudioPlayerBar, _Bar, build, _ControlButton, icon (+8 more)

### Community 37 - "app_shell.dart"
Cohesion: 0.10
Nodes (20): Animation, ../../features/audio/widgets/audio_player_bar.dart, get, barHeight, build, _buildTab, _controller, createState (+12 more)

### Community 38 - "audio_provider.dart"
Cohesion: 0.06
Nodes (35): AudioPlayer, _attachPlayer, call, currentAyahNumber, dispose, _ensureSession, errorMessage, _finish (+27 more)

### Community 39 - "donate_screen.dart"
Cohesion: 0.08
Nodes (28): ConsumerWidget, AppShell, donationProvider, build, channel, _ChannelTile, _confirmDonated, _confirmNever (+20 more)

### Community 40 - "download_provider.dart"
Cohesion: 0.11
Nodes (19): ../../../data/models/reciter.dart, AudioDownload, AyahSetDownloadNotifier, byId, cancel, _cancelled, delete, download (+11 more)

### Community 41 - "surah.dart"
Cohesion: 0.12
Nodes (15): ayahCount, fromMap, labelKey, meaning, meaningEn, meaningFor, medine, name (+7 more)

### Community 42 - "audio_download_sheet.dart"
Cohesion: 0.13
Nodes (14): download, _Failure, formatBytes, label, mb, message, _MobileDataNotice, onCancel (+6 more)

### Community 43 - "WidgetStore"
Cohesion: 0.21
Nodes (9): Foundation, Any, Date, Int, String, todayDayNumber(), WidgetKeys, WidgetStore (+1 more)

### Community 44 - "package:kuran_turkce_meal/core/theme/app_theme.dart"
Cohesion: 0.12
Nodes (15): package:kuran_turkce_meal/core/theme/app_theme.dart, package:kuran_turkce_meal/data/models/surah.dart, package:kuran_turkce_meal/features/home/providers/home_provider.dart, package:kuran_turkce_meal/features/home/widgets/home_cards.dart, package:kuran_turkce_meal/features/reader/widgets/surah_end_card.dart, ensureInitialized, main, _surah (+7 more)

### Community 45 - "Android Density Bucket Ladder"
Cohesion: 0.39
Nodes (8): App Launcher Icon (hdpi, 72x72), Android Density Bucket Ladder, App Launcher Icon (mdpi, 48x48), Missing Adaptive Icon Configuration, App Launcher Icon (xhdpi, 96x96), App Launcher Icon (xxhdpi, 144x144), Unreplaced Flutter Default Branding, App Launcher Icon (xxxhdpi, 192x192)

### Community 46 - "root_screens_test.dart"
Cohesion: 0.12
Nodes (16): RootRepository, package:kuran_turkce_meal/data/repositories/root_repository.dart, package:kuran_turkce_meal/features/roots/view/root_search_screen.dart, package:kuran_turkce_meal/features/roots/widgets/root_highlight.dart, ensureInitialized, main, repo, ensureInitialized (+8 more)

### Community 47 - "ayah_card_render_test.dart"
Cohesion: 0.15
Nodes (12): await, BuildContext, dart:typed_data, context, done, future, main, pumpWidget (+4 more)

### Community 48 - "root_detail_screen.dart"
Cohesion: 0.09
Nodes (25): rootDetailProvider, ayahs, build, detail, focusAyah, focusSurah, _groupByVerse, highlightIndexes (+17 more)

### Community 49 - "coach_mark.dart"
Cohesion: 0.05
Nodes (38): CustomPainter, body, build, _controller, createState, dispose, _fade, _finish (+30 more)

### Community 50 - "root_search_screen.dart"
Cohesion: 0.09
Nodes (21): TourNotifier, _buildResults, _controller, createState, dispose, isExpanded, isSelected, letter (+13 more)

### Community 51 - "plan_reader_screen.dart"
Cohesion: 0.05
Nodes (41): ../../audio/providers/audio_provider.dart, ../../audio/providers/download_provider.dart, ../../audio/widgets/audio_player_bar.dart, ../../audio/widgets/day_download_sheet.dart, planDayMarksProvider, _advanceToNextDay, _buildList, createState (+33 more)

### Community 52 - "reader_tour_test.dart"
Cohesion: 0.09
Nodes (22): CustomPaint, main, package:integration_test/integration_test.dart, package:kuran_turkce_meal/core/providers/app_providers.dart, package:kuran_turkce_meal/features/onboarding/providers/tour_provider.dart, package:kuran_turkce_meal/features/onboarding/widgets/coach_mark.dart, package:kuran_turkce_meal/features/onboarding/widgets/tour_host.dart, package:kuran_turkce_meal/features/reader/providers/reader_provider.dart (+14 more)

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
Nodes (21): QuranRoot, clear, clearLetters, copyWith, isActive, isEmpty, meaning, occurrences (+13 more)

### Community 67 - "root.dart"
Cohesion: 0.10
Nodes (20): arabic, ArabicLetter, ayahNumber, count, fromJson, hasMeaning, lemma, letter (+12 more)

### Community 68 - "tour_host.dart"
Cohesion: 0.12
Nodes (16): coach_mark.dart, build, child, createState, didChangeDependencies, didUpdateWidget, dispose, enabled (+8 more)

### Community 69 - "_"
Cohesion: 0.07
Nodes (31): content or, _, amaçlıdır, audioInfo, _audioInfoEn, _audioInfoTr, contactEmail, have (+23 more)

### Community 70 - "build_roots.py"
Cohesion: 0.17
Nodes (18): align(), load_lemma_tr(), load_morphology(), load_tr_dict(), main(), normalize_letters(), Harekeli lemmayı kabaca Türkçe okunuşa çevirir. Uzun ünlüler ayrıca ele alınır:…, Kökün olası latin yazımlarını üretir. 'rsl', 'rasul' değil — iskelet. (+10 more)

### Community 71 - "reading_plan.dart"
Cohesion: 0.10
Nodes (20): all, ayahCount, ayahIds, ayahsPerDay, byId, copyWith, dayCount, descriptionKey (+12 more)

### Community 72 - "plan_schedule.dart"
Cohesion: 0.09
Nodes (21): a, b, calculateStreak, calendarDaysBetween, completedDays, current, currentDay, dayCount (+13 more)

### Community 73 - "build_privacy_html.dart"
Cohesion: 0.08
Nodes (21): , Database, ../lib/features/legal/data/legal_texts.dart, package:kuran_turkce_meal/data/db/search_normalizer.dart, db, factory, main, search (+13 more)

### Community 74 - "ayah_card.dart"
Cohesion: 0.11
Nodes (18): Color get, _accent, appName, arabic, _arabicFontSize, AyahCard, _background, build (+10 more)

### Community 75 - "main.dart"
Cohesion: 0.05
Nodes (38): core/notifications/daily_ayah_bootstrap.dart, core/router/app_router.dart, core/theme/app_theme.dart, core/widgets_bridge/home_widget_service.dart, core/widgets_bridge/home_widget_sync.dart, daily_ayah_notifications.dart, features/donate/providers/donation_provider.dart, features/donate/providers/donation_reminder.dart (+30 more)

### Community 76 - "reader_advance_test.dart"
Cohesion: 0.14
Nodes (13): ScrollController, ScrollNotification, advanceCount, _AdvanceDecider, controller, decider, handle, isDragging (+5 more)

### Community 77 - "Mağaza Yayın Bilgileri"
Cohesion: 0.14
Nodes (13): Alt başlık (App Store — en fazla 30 karakter), Anahtar kelimeler (App Store — en fazla 100 karakter), App Store Connect — App Privacy, Ekran görüntüsü listesi, Gizlilik formu cevapları, Gizlilik politikası bağlantısı, Google Play — Data safety, İnceleme notu (App Review Notes) (+5 more)

### Community 78 - "package:flutter/services.dart"
Cohesion: 0.15
Nodes (13): dart:convert, PlanDayMarksNotifier, SurahMarksNotifier, Map, package:flutter/services.dart, ayahCountByNumber, ensureInitialized, main (+5 more)

### Community 79 - "donation_provider.dart"
Cohesion: 0.06
Nodes (36): copyWith, _dateOrNull, dismissCard, dismissDays, dismissedForever, dismissForever, DonationNotifier, DonationState (+28 more)

### Community 80 - "home_widget_data.dart"
Cohesion: 0.08
Nodes (24): androidPackage, ayahLabel, continueReading, ContinueReadingWidgetData, current, dailyAyah, dailyAyahPool, DailyAyahWidgetData (+16 more)

### Community 81 - "Color"
Cohesion: 0.27
Nodes (9): ColorScheme, .homeScreen, .progressBar, .homeScreen, .homeScreen, Color, View, WidgetTheme (+1 more)

### Community 82 - "splash_screen.dart"
Cohesion: 0.13
Nodes (14): AnimationController, ../../../core/theme/app_colors.dart, build, _controller, createState, dispose, _goNext, _holdTimer (+6 more)

### Community 83 - "../../../shared/widgets/responsive_layout.dart"
Cohesion: 0.22
Nodes (8): body, _bodyStyle, build, _inline, LegalDocumentScreen, _render, title, ../../../shared/widgets/responsive_layout.dart

### Community 84 - "root_navigation_test.dart"
Cohesion: 0.10
Nodes (18): package:kuran_turkce_meal/core/theme/app_colors.dart, package:kuran_turkce_meal/data/models/ayah.dart, package:kuran_turkce_meal/features/reader/widgets/ayah_actions_sheet.dart, package:kuran_turkce_meal/features/roots/widgets/word_picker_sheet.dart, package:sqflite_common_ffi/sqflite_ffi.dart, _ayah, ensureInitialized, main (+10 more)

### Community 85 - "prophet_repository.dart"
Cohesion: 0.15
Nodes (12): Future, all, _assetPath, byId, byName, ensureLoaded, isLoaded, _load (+4 more)

### Community 86 - "static const"
Cohesion: 0.12
Nodes (15): dart:async, dart:ui, _diacriticFolding, normalize, SearchNormalizer, _stopWords, toFtsQuery, _turkishLowercase (+7 more)

### Community 87 - "Icons.jsx"
Cohesion: 0.05
Nodes (61): react, zustand, App(), featureIcons, base, IconApple(), IconAudio(), IconBack() (+53 more)

### Community 88 - "widget_back_navigation_test.dart"
Cohesion: 0.18
Nodes (9): package:kuran_turkce_meal/core/router/app_router.dart, package:kuran_turkce_meal/core/widgets_bridge/home_widget_data.dart, package:kuran_turkce_meal/core/widgets_bridge/home_widget_keys.dart, package:kuran_turkce_meal/core/widgets_bridge/home_widget_service.dart, Route /sure/2?ayet=255, main, buildRouter, main (+1 more)

### Community 89 - "screens_smoke_test.dart"
Cohesion: 0.05
Nodes (37): AnimatedAlign, AnimatedDefaultTextStyle, Brightness, package:kuran_turkce_meal/core/theme/app_typography.dart, package:kuran_turkce_meal/features/bookmarks/providers/bookmarks_provider.dart, package:kuran_turkce_meal/features/bookmarks/view/bookmarks_screen.dart, package:kuran_turkce_meal/features/plans/view/plans_screen.dart, package:kuran_turkce_meal/features/settings/providers/preferences_provider.dart (+29 more)

### Community 90 - "package.json"
Cohesion: 0.06
Nodes (33): express, oxlint, react-dom, @types/react, @types/react-dom, vite, @vitejs/plugin-react, dependencies (+25 more)

### Community 92 - "screens_preview.dart"
Cohesion: 0.13
Nodes (21): _NavItem, _NavItemState, CoachMarkOverlay, _CoachMarkOverlayState, NoteEditorSheet, _NoteEditorSheetState, _VersionTile, _VersionTileState (+13 more)

### Community 93 - "prophet_data_test.dart"
Cohesion: 0.25
Nodes (7): package:kuran_turkce_meal/data/models/prophet.dart, package:kuran_turkce_meal/data/repositories/prophet_repository.dart, ayahsById, ensureInitialized, main, prophets, surahs

### Community 94 - "StreakWidgetView"
Cohesion: 0.15
Nodes (15): KuranWidgetsBundle, .body, Widget, StreakWidget, .body, .supportedFamilies, StreakWidgetView, .body (+7 more)

### Community 95 - "daily_ayah_notifications.dart"
Cohesion: 0.10
Nodes (20): cancel, cancelDonationReminder, _channelId, DailyAyahNotifications, _donateChannelId, _donateNotificationId, hasPermission, init (+12 more)

### Community 96 - "build_prophets.py"
Cohesion: 0.47
Nodes (5): build_regex(), load(), main(), Ad varyantlarını tek bir kelime-sınırlı desende birleştirir., Meal metninden peygamber-ayet eşleştirmesi üretir. Kullanım: python3…

### Community 97 - "home_widget_service.dart"
Cohesion: 0.14
Nodes (13): home_widget_data.dart, home_widget_keys.dart, HomeWidgetService, init, _initialized, instance, launchRoute, listenForClicks (+5 more)

### Community 98 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.07
Nodes (28): ProgressRepository, package:flutter_test/flutter_test.dart, package:kuran_turkce_meal/data/db/app_database.dart, package:kuran_turkce_meal/data/models/plan_schedule.dart, package:kuran_turkce_meal/data/models/reading_plan.dart, package:kuran_turkce_meal/data/repositories/progress_repository.dart, package:kuran_turkce_meal/features/plans/providers/plans_provider.dart, package:kuran_turkce_meal/features/plans/view/plan_detail_screen.dart (+20 more)

### Community 99 - "verse_reference.dart"
Cohesion: 0.11
Nodes (18): ayahNumber, buffer, _build, byName, folding, foldSurahName, hashCode, isExplicitAyah (+10 more)

### Community 100 - "Planlar bölümü — geliştirme promptları"
Cohesion: 0.22
Nodes (8): Ortak bağlam (her promptun başına ekleyin), Planlar bölümü — geliştirme promptları, PROMPT 1 — Seri (streak) ve aylık takvim görünümü, PROMPT 2 — Plan başlangıç tarihi ve "bugün kaçıncı gün", PROMPT 3 — Plan hatırlatma bildirimi, PROMPT 4 — Gün içi kısmi ilerleme, PROMPT 5 — Esnek plan süresi, Sıra neden böyle

### Community 101 - "StreakEntry"
Cohesion: 0.22
Nodes (11): StreakEntry, StreakProvider, Bool, Context, Date, Int, String, Timeline (+3 more)

### Community 102 - "word_picker_sheet.dart"
Cohesion: 0.14
Nodes (14): ../../../data/models/root.dart, AnalysedWord, verseWordsProvider, ayah, build, entry, _Message, onSelect (+6 more)

### Community 103 - "ContinueEntry"
Cohesion: 0.17
Nodes (16): ContinueEntry, ContinueProvider, ContinueReadingWidget, .body, .supportedFamilies, ContinueWidgetView, .body, .lockScreenRectangular (+8 more)

### Community 104 - "audio_ui_test.dart"
Cohesion: 0.12
Nodes (15): package:kuran_turkce_meal/data/models/audio_download.dart, package:kuran_turkce_meal/features/audio/providers/audio_provider.dart, package:kuran_turkce_meal/features/audio/widgets/audio_download_sheet.dart, package:kuran_turkce_meal/features/audio/widgets/audio_player_bar.dart, main, _range, _single, _ayah (+7 more)

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

### Community 110 - "donation_links.dart"
Cohesion: 0.12
Nodes (15): active, channels, DonationChannel, DonationKind, DonationLinks, enabled, id, isConfigured (+7 more)

### Community 111 - "ContinueReadingWidgetProvider"
Cohesion: 0.42
Nodes (5): ContinueReadingWidgetProvider, AppWidgetManager, AppWidgetProvider, Context, IntArray

### Community 112 - "StreakWidgetProvider"
Cohesion: 0.42
Nodes (5): AppWidgetManager, AppWidgetProvider, Context, IntArray, StreakWidgetProvider

### Community 113 - "surah_search_field.dart"
Cohesion: 0.23
Nodes (11): surahQueryProvider, build, _clear, _controller, createState, dispose, initState, SurahSearchField (+3 more)

### Community 114 - "day_download_sheet.dart"
Cohesion: 0.14
Nodes (13): audio_download_sheet.dart, ../../../data/models/audio_download.dart, dayLabel, download, _Failure, label, _MobileDataNotice, onCancel (+5 more)

### Community 115 - "return"
Cohesion: 0.33
Nodes (5): return, _block, entries, main, started

### Community 116 - "root_highlight.dart"
Cohesion: 0.20
Nodes (9): build, fontSize, HighlightedArabic, highlightIndexes, _roundTanween, splitWords, _tanweenTail, text (+1 more)

### Community 121 - "core/providers/app_providers.dart"
Cohesion: 0.22
Nodes (8): core/providers/app_providers.dart, hasSeen, markSeen, _prefs, _read, resetAll, storageKey, TourId

### Community 122 - "prophet.dart"
Cohesion: 0.20
Nodes (9): int get, ayahCount, ayahIds, fromMap, id, name, nameEn, nameFor (+1 more)

### Community 123 - "home_provider.dart"
Cohesion: 0.13
Nodes (14): AsyncValue, ../../../data/db/search_normalizer.dart, ayah, ayahNumber, fraction, progress, query, quran (+6 more)

### Community 124 - "package:flutter/material.dart"
Cohesion: 0.12
Nodes (14): AnimatedContainer, bottomInsetFor, package:flutter/material.dart, package:kuran_turkce_meal/core/router/app_shell.dart, package:kuran_turkce_meal/features/legal/data/legal_texts.dart, package:kuran_turkce_meal/features/legal/view/legal_document_screen.dart, package:kuran_turkce_meal/shared/widgets/tab_bar_inset.dart, RichText (+6 more)

### Community 125 - "package:shared_preferences/shared_preferences.dart"
Cohesion: 0.10
Nodes (19): package:kuran_turkce_meal/features/donate/data/donation_links.dart, package:kuran_turkce_meal/features/donate/providers/donation_provider.dart, package:kuran_turkce_meal/features/donate/view/donate_screen.dart, package:kuran_turkce_meal/features/donate/widgets/donation_card.dart, package:kuran_turkce_meal/features/donate/widgets/support_banner.dart, package:shared_preferences/shared_preferences.dart, static int, build (+11 more)

### Community 126 - "deploy"
Cohesion: 0.22
Nodes (8): build, buildCommand, builder, deploy, restartPolicyMaxRetries, restartPolicyType, startCommand, $schema

### Community 127 - "donation_reminder.dart"
Cohesion: 0.29
Nodes (6): core/notifications/daily_ayah_notifications.dart, ../data/donation_links.dart, donation_provider.dart, notificationsOn, notifier, ../../settings/providers/preferences_provider.dart

### Community 128 - "user_marks.dart"
Cohesion: 0.14
Nodes (13): DateTime, ayahId, AyahMark, copyWith, fromMap, hasNote, highlightColor, isBookmarked (+5 more)

### Community 129 - "DailyAyahWidget"
Cohesion: 0.40
Nodes (6): DailyAyahWidget, .body, .supportedFamilies, WidgetConfiguration, WidgetFamily, Widget

### Community 130 - "bool get"
Cohesion: 0.17
Nodes (11): bool get, AudioDownloadStatus, completedAyahs, copyWith, errorMessage, hasFailed, isDownloading, isReady (+3 more)

### Community 131 - "StateNotifier"
Cohesion: 0.83
Nodes (4): AudioNotifier, AudioState, StateNotifier, _FakeAudioNotifier

### Community 132 - "reciter.dart"
Cohesion: 0.15
Nodes (12): all, approximateBytesPerAyah, baseUrl, byId, estimatedBytesFor, fallback, fileName, id (+4 more)

### Community 133 - "surah_row.dart"
Cohesion: 0.17
Nodes (11): ../../../data/models/surah.dart, Surah, build, fraction, lastReadAyah, onTap, _ProgressBar, showRevelationOrder (+3 more)

### Community 134 - "ConsumerState"
Cohesion: 0.12
Nodes (19): ConsumerState, ConsumerStatefulWidget, rootDataProvider, _openDay, _openWordPicker, _openWordPicker, ReaderScreen, rootSearchProvider (+11 more)

### Community 135 - "@visibleForTesting"
Cohesion: 0.67
Nodes (3): @visibleForTesting, routeFromUri, debugOverrideChannels

### Community 136 - "home_cards.dart"
Cohesion: 0.15
Nodes (12): AyahWithSurah, LastRead, AyahOfTheDayCard, build, ContinueReadingCard, data, lastRead, onChanged (+4 more)

### Community 137 - "preferencesProvider"
Cohesion: 0.18
Nodes (13): maybeScheduleDonationReminder, planDayReadingProvider, planActionsProvider, _confirmRestart, build, _onPositionsChanged, PlanReaderScreen, _PlanReaderScreenState (+5 more)

### Community 138 - "Kur'an Meal — tanıtım sitesi"
Cohesion: 0.17
Nodes (11): Bağlantılar, Diğer statik barındırıcılar, Durum yönetimi, Ekran mockup'ları, Kur'an Meal — tanıtım sitesi, Railway, Tasarım kaynağı, Veriyi yenileme (+3 more)

### Community 139 - "WidgetStrings"
Cohesion: 0.17
Nodes (12): Bool, WidgetStrings, .continueEmpty, .continueLabel, .dailyAyahLabel, .empty, .isEnglish, .streakDays (+4 more)

### Community 140 - "notification_bootstrap_test.dart"
Cohesion: 0.17
Nodes (11): package:kuran_turkce_meal/core/notifications/daily_ayah_bootstrap.dart, build, createState, done, ensureInitialized, initState, main, pump (+3 more)

### Community 141 - "selectedReciterProvider"
Cohesion: 0.29
Nodes (11): audioRepositoryProvider, ayahSetDownloadProvider, isOnMobileDataProvider, missingAyahCountProvider, selectedReciterProvider, surahDownloadProvider, AudioDownloadSheet, build (+3 more)

### Community 142 - ".oxlintrc.json"
Cohesion: 0.33
Nodes (5): plugins, rules, react/only-export-components, react/rules-of-hooks, $schema

### Community 143 - "VoidCallback?"
Cohesion: 0.20
Nodes (9): build, _CompletedBadge, day, isCompleted, nextDay, onContinue, PlanDayEndCard, pullProgress (+1 more)

### Community 144 - "splash_test.dart"
Cohesion: 0.22
Nodes (8): dart:io, package:kuran_turkce_meal/features/splash/view/splash_screen.dart, package:lottie/lottie.dart, Scaffold, ensureInitialized, main, pumpSplash, _splashDuration

### Community 145 - "App Store Connect — Türkçe metinler"
Cohesion: 0.50
Nodes (3): App Store Connect — Türkçe metinler, Description (4.000), Promotional Text (170)

### Community 146 - "build"
Cohesion: 0.29
Nodes (8): downloadedSizeProvider, downloadedSurahsProvider, build, _DownloadedAudioTile, Route /gizlilik, Route /kaynaklar, Route /kosullar, Route /ses-hakkinda

### Community 147 - "theme_test.dart"
Cohesion: 0.25
Nodes (7): _contrastRatio, darker, l1, l2, lighter, luminance, main

### Community 148 - "HomeScreen"
Cohesion: 0.48
Nodes (7): showDonationCardProvider, ayahOfTheDayProvider, filteredSurahListProvider, lastReadProvider, surahProgressProvider, build, HomeScreen

### Community 149 - "tourProvider"
Cohesion: 0.40
Nodes (5): tourProvider, _finish, TourHost, _TourHostState, SettingsScreen

### Community 150 - "BookmarksScreen"
Cohesion: 0.67
Nodes (4): savedEntriesProvider, savedTabProvider, BookmarksScreen, build

## Ambiguous Edges - Review These
- `iOS Launch Screen Assets` → `Sıcak Kırık Ton Renk Paleti`  [AMBIGUOUS]
  ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md · relation: conceptually_related_to
- `App Launcher Icon (xhdpi, 96x96)` → `Missing Adaptive Icon Configuration`  [AMBIGUOUS]
  android/app/src/main/res/mipmap-xhdpi/ic_launcher.png · relation: rationale_for

## Knowledge Gaps
- **1555 isolated node(s):** `context`, `result`, `done`, `future`, `main` (+1550 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1817 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `iOS Launch Screen Assets` and `Sıcak Kırık Ton Renk Paleti`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `App Launcher Icon (xhdpi, 96x96)` and `Missing Adaptive Icon Configuration`?**
  _Edge tagged AMBIGUOUS (relation: rationale_for) - confidence is low._
- **Why does `DailyAyahWidget` connect `DailyAyahWidget` to `DailyAyahEntry`, `StreakWidgetView`?**
  _High betweenness centrality (0.034) - this node is a cross-community bridge._
- **Why does `ContinueReadingWidget` connect `ContinueEntry` to `DailyAyahWidget`, `StreakWidgetView`?**
  _High betweenness centrality (0.034) - this node is a cross-community bridge._
- **Why does `tool/** Analiz Dışı Bırakma` connect `lib/features (home, reader, search, plans, bookmarks, settings)` to `screens_preview.dart`?**
  _High betweenness centrality (0.033) - this node is a cross-community bridge._
- **What connects `context`, `result`, `done` to the rest of the system?**
  _1555 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `lib/features (home, reader, search, plans, bookmarks, settings)` be split into smaller, more focused modules?**
  _Cohesion score 0.05254901960784314 - nodes in this community are weakly interconnected._