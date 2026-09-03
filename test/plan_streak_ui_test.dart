import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/core/providers/app_providers.dart';
import 'package:kuran_turkce_meal/core/theme/app_theme.dart';
import 'package:kuran_turkce_meal/data/models/plan_schedule.dart';
import 'package:kuran_turkce_meal/data/models/reading_plan.dart';
import 'package:kuran_turkce_meal/features/plans/providers/plans_provider.dart';
import 'package:kuran_turkce_meal/features/plans/view/plan_detail_screen.dart';
import 'package:kuran_turkce_meal/features/plans/widgets/streak_summary.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/localized_app.dart';

/// Seri özeti ve aylık takvimin ekranda doğru göründüğünü sınar.
void main() async {
  await TestApp.ensureInitialized();
  setUp(TestApp.reset);

  List<PlanDay> fakeDays() => const [
    PlanDay(index: 1, ayahIds: [1, 2], label: 'Alak 1–2', isCompleted: true),
    PlanDay(index: 2, ayahIds: [3, 4], label: 'Alak 3–4', isCompleted: false),
  ];

  Future<void> pumpDetail(
    WidgetTester tester, {
    ReadingStreak? streak,
    List<DateTime> completions = const [],
    Brightness brightness = Brightness.light,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            planDaysProvider.overrideWith((ref, id) async => fakeDays()),
            planProgressProvider.overrideWith((ref, id) async => 1),
            planScheduleProvider.overrideWith((ref, id) async => null),
            planStreakProvider.overrideWith(
              (ref, id) => streak == null
                  // Hiç tamamlanmayan Future: sağlayıcı "yükleniyor"da
                  // kalır, valueOrNull null döner.
                  ? Completer<ReadingStreak>().future
                  : Future.value(streak),
            ),
            planCompletionsProvider.overrideWith(
              (ref, id) async => completions,
            ),
          ],
          child: TestApp.wrap(
            const PlanDetailScreen(planId: 'mushaf_30'),
            theme: brightness == Brightness.light
                ? AppTheme.light
                : AppTheme.dark,
          ),
        ),
      );
      await tester.pump();
    });
    await tester.pumpAndSettle();
  }

  group('Seri özeti', () {
    testWidgets('seri sıfırken cesaret kırıcı sayaç değil davet gösterilir', (
      tester,
    ) async {
      await pumpDetail(tester, streak: ReadingStreak.empty);

      expect(find.textContaining('İlk gününüzü tamamlayın'), findsOneWidget);
      // Boş sayaç gösterilmemeli.
      expect(find.text('0 gün'), findsNothing);
    });

    testWidgets('seri varken güncel ve en uzun birlikte görünür', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        streak: const ReadingStreak(current: 5, longest: 12),
      );

      expect(find.text('5 gün'), findsOneWidget);
      expect(find.text('En uzun 12 gün'), findsOneWidget);
    });

    testWidgets('seri yüklenmemişken hiç yer tutulmaz', (tester) async {
      await pumpDetail(tester, streak: null);
      expect(find.byType(StreakSummary), findsNothing);
    });
  });
}
