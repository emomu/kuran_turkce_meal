import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/app_providers.dart';
import '../data/donation_links.dart';

/// Bağış hatırlatmasının durumu ve ne zaman gösterileceği.
///
/// Kural basit: kullanıcı uygulamayı bir süre gerçekten kullanmadan bağış
/// istenmez, istendikten sonra da uzun süre susulur. Bir Kur'an uygulamasında
/// para istemenin tonu, bir oyunun "bize puan ver" penceresiyle aynı olamaz;
/// bu yüzden eşikler bilinçli olarak yüksek, sessizlik süreleri uzun.
///
/// Tüm durum cihazda `SharedPreferences` içinde tutulur. Sunucu, hesap ya da
/// kimlik yok — uygulamanın geri kalanıyla aynı duruş.
class DonationState {
  const DonationState({
    required this.firstLaunch,
    required this.openCount,
    required this.snoozedUntil,
    required this.hasDonated,
    required this.dismissedForever,
    required this.lastNotifiedAt,
  });

  /// Uygulamanın ilk açıldığı an. Eşik buradan sayılır.
  final DateTime firstLaunch;

  /// Uygulamanın kaç kez açıldığı.
  final int openCount;

  /// Bu ana kadar hatırlatma gösterilmez.
  final DateTime? snoozedUntil;

  /// Kullanıcı "destekledim" dedi. Bir daha hiçbir hatırlatma çıkmaz.
  final bool hasDonated;

  /// Kullanıcı "bir daha gösterme" dedi.
  final bool dismissedForever;

  /// Planlanmış bağış bildiriminin düşeceği an.
  final DateTime? lastNotifiedAt;

  /// Kullanıcı hatırlatmayı tamamen kapattı mı.
  bool get isSilenced => hasDonated || dismissedForever;

  DonationState copyWith({
    int? openCount,
    DateTime? snoozedUntil,
    bool? hasDonated,
    bool? dismissedForever,
    DateTime? lastNotifiedAt,
  }) {
    return DonationState(
      firstLaunch: firstLaunch,
      openCount: openCount ?? this.openCount,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      hasDonated: hasDonated ?? this.hasDonated,
      dismissedForever: dismissedForever ?? this.dismissedForever,
      lastNotifiedAt: lastNotifiedAt ?? this.lastNotifiedAt,
    );
  }
}

/// Hatırlatmanın eşikleri.
///
/// Ayrı bir sınıfta duruyorlar ki testler gerçek değerlerle çalışsın ve
/// sayılar kodun içine dağılmasın.
abstract final class DonationThresholds {
  /// Kart çıkmadan önce geçmesi gereken süre.
  static const minDays = 14;

  /// Kart çıkmadan önce gereken açılış sayısı. Süre tek başına yetmez:
  /// kurup unutulmuş bir uygulamada bağış istemek anlamsız.
  static const minOpens = 20;

  /// "Şimdi değil" denince susulacak süre.
  static const snoozeDays = 60;

  /// Kart kapatıldığında (çarpı) susulacak süre. Kartı kapatmak "hayır"
  /// değil "şu an değil" demektir; yine de erteleme kadar uzun susulmaz.
  static const dismissDays = 30;

  /// Bağış bildirimlerinin düşeceği günler — ilk açılıştan itibaren sayılır.
  ///
  /// Basamaklar sıklaşarak değil seyrekleşerek ilerler: ilk haftalarda
  /// birbirine yakın, sonra giderek açılır. Kullanıcı uygulamayı yeni
  /// tanırken hatırlatmayı görür, alışkanlık kurduktan sonra rahat bırakılır.
  ///
  /// Liste bittiğinde hatırlatma tamamen durur — sonsuza dek tekrarlayan bir
  /// bağış bildirimi, susturmayı unutan kullanıcıyı yıllarca rahatsız ederdi.
  static const notificationDays = <int>[1, 3, 7, 10, 14, 21, 30, 60, 120, 240];

  /// Sıradaki basamak: [daysSinceFirstLaunch]'tan büyük ilk gün.
  ///
  /// Hepsi geçilmişse `null` döner ve bildirim bir daha planlanmaz.
  static int? nextNotificationDay(int daysSinceFirstLaunch) {
    for (final day in notificationDays) {
      if (day > daysSinceFirstLaunch) return day;
    }
    return null;
  }
}

class DonationNotifier extends StateNotifier<DonationState> {
  DonationNotifier(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;

  static const _kFirstLaunch = 'donate_first_launch';
  static const _kOpenCount = 'donate_open_count';
  static const _kSnoozedUntil = 'donate_snoozed_until';
  static const _kHasDonated = 'donate_has_donated';
  static const _kDismissedForever = 'donate_dismissed_forever';
  static const _kLastNotifiedAt = 'donate_last_notified_at';

  static DonationState _read(SharedPreferences prefs) {
    final firstMs = prefs.getInt(_kFirstLaunch);
    return DonationState(
      firstLaunch: firstMs == null
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(firstMs),
      openCount: prefs.getInt(_kOpenCount) ?? 0,
      snoozedUntil: _dateOrNull(prefs, _kSnoozedUntil),
      hasDonated: prefs.getBool(_kHasDonated) ?? false,
      dismissedForever: prefs.getBool(_kDismissedForever) ?? false,
      lastNotifiedAt: _dateOrNull(prefs, _kLastNotifiedAt),
    );
  }

  static DateTime? _dateOrNull(SharedPreferences prefs, String key) {
    final ms = prefs.getInt(key);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Açılışta bir kez çağrılır: ilk açılış anını kaydeder ve sayacı artırır.
  ///
  /// İlk açılış anı yalnızca bir kez yazılır; sonraki açılışlarda
  /// dokunulmaz, yoksa eşik hiç dolmazdı.
  void registerAppOpen() {
    if (!_prefs.containsKey(_kFirstLaunch)) {
      _prefs.setInt(_kFirstLaunch, state.firstLaunch.millisecondsSinceEpoch);
    }
    final next = state.openCount + 1;
    state = state.copyWith(openCount: next);
    _prefs.setInt(_kOpenCount, next);
  }

  /// Ana ekrandaki kart şu an gösterilmeli mi.
  bool shouldShowCard({DateTime? now}) {
    if (!DonationLinks.isConfigured) return false;
    if (state.isSilenced) return false;

    final moment = now ?? DateTime.now();

    final snoozed = state.snoozedUntil;
    if (snoozed != null && moment.isBefore(snoozed)) return false;

    final days = moment.difference(state.firstLaunch).inDays;
    return days >= DonationThresholds.minDays &&
        state.openCount >= DonationThresholds.minOpens;
  }

  /// Sıradaki bağış bildiriminin ne kadar sonra düşeceği.
  ///
  /// `null` dönerse bildirim planlanmaz: kullanıcı susturmuş, kanal yok,
  /// erteleme sürüyor ya da programdaki bütün basamaklar geçilmiş demektir.
  ///
  /// Karttan bağımsız değerlendirilir: kartı erteleyen kullanıcı bildirimi de
  /// almamalı, ama kartı hiç görmemiş (uygulamayı ana ekrana uğramadan
  /// kullanan) biri için bildirim tek hatırlatma olabilir.
  Duration? nextNotificationDelay({DateTime? now}) {
    if (!DonationLinks.isConfigured) return null;
    if (state.isSilenced) return null;

    final moment = now ?? DateTime.now();

    final snoozed = state.snoozedUntil;
    if (snoozed != null && moment.isBefore(snoozed)) return null;

    final elapsed = moment.difference(state.firstLaunch).inDays;

    // Zaten planlanmış bir basamak varsa tekrar kurulmaz. Aksi halde her
    // açılış aynı bildirimi yeniden planlar ve kullanıcı uygulamayı günde
    // birkaç kez açtığında basamak sürekli ileri kayardı.
    final last = state.lastNotifiedAt;
    if (last != null && moment.isBefore(last)) return null;

    final target = DonationThresholds.nextNotificationDay(elapsed);
    if (target == null) return null;

    final fireAt = state.firstLaunch.add(Duration(days: target));
    final delay = fireAt.difference(moment);

    // Geçmişte kalmış bir basamak (uygulama uzun süre açılmamış olabilir)
    // hemen değil, kısa bir gecikmeyle düşer: kullanıcı uygulamayı yeni
    // açmışken bildirim göndermek, uygulamanın içinden sormakla aynı şey.
    return delay.isNegative ? const Duration(hours: 6) : delay;
  }

  /// Sıradaki basamağın düşeceği an. Planlama sonrası kaydedilir.
  DateTime? nextNotificationTime({DateTime? now}) {
    final delay = nextNotificationDelay(now: now);
    if (delay == null) return null;
    return (now ?? DateTime.now()).add(delay);
  }

  /// "Şimdi değil" — belirli bir süre susulur.
  void snooze({int days = DonationThresholds.snoozeDays}) {
    _setSnooze(DateTime.now().add(Duration(days: days)));
  }

  /// Kart çarpıyla kapatıldı.
  void dismissCard() {
    _setSnooze(
      DateTime.now().add(
        const Duration(days: DonationThresholds.dismissDays),
      ),
    );
  }

  void _setSnooze(DateTime until) {
    state = state.copyWith(snoozedUntil: until);
    _prefs.setInt(_kSnoozedUntil, until.millisecondsSinceEpoch);
  }

  /// "Destekledim" — hatırlatma tamamen susar.
  ///
  /// Doğrulama yapılmaz ve yapılmamalı: doğrulamak için bir sunucuya ve
  /// kullanıcıyı tanımaya ihtiyaç olurdu. Kullanıcının sözü yeterli.
  void markDonated() {
    state = state.copyWith(hasDonated: true);
    _prefs.setBool(_kHasDonated, true);
  }

  /// "Bir daha gösterme".
  void dismissForever() {
    state = state.copyWith(dismissedForever: true);
    _prefs.setBool(_kDismissedForever, true);
  }

  /// Bildirimin düşeceği an kaydedilir.
  ///
  /// Saklanan değer "planlandığı an" değil "düşeceği an": o an gelmeden
  /// yapılan açılışlarda aynı basamak yeniden kurulmaz. Geçmişse, sıradaki
  /// basamağa geçilmiş demektir.
  void markNotificationScheduled({DateTime? at}) {
    final moment = at ?? DateTime.now();
    state = state.copyWith(lastNotifiedAt: moment);
    _prefs.setInt(_kLastNotifiedAt, moment.millisecondsSinceEpoch);
  }

  /// Test ve hata ayıklama için durumu sıfırlar.
  void reset() {
    _prefs
      ..remove(_kSnoozedUntil)
      ..remove(_kHasDonated)
      ..remove(_kDismissedForever)
      ..remove(_kLastNotifiedAt);
    state = DonationState(
      firstLaunch: state.firstLaunch,
      openCount: state.openCount,
      snoozedUntil: null,
      hasDonated: false,
      dismissedForever: false,
      lastNotifiedAt: null,
    );
  }
}

final donationProvider =
    StateNotifierProvider<DonationNotifier, DonationState>(
  (ref) => DonationNotifier(ref.watch(sharedPreferencesProvider)),
);

/// Ana ekranın dinlediği tek değer: kart çizilsin mi.
final showDonationCardProvider = Provider<bool>((ref) {
  ref.watch(donationProvider);
  return ref.read(donationProvider.notifier).shouldShowCard();
});
