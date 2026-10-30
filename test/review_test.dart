import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/features/review/providers/review_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Puan isteğinin ne zaman yapılıp ne zaman susulduğu.
///
/// Eşikler yanlış çalışırsa kullanıcı ya hiç sorulmaz ya da her sure sonunda
/// sorulur; ikincisi okuma akışını bozar.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Verilen geçmişle bir notifier kurar.
  Future<ReviewNotifier> build({
    required int daysAgo,
    required int opens,
    required int milestones,
    Map<String, Object> extra = const {},
  }) async {
    final firstLaunch = DateTime.now().subtract(Duration(days: daysAgo));
    SharedPreferences.setMockInitialValues({
      'review_first_launch': firstLaunch.millisecondsSinceEpoch,
      'review_open_count': opens,
      'review_milestone_count': milestones,
      ...extra,
    });
    return ReviewNotifier(await SharedPreferences.getInstance());
  }

  test('bütün eşikler dolunca istenir', () async {
    final notifier = await build(daysAgo: 7, opens: 10, milestones: 3);
    expect(notifier.shouldRequest(), isTrue);
  });

  test('eşiklerden biri eksikse istenmez', () async {
    expect(
      (await build(daysAgo: 6, opens: 50, milestones: 50)).shouldRequest(),
      isFalse,
    );
    expect(
      (await build(daysAgo: 90, opens: 9, milestones: 50)).shouldRequest(),
      isFalse,
    );
    expect(
      (await build(daysAgo: 90, opens: 50, milestones: 2)).shouldRequest(),
      isFalse,
    );
  });

  test('istendikten sonra bekleme süresi boyunca susulur', () async {
    final notifier = await build(daysAgo: 30, opens: 20, milestones: 5);
    notifier.markRequested();

    expect(notifier.shouldRequest(), isFalse);
    expect(
      notifier.shouldRequest(
        now: DateTime.now().add(
          const Duration(days: ReviewThresholds.cooldownDays - 1),
        ),
      ),
      isFalse,
    );
    expect(
      notifier.shouldRequest(
        now: DateTime.now().add(
          const Duration(days: ReviewThresholds.cooldownDays),
        ),
      ),
      isTrue,
    );
  });

  test('istek sınırı dolunca bir daha istenmez', () async {
    final notifier = await build(
      daysAgo: 900,
      opens: 900,
      milestones: 900,
      extra: {
        'review_request_count': ReviewThresholds.maxRequests,
        'review_last_requested_at': DateTime.now()
            .subtract(const Duration(days: 900))
            .millisecondsSinceEpoch,
      },
    );
    expect(notifier.shouldRequest(), isFalse);
  });

  test('ilk açılış anı bir kez yazılır, sayaçlar kalıcıdır', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final notifier = ReviewNotifier(prefs)
      ..registerAppOpen()
      ..registerMilestone();
    final first = prefs.getInt('review_first_launch');

    notifier.registerAppOpen();

    expect(prefs.getInt('review_first_launch'), first);
    final reloaded = ReviewNotifier(prefs).state;
    expect(reloaded.openCount, 2);
    expect(reloaded.milestoneCount, 1);
  });
}
