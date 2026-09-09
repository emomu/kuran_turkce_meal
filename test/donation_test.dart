import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/features/donate/data/donation_links.dart';
import 'package:kuran_turkce_meal/features/donate/providers/donation_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bağış hatırlatmasının ne zaman çıkıp ne zaman sustuğu.
///
/// Bu mantığın testi, ekranların testinden daha kıymetli: eşikler yanlış
/// çalışırsa kullanıcı bağış isteğini ya hiç görmez ya da her açılışta görür.
/// İkincisi bir Kur'an uygulamasında kabul edilemez.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Depodaki kanallar yayına kadar kapalı duruyor (bkz. [DonationLinks]) ve
  // kapalıyken hatırlatma mantığı hiç çalışmıyor. Eşikleri sınayabilmek için
  // açık tek bir kanal varmış gibi davranılır.
  setUp(() {
    DonationLinks.debugOverrideChannels(const [
      DonationChannel(
        id: 'test',
        kind: DonationKind.link,
        value: 'https://example.com',
      ),
    ]);
  });

  tearDown(() => DonationLinks.debugOverrideChannels(null));

  test('kanal yapılandırılmamışsa hiçbir hatırlatma çıkmaz', () async {
    DonationLinks.debugOverrideChannels(const []);
    SharedPreferences.setMockInitialValues({
      'donate_first_launch': DateTime.now()
          .subtract(const Duration(days: 900))
          .millisecondsSinceEpoch,
      'donate_open_count': 900,
    });
    final notifier = DonationNotifier(await SharedPreferences.getInstance());

    expect(notifier.shouldShowCard(), isFalse);
    expect(notifier.nextNotificationDelay(), isNull);
  });

  /// Verilen geçmişle bir notifier kurar.
  ///
  /// [daysAgo] ilk açılışın kaç gün önce olduğunu, [opens] o güne kadarki
  /// açılış sayısını verir.
  Future<DonationNotifier> build({
    required int daysAgo,
    required int opens,
    Map<String, Object> extra = const {},
  }) async {
    final firstLaunch = DateTime.now().subtract(Duration(days: daysAgo));
    SharedPreferences.setMockInitialValues({
      'donate_first_launch': firstLaunch.millisecondsSinceEpoch,
      'donate_open_count': opens,
      ...extra,
    });
    return DonationNotifier(await SharedPreferences.getInstance());
  }

  group('kart eşiği', () {
    test('süre dolmadan gösterilmez', () async {
      final notifier = await build(daysAgo: 3, opens: 100);
      expect(notifier.shouldShowCard(), isFalse);
    });

    test('açılış sayısı yetmezse gösterilmez', () async {
      // Kurup unutulmuş uygulama: aradan aylar geçmiş ama kullanılmamış.
      final notifier = await build(daysAgo: 200, opens: 3);
      expect(notifier.shouldShowCard(), isFalse);
    });

    test('süre ve kullanım birlikte dolunca gösterilir', () async {
      final notifier = await build(
        daysAgo: DonationThresholds.minDays + 1,
        opens: DonationThresholds.minOpens,
      );
      expect(notifier.shouldShowCard(), isTrue);
    });
  });

  group('susturma', () {
    test('erteleme süresince gösterilmez, sonrasında geri gelir', () async {
      final notifier = await build(daysAgo: 400, opens: 500);
      expect(notifier.shouldShowCard(), isTrue);

      notifier.snooze();
      expect(notifier.shouldShowCard(), isFalse);

      // Erteleme dolduktan sonraki bir an.
      final after = DateTime.now().add(
        const Duration(days: DonationThresholds.snoozeDays + 1),
      );
      expect(notifier.shouldShowCard(now: after), isTrue);
    });

    test('kart kapatma ertelemeden kısa susar', () async {
      final notifier = await build(daysAgo: 400, opens: 500);
      notifier.dismissCard();

      final midway = DateTime.now().add(
        const Duration(days: DonationThresholds.dismissDays + 1),
      );
      expect(notifier.shouldShowCard(now: midway), isTrue);
    });

    test('"destekledim" kalıcı olarak susturur', () async {
      final notifier = await build(daysAgo: 400, opens: 500);
      notifier.markDonated();

      expect(notifier.shouldShowCard(), isFalse);
      // Yıllar sonra bile.
      final later = DateTime.now().add(const Duration(days: 4000));
      expect(notifier.shouldShowCard(now: later), isFalse);
      expect(notifier.nextNotificationDelay(now: later), isNull);
    });

    test('"bir daha gösterme" kalıcı olarak susturur', () async {
      final notifier = await build(daysAgo: 400, opens: 500);
      notifier.dismissForever();

      final later = DateTime.now().add(const Duration(days: 4000));
      expect(notifier.shouldShowCard(now: later), isFalse);
      expect(notifier.nextNotificationDelay(now: later), isNull);
    });
  });

  group('bildirim', () {
    /// [daysAgo] gün önce kurulmuş bir uygulamada sıradaki basamağa kalan
    /// süre, saat cinsinden.
    ///
    /// Saat kullanılıyor çünkü `inDays` aşağı yuvarlar: tam 24 saat kalan bir
    /// basamak, kurulum anı ile ölçüm anı arasındaki mikrosaniyeler yüzünden
    /// 0 gün görünür ve test kırılgan olurdu.
    Future<int?> hoursUntilNext(int daysAgo) async {
      final notifier = await build(daysAgo: daysAgo, opens: 100);
      return notifier.nextNotificationDelay()?.inHours;
    }

    test('basamaklar sırayla ilerler', () async {
      // Her basamakta bir sonrakine kalan süre. 23 saat = "yarın", çünkü
      // ölçüm kurulumdan birkaç mikrosaniye sonra yapılıyor.
      expect(await hoursUntilNext(0), 23); // 1. güne
      expect(await hoursUntilNext(1), 47); // 3. güne 2 gün
      expect(await hoursUntilNext(3), 95); // 7. güne 4 gün
      expect(await hoursUntilNext(7), 71); // 10. güne 3 gün
      expect(await hoursUntilNext(10), 95); // 14. güne 4 gün
      expect(await hoursUntilNext(14), 167); // 21. güne 7 gün
      expect(await hoursUntilNext(21), 215); // 30. güne 9 gün
    });

    test('program bitince bildirim durur', () async {
      final last = DonationThresholds.notificationDays.last;
      expect(await hoursUntilNext(last), isNull);
      expect(await hoursUntilNext(last + 500), isNull);
    });

    test('kaçırılan basamak sıradakine devreder', () async {
      // Uygulama 5. günde açılmış; 3. günün basamağı kaçmış, sıradaki 7.
      // gün — yaklaşık 2 gün sonra.
      expect(await hoursUntilNext(5), 47);
    });

    test('planlanmış basamak beklerken yeniden kurulmaz', () async {
      final notifier = await build(daysAgo: 0, opens: 5);
      final delay = notifier.nextNotificationDelay();
      expect(delay, isNotNull);

      // Kaydedilen değer bildirimin düşeceği an.
      notifier.markNotificationScheduled(at: DateTime.now().add(delay!));

      // Aynı gün içindeki ikinci açılış aynı basamağı tekrar kurmamalı.
      expect(notifier.nextNotificationDelay(), isNull);
    });

    test('basamak düştükten sonra sıradaki planlanır', () async {
      final notifier = await build(daysAgo: 0, opens: 5);
      notifier.markNotificationScheduled(
        at: DateTime.now().add(const Duration(days: 1)),
      );

      // 1. basamak düşmüş. 2 gün sonra açılan uygulamada sıradaki basamak
      // 3. gün: bir gün sonrası.
      final after = DateTime.now().add(const Duration(days: 2));
      expect(notifier.nextNotificationDelay(now: after)?.inHours, 23);
    });

    test('uzun süre açılmayan uygulamada kaçan basamak kısa gecikmeyle düşer',
        () async {
      // 25. günde açılan uygulama: 21. basamak geçmiş, 30. gün henüz uzak.
      // Sıradaki basamak 30. gün olduğu için normal gecikme kullanılır.
      final notifier = await build(daysAgo: 25, opens: 100);
      expect(notifier.nextNotificationDelay()?.inHours, 119);

      // Program biterken son basamağı da geçmiş bir uygulamada bildirim yok.
      final finished = await build(
        daysAgo: DonationThresholds.notificationDays.last + 1,
        opens: 100,
      );
      expect(finished.nextNotificationDelay(), isNull);
    });

    test('erteleme bildirimi de susturur', () async {
      final notifier = await build(daysAgo: 5, opens: 100);
      expect(notifier.nextNotificationDelay(), isNotNull);

      notifier.snooze();
      expect(notifier.nextNotificationDelay(), isNull);
    });

    test('kanal yokken hiç planlanmaz', () async {
      DonationLinks.debugOverrideChannels(const []);
      final notifier = await build(daysAgo: 5, opens: 100);
      expect(notifier.nextNotificationDelay(), isNull);
    });
  });

  group('açılış kaydı', () {
    test('sayaç artar ve cihazda kalır', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      DonationNotifier(prefs)
        ..registerAppOpen()
        ..registerAppOpen();

      expect(prefs.getInt('donate_open_count'), 2);

      // Yeni bir oturum sayacı sıfırlamaz.
      final resumed = DonationNotifier(prefs)..registerAppOpen();
      expect(resumed.state.openCount, 3);
    });

    test('ilk açılış anı sonraki açılışlarda değişmez', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      DonationNotifier(prefs).registerAppOpen();
      final first = prefs.getInt('donate_first_launch');

      DonationNotifier(prefs).registerAppOpen();
      expect(prefs.getInt('donate_first_launch'), first);
    });
  });
}
