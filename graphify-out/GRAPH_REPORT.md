# Graph Report - kuran_turkce_meal  (2026-09-11)

## Corpus Check
- 263 files · ~765,029 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 3281 nodes · 4957 edges · 185 communities (174 shown, 7 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 98 edges (avg confidence: 0.87)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `5fde016c`
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
- plans_screen.dart
- reader_settings_sheet.dart
- AppDelegate
- reader_provider.dart
- package:flutter_test/flutter_test.dart
- settings_screen.dart
- quran_repository.dart
- prophet_ayahs_screen.dart
- WidgetData.kt
- intent_classifier.dart
- app_database.dart
- ayah_tile.dart
- home_widget_keys.dart
- plan_detail_screen.dart
- surah_end_card.dart
- app_router.dart
- package:flutter/material.dart
- note_editor_sheet.dart
- app_providers.dart
- audio_repository.dart
- marks_repository.dart
- responsive_layout.dart
- helpers/localized_app.dart
- reader_preferences.dart
- progress_repository.dart
- build
- app_shell.dart
- audio_provider.dart
- assistant_intent.dart
- download_provider.dart
- home_provider.dart
- audio_download_sheet.dart
- WidgetStrings
- package:kuran_turkce_meal/core/theme/app_theme.dart
- Android Density Bucket Ladder
- root_navigation_test.dart
- ayah_card_render_test.dart
- root_detail_screen.dart
- coach_mark.dart
- root_search_screen.dart
- plan_reader_screen.dart
- state_sync_test.dart
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
- note_editor_test.dart
- Mağaza Yayın Bilgileri
- assistant_thinking_indicator.dart
- donation_provider.dart
- home_widget_data.dart
- Color
- splash_screen.dart
- search_suggestion_marquee.dart
- ConsumerWidget
- prophet_repository.dart
- static const
- App.jsx
- audioProvider
- screens_smoke_test.dart
- package.json
- CLAUDE.md
- State
- List
- ContinueReadingWidget
- daily_ayah_notifications.dart
- build_prophets.py
- home_widget_service.dart
- plan_streak_ui_test.dart
- return
- Planlar bölümü — geliştirme promptları
- StreakEntry
- assistant_provider.dart
- ContinueEntry
- audio_ui_test.dart
- WidgetMidnightRefresh.kt
- DailyAyahEntry
- assistant_history.dart
- verse_reference_test.dart
- package:flutter/services.dart
- donation_links.dart
- ContinueReadingWidgetProvider
- StreakWidgetProvider
- ConsumerState
- home_widget_sync.dart
- AppDemo.jsx
- root_highlight.dart
- int?
- SharedPreferences
- String?
- Widget
- core/providers/app_providers.dart
- search_integration_test.dart
- assistant_stats.dart
- assistant_screen.dart
- donation_ui_test.dart
- deploy
- donation_reminder.dart
- user_marks.dart
- ../../core/theme/app_typography.dart
- bool get
- StateNotifier
- reciter.dart
- assistant_english_test.dart
- StatelessWidget
- VoidCallback?
- home_cards.dart
- answer_composer.dart
- Kur'an Meal — tanıtım sitesi
- verse_reference.dart
- notification_bootstrap_test.dart
- selectedReciterProvider
- .oxlintrc.json
- turkish_suffix.dart
- assistant_message.dart
- App Store Connect — Türkçe metinler
- assistant_screen_test.dart
- topic_lexicon.dart
- daily_ayah_bootstrap.dart
- Icons.jsx
- ayah.dart
- Screens.jsx
- voice_input_provider.dart
- surah.dart
- assistant_message_bubble.dart
- screen_tours_test.dart
- prophet.dart
- ReaderScreen.jsx
- assistant_ayah_card.dart
- ../../../shared/widgets/responsive_layout.dart
- bookmarks_screen.dart
- assistant_smart_intent_test.dart
- home_screen.dart
- app_theme.dart
- ../../../data/models/ayah.dart
- assistant_intent_test.dart
- reader_advance_test.dart
- surah_search_field.dart
- query_cleaner.dart
- dart:async
- search_screen.dart
- preferencesProvider
- PlanDetailScreen
- result_ranker.dart
- fuzzy_match.dart
- localized_app.dart
- assistant_results_screen.dart
- assistantProvider
- AssistantNotifier
- server.js
- scripts
- _QuranAppState
- tourProvider
- searchProvider
- BookmarksScreen

## God Nodes (most connected - your core abstractions)
1. `_` - 43 edges
2. `_` - 33 edges
3. `WidgetStrings` - 22 edges
4. `preferencesProvider` - 16 edges
5. `AssistantIntent` - 15 edges
6. `StreakEntry` - 13 edges
7. `useDemoStore` - 13 edges
8. `ContinueEntry` - 12 edges
9. `donationProvider` - 12 edges
10. `DailyAyahEntry` - 11 edges

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

## Communities (185 total, 7 thin omitted)

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
Nodes (49): ../../assistant/view/widgets/assistant_fab.dart, ../../audio/widgets/audio_download_sheet.dart, createState, CupertinoStyleLoader, _didScrollToInitial, dispose, _fabClearance, _firstAyahKey (+41 more)

### Community 7 - "bookmarks_provider.dart"
Cohesion: 0.15
Nodes (12): ../../../data/models/user_marks.dart, Surah, ayah, ayahById, ayahs, mark, marks, marksRepo (+4 more)

### Community 8 - "app_typography.dart"
Cohesion: 0.07
Nodes (26): AppTypography, emphasized, fast, Insets, lg, md, Motion, normal (+18 more)

### Community 9 - "_"
Cohesion: 0.07
Nodes (29): _, _buildDays, bySurah, calculateStreak, completed, completions, days, endAyah (+21 more)

### Community 10 - "ayah_actions_sheet.dart"
Cohesion: 0.08
Nodes (24): _ActionRow, ayah, AyahActionsSheet, build, color, _ColorDot, _HighlightPicker, icon (+16 more)

### Community 11 - "plans_screen.dart"
Cohesion: 0.13
Nodes (15): GlobalKey?, planProgressProvider, badgeKey, build, _firstBadgeKey, _firstPlanKey, onTap, order (+7 more)

### Community 12 - "reader_settings_sheet.dart"
Cohesion: 0.09
Nodes (21): double?, divisions, icon, isSelected, label, max, maxIcon, maxLabel (+13 more)

### Community 13 - "AppDelegate"
Cohesion: 0.10
Nodes (15): Flutter, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, FlutterSceneDelegate, AppDelegate, Any, Bool (+7 more)

### Community 14 - "reader_provider.dart"
Cohesion: 0.08
Nodes (30): ../../bookmarks/providers/bookmarks_provider.dart, ../../home/providers/home_provider.dart, playSurahProvider, _apply, ayahs, byRevelation, call, _load (+22 more)

### Community 15 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.06
Nodes (27): package:flutter_test/flutter_test.dart, package:kuran_turkce_meal/core/widgets_bridge/home_widget_data.dart, package:kuran_turkce_meal/core/widgets_bridge/home_widget_keys.dart, package:kuran_turkce_meal/core/widgets_bridge/home_widget_service.dart, package:kuran_turkce_meal/features/assistant/data/assistant_history.dart, package:kuran_turkce_meal/features/assistant/data/assistant_stats.dart, package:kuran_turkce_meal/features/assistant/domain/fuzzy_match.dart, package:kuran_turkce_meal/features/assistant/domain/query_cleaner.dart (+19 more)

### Community 16 - "settings_screen.dart"
Cohesion: 0.06
Nodes (32): ../../donate/data/donation_links.dart, ../../donate/widgets/support_banner.dart, children, _confirmReset, createState, displayValue, divisions, initState (+24 more)

### Community 17 - "quran_repository.dart"
Cohesion: 0.10
Nodes (19): ../db/search_normalizer.dart, ayah, ayahById, ayahOfTheDay, ayahPoolFrom, ayahRange, ayahsByIds, ayahsOfSurah (+11 more)

### Community 18 - "prophet_ayahs_screen.dart"
Cohesion: 0.08
Nodes (27): _AppBar, ayah, _AyahEntry, ayahs, _Body, build, byId, data (+19 more)

### Community 19 - "WidgetData.kt"
Cohesion: 0.11
Nodes (12): DailyAyahTileService, DailyAyahWidgetProvider, AppWidgetManager, AppWidgetProvider, Context, IntArray, Intent, SharedPreferences (+4 more)

### Community 20 - "intent_classifier.dart"
Cohesion: 0.06
Nodes (34): ../data/topic_lexicon.dart, fuzzy_match.dart, classify, _conjunctions, _containsWord, _en, _greetingPatterns, _helpPatterns (+26 more)

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
Cohesion: 0.11
Nodes (17): color, completedDays, completions, day, _DayRow, _Dot, onOpen, onRestart (+9 more)

### Community 25 - "surah_end_card.dart"
Cohesion: 0.12
Nodes (15): ../../../data/models/surah.dart, build, _CompletionNote, current, isReady, lang, next, nextSurah (+7 more)

### Community 26 - "app_router.dart"
Cohesion: 0.08
Nodes (26): app_shell.dart, ../../features/assistant/view/assistant_screen.dart, ../../features/bookmarks/view/bookmarks_screen.dart, ../../features/donate/view/donate_screen.dart, ../../features/home/view/home_screen.dart, ../../features/legal/data/legal_texts.dart, ../../features/legal/view/legal_document_screen.dart, ../../features/plans/view/plan_detail_screen.dart (+18 more)

### Community 27 - "package:flutter/material.dart"
Cohesion: 0.06
Nodes (41): ask, main, openAssistant, main, main, bottomOffset, build, bottomInsetFor (+33 more)

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

### Community 33 - "helpers/localized_app.dart"
Cohesion: 0.06
Nodes (35): Container, Directionality, helpers/localized_app.dart, package:kuran_turkce_meal/core/notifications/daily_ayah_notifications.dart, package:kuran_turkce_meal/core/theme/app_colors.dart, package:kuran_turkce_meal/data/models/ayah.dart, package:kuran_turkce_meal/data/models/reader_preferences.dart, package:kuran_turkce_meal/data/models/user_marks.dart (+27 more)

### Community 34 - "reader_preferences.dart"
Cohesion: 0.12
Nodes (16): arabicFontSize, autoScrollWithAudio, copyWith, dailyAyahEnabled, dailyAyahHour, dailyAyahMinute, dailyAyahTime, fontScale (+8 more)

### Community 35 - "progress_repository.dart"
Cohesion: 0.11
Nodes (17): allProgress, clearPlanStartDate, completedDayCount, completedDays, _db, ensurePlanStarted, hasCompletionOn, markDayComplete (+9 more)

### Community 36 - "build"
Cohesion: 0.29
Nodes (8): downloadedSizeProvider, downloadedSurahsProvider, build, _DownloadedAudioTile, Route /gizlilik, Route /kaynaklar, Route /kosullar, Route /ses-hakkinda

### Community 37 - "app_shell.dart"
Cohesion: 0.10
Nodes (20): ../../features/assistant/view/widgets/assistant_fab.dart, ../../features/audio/widgets/audio_player_bar.dart, get, barHeight, build, _buildTab, _controller, createState (+12 more)

### Community 38 - "audio_provider.dart"
Cohesion: 0.06
Nodes (35): AudioPlayer, _attachPlayer, call, currentAyahNumber, dispose, _ensureSession, errorMessage, _finish (+27 more)

### Community 39 - "assistant_intent.dart"
Cohesion: 0.08
Nodes (24): ayah, ayahNumber, facet, index, intent, IntentResult, isFromLexicon, isSituational (+16 more)

### Community 40 - "download_provider.dart"
Cohesion: 0.12
Nodes (16): ../../../data/models/reciter.dart, byId, cancel, _cancelled, delete, download, ensureLoaded, id (+8 more)

### Community 41 - "home_provider.dart"
Cohesion: 0.12
Nodes (21): AsyncValue, double get, showDonationCardProvider, ayah, ayahNumber, ayahOfTheDayProvider, filteredSurahListProvider, fraction (+13 more)

### Community 42 - "audio_download_sheet.dart"
Cohesion: 0.07
Nodes (27): audio_download_sheet.dart, ../../../data/models/audio_download.dart, download, _Failure, formatBytes, label, mb, message (+19 more)

### Community 43 - "WidgetStrings"
Cohesion: 0.10
Nodes (21): Foundation, Any, Bool, Date, Int, String, todayDayNumber(), WidgetKeys (+13 more)

### Community 44 - "package:kuran_turkce_meal/core/theme/app_theme.dart"
Cohesion: 0.08
Nodes (22): package:kuran_turkce_meal/core/theme/app_theme.dart, package:kuran_turkce_meal/data/models/surah.dart, package:kuran_turkce_meal/features/home/providers/home_provider.dart, package:kuran_turkce_meal/features/home/widgets/home_cards.dart, package:kuran_turkce_meal/features/reader/widgets/surah_end_card.dart, ensureInitialized, main, _surah (+14 more)

### Community 45 - "Android Density Bucket Ladder"
Cohesion: 0.39
Nodes (8): App Launcher Icon (hdpi, 72x72), Android Density Bucket Ladder, App Launcher Icon (mdpi, 48x48), Missing Adaptive Icon Configuration, App Launcher Icon (xhdpi, 96x96), App Launcher Icon (xxhdpi, 144x144), Unreplaced Flutter Default Branding, App Launcher Icon (xxxhdpi, 192x192)

### Community 46 - "root_navigation_test.dart"
Cohesion: 0.09
Nodes (22): RootRepository, package:kuran_turkce_meal/data/repositories/root_repository.dart, package:kuran_turkce_meal/features/roots/view/root_detail_screen.dart, package:kuran_turkce_meal/features/roots/view/root_search_screen.dart, package:kuran_turkce_meal/features/roots/widgets/root_highlight.dart, package:kuran_turkce_meal/features/roots/widgets/word_picker_sheet.dart, ensureInitialized, main (+14 more)

### Community 47 - "ayah_card_render_test.dart"
Cohesion: 0.17
Nodes (11): await, BuildContext, context, done, future, main, pumpWidget, _render (+3 more)

### Community 48 - "root_detail_screen.dart"
Cohesion: 0.09
Nodes (25): rootDetailProvider, ayahs, build, detail, focusAyah, focusSurah, _groupByVerse, highlightIndexes (+17 more)

### Community 49 - "coach_mark.dart"
Cohesion: 0.05
Nodes (38): CustomPainter, body, build, _controller, createState, dispose, _fade, _finish (+30 more)

### Community 50 - "root_search_screen.dart"
Cohesion: 0.06
Nodes (33): ../../../data/models/root.dart, AnalysedWord, verseWordsProvider, _buildResults, _controller, createState, dispose, isExpanded (+25 more)

### Community 51 - "plan_reader_screen.dart"
Cohesion: 0.05
Nodes (41): ../../audio/providers/audio_provider.dart, ../../audio/providers/download_provider.dart, ../../audio/widgets/audio_player_bar.dart, ../../audio/widgets/day_download_sheet.dart, planDayMarksProvider, _advanceToNextDay, _buildList, createState (+33 more)

### Community 52 - "state_sync_test.dart"
Cohesion: 0.07
Nodes (27): dart:io, ProgressRepository, package:kuran_turkce_meal/data/db/app_database.dart, package:kuran_turkce_meal/data/repositories/progress_repository.dart, package:kuran_turkce_meal/features/reader/providers/reader_provider.dart, package:kuran_turkce_meal/features/reader/view/reader_screen.dart, package:kuran_turkce_meal/features/splash/view/splash_screen.dart, package:lottie/lottie.dart (+19 more)

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
Cohesion: 0.13
Nodes (14): , ../lib/features/legal/data/legal_texts.dart, buffer, charset, escaped, html, _inline, lang (+6 more)

### Community 74 - "ayah_card.dart"
Cohesion: 0.11
Nodes (18): Color get, _accent, appName, arabic, _arabicFontSize, AyahCard, _background, build (+10 more)

### Community 75 - "main.dart"
Cohesion: 0.08
Nodes (25): core/notifications/daily_ayah_bootstrap.dart, core/theme/app_theme.dart, core/widgets_bridge/home_widget_service.dart, core/widgets_bridge/home_widget_sync.dart, features/donate/providers/donation_provider.dart, features/donate/providers/donation_reminder.dart, createState, didChangeAppLifecycleState (+17 more)

### Community 76 - "note_editor_test.dart"
Cohesion: 0.10
Nodes (17): AnimatedOpacity, CircularProgressIndicator, package:kuran_turkce_meal/features/assistant/view/widgets/assistant_thinking_indicator.dart, package:kuran_turkce_meal/features/plans/widgets/plan_day_end_card.dart, package:kuran_turkce_meal/features/reader/widgets/note_editor_sheet.dart, main, show, stop (+9 more)

### Community 77 - "Mağaza Yayın Bilgileri"
Cohesion: 0.14
Nodes (13): Alt başlık (App Store — en fazla 30 karakter), Anahtar kelimeler (App Store — en fazla 100 karakter), App Store Connect — App Privacy, Ekran görüntüsü listesi, Gizlilik formu cevapları, Gizlilik politikası bağlantısı, Google Play — Data safety, İnceleme notu (App Review Notes) (+5 more)

### Community 78 - "assistant_thinking_indicator.dart"
Cohesion: 0.10
Nodes (19): Animation, Duration, animation, baseColor, build, _counterThreshold, createState, dispose (+11 more)

### Community 79 - "donation_provider.dart"
Cohesion: 0.05
Nodes (37): copyWith, _dateOrNull, dismissCard, dismissDays, dismissedForever, dismissForever, DonationNotifier, DonationState (+29 more)

### Community 80 - "home_widget_data.dart"
Cohesion: 0.08
Nodes (24): androidPackage, ayahLabel, continueReading, ContinueReadingWidgetData, current, dailyAyah, dailyAyahPool, DailyAyahWidgetData (+16 more)

### Community 81 - "Color"
Cohesion: 0.22
Nodes (12): ColorScheme, ContinueWidgetView, .body, .homeScreen, .lockScreenRectangular, .progressBar, .homeScreen, .homeScreen (+4 more)

### Community 82 - "splash_screen.dart"
Cohesion: 0.13
Nodes (14): AnimationController, ../../../core/theme/app_colors.dart, build, _controller, createState, dispose, _goNext, _holdTimer (+6 more)

### Community 83 - "search_suggestion_marquee.dart"
Cohesion: 0.07
Nodes (28): build, _controller, createRenderObject, createState, dispose, duration, items, label (+20 more)

### Community 84 - "ConsumerWidget"
Cohesion: 0.16
Nodes (15): ConsumerWidget, AppShell, donationProvider, build, _confirmDonated, _confirmNever, DonateScreen, build (+7 more)

### Community 85 - "prophet_repository.dart"
Cohesion: 0.15
Nodes (12): Future, all, _assetPath, byId, byName, ensureLoaded, isLoaded, _load (+4 more)

### Community 86 - "static const"
Cohesion: 0.22
Nodes (8): _diacriticFolding, normalize, SearchNormalizer, _stopWords, toFtsOrQuery, toFtsQuery, _turkishLowercase, static const

### Community 87 - "App.jsx"
Cohesion: 0.12
Nodes (21): react, App(), featureIcons, IconApple(), IconGithub(), IconPlayStore(), IconPlus(), Logo() (+13 more)

### Community 88 - "audioProvider"
Cohesion: 0.40
Nodes (6): audioProvider, playingSurahProvider, AudioPlayerBar, _Bar, build, _isDayPlaying

### Community 89 - "screens_smoke_test.dart"
Cohesion: 0.11
Nodes (18): AnimatedAlign, AnimatedDefaultTextStyle, Brightness, package:kuran_turkce_meal/features/bookmarks/providers/bookmarks_provider.dart, package:kuran_turkce_meal/features/bookmarks/view/bookmarks_screen.dart, ensureInitialized, main, pumpScreen (+10 more)

### Community 90 - "package.json"
Cohesion: 0.08
Nodes (24): oxlint, react-dom, @types/react, @types/react-dom, vite, @vitejs/plugin-react, zustand, dependencies (+16 more)

### Community 92 - "State"
Cohesion: 0.16
Nodes (21): _NavItem, _NavItemState, _MicButton, _MicButtonState, AssistantThinkingIndicator, _AssistantThinkingIndicatorState, CoachMarkOverlay, _CoachMarkOverlayState (+13 more)

### Community 93 - "List"
Cohesion: 0.11
Nodes (16): dart:convert, Ayah, List, package:kuran_turkce_meal/data/repositories/prophet_repository.dart, package:kuran_turkce_meal/features/assistant/data/topic_lexicon.dart, main, ayahsById, ensureInitialized (+8 more)

### Community 94 - "ContinueReadingWidget"
Cohesion: 0.11
Nodes (22): ContinueReadingWidget, .body, .supportedFamilies, WidgetConfiguration, WidgetFamily, DailyAyahWidget, .body, .supportedFamilies (+14 more)

### Community 95 - "daily_ayah_notifications.dart"
Cohesion: 0.10
Nodes (20): cancel, cancelDonationReminder, _channelId, DailyAyahNotifications, _donateChannelId, _donateNotificationId, hasPermission, init (+12 more)

### Community 96 - "build_prophets.py"
Cohesion: 0.27
Nodes (8): build_regex(), load(), main(), Sınır dosyasındaki kimlikleri ve aralıkları denetler. Yazım hatası sessizce…, Ad varyantlarını tek bir kelime-sınırlı desende birleştirir., Meal metninden peygamber-ayet eşleştirmesi üretir. Kullanım: python3…, validate_bounds(), Peygamber kıssalarının ayet sınırları. `build_prophets.py` kıssa listesini meal…

### Community 97 - "home_widget_service.dart"
Cohesion: 0.12
Nodes (16): @visibleForTesting, home_widget_data.dart, home_widget_keys.dart, HomeWidgetService, init, _initialized, instance, launchRoute (+8 more)

### Community 98 - "plan_streak_ui_test.dart"
Cohesion: 0.10
Nodes (18): ReadingStreak, package:kuran_turkce_meal/data/models/plan_schedule.dart, package:kuran_turkce_meal/data/models/reading_plan.dart, package:kuran_turkce_meal/features/plans/providers/plans_provider.dart, package:kuran_turkce_meal/features/plans/view/plan_detail_screen.dart, package:kuran_turkce_meal/features/plans/widgets/streak_summary.dart, ensureInitialized, fakeDays (+10 more)

### Community 99 - "return"
Cohesion: 0.33
Nodes (5): return, _block, entries, main, started

### Community 100 - "Planlar bölümü — geliştirme promptları"
Cohesion: 0.22
Nodes (8): Ortak bağlam (her promptun başına ekleyin), Planlar bölümü — geliştirme promptları, PROMPT 1 — Seri (streak) ve aylık takvim görünümü, PROMPT 2 — Plan başlangıç tarihi ve "bugün kaçıncı gün", PROMPT 3 — Plan hatırlatma bildirimi, PROMPT 4 — Gün içi kısmi ilerleme, PROMPT 5 — Esnek plan süresi, Sıra neden böyle

### Community 101 - "StreakEntry"
Cohesion: 0.19
Nodes (13): StreakEntry, StreakProvider, StreakWidgetView, .body, .lockScreenCircular, .lockScreenRectangular, Bool, Context (+5 more)

### Community 102 - "assistant_provider.dart"
Cohesion: 0.03
Nodes (60): ../data/assistant_history.dart, ../data/assistant_stats.dart, ../domain/intent_classifier.dart, ../domain/result_ranker.dart, _answerFor, _append, ask, assistantStatsProvider (+52 more)

### Community 103 - "ContinueEntry"
Cohesion: 0.24
Nodes (10): ContinueEntry, ContinueProvider, Context, Date, Int, String, Timeline, Void (+2 more)

### Community 104 - "audio_ui_test.dart"
Cohesion: 0.07
Nodes (23): AnimatedContainer, package:kuran_turkce_meal/core/router/app_shell.dart, package:kuran_turkce_meal/data/models/audio_download.dart, package:kuran_turkce_meal/features/audio/providers/audio_provider.dart, package:kuran_turkce_meal/features/audio/widgets/audio_download_sheet.dart, package:kuran_turkce_meal/features/audio/widgets/audio_player_bar.dart, package:kuran_turkce_meal/shared/widgets/tab_bar_inset.dart, ensureInitialized (+15 more)

### Community 105 - "WidgetMidnightRefresh.kt"
Cohesion: 0.40
Nodes (6): Context, Intent, PendingIntent, WidgetMidnightRefresh, WidgetMidnightRefreshReceiver, BroadcastReceiver

### Community 106 - "DailyAyahEntry"
Cohesion: 0.21
Nodes (12): DailyAyahEntry, DailyAyahProvider, DailyAyahWidgetView, .body, .lockScreenRectangular, .routePath, Bool, Context (+4 more)

### Community 107 - "assistant_history.dart"
Cohesion: 0.08
Nodes (24): allAyahIds, AssistantHistory, ayahIds, clear, fromJson, highlightTerms, _intList, isUser (+16 more)

### Community 108 - "verse_reference_test.dart"
Cohesion: 0.33
Nodes (5): package:kuran_turkce_meal/features/search/data/verse_reference.dart, main, names, parse, _resolve

### Community 109 - "package:flutter/services.dart"
Cohesion: 0.15
Nodes (12): PlanDayMarksNotifier, SurahMarksNotifier, Map, package:flutter/services.dart, ayahCountByNumber, ensureInitialized, main, revelationByNumber (+4 more)

### Community 110 - "donation_links.dart"
Cohesion: 0.12
Nodes (15): active, channels, DonationChannel, DonationKind, DonationLinks, enabled, holder, id (+7 more)

### Community 111 - "ContinueReadingWidgetProvider"
Cohesion: 0.42
Nodes (5): ContinueReadingWidgetProvider, AppWidgetManager, AppWidgetProvider, Context, IntArray

### Community 112 - "StreakWidgetProvider"
Cohesion: 0.42
Nodes (5): AppWidgetManager, AppWidgetProvider, Context, IntArray, StreakWidgetProvider

### Community 113 - "ConsumerState"
Cohesion: 0.13
Nodes (17): ConsumerState, ConsumerStatefulWidget, rootDataProvider, _openResults, _openDay, _openWordPicker, PlanReaderScreen, _openWordPicker (+9 more)

### Community 114 - "home_widget_sync.dart"
Cohesion: 0.14
Nodes (13): ../../../data/models/plan_schedule.dart, ../../../data/models/reading_plan.dart, home_widget_service.dart, _collect, _continueReading, _dailyAyahPool, HomeWidgetSync, _inFlight (+5 more)

### Community 115 - "AppDemo.jsx"
Cohesion: 0.13
Nodes (14): IconChevron(), IconPlay(), AppDemo(), PhoneFrame(), PLANS, PlansScreen(), ReadScreen(), ITEMS (+6 more)

### Community 116 - "root_highlight.dart"
Cohesion: 0.17
Nodes (11): TourNotifier, build, fontSize, HighlightedArabic, highlightIndexes, _roundTanween, splitWords, _tanweenTail (+3 more)

### Community 121 - "core/providers/app_providers.dart"
Cohesion: 0.22
Nodes (8): core/providers/app_providers.dart, hasSeen, markSeen, _prefs, _read, resetAll, storageKey, TourId

### Community 122 - "search_integration_test.dart"
Cohesion: 0.22
Nodes (7): Database, package:kuran_turkce_meal/data/db/search_normalizer.dart, db, factory, main, search, main

### Community 123 - "assistant_stats.dart"
Cohesion: 0.12
Nodes (15): AssistantStats, clear, count, fromJson, _key, kind, load, maxEntries (+7 more)

### Community 124 - "assistant_screen.dart"
Cohesion: 0.09
Nodes (22): assistant_results_screen.dart, _controller, createState, didUpdateWidget, dispose, enabled, _focusNode, initState (+14 more)

### Community 125 - "donation_ui_test.dart"
Cohesion: 0.18
Nodes (10): package:kuran_turkce_meal/features/donate/data/donation_links.dart, package:kuran_turkce_meal/features/donate/providers/donation_provider.dart, package:kuran_turkce_meal/features/donate/view/donate_screen.dart, package:kuran_turkce_meal/features/donate/widgets/donation_card.dart, package:kuran_turkce_meal/features/donate/widgets/support_banner.dart, build, main, ensureInitialized (+2 more)

### Community 126 - "deploy"
Cohesion: 0.22
Nodes (8): build, buildCommand, builder, deploy, restartPolicyMaxRetries, restartPolicyType, startCommand, $schema

### Community 127 - "donation_reminder.dart"
Cohesion: 0.22
Nodes (8): core/notifications/daily_ayah_notifications.dart, ../data/donation_links.dart, donation_provider.dart, delay, fireAt, notificationsOn, notifier, ../../settings/providers/preferences_provider.dart

### Community 128 - "user_marks.dart"
Cohesion: 0.14
Nodes (13): DateTime, ayahId, AyahMark, copyWith, fromMap, hasNote, highlightColor, isBookmarked (+5 more)

### Community 129 - "../../core/theme/app_typography.dart"
Cohesion: 0.08
Nodes (22): ../../core/theme/app_typography.dart, IconData, applyBottomSafeArea, _ControlButton, icon, isLoading, isPlaying, onTap (+14 more)

### Community 130 - "bool get"
Cohesion: 0.17
Nodes (11): bool get, AudioDownloadStatus, completedAyahs, copyWith, errorMessage, hasFailed, isDownloading, isReady (+3 more)

### Community 131 - "StateNotifier"
Cohesion: 0.43
Nodes (7): AudioDownload, AudioNotifier, AudioState, AyahSetDownloadNotifier, SurahDownloadNotifier, StateNotifier, _FakeAudioNotifier

### Community 132 - "reciter.dart"
Cohesion: 0.15
Nodes (12): all, approximateBytesPerAyah, baseUrl, byId, estimatedBytesFor, fallback, fileName, id (+4 more)

### Community 133 - "assistant_english_test.dart"
Cohesion: 0.20
Nodes (9): OutOfScopeIntent, TopicIntent, bakara, classifier, classify, composer, kehf, main (+1 more)

### Community 134 - "StatelessWidget"
Cohesion: 0.10
Nodes (23): AssistantFab, channel, _ChannelTile, _DonateHeader, _NoChannels, onDonated, onNever, onTap (+15 more)

### Community 135 - "VoidCallback?"
Cohesion: 0.10
Nodes (19): build, fraction, lastReadAyah, onTap, _ProgressBar, showRevelationOrder, _subtitle, surah (+11 more)

### Community 136 - "home_cards.dart"
Cohesion: 0.15
Nodes (12): AyahWithSurah, LastRead, AyahOfTheDayCard, build, ContinueReadingCard, data, lastRead, onChanged (+4 more)

### Community 137 - "answer_composer.dart"
Cohesion: 0.05
Nodes (38): AssistantAction get, actions, AnswerComposer, ayahs, ComposedAnswer, continuation, _countPhrase, _en (+30 more)

### Community 138 - "Kur'an Meal — tanıtım sitesi"
Cohesion: 0.17
Nodes (11): Bağlantılar, Diğer statik barındırıcılar, Durum yönetimi, Ekran mockup'ları, Kur'an Meal — tanıtım sitesi, Railway, Tasarım kaynağı, Veriyi yenileme (+3 more)

### Community 139 - "verse_reference.dart"
Cohesion: 0.11
Nodes (18): ayahNumber, buffer, _build, byName, folding, foldSurahName, hashCode, isExplicitAyah (+10 more)

### Community 140 - "notification_bootstrap_test.dart"
Cohesion: 0.07
Nodes (24): package:kuran_turkce_meal/core/notifications/daily_ayah_bootstrap.dart, package:kuran_turkce_meal/core/theme/app_typography.dart, package:kuran_turkce_meal/features/settings/providers/preferences_provider.dart, package:kuran_turkce_meal/features/settings/view/settings_screen.dart, package:kuran_turkce_meal/shared/widgets/responsive_layout.dart, SliderTheme, landscape, main (+16 more)

### Community 141 - "selectedReciterProvider"
Cohesion: 0.29
Nodes (11): audioRepositoryProvider, ayahSetDownloadProvider, isOnMobileDataProvider, missingAyahCountProvider, selectedReciterProvider, surahDownloadProvider, AudioDownloadSheet, build (+3 more)

### Community 142 - ".oxlintrc.json"
Cohesion: 0.33
Nodes (5): plugins, rules, react/only-export-components, react/rules-of-hooks, $schema

### Community 143 - "turkish_suffix.dart"
Cohesion: 0.11
Nodes (17): ablative, aboutCommon, accusative, _backVowels, dative, _endsWithConsonant, genitive, _isBack (+9 more)

### Community 144 - "assistant_message.dart"
Cohesion: 0.10
Nodes (20): assistant_intent.dart, actions, allAyahs, AssistantActionKind, author, ayahs, copyWith, followUpQuery (+12 more)

### Community 145 - "App Store Connect — Türkçe metinler"
Cohesion: 0.50
Nodes (3): App Store Connect — Türkçe metinler, Description (4.000), Promotional Text (170)

### Community 146 - "assistant_screen_test.dart"
Cohesion: 0.14
Nodes (13): package:kuran_turkce_meal/data/models/prophet.dart, package:kuran_turkce_meal/features/assistant/data/assistant_intent.dart, package:kuran_turkce_meal/features/assistant/data/assistant_message.dart, package:kuran_turkce_meal/features/assistant/domain/answer_composer.dart, package:kuran_turkce_meal/features/assistant/domain/turkish_suffix.dart, package:kuran_turkce_meal/features/assistant/view/widgets/assistant_message_bubble.dart, bakara, kehf (+5 more)

### Community 147 - "topic_lexicon.dart"
Cohesion: 0.11
Nodes (17): all, byId, concepts, id, isSituational, label, labelEn, labelFor (+9 more)

### Community 148 - "daily_ayah_bootstrap.dart"
Cohesion: 0.15
Nodes (12): daily_ayah_notifications.dart, features/settings/providers/preferences_provider.dart, granted, _kPermissionAsked, notifications, prefs, prefsStore, refreshDailyAyahNotification (+4 more)

### Community 149 - "Icons.jsx"
Cohesion: 0.13
Nodes (17): base, IconAudio(), IconBank(), IconCheck(), IconCoffee(), IconCopy(), IconExternal(), IconHeart() (+9 more)

### Community 150 - "ayah.dart"
Cohesion: 0.14
Nodes (13): arabic, ayahNumber, endAyahNumber, fromMap, id, isRange, numberLabel, reference (+5 more)

### Community 151 - "Screens.jsx"
Cohesion: 0.29
Nodes (8): IconBook(), IconBookmark(), IconCalendar(), IconSearch(), IconSettings(), HeroPhone(), TABS, StatusBar()

### Community 152 - "voice_input_provider.dart"
Cohesion: 0.12
Nodes (17): cancel, copyWith, dispose, _ensureReady, _initialized, isListening, soundLevel, _speech (+9 more)

### Community 153 - "surah.dart"
Cohesion: 0.12
Nodes (15): ayahCount, fromMap, labelKey, meaning, meaningEn, meaningFor, medine, name (+7 more)

### Community 154 - "assistant_message_bubble.dart"
Cohesion: 0.12
Nodes (16): assistant_ayah_card.dart, ../../data/assistant_message.dart, ../../domain/answer_composer.dart, AssistantAction, AssistantMessage, AnswerSection, action, _ActionChip (+8 more)

### Community 155 - "screen_tours_test.dart"
Cohesion: 0.15
Nodes (12): CustomPaint, package:kuran_turkce_meal/features/onboarding/providers/tour_provider.dart, package:kuran_turkce_meal/features/onboarding/widgets/coach_mark.dart, package:kuran_turkce_meal/features/onboarding/widgets/tour_host.dart, package:kuran_turkce_meal/features/plans/view/plans_screen.dart, package:kuran_turkce_meal/features/search/view/search_screen.dart, ensureInitialized, main (+4 more)

### Community 156 - "prophet.dart"
Cohesion: 0.15
Nodes (12): int get, ayahCount, ayahIds, fromMap, hasSeparateMentions, id, mentionCount, mentionIds (+4 more)

### Community 157 - "ReaderScreen.jsx"
Cohesion: 0.29
Nodes (9): IconBack(), IconHeadphones(), IconTextSize(), isRootInAyah(), normalise(), ReaderScreen(), rootKeyFor(), ROOTS (+1 more)

### Community 158 - "assistant_ayah_card.dart"
Cohesion: 0.14
Nodes (13): AnswerAyah, answer, AssistantAyahCard, build, highlightColor, highlightTerms, languageCode, showDivider (+5 more)

### Community 159 - "../../../shared/widgets/responsive_layout.dart"
Cohesion: 0.22
Nodes (8): body, _bodyStyle, build, _inline, LegalDocumentScreen, _render, title, ../../../shared/widgets/responsive_layout.dart

### Community 160 - "bookmarks_screen.dart"
Cohesion: 0.14
Nodes (13): SavedEntry, SavedTab, _emptyFor, entry, onChanged, onTap, _SavedRow, selected (+5 more)

### Community 161 - "assistant_smart_intent_test.dart"
Cohesion: 0.17
Nodes (15): AssistantIntent, GreetingIntent, MultiTopicIntent, OpenResultIntent, ProphetIntent, ReferenceIntent, SameSurahIntent, SaveAyahIntent (+7 more)

### Community 162 - "home_screen.dart"
Cohesion: 0.17
Nodes (11): ../../donate/providers/donation_provider.dart, ../../donate/widgets/donation_card.dart, _ayahOfDayKey, _orderToggleKey, _surahSearchKey, _tourSteps, ../../onboarding/widgets/coach_mark.dart, ../../onboarding/widgets/tour_host.dart (+3 more)

### Community 163 - "app_theme.dart"
Cohesion: 0.25
Nodes (7): app_colors.dart, app_typography.dart, AppTheme, _build, dark, light, static ThemeData get

### Community 164 - "../../../data/models/ayah.dart"
Cohesion: 0.20
Nodes (9): ayah_card.dart, ayah_card_renderer.dart, ../../../data/models/ayah.dart, AyahShare, card, _format, text, package:path_provider/path_provider.dart (+1 more)

### Community 165 - "assistant_intent_test.dart"
Cohesion: 0.22
Nodes (8): HelpIntent, MoreResultsIntent, SurahInfoIntent, classifier, classify, main, prophets, surahs

### Community 166 - "reader_advance_test.dart"
Cohesion: 0.14
Nodes (13): ScrollController, ScrollNotification, advanceCount, _AdvanceDecider, controller, decider, handle, isDragging (+5 more)

### Community 167 - "surah_search_field.dart"
Cohesion: 0.23
Nodes (11): surahQueryProvider, build, _clear, _controller, createState, dispose, initState, SurahSearchField (+3 more)

### Community 168 - "query_cleaner.dart"
Cohesion: 0.17
Nodes (11): clean, CleanedQuery, isEmpty, isStopWord, original, query, QueryCleaner, _stopWords (+3 more)

### Community 169 - "dart:async"
Cohesion: 0.20
Nodes (9): dart:async, dart:typed_data, dart:ui, AyahCardRenderer, _capture, _paintedBoundary, _renderTimeout, toPng (+1 more)

### Community 170 - "search_screen.dart"
Cohesion: 0.08
Nodes (25): ../../../data/models/prophet.dart, ReferenceHit, _buildBody, _controller, createState, dispose, _fieldKey, _focusNode (+17 more)

### Community 171 - "preferencesProvider"
Cohesion: 0.25
Nodes (9): maybeScheduleDonationReminder, planDayReadingProvider, build, _PlanReaderScreenState, _followPlayingAyah, build, ReaderSettingsSheet, preferencesProvider (+1 more)

### Community 172 - "PlanDetailScreen"
Cohesion: 0.31
Nodes (9): planActionsProvider, planCompletionsProvider, planDaysProvider, planScheduleProvider, planStreakProvider, build, _confirmRestart, PlanDetailScreen (+1 more)

### Community 173 - "result_ranker.dart"
Cohesion: 0.25
Nodes (7): ../../data/assistant_intent.dart, ../../../data/db/search_normalizer.dart, _matchCeiling, rank, ResultRanker, _score, _shortTextThreshold

### Community 174 - "fuzzy_match.dart"
Cohesion: 0.29
Nodes (6): distance, FuzzyMatch, isNear, matchesWithSuffix, _min3, toleranceFor

### Community 175 - "localized_app.dart"
Cohesion: 0.22
Nodes (8): static int, ensureInitialized, _instance, pump, reset, TestApp, wrap, wrapRouter

### Community 176 - "assistant_results_screen.dart"
Cohesion: 0.25
Nodes (7): core/router/app_router.dart, AssistantResultsScreen, ayahs, build, languageCode, title, widgets/assistant_ayah_card.dart

### Community 177 - "assistantProvider"
Cohesion: 0.25
Nodes (8): assistantProvider, voiceInputProvider, AssistantScreen, _AssistantScreenState, build, _Composer, _send, _toggleVoice

### Community 179 - "server.js"
Cohesion: 0.33
Nodes (4): express, app, __dirname, dist

### Community 180 - "scripts"
Cohesion: 0.33
Nodes (6): scripts, build, dev, lint, preview, start

### Community 181 - "_QuranAppState"
Cohesion: 0.40
Nodes (5): homeWidgetSyncProvider, QuranApp, _QuranAppState, _syncWidgets, WidgetsBindingObserver

### Community 182 - "tourProvider"
Cohesion: 0.40
Nodes (5): tourProvider, _finish, TourHost, _TourHostState, SettingsScreen

### Community 183 - "searchProvider"
Cohesion: 0.40
Nodes (5): searchProvider, _applySuggestion, build, SearchScreen, _SearchScreenState

### Community 184 - "BookmarksScreen"
Cohesion: 0.67
Nodes (4): savedEntriesProvider, savedTabProvider, BookmarksScreen, build

## Ambiguous Edges - Review These
- `iOS Launch Screen Assets` → `Sıcak Kırık Ton Renk Paleti`  [AMBIGUOUS]
  ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md · relation: conceptually_related_to
- `App Launcher Icon (xhdpi, 96x96)` → `Missing Adaptive Icon Configuration`  [AMBIGUOUS]
  android/app/src/main/res/mipmap-xhdpi/ic_launcher.png · relation: rationale_for

## Knowledge Gaps
- **1957 isolated node(s):** `ask`, `context`, `result`, `done`, `future` (+1952 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 2255 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `iOS Launch Screen Assets` and `Sıcak Kırık Ton Renk Paleti`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `App Launcher Icon (xhdpi, 96x96)` and `Missing Adaptive Icon Configuration`?**
  _Edge tagged AMBIGUOUS (relation: rationale_for) - confidence is low._
- **Why does `_` connect `_` to `return`, `plans_screen.dart`, `PlanDetailScreen`, `home_widget_sync.dart`, `core/providers/app_providers.dart`, `package:flutter/material.dart`, `surah_end_card.dart`?**
  _High betweenness centrality (0.029) - this node is a cross-community bridge._
- **What connects `ask`, `context`, `result` to the rest of the system?**
  _1957 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `lib/features (home, reader, search, plans, bookmarks, settings)` be split into smaller, more focused modules?**
  _Cohesion score 0.05254901960784314 - nodes in this community are weakly interconnected._
- **Should `app_colors.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.08333333333333333 - nodes in this community are weakly interconnected._
- **Should `search_provider.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.07407407407407407 - nodes in this community are weakly interconnected._