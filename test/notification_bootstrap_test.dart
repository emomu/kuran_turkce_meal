import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/core/notifications/daily_ayah_bootstrap.dart';
import 'package:kuran_turkce_meal/core/providers/app_providers.dart';
import 'package:kuran_turkce_meal/features/settings/providers/preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/localized_app.dart';

/// Açılışta bildirim kaydının tazelenmesi.
///
/// Bu mantık bir hatanın karşılığı: tercih varsayılan olarak açık geldiği
/// için kullanıcı ayarlardaki anahtara hiç dokunmuyor, dolayısıyla bildirim
/// hiç planlanmıyor ve izin hiç istenmiyordu. Ayarlar "açık" gösteriyor,
/// bildirim düşmüyordu.
///
/// Test ortamında bildirim eklentisinin platform kanalı yok; `hasPermission`
/// ve `requestPermission` her zaman `false` döner. Bu yüzden burada
/// doğrulanabilen şey "izinsiz cihazda ne olduğu": tercihin kapatılması ve
/// iznin yalnızca bir kez istenmesi. İznin verildiği yol gerçek cihazda
/// sınanır.
void main() async {
  await TestApp.ensureInitialized();

  setUp(TestApp.reset);

  /// Verilen tercihlerle bir kap kurar ve tazelemeyi çalıştırır.
  Future<ProviderContainer> run(
    WidgetTester tester, {
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues({...prefs});
    final store = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    await _pumpAndRun(tester, container);
    return container;
  }

  testWidgets('izin yokken tercih kapatılır', (tester) async {
    final container = await run(tester, prefs: {'daily_ayah_enabled': true});

    expect(
      container.read(preferencesProvider).dailyAyahEnabled,
      isFalse,
      reason: 'izin alınamadığında açık anahtar bırakılmamalı',
    );
  });

  testWidgets('izin bir kez istenir, sonraki açılışlarda tekrar sorulmaz',
      (tester) async {
    final container = await run(tester, prefs: {'daily_ayah_enabled': true});
    final store = container.read(sharedPreferencesProvider);

    expect(store.getBool('daily_ayah_permission_asked'), isTrue);
  });

  testWidgets('tercih kapalıyken izin hiç istenmez', (tester) async {
    final container = await run(tester, prefs: {'daily_ayah_enabled': false});
    final store = container.read(sharedPreferencesProvider);

    expect(
      store.getBool('daily_ayah_permission_asked'),
      isNull,
      reason: 'bildirim istemeyen kullanıcıya izin penceresi açılmamalı',
    );
    expect(container.read(preferencesProvider).dailyAyahEnabled, isFalse);
  });
}

/// Tazelemeyi bir widget ağacı içinden çalıştırır.
///
/// `refreshDailyAyahNotification` bir [WidgetRef] ister, bu yüzden çağrı
/// gerçek bir tüketici widget'ının içinden yapılmalı.
Future<void> _pumpAndRun(WidgetTester tester, ProviderContainer container) async {
  final done = Completer<void>();

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: _Runner(
        onReady: (ref) async {
          await refreshDailyAyahNotification(ref);
          if (!done.isCompleted) done.complete();
        },
      ),
    ),
  );
  await tester.pump();
  await done.future;
}

class _Runner extends ConsumerStatefulWidget {
  const _Runner({required this.onReady});

  final Future<void> Function(WidgetRef ref) onReady;

  @override
  ConsumerState<_Runner> createState() => _RunnerState();
}

class _RunnerState extends ConsumerState<_Runner> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onReady(ref));
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
