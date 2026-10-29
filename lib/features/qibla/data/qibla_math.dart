import 'dart:math' as math;

/// Kıble yönü ve Kâbe uzaklığı hesapları.
///
/// Saf fonksiyonlar: cihaz, izin ve sensör bilmezler. Hesabın doğruluğu
/// bu dosyada sınanır; ekran yalnızca sonucu çizer.
///
/// Dünya küre kabul edilir. Elipsoit (WGS84) hesabı birkaç metrelik bir
/// fark getirir ve pusula iğnesinde görünmez — manyetometre hatası zaten
/// bundan büyüktür.
abstract final class QiblaMath {
  /// Kâbe'nin konumu (Mescid-i Haram, Mekke).
  static const kaabaLatitude = 21.4224779;
  static const kaabaLongitude = 39.6319306;

  /// Dünya'nın ortalama yarıçapı (km).
  static const _earthRadiusKm = 6371.0088;

  /// Verilen konumdan Kâbe'ye olan yön (gerçek kuzeyden saat yönünde derece).
  ///
  /// Büyük daire (great-circle) yönüdür: küre üzerindeki en kısa yolun
  /// başlangıç açısı. Düz harita üzerinde çizilen doğru ile aynı değildir
  /// ve uzak enlemlerde fark belirgindir — İstanbul'dan bakıldığında kıble
  /// güneydoğu değil, güney-güneydoğudur.
  ///
  /// Dönen değer 0–360 aralığındadır: 0 kuzey, 90 doğu, 180 güney.
  static double bearing({
    required double latitude,
    required double longitude,
  }) {
    final lat1 = _toRadians(latitude);
    final lat2 = _toRadians(kaabaLatitude);
    final deltaLon = _toRadians(kaabaLongitude - longitude);

    final y = math.sin(deltaLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(deltaLon);

    return _normalizeDegrees(_toDegrees(math.atan2(y, x)));
  }

  /// Verilen konumdan Kâbe'ye kuş uçuşu uzaklık (km).
  ///
  /// Haversine formülü; küçük açılarda da duyarlı kalır.
  static double distanceKm({
    required double latitude,
    required double longitude,
  }) {
    final lat1 = _toRadians(latitude);
    final lat2 = _toRadians(kaabaLatitude);
    final deltaLat = lat2 - lat1;
    final deltaLon = _toRadians(kaabaLongitude - longitude);

    final a = math.pow(math.sin(deltaLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(deltaLon / 2), 2);

    return 2 * _earthRadiusKm * math.asin(math.min(1, math.sqrt(a)));
  }

  /// Pusula iğnesinin dönmesi gereken açı.
  ///
  /// [heading] cihazın baktığı yön, [qiblaBearing] kıblenin yönü. İkisi de
  /// gerçek kuzeye göredir. Dönen değer kadranın merkezinden kıbleye uzanan
  /// okun açısıdır: 0 ise telefonun tepesi kıbleyi gösteriyor demektir.
  static double needleAngle({
    required double heading,
    required double qiblaBearing,
  }) =>
      _normalizeDegrees(qiblaBearing - heading);

  /// İğne ile kıble arasındaki en kısa açısal fark (0–180).
  ///
  /// Hizalanma geri bildirimi bunu kullanır: 350° ile 10° arasındaki fark
  /// 340 değil 20 derecedir, çıplak çıkarma yanlış sonuç verirdi.
  static double deviation({
    required double heading,
    required double qiblaBearing,
  }) {
    final diff = _normalizeDegrees(qiblaBearing - heading);
    return diff > 180 ? 360 - diff : diff;
  }

  /// Yönün hizalanmış sayılacağı tolerans (derece).
  ///
  /// Namaz için kıbleye tam isabet şart değildir; yöne dönmek yeterli
  /// sayılır. Tolerans dar tutulsaydı iğne elde titrerken sürekli yanıp
  /// sönerdi — manyetometre gürültüsü zaten birkaç derece oynatıyor.
  static const alignmentToleranceDegrees = 5.0;

  /// Cihaz kıbleye dönük mü.
  static bool isAligned({
    required double heading,
    required double qiblaBearing,
  }) =>
      deviation(heading: heading, qiblaBearing: qiblaBearing) <=
      alignmentToleranceDegrees;

  static double _toRadians(double degrees) => degrees * math.pi / 180;
  static double _toDegrees(double radians) => radians * 180 / math.pi;

  /// Açıyı 0–360 aralığına taşır. Negatif girdiyi de doğru çevirir.
  static double _normalizeDegrees(double degrees) =>
      (degrees % 360 + 360) % 360;
}
