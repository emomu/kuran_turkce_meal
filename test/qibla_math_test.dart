import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/features/qibla/data/qibla_math.dart';

/// Kıble hesabının doğruluğu.
///
/// Beklenen açılar Diyanet'in ve yaygın kıble hesaplayıcılarının verdiği
/// değerlerdir. Tolerans 1 derece: bunun altındaki fark pusula iğnesinde
/// görünmez, üstündeki fark hesabın bozulduğunu gösterir.
void main() {
  group('kıble yönü', () {
    test('bilinen şehirlerde doğru açıyı verir', () {
      // (şehir, enlem, boylam, beklenen kıble açısı)
      const cities = [
        ('İstanbul', 41.0082, 28.9784, 152.1),
        ('Ankara', 39.9334, 32.8597, 160.7),
        ('İzmir', 38.4237, 27.1428, 144.2),
        ('Londra', 51.5074, -0.1278, 119.2),
        ('New York', 40.7128, -74.0060, 58.6),
        ('Jakarta', -6.2088, 106.8456, 295.1),
      ];

      for (final (name, lat, lon, expected) in cities) {
        final actual = QiblaMath.bearing(latitude: lat, longitude: lon);
        expect(actual, closeTo(expected, 1.0), reason: name);
      }
    });

    test('Kâbe\'nin kuzeyinde güneye bakar', () {
      // Medine, Kâbe'nin kuzeyindedir; kıble kabaca güney olmalı.
      final bearing = QiblaMath.bearing(latitude: 24.4686, longitude: 39.6142);
      expect(bearing, closeTo(180, 2.0));
    });

    test('her zaman 0-360 aralığında', () {
      for (var lat = -80.0; lat <= 80; lat += 10) {
        for (var lon = -180.0; lon <= 180; lon += 15) {
          final bearing = QiblaMath.bearing(latitude: lat, longitude: lon);
          expect(bearing, inInclusiveRange(0, 360), reason: '$lat,$lon');
          expect(bearing.isNaN, isFalse, reason: '$lat,$lon');
        }
      }
    });
  });

  group('uzaklık', () {
    test('bilinen şehirlerde doğru', () {
      const cities = [
        ('İstanbul', 41.0082, 28.9784, 2397.0),
        ('Ankara', 39.9334, 32.8597, 2156.0),
        ('Londra', 51.5074, -0.1278, 4782.0),
        ('Jakarta', -6.2088, 106.8456, 7940.0),
      ];

      for (final (name, lat, lon, expected) in cities) {
        final actual = QiblaMath.distanceKm(latitude: lat, longitude: lon);
        // %2 tolerans: küre kabulü ile elipsoit arasındaki fark bu mertebede.
        expect(actual, closeTo(expected, expected * 0.02), reason: name);
      }
    });

    test('Kâbe\'nin kendisinde sıfır', () {
      final distance = QiblaMath.distanceKm(
        latitude: QiblaMath.kaabaLatitude,
        longitude: QiblaMath.kaabaLongitude,
      );
      expect(distance, closeTo(0, 0.001));
    });
  });

  group('iğne açısı', () {
    test('cihaz kıbleye bakarken sıfır', () {
      final angle = QiblaMath.needleAngle(heading: 151.6, qiblaBearing: 151.6);
      expect(angle, closeTo(0, 0.001));
    });

    test('cihaz döndükçe iğne ters yönde döner', () {
      // Kullanıcı sağa 30 derece dönerse iğne sola 30 derece kaymalı:
      // kıble sabit, dönen cihazdır.
      final angle = QiblaMath.needleAngle(heading: 30, qiblaBearing: 0);
      expect(angle, closeTo(330, 0.001));
    });
  });

  group('sapma', () {
    test('kuzey çevresinde kısa yoldan ölçülür', () {
      // 350 ile 10 arasındaki fark 340 değil 20 derecedir.
      final deviation = QiblaMath.deviation(heading: 350, qiblaBearing: 10);
      expect(deviation, closeTo(20, 0.001));
    });

    test('hiçbir zaman 180'
        'i aşmaz', () {
      for (var heading = 0.0; heading < 360; heading += 7) {
        for (var qibla = 0.0; qibla < 360; qibla += 11) {
          final deviation =
              QiblaMath.deviation(heading: heading, qiblaBearing: qibla);
          expect(deviation, inInclusiveRange(0, 180));
        }
      }
    });

    test('tolerans içinde hizalanmış sayılır', () {
      expect(QiblaMath.isAligned(heading: 151, qiblaBearing: 153), isTrue);
      expect(QiblaMath.isAligned(heading: 151, qiblaBearing: 170), isFalse);
      // Kuzey çevresinde de doğru çalışmalı.
      expect(QiblaMath.isAligned(heading: 358, qiblaBearing: 2), isTrue);
    });
  });
}
