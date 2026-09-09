import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/core/providers/app_providers.dart';
import 'package:kuran_turkce_meal/features/donate/data/donation_links.dart';
import 'package:kuran_turkce_meal/features/donate/providers/donation_provider.dart';
import 'package:kuran_turkce_meal/features/donate/view/donate_screen.dart';
import 'package:kuran_turkce_meal/features/donate/widgets/donation_card.dart';
import 'package:kuran_turkce_meal/features/donate/widgets/support_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/localized_app.dart';

/// Bağış arayüzü: ekran çizilir mi, kanallar listelenir mi, susturma
/// düğmeleri durumu değiştirir mi.
void main() async {
  await TestApp.ensureInitialized();

  setUp(() async {
    await TestApp.reset();
    // Ekran uzun tutulur: destek sayfası kaydırılabilir bir liste ve
    // varsayılan 800 piksellik test penceresinde alttaki satırlar hiç
    // çizilmiyor — `ListView` tembel çalışır, çizilmemiş satır `find` ile de
    // bulunamaz.
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher
        .implicitView!;
    view.physicalSize = const Size(1200, 4000);
    view.devicePixelRatio = 1.0;
    DonationLinks.debugOverrideChannels(const [
      DonationChannel(
        id: 'buymeacoffee',
        kind: DonationKind.link,
        value: 'https://example.com',
      ),
      DonationChannel(
        id: 'iban',
        kind: DonationKind.copy,
        value: 'TR11 1111 1111 1111 1111 1111 11',
      ),
    ]);
  });

  tearDown(() {
    DonationLinks.debugOverrideChannels(null);
    TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!.reset();
  });

  /// [child]'ı gerçek sağlayıcılarla ve çeviriyle çizer.
  ///
  /// Çeviriler diskten gerçek asenkron I/O ile okunur; `pumpAndSettle` tek
  /// başına yetmez, bu yüzden çizim [TestApp.pump] üzerinden yapılır
  /// (bkz. `helpers/localized_app.dart`). Sağlayıcı kapsamı çeviri
  /// sarmalayıcısının içine değil dışına konur — kapsam ağacın kökünde
  /// durmalı ki testin tuttuğu kap ile widget'ların okuduğu kap aynı olsun.
  Future<ProviderContainer> pump(
    WidgetTester tester,
    Widget child, {
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues({...prefs});
    final instance = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(instance)],
    );
    addTearDown(container.dispose);

    await TestApp.pump(
      tester,
      UncontrolledProviderScope(container: container, child: child),
    );
    return container;
  }

  group('Destek ekranı', () {
    testWidgets('açık kanalları listeler', (tester) async {
      await pump(tester, const DonateScreen());

      expect(find.text('Destek Ol'), findsOneWidget);
      expect(find.text('Buy Me a Coffee'), findsOneWidget);
      expect(find.text('Banka havalesi (IBAN)'), findsOneWidget);
    });

    testWidgets('kapalı kanal listelenmez', (tester) async {
      DonationLinks.debugOverrideChannels(const [
        DonationChannel(
          id: 'papara',
          kind: DonationKind.link,
          value: 'https://example.com',
          enabled: false,
        ),
      ]);
      await pump(tester, const DonateScreen());

      expect(find.text('Papara'), findsNothing);
      // Kanal yoksa kullanıcı boş bir listeyle karşılaşmaz.
      expect(find.text('Şu anda tanımlı bir bağış yolu yok.'), findsOneWidget);
    });

    testWidgets('"zaten destek oldum" hatırlatmaları susturur',
        (tester) async {
      final container = await pump(tester, const DonateScreen());
      expect(container.read(donationProvider).hasDonated, isFalse);

      await tester.tap(find.text('Zaten destek oldum'));
      await tester.pumpAndSettle();

      expect(container.read(donationProvider).hasDonated, isTrue);
      // Susturulmuş durumda düğmelerin yerini bilgilendirme satırı alır.
      expect(find.text('Zaten destek oldum'), findsNothing);
    });

    testWidgets('"bir daha hatırlatma" onay ister', (tester) async {
      final container = await pump(tester, const DonateScreen());

      await tester.tap(find.text('Bir daha hatırlatma'));
      await tester.pumpAndSettle();
      expect(find.text('Hatırlatmalar kapatılsın mı?'), findsOneWidget);

      // Vazgeçilirse durum değişmez.
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(container.read(donationProvider).dismissedForever, isFalse);
    });
  });

  group('Ayarlar afişi', () {
    testWidgets('bağış yapılmamışken davet metnini gösterir', (tester) async {
      await pump(tester, const Scaffold(body: SupportBanner()));
      expect(find.text('Destek ol'), findsOneWidget);
    });

    testWidgets('bağış yapılmışsa teşekkür metnine döner', (tester) async {
      await pump(
        tester,
        const Scaffold(body: SupportBanner()),
        prefs: {'donate_has_donated': true},
      );
      expect(find.text('Desteğiniz için teşekkürler'), findsOneWidget);
    });
  });

  group('Ana ekran kartı', () {
    testWidgets('kapatma düğmesi kartı erteler', (tester) async {
      final container = await pump(
        tester,
        const Scaffold(body: DonationCard()),
      );
      expect(container.read(donationProvider).snoozedUntil, isNull);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(container.read(donationProvider).snoozedUntil, isNotNull);
      // Erteleme sonrası kart artık gösterilmemeli.
      expect(
        container.read(donationProvider.notifier).shouldShowCard(),
        isFalse,
      );
    });
  });
}
