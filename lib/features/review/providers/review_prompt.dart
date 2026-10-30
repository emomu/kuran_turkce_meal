import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';

import 'review_provider.dart';

/// App Store Connect'teki Apple ID. iOS'ta mağaza sayfasını açmak için
/// gerekir; Android paket adından bulunur.
const appStoreId = '6808983927';

/// Ayarlardaki "Uygulamayı değerlendir" satırı: mağaza sayfasını açar.
///
/// Burada [InAppReview.requestReview] kullanılmaz. Sistem penceresi kotaya
/// takılıp hiç görünmeyebilir; kullanıcının bilerek bastığı bir düğmenin
/// hiçbir şey yapmaması bozuk görünürdü. Mağaza sayfası her zaman açılır.
Future<void> openStoreListing() {
  return InAppReview.instance.openStoreListing(appStoreId: appStoreId);
}

/// Bir bitişi kaydeder ve koşullar uygunsa sistemin puan penceresini açar.
///
/// Plan günü ya da sure bitirildiğinde çağrılır. Kendi başına karar vermez;
/// koşulları [ReviewNotifier.shouldRequest] belirler, buradaki iş yalnızca o
/// kararı sistem penceresine bağlamak.
///
/// Uygulama kendi "bizi beğendiniz mi?" penceresini göstermez. Google Play
/// puan isteğinden önce memnuniyet sorup yalnızca memnunları mağazaya
/// yönlendirmeyi yasaklıyor; üstelik araya giren ikinci bir pencere, bitişin
/// verdiği sakinliği bozardı.
Future<void> recordMilestoneAndMaybeRequestReview(WidgetRef ref) async {
  final notifier = ref.read(reviewProvider.notifier)..registerMilestone();
  if (!notifier.shouldRequest()) return;

  final review = InAppReview.instance;
  // Mağaza uygulaması olmayan cihazlarda (ör. Play Store'suz Android)
  // istek atılmaz ve sayılmaz; bir sonraki bitişte yeniden bakılır.
  if (!await review.isAvailable()) return;

  // Kayıt istekten önce yazılır: pencere açıkken uygulama kapatılırsa istek
  // yine de yapılmış sayılmalı.
  notifier.markRequested();
  await review.requestReview();
}
