import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/daily_ayah_notifications.dart';
import '../../settings/providers/preferences_provider.dart';
import '../data/donation_links.dart';
import 'donation_provider.dart';

/// Bağış hatırlatma bildirimini uygun olduğunda planlar.
///
/// Açılışta bir kez çağrılır. Kendi başına karar vermez; koşulları
/// [DonationNotifier.nextNotificationDelay] belirler, buradaki iş
/// yalnızca o kararı bildirim servisine bağlamak.
///
/// Bildirim, kullanıcının günün ayeti bildirimini açık tutmasına bağlı.
/// Bildirimleri kapatmış birine bağış için izin penceresi açmak — ya da izin
/// zaten varken yine de bildirim göndermek — kullanıcının açıkça belirttiği
/// tercihi delmek olurdu.
///
/// [WidgetRef] alır: çağrı, açılışta bir kez, arayüz katmanından yapılıyor.
/// Bir sağlayıcının içinde yaşamıyor — bu iş bir değer üretmiyor, yan etki
/// olarak bildirim planlıyor; sağlayıcıya sarmak onu gözden düştüğünde
/// yeniden çalışan bir şeye çevirirdi.
Future<void> maybeScheduleDonationReminder(WidgetRef ref) async {
  if (!DonationLinks.isConfigured) return;

  final notifier = ref.read(donationProvider.notifier);

  // Kullanıcı hatırlatmayı susturduysa varsa planlanmış bildirim de kaldırılır:
  // "destekledim" dedikten sonra aylar önce kurulmuş bir bildirimin düşmesi,
  // tercihin dikkate alınmadığı izlenimi verir.
  if (ref.read(donationProvider).isSilenced) {
    await DailyAyahNotifications.instance.cancelDonationReminder();
    return;
  }

  final notificationsOn = ref.read(
    preferencesProvider.select((p) => p.dailyAyahEnabled),
  );
  if (!notificationsOn) return;

  // Sıradaki basamak. Program bittiyse ya da erteleme sürüyorsa null döner
  // ve hiçbir şey planlanmaz (bkz. [DonationThresholds.notificationDays]).
  final delay = notifier.nextNotificationDelay();
  if (delay == null) return;

  final fireAt = DateTime.now().add(delay);

  await DailyAyahNotifications.instance.scheduleDonationReminder(
    delay: delay,
    title: 'donate.notificationTitle'.tr(),
    body: 'donate.notificationBody'.tr(),
  );

  // Planlanan an kaydedilir; o an gelmeden yapılan açılışlarda bildirim
  // yeniden kurulmaz.
  notifier.markNotificationScheduled(at: fireAt);
}
