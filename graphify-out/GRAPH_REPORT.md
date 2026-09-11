# Graph Report - kuran_turkce_meal  (2026-09-11)

## Corpus Check
- 278 files · ~3,494,637 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 3468 nodes · 5288 edges · 186 communities (174 shown, 8 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 98 edges (avg confidence: 0.87)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `c94e9e5f`
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
- package:kuran_turkce_meal/core/theme/app_theme.dart
- StatelessWidget
- quran_repository.dart
- prophet_ayahs_screen.dart
- WidgetData.kt
- intent_classifier.dart
- app_database.dart
- ayah_tile.dart
- home_widget_keys.dart
- plan_detail_screen.dart
- topic_ayahs_screen.dart
- app_router.dart
- screens_preview.dart
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
- package:flutter/material.dart
- Android Density Bucket Ladder
- root_navigation_test.dart
- ayah_card_render_test.dart
- root_detail_screen.dart
- coach_mark.dart
- root_search_screen.dart
- plan_reader_screen.dart
- splash_test.dart
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
- Konu promptları
- main.dart
- note_editor_test.dart
- package:easy_localization/easy_localization.dart
- assistant_thinking_indicator.dart
- donation_provider.dart
- home_widget_data.dart
- Color
- splash_screen.dart
- search_suggestion_marquee.dart
- topic.dart
- prophet_repository.dart
- static const
- App.jsx
- word_picker_sheet.dart
- screens_smoke_test.dart
- package.json
- CLAUDE.md
- State
- List
- ContinueReadingWidget
- daily_ayah_notifications.dart
- build_prophets.py
- home_widget_service.dart
- package:flutter_test/flutter_test.dart
- return
- Planlar bölümü — geliştirme promptları
- StreakEntry
- assistant_provider.dart
- ContinueEntry
- package:flutter_riverpod/flutter_riverpod.dart
- WidgetMidnightRefresh.kt
- DailyAyahEntry
- assistant_history.dart
- package:kuran_turkce_meal/features/search/data/verse_reference.dart
- package:flutter/services.dart
- donation_links.dart
- ContinueReadingWidgetProvider
- StreakWidgetProvider
- MaterialPageRoute
- home_widget_sync.dart
- AppDemo.jsx
- root_highlight.dart
- int?
- SharedPreferences
- String?
- Widget
- preferencesProvider
- search_integration_test.dart
- assistant_stats.dart
- assistant_screen.dart
- donation_ui_test.dart
- deploy
- donation_reminder.dart
- user_marks.dart
- audio_player_bar.dart
- bool get
- StateNotifier
- reciter.dart
- assistant_english_test.dart
- donate_screen.dart
- topic_repository.dart
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
- HeroPhone.jsx
- voice_input_provider.dart
- surah.dart
- assistant_message_bubble.dart
- package:shared_preferences/shared_preferences.dart
- prophet.dart
- ReaderScreen.jsx
- assistant_ayah_card.dart
- ../../../shared/widgets/responsive_layout.dart
- discover_screen.dart
- assistant_smart_intent_test.dart
- build_topics.py
- app_theme.dart
- ../../../data/models/ayah.dart
- TopBar.jsx
- reader_advance_test.dart
- surah_search_field.dart
- query_cleaner.dart
- dart:async
- search_result_parts.dart
- ayah_card.dart
- SearchScreen.jsx
- VoidCallback?
- fuzzy_match.dart
- localized_app.dart
- day_download_sheet.dart
- ConsumerState
- surah_end_card.dart
- plan_day_end_card.dart
- PlanDetailScreen
- _QuranAppState
- result_ranker.dart
- HomeScreen
- streak_summary.dart
- AssistantNotifier

## God Nodes (most connected - your core abstractions)
1. `_` - 43 edges
2. `_` - 33 edges
3. `WidgetStrings` - 22 edges
4. `preferencesProvider` - 16 edges
5. `AssistantIntent` - 15 edges
6. `StreakEntry` - 13 edges
7. `useDemoStore` - 13 edges
8. `ContinueEntry` - 12 edges
9. `Ayah` - 12 edges
10. `Surah` - 12 edges

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

## Communities (186 total, 8 thin omitted)

### Community 0 - "lib/features (home, reader, search, plans, bookmarks, settings)"
Cohesion: 0.05
Nodes (51): Dart Analyzer Yapılandırması, tool/** Analiz Dışı Bırakma, iOS Launch Screen Assets, Flutter Asset Bildirimi (assets/data, assets/translations), easy_localization ^3.0.8, flutter_lints ^6.0.0 (dev), flutter_riverpod ^2.6.1, go_router ^17.5.0 (+43 more)

### Community 1 - "app_colors.dart"
Cohesion: 0.07
Nodes (26): accentDark, accentLight, AppColors, darkBackground, darkDivider, darkInk, darkInkFaint, darkInkMuted (+18 more)

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
Cohesion: 0.14
Nodes (15): ../../../data/models/user_marks.dart, ayah, ayahById, ayahs, mark, marks, marksRepo, quran (+7 more)

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
Cohesion: 0.09
Nodes (22): ../../donate/providers/donation_provider.dart, ../../donate/widgets/donation_card.dart, GlobalKey?, _ayahOfDayKey, _orderToggleKey, _surahSearchKey, _tourSteps, badgeKey (+14 more)

### Community 12 - "reader_settings_sheet.dart"
Cohesion: 0.09
Nodes (21): double?, divisions, icon, isSelected, label, max, maxIcon, maxLabel (+13 more)

### Community 13 - "AppDelegate"
Cohesion: 0.10
Nodes (15): Flutter, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, FlutterSceneDelegate, AppDelegate, Any, Bool (+7 more)

### Community 14 - "reader_provider.dart"
Cohesion: 0.11
Nodes (18): ../../bookmarks/providers/bookmarks_provider.dart, ../../home/providers/home_provider.dart, _apply, ayahs, byRevelation, call, _load, quran (+10 more)

### Community 15 - "package:kuran_turkce_meal/core/theme/app_theme.dart"
Cohesion: 0.12
Nodes (15): package:kuran_turkce_meal/core/theme/app_theme.dart, package:kuran_turkce_meal/data/models/surah.dart, package:kuran_turkce_meal/features/home/providers/home_provider.dart, package:kuran_turkce_meal/features/home/widgets/home_cards.dart, package:kuran_turkce_meal/features/reader/widgets/surah_end_card.dart, ensureInitialized, main, _surah (+7 more)

### Community 16 - "StatelessWidget"
Cohesion: 0.06
Nodes (41): ../../donate/data/donation_links.dart, ../../donate/widgets/support_banner.dart, _ActionTile, children, _confirmReset, createState, displayValue, divisions (+33 more)

### Community 17 - "quran_repository.dart"
Cohesion: 0.10
Nodes (19): ../db/search_normalizer.dart, ayah, ayahById, ayahOfTheDay, ayahPoolFrom, ayahRange, ayahsByIds, ayahsOfSurah (+11 more)

### Community 18 - "prophet_ayahs_screen.dart"
Cohesion: 0.08
Nodes (26): _AppBar, ayah, _AyahEntry, ayahs, _Body, build, byId, data (+18 more)

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

### Community 25 - "topic_ayahs_screen.dart"
Cohesion: 0.05
Nodes (44): ../../../core/theme/app_colors.dart, ../../../data/models/topic.dart, ayah, _AyahEntry, _AyahItem, ayahs, _Body, build (+36 more)

### Community 26 - "app_router.dart"
Cohesion: 0.07
Nodes (30): app_shell.dart, ../../features/assistant/view/assistant_screen.dart, ../../features/bookmarks/view/bookmarks_screen.dart, ../../features/discover/view/discover_screen.dart, ../../features/discover/view/prophets_screen.dart, ../../features/discover/view/topic_ayahs_screen.dart, ../../features/discover/view/verse_search_screen.dart, ../../features/donate/view/donate_screen.dart (+22 more)

### Community 27 - "screens_preview.dart"
Cohesion: 0.11
Nodes (15): package:kuran_turkce_meal/core/router/app_router.dart, package:kuran_turkce_meal/core/widgets_bridge/home_widget_data.dart, package:kuran_turkce_meal/core/widgets_bridge/home_widget_keys.dart, package:kuran_turkce_meal/core/widgets_bridge/home_widget_service.dart, Route /sure/2?ayet=255, main, buildRouter, main (+7 more)

### Community 28 - "note_editor_sheet.dart"
Cohesion: 0.11
Nodes (18): FocusNode, ayah, build, _confirmDelete, _controller, createState, dispose, enabled (+10 more)

### Community 29 - "app_providers.dart"
Cohesion: 0.10
Nodes (19): ../../data/db/app_database.dart, ../../data/repositories/audio_repository.dart, ../../data/repositories/marks_repository.dart, ../../data/repositories/progress_repository.dart, ../../data/repositories/prophet_repository.dart, ../../data/repositories/root_repository.dart, ../../../data/repositories/topic_repository.dart, databaseProvider (+11 more)

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
Cohesion: 0.05
Nodes (44): Container, Directionality, helpers/localized_app.dart, package:kuran_turkce_meal/core/notifications/daily_ayah_notifications.dart, package:kuran_turkce_meal/core/theme/app_colors.dart, package:kuran_turkce_meal/data/models/ayah.dart, package:kuran_turkce_meal/data/models/reader_preferences.dart, package:kuran_turkce_meal/data/models/user_marks.dart (+36 more)

### Community 34 - "reader_preferences.dart"
Cohesion: 0.11
Nodes (17): double get, arabicFontSize, autoScrollWithAudio, copyWith, dailyAyahEnabled, dailyAyahHour, dailyAyahMinute, dailyAyahTime (+9 more)

### Community 35 - "progress_repository.dart"
Cohesion: 0.11
Nodes (18): allProgress, clearPlanStartDate, completedDayCount, completedDays, _db, ensurePlanStarted, hasCompletionOn, markDayComplete (+10 more)

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
Cohesion: 0.14
Nodes (13): AsyncValue, ayah, ayahNumber, fraction, progress, query, quran, sortByRevelation (+5 more)

### Community 42 - "audio_download_sheet.dart"
Cohesion: 0.08
Nodes (24): ../../../data/models/surah.dart, Surah, download, _Failure, formatBytes, label, mb, message (+16 more)

### Community 43 - "WidgetStrings"
Cohesion: 0.10
Nodes (21): Foundation, Any, Bool, Date, Int, String, todayDayNumber(), WidgetKeys (+13 more)

### Community 44 - "package:flutter/material.dart"
Cohesion: 0.10
Nodes (17): bottomInsetFor, package:flutter/material.dart, package:kuran_turkce_meal/features/legal/data/legal_texts.dart, package:kuran_turkce_meal/features/legal/view/legal_document_screen.dart, package:kuran_turkce_meal/main.dart, package:kuran_turkce_meal/shared/widgets/pressable.dart, RichText, hitsInteractiveAt (+9 more)

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
Cohesion: 0.07
Nodes (28): core/providers/app_providers.dart, hasSeen, markSeen, _prefs, _read, resetAll, storageKey, TourNotifier (+20 more)

### Community 51 - "plan_reader_screen.dart"
Cohesion: 0.05
Nodes (46): ../../audio/providers/audio_provider.dart, ../../audio/providers/download_provider.dart, ../../audio/widgets/audio_player_bar.dart, ../../audio/widgets/day_download_sheet.dart, planDayMarksProvider, planDayReadingProvider, _advanceToNextDay, build (+38 more)

### Community 52 - "splash_test.dart"
Cohesion: 0.22
Nodes (8): dart:io, package:kuran_turkce_meal/features/splash/view/splash_screen.dart, package:lottie/lottie.dart, Scaffold, ensureInitialized, main, pumpSplash, _splashDuration

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
Cohesion: 0.09
Nodes (21): arabic, ArabicLetter, ayahNumber, count, fromJson, hasMeaning, lemma, letter (+13 more)

### Community 68 - "tour_host.dart"
Cohesion: 0.09
Nodes (22): coach_mark.dart, TourId, tourProvider, build, child, createState, didChangeDependencies, didUpdateWidget (+14 more)

### Community 69 - "_"
Cohesion: 0.07
Nodes (31): content or, _, amaçlıdır, audioInfo, _audioInfoEn, _audioInfoTr, contactEmail, have (+23 more)

### Community 70 - "build_roots.py"
Cohesion: 0.17
Nodes (18): align(), load_lemma_tr(), load_morphology(), load_tr_dict(), main(), normalize_letters(), Harekeli lemmayı kabaca Türkçe okunuşa çevirir. Uzun ünlüler ayrıca ele alınır:…, Kökün olası latin yazımlarını üretir. 'rsl', 'rasul' değil — iskelet. (+10 more)

### Community 71 - "reading_plan.dart"
Cohesion: 0.10
Nodes (19): all, ayahCount, ayahIds, ayahsPerDay, byId, copyWith, dayCount, descriptionKey (+11 more)

### Community 72 - "plan_schedule.dart"
Cohesion: 0.09
Nodes (21): a, b, calculateStreak, calendarDaysBetween, completedDays, current, currentDay, dayCount (+13 more)

### Community 73 - "build_privacy_html.dart"
Cohesion: 0.13
Nodes (14): , ../lib/features/legal/data/legal_texts.dart, buffer, charset, escaped, html, _inline, lang (+6 more)

### Community 74 - "Konu promptları"
Cohesion: 0.10
Nodes (20): Ahiret — #6B4F6B, Ahlak — #7C6545, Bölüm renkleri, Denetim, Dosya adlandırma, Figma iş akışı, Fihrist kartı görselleri — üretim promptları, Hukuk ve Toplum — #5A5A78 (+12 more)

### Community 75 - "main.dart"
Cohesion: 0.08
Nodes (25): core/notifications/daily_ayah_bootstrap.dart, core/theme/app_theme.dart, core/widgets_bridge/home_widget_service.dart, core/widgets_bridge/home_widget_sync.dart, features/donate/providers/donation_provider.dart, features/donate/providers/donation_reminder.dart, createState, didChangeAppLifecycleState (+17 more)

### Community 76 - "note_editor_test.dart"
Cohesion: 0.10
Nodes (17): AnimatedOpacity, CircularProgressIndicator, package:kuran_turkce_meal/features/assistant/view/widgets/assistant_thinking_indicator.dart, package:kuran_turkce_meal/features/plans/widgets/plan_day_end_card.dart, package:kuran_turkce_meal/features/reader/widgets/note_editor_sheet.dart, main, show, stop (+9 more)

### Community 77 - "package:easy_localization/easy_localization.dart"
Cohesion: 0.08
Nodes (30): core/router/app_router.dart, ../../core/theme/app_typography.dart, ../../../data/models/prophet.dart, AssistantFab, bottomOffset, SavedEntry, SavedTab, _emptyFor (+22 more)

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
Cohesion: 0.14
Nodes (13): AnimationController, build, _controller, createState, dispose, _goNext, _holdTimer, initState (+5 more)

### Community 83 - "search_suggestion_marquee.dart"
Cohesion: 0.07
Nodes (28): build, _controller, createRenderObject, createState, dispose, duration, items, label (+20 more)

### Community 84 - "topic.dart"
Cohesion: 0.12
Nodes (15): ayahCount, ayahIds, categoryId, core, coreCount, fromMap, hasScanned, id (+7 more)

### Community 85 - "prophet_repository.dart"
Cohesion: 0.15
Nodes (12): Future, all, _assetPath, byId, byName, ensureLoaded, isLoaded, _load (+4 more)

### Community 86 - "static const"
Cohesion: 0.22
Nodes (8): _diacriticFolding, normalize, SearchNormalizer, _stopWords, toFtsOrQuery, toFtsQuery, _turkishLowercase, static const

### Community 87 - "App.jsx"
Cohesion: 0.13
Nodes (19): react, App(), featureIcons, IconApple(), IconCheck(), IconGithub(), IconLock(), IconPlayStore() (+11 more)

### Community 88 - "word_picker_sheet.dart"
Cohesion: 0.10
Nodes (20): ../../../data/models/root.dart, build, FilterChips, labels, onSelected, selectedIndex, AnalysedWord, verseWordsProvider (+12 more)

### Community 89 - "screens_smoke_test.dart"
Cohesion: 0.06
Nodes (34): AnimatedAlign, Brightness, package:kuran_turkce_meal/features/bookmarks/providers/bookmarks_provider.dart, package:kuran_turkce_meal/features/bookmarks/view/bookmarks_screen.dart, package:kuran_turkce_meal/features/discover/view/discover_screen.dart, package:kuran_turkce_meal/features/plans/view/plans_screen.dart, package:kuran_turkce_meal/features/settings/view/settings_screen.dart, SliverGrid (+26 more)

### Community 90 - "package.json"
Cohesion: 0.06
Nodes (33): express, oxlint, react-dom, @types/react, @types/react-dom, vite, @vitejs/plugin-react, dependencies (+25 more)

### Community 92 - "State"
Cohesion: 0.16
Nodes (21): _NavItem, _NavItemState, _MicButton, _MicButtonState, AssistantThinkingIndicator, _AssistantThinkingIndicatorState, CoachMarkOverlay, _CoachMarkOverlayState (+13 more)

### Community 93 - "List"
Cohesion: 0.13
Nodes (13): Ayah, List, package:kuran_turkce_meal/data/repositories/prophet_repository.dart, ayahsById, ensureInitialized, main, prophets, surahs (+5 more)

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
Cohesion: 0.13
Nodes (14): @visibleForTesting, HomeWidgetService, init, _initialized, instance, launchRoute, listenForClicks, _refresh (+6 more)

### Community 98 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.06
Nodes (31): package:flutter_test/flutter_test.dart, package:kuran_turkce_meal/data/db/app_database.dart, package:kuran_turkce_meal/data/models/plan_schedule.dart, package:kuran_turkce_meal/data/models/reading_plan.dart, package:kuran_turkce_meal/data/repositories/progress_repository.dart, package:kuran_turkce_meal/features/assistant/domain/fuzzy_match.dart, package:kuran_turkce_meal/features/assistant/domain/query_cleaner.dart, package:kuran_turkce_meal/features/plans/providers/plans_provider.dart (+23 more)

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

### Community 104 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.07
Nodes (24): AnimatedContainer, package:flutter_riverpod/flutter_riverpod.dart, package:kuran_turkce_meal/core/router/app_shell.dart, package:kuran_turkce_meal/data/models/audio_download.dart, package:kuran_turkce_meal/features/audio/providers/audio_provider.dart, package:kuran_turkce_meal/features/audio/widgets/audio_download_sheet.dart, package:kuran_turkce_meal/features/audio/widgets/audio_player_bar.dart, package:kuran_turkce_meal/shared/widgets/tab_bar_inset.dart (+16 more)

### Community 105 - "WidgetMidnightRefresh.kt"
Cohesion: 0.40
Nodes (6): Context, Intent, PendingIntent, WidgetMidnightRefresh, WidgetMidnightRefreshReceiver, BroadcastReceiver

### Community 106 - "DailyAyahEntry"
Cohesion: 0.21
Nodes (12): DailyAyahEntry, DailyAyahProvider, DailyAyahWidgetView, .body, .lockScreenRectangular, .routePath, Bool, Context (+4 more)

### Community 107 - "assistant_history.dart"
Cohesion: 0.08
Nodes (24): allAyahIds, AssistantHistory, ayahIds, clear, fromJson, highlightTerms, _intList, isUser (+16 more)

### Community 108 - "package:kuran_turkce_meal/features/search/data/verse_reference.dart"
Cohesion: 0.33
Nodes (5): package:kuran_turkce_meal/features/search/data/verse_reference.dart, main, names, parse, _resolve

### Community 109 - "package:flutter/services.dart"
Cohesion: 0.09
Nodes (21): dart:convert, TopicRepository, PlanDayMarksNotifier, SurahMarksNotifier, Map, package:flutter/services.dart, package:kuran_turkce_meal/data/repositories/topic_repository.dart, package:kuran_turkce_meal/features/assistant/data/topic_lexicon.dart (+13 more)

### Community 110 - "donation_links.dart"
Cohesion: 0.12
Nodes (15): active, channels, DonationChannel, DonationKind, DonationLinks, enabled, holder, id (+7 more)

### Community 111 - "ContinueReadingWidgetProvider"
Cohesion: 0.42
Nodes (5): ContinueReadingWidgetProvider, AppWidgetManager, AppWidgetProvider, Context, IntArray

### Community 112 - "StreakWidgetProvider"
Cohesion: 0.42
Nodes (5): AppWidgetManager, AppWidgetProvider, Context, IntArray, StreakWidgetProvider

### Community 113 - "MaterialPageRoute"
Cohesion: 0.33
Nodes (6): _openResults, _openDay, _openWordPicker, _openWordPicker, MaterialPageRoute, main

### Community 114 - "home_widget_sync.dart"
Cohesion: 0.14
Nodes (13): home_widget_data.dart, home_widget_keys.dart, home_widget_service.dart, _collect, _continueReading, _dailyAyahPool, HomeWidgetSync, _inFlight (+5 more)

### Community 115 - "AppDemo.jsx"
Cohesion: 0.14
Nodes (13): IconChevron(), IconPlay(), AppDemo(), PhoneFrame(), PLANS, PlansScreen(), ReaderScreen(), ReadScreen() (+5 more)

### Community 116 - "root_highlight.dart"
Cohesion: 0.20
Nodes (9): build, fontSize, HighlightedArabic, highlightIndexes, _roundTanween, splitWords, _tanweenTail, text (+1 more)

### Community 121 - "preferencesProvider"
Cohesion: 0.13
Nodes (19): playSurahProvider, maybeScheduleDonationReminder, nextSurahProvider, readerDataProvider, saveProgressProvider, surahMarksProvider, _advanceToNextSurah, build (+11 more)

### Community 122 - "search_integration_test.dart"
Cohesion: 0.22
Nodes (7): Database, package:kuran_turkce_meal/data/db/search_normalizer.dart, db, factory, main, search, main

### Community 123 - "assistant_stats.dart"
Cohesion: 0.12
Nodes (15): AssistantStats, clear, count, fromJson, _key, kind, load, maxEntries (+7 more)

### Community 124 - "assistant_screen.dart"
Cohesion: 0.07
Nodes (31): assistant_results_screen.dart, assistantProvider, voiceInputProvider, build, _Composer, _composerKey, _controller, createState (+23 more)

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

### Community 129 - "audio_player_bar.dart"
Cohesion: 0.12
Nodes (18): audioProvider, playingSurahProvider, applyBottomSafeArea, AudioPlayerBar, _Bar, barHeight, build, _ControlButton (+10 more)

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
Cohesion: 0.13
Nodes (17): GreetingIntent, HelpIntent, MoreResultsIntent, TopicIntent, package:kuran_turkce_meal/features/assistant/domain/intent_classifier.dart, bakara, classifier, classify (+9 more)

### Community 134 - "donate_screen.dart"
Cohesion: 0.07
Nodes (33): ConsumerWidget, prophetDataProvider, AppShell, _Body, _EntryCards, build, ProphetsScreen, donationProvider (+25 more)

### Community 135 - "topic_repository.dart"
Cohesion: 0.14
Nodes (13): all, _assetPath, byId, _categories, ensureLoaded, inCategory, isLoaded, _load (+5 more)

### Community 136 - "home_cards.dart"
Cohesion: 0.17
Nodes (11): AyahWithSurah, LastRead, AyahOfTheDayCard, build, ContinueReadingCard, data, lastRead, onChanged (+3 more)

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
Nodes (24): AnimatedDefaultTextStyle, package:kuran_turkce_meal/core/notifications/daily_ayah_bootstrap.dart, package:kuran_turkce_meal/core/theme/app_typography.dart, package:kuran_turkce_meal/features/settings/providers/preferences_provider.dart, package:kuran_turkce_meal/shared/widgets/responsive_layout.dart, SliderTheme, landscape, main (+16 more)

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
Cohesion: 0.11
Nodes (16): package:kuran_turkce_meal/data/models/prophet.dart, package:kuran_turkce_meal/features/assistant/data/assistant_intent.dart, package:kuran_turkce_meal/features/assistant/data/assistant_message.dart, package:kuran_turkce_meal/features/assistant/domain/answer_composer.dart, package:kuran_turkce_meal/features/assistant/domain/result_ranker.dart, package:kuran_turkce_meal/features/assistant/domain/turkish_suffix.dart, package:kuran_turkce_meal/features/assistant/view/widgets/assistant_message_bubble.dart, bakara (+8 more)

### Community 147 - "topic_lexicon.dart"
Cohesion: 0.11
Nodes (17): all, byId, concepts, id, isSituational, label, labelEn, labelFor (+9 more)

### Community 148 - "daily_ayah_bootstrap.dart"
Cohesion: 0.15
Nodes (12): daily_ayah_notifications.dart, features/settings/providers/preferences_provider.dart, granted, _kPermissionAsked, notifications, prefs, prefsStore, refreshDailyAyahNotification (+4 more)

### Community 149 - "Icons.jsx"
Cohesion: 0.18
Nodes (12): base, IconAudio(), IconBank(), IconCoffee(), IconCopy(), IconExternal(), IconHeart(), IconNote() (+4 more)

### Community 150 - "ayah.dart"
Cohesion: 0.14
Nodes (13): arabic, ayahNumber, endAyahNumber, fromMap, id, isRange, numberLabel, reference (+5 more)

### Community 151 - "HeroPhone.jsx"
Cohesion: 0.27
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

### Community 155 - "package:shared_preferences/shared_preferences.dart"
Cohesion: 0.06
Nodes (32): CustomPaint, ask, main, openAssistant, main, main, build, package:integration_test/integration_test.dart (+24 more)

### Community 156 - "prophet.dart"
Cohesion: 0.15
Nodes (12): int get, ayahCount, ayahIds, fromMap, hasSeparateMentions, id, mentionCount, mentionIds (+4 more)

### Community 157 - "ReaderScreen.jsx"
Cohesion: 0.31
Nodes (8): IconBack(), IconHeadphones(), IconTextSize(), isRootInAyah(), normalise(), rootKeyFor(), ROOTS, Words()

### Community 158 - "assistant_ayah_card.dart"
Cohesion: 0.14
Nodes (13): AnswerAyah, answer, AssistantAyahCard, build, highlightColor, highlightTerms, languageCode, showDivider (+5 more)

### Community 159 - "../../../shared/widgets/responsive_layout.dart"
Cohesion: 0.12
Nodes (14): AssistantResultsScreen, ayahs, build, languageCode, title, body, _bodyStyle, build (+6 more)

### Community 160 - "discover_screen.dart"
Cohesion: 0.04
Nodes (51): topicDataProvider, _applySuggestion, _browseSlivers, build, _categoryIndex, _clear, _controller, count (+43 more)

### Community 161 - "assistant_smart_intent_test.dart"
Cohesion: 0.17
Nodes (15): AssistantIntent, MultiTopicIntent, OpenResultIntent, OutOfScopeIntent, ProphetIntent, ReferenceIntent, SameSurahIntent, SaveAyahIntent (+7 more)

### Community 162 - "build_topics.py"
Cohesion: 0.23
Nodes (10): build_regex(), load(), main(), mutual_related(), Kur'an konu fihristini üretir. Kullanım: python3 tool/build_topics.py #…, Terimleri kelime başı sınırlı tek bir desende birleştirir. Sınır yalnızca BAŞTA…, Veri tutarlılığını üretimden önce denetler. Yazım hatası sessizce kaybolur:…, `related` bağlarını karşılıklı hâle getirir. Elle yazarken tek yön yazmak… (+2 more)

### Community 163 - "app_theme.dart"
Cohesion: 0.25
Nodes (7): app_colors.dart, app_typography.dart, AppTheme, _build, dark, light, static ThemeData get

### Community 164 - "../../../data/models/ayah.dart"
Cohesion: 0.20
Nodes (9): ayah_card.dart, ayah_card_renderer.dart, ../../../data/models/ayah.dart, AyahShare, card, _format, text, package:path_provider/path_provider.dart (+1 more)

### Community 165 - "TopBar.jsx"
Cohesion: 0.27
Nodes (8): zustand, IconMoon(), IconSun(), Logo(), TopBar(), useAppStore, useLang(), useTheme()

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

### Community 170 - "search_result_parts.dart"
Cohesion: 0.12
Nodes (15): ../../../data/repositories/quran_repository.dart, ReferenceHit, build, HighlightedText, hit, maxLines, onTap, prophet (+7 more)

### Community 171 - "ayah_card.dart"
Cohesion: 0.11
Nodes (17): Color get, _accent, appName, arabic, _arabicFontSize, AyahCard, _background, build (+9 more)

### Community 173 - "VoidCallback?"
Cohesion: 0.11
Nodes (16): IconData, build, count, DiscoverEntryCard, hint, icon, onTap, title (+8 more)

### Community 174 - "fuzzy_match.dart"
Cohesion: 0.29
Nodes (6): distance, FuzzyMatch, isNear, matchesWithSuffix, _min3, toleranceFor

### Community 175 - "localized_app.dart"
Cohesion: 0.22
Nodes (8): static int, ensureInitialized, _instance, pump, reset, TestApp, wrap, wrapRouter

### Community 176 - "day_download_sheet.dart"
Cohesion: 0.13
Nodes (14): audio_download_sheet.dart, ../../../data/models/audio_download.dart, dayLabel, download, _Failure, label, _MobileDataNotice, onCancel (+6 more)

### Community 177 - "ConsumerState"
Cohesion: 0.21
Nodes (13): ConsumerState, ConsumerStatefulWidget, rootDataProvider, AssistantScreen, _AssistantScreenState, VerseSearchScreen, _VerseSearchScreenState, rootSearchProvider (+5 more)

### Community 178 - "surah_end_card.dart"
Cohesion: 0.13
Nodes (14): build, _CompletionNote, current, isReady, lang, next, nextSurah, _NextSurahTile (+6 more)

### Community 179 - "plan_day_end_card.dart"
Cohesion: 0.18
Nodes (10): ../../../data/models/reading_plan.dart, PlanDay, build, _CompletedBadge, day, isCompleted, nextDay, onContinue (+2 more)

### Community 180 - "PlanDetailScreen"
Cohesion: 0.25
Nodes (11): planActionsProvider, planCompletionsProvider, planDaysProvider, planProgressProvider, planScheduleProvider, planStreakProvider, build, _confirmRestart (+3 more)

### Community 181 - "_QuranAppState"
Cohesion: 0.40
Nodes (5): homeWidgetSyncProvider, QuranApp, _QuranAppState, _syncWidgets, WidgetsBindingObserver

### Community 182 - "result_ranker.dart"
Cohesion: 0.25
Nodes (7): ../../data/assistant_intent.dart, ../../../data/db/search_normalizer.dart, _matchCeiling, rank, ResultRanker, _score, _shortTextThreshold

### Community 183 - "HomeScreen"
Cohesion: 0.48
Nodes (7): showDonationCardProvider, ayahOfTheDayProvider, filteredSurahListProvider, lastReadProvider, surahProgressProvider, build, HomeScreen

### Community 184 - "streak_summary.dart"
Cohesion: 0.33
Nodes (5): ../../../data/models/plan_schedule.dart, ReadingStreak, build, streak, StreakSummary

## Ambiguous Edges - Review These
- `iOS Launch Screen Assets` → `Sıcak Kırık Ton Renk Paleti`  [AMBIGUOUS]
  ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md · relation: conceptually_related_to
- `App Launcher Icon (xhdpi, 96x96)` → `Missing Adaptive Icon Configuration`  [AMBIGUOUS]
  android/app/src/main/res/mipmap-xhdpi/ic_launcher.png · relation: rationale_for

## Knowledge Gaps
- **2068 isolated node(s):** `ask`, `context`, `result`, `done`, `future` (+2063 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 2380 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **8 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `iOS Launch Screen Assets` and `Sıcak Kırık Ton Renk Paleti`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `App Launcher Icon (xhdpi, 96x96)` and `Missing Adaptive Icon Configuration`?**
  _Edge tagged AMBIGUOUS (relation: rationale_for) - confidence is low._
- **Why does `tool/** Analiz Dışı Bırakma` connect `lib/features (home, reader, search, plans, bookmarks, settings)` to `screens_preview.dart`?**
  _High betweenness centrality (0.031) - this node is a cross-community bridge._
- **What connects `ask`, `context`, `result` to the rest of the system?**
  _2068 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `lib/features (home, reader, search, plans, bookmarks, settings)` be split into smaller, more focused modules?**
  _Cohesion score 0.05254901960784314 - nodes in this community are weakly interconnected._
- **Should `app_colors.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.07407407407407407 - nodes in this community are weakly interconnected._
- **Should `search_provider.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.07407407407407407 - nodes in this community are weakly interconnected._