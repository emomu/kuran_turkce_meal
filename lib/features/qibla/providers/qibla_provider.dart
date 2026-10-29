import 'dart:async';

import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../data/qibla_math.dart';

/// Kıble ekranının konum durumu.
///
/// Konum yalnızca bu ekran açıkken istenir ve hiçbir yere gönderilmez:
/// kıble açısı cihazda hesaplanır. Uygulamanın geri kalanı izin istemez.
sealed class QiblaLocation {
  const QiblaLocation();
}

/// Henüz izin istenmedi; kullanıcı düğmeye basmalı.
class QiblaLocationIdle extends QiblaLocation {
  const QiblaLocationIdle();
}

/// Konum alınıyor.
class QiblaLocationLoading extends QiblaLocation {
  const QiblaLocationLoading();
}

/// Konum alındı; kıble açısı ve uzaklık hesaplandı.
class QiblaLocationReady extends QiblaLocation {
  const QiblaLocationReady({
    required this.bearing,
    required this.distanceKm,
  });

  /// Gerçek kuzeyden kıbleye açı (derece).
  final double bearing;

  /// Kâbe'ye kuş uçuşu uzaklık.
  final double distanceKm;
}

/// Konum alınamadı.
class QiblaLocationError extends QiblaLocation {
  const QiblaLocationError(this.reason);

  final QiblaLocationFailure reason;
}

/// Konumun neden alınamadığı.
///
/// Her birinin kullanıcıya söyleyeceği farklı: kapalı servis ayarlardan
/// açılır, reddedilen izin yeniden istenebilir, kalıcı ret ise yalnızca
/// sistem ayarlarından geri alınır. Tek bir "hata" mesajı kullanıcıyı
/// çıkmazda bırakırdı.
enum QiblaLocationFailure {
  /// Cihazda konum servisi kapalı.
  serviceDisabled,

  /// Kullanıcı izni reddetti; yeniden sorulabilir.
  denied,

  /// Kullanıcı "bir daha sorma" dedi; yalnızca sistem ayarlarından açılır.
  deniedForever,

  /// Konum okunamadı (sinyal yok, zaman aşımı).
  unavailable,
}

/// Konum durumunu tutar ve izin akışını yürütür.
class QiblaLocationNotifier extends StateNotifier<QiblaLocation> {
  QiblaLocationNotifier() : super(const QiblaLocationIdle());

  /// Konumu ister ve kıble açısını hesaplar.
  ///
  /// Kullanıcı eylemiyle çağrılır; ekran açılır açılmaz izin istenmez.
  /// Kıble bir araçtır, kullanıcı onu kullanmaya karar verdiğinde sorulur.
  Future<void> locate() async {
    state = const QiblaLocationLoading();

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        state = const QiblaLocationError(QiblaLocationFailure.serviceDisabled);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      switch (permission) {
        case LocationPermission.denied:
          state = const QiblaLocationError(QiblaLocationFailure.denied);
          return;
        case LocationPermission.deniedForever:
          state = const QiblaLocationError(
            QiblaLocationFailure.deniedForever,
          );
          return;
        case LocationPermission.whileInUse:
        case LocationPermission.always:
        case LocationPermission.unableToDetermine:
          break;
      }

      // Düşük doğruluk yeterli: kıble açısı kilometrelerce uzaklıkta bile
      // bir derecenin altında değişir. Yüksek doğruluk istemek pili
      // boşaltır ve ilk sonucu geciktirir.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 15),
        ),
      );

      if (!mounted) return;
      state = QiblaLocationReady(
        bearing: QiblaMath.bearing(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
        distanceKm: QiblaMath.distanceKm(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
    } on TimeoutException {
      if (mounted) {
        state = const QiblaLocationError(QiblaLocationFailure.unavailable);
      }
    } catch (_) {
      // Platform hataları da aynı kovaya düşer: kullanıcı için ayrımı yok,
      // yapacağı şey yine yeniden denemek.
      if (mounted) {
        state = const QiblaLocationError(QiblaLocationFailure.unavailable);
      }
    }
  }

  /// Sistem ayarlarını açar — kalıcı ret durumunda tek çıkış yolu.
  Future<void> openSettings() => Geolocator.openAppSettings();

  /// Konum servisi ayarlarını açar.
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}

final qiblaLocationProvider =
    StateNotifierProvider.autoDispose<QiblaLocationNotifier, QiblaLocation>(
  (ref) => QiblaLocationNotifier(),
);

/// Cihazın baktığı yön (gerçek kuzeyden derece) ve pusula doğruluğu.
///
/// `flutter_compass` manyetik kuzeyi değil, platformun düzelttiği gerçek
/// kuzeyi verir; kıble açısı da gerçek kuzeye göre hesaplandığı için ikisi
/// doğrudan karşılaştırılabilir.
///
/// Pusulası olmayan cihazlarda akış null yayar; ekran o durumda yön yerine
/// yalnızca açı ve uzaklığı gösterir.
final compassProvider = StreamProvider.autoDispose<CompassEvent?>((ref) {
  final events = FlutterCompass.events;
  if (events == null) return Stream.value(null);
  return events;
});

/// Pusulanın yeniden kalibre edilmesi gerekip gerekmediği.
///
/// Manyetometre metal, hoparlör ve elektrik alanından etkilenir; doğruluk
/// düştüğünde iğne onlarca derece sapar ve kullanıcı yanlış yöne döner.
/// Platform bunu bir güven değeriyle bildirir.
///
/// Eşik 25 derece: altındaki sapma namaz yönü için kabul edilebilir,
/// üstünde uyarmak gerekir. Android doğruluğu bildirmediğinde null gelir
/// ve uyarı gösterilmez — var olmayan bir sorunu haber vermek, kullanıcıyı
/// gereksiz yere telefonunu sallamaya iter.
bool needsCalibration(CompassEvent? event) {
  final accuracy = event?.accuracy;
  return accuracy != null && accuracy > 25;
}
