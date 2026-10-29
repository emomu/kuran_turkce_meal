import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/features/qibla/providers/qibla_provider.dart';
import 'package:kuran_turkce_meal/features/qibla/view/qibla_screen.dart';

import 'helpers/localized_app.dart';

/// Kıble ekranının izin akışı ve durum geçişleri.
///
/// Gerçek konum ve pusula sensörü testte yok; durumlar provider override
/// ile kurulur. Sınanan şey ekranın her duruma doğru karşılık verip
/// vermediği — özellikle izin reddinde kullanıcıya bir çıkış yolu
/// gösterilmesi.
void main() async {
  await TestApp.ensureInitialized();

  Future<void> pumpWith(WidgetTester tester, QiblaLocation state) =>
      TestApp.pump(
        tester,
        ProviderScope(
          overrides: [
            qiblaLocationProvider.overrideWith(
              (ref) => _FixedLocationNotifier(state),
            ),
          ],
          child: const QiblaScreen(),
        ),
      );

  group('izin akışı', () {
    testWidgets('açılışta izin istenmez, önce açıklama gösterilir',
        (tester) async {
      await pumpWith(tester, const QiblaLocationIdle());

      // Uygulamanın geri kalanı hiç izin istemiyor; kıble ekranı da
      // kullanıcı isteyene kadar sormamalı.
      expect(find.text('qibla.permissionTitle'.tr()), findsOneWidget);
      expect(find.text('qibla.locate'.tr()), findsOneWidget);
    });

    testWidgets('açıklamada konumun cihazdan çıkmadığı yazar', (tester) async {
      await pumpWith(tester, const QiblaLocationIdle());

      // Gizlilik vaadi uygulamanın ana iddiası; izin kutusundan önce
      // kullanıcının bunu okuması gerekir.
      expect(find.text('qibla.permissionBody'.tr()), findsOneWidget);
    });

    testWidgets('konum alınırken ilerleme gösterilir', (tester) async {
      // Dönen gösterge sürekli animasyon yaptığı için `pumpAndSettle`
      // zaman aşımına uğrar; bu yüzden ortak yardımcı yerine doğrudan
      // çizilip tek kare ilerletilir.
      await tester.runAsync(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              qiblaLocationProvider.overrideWith(
                (ref) => _FixedLocationNotifier(const QiblaLocationLoading()),
              ),
            ],
            child: TestApp.wrap(const QiblaScreen()),
          ),
        );
      });
      await tester.pump();

      expect(find.text('qibla.locating'.tr()), findsOneWidget);
    });
  });

  group('hata durumları', () {
    testWidgets('her hata bir çıkış yolu gösterir', (tester) async {
      // Hatanın türü ne olursa olsun kullanıcı çıkmazda kalmamalı:
      // kapalı servis ayarlardan açılır, reddedilen izin yeniden
      // istenebilir, kalıcı ret sistem ayarlarına yönlendirir.
      for (final failure in QiblaLocationFailure.values) {
        await pumpWith(tester, QiblaLocationError(failure));
        await tester.pumpAndSettle();

        expect(
          find.byType(FilledButton),
          findsOneWidget,
          reason: '$failure için eylem düğmesi yok',
        );
      }
    });

    testWidgets('kalıcı ret ayarlara yönlendirir', (tester) async {
      await pumpWith(
        tester,
        const QiblaLocationError(QiblaLocationFailure.deniedForever),
      );

      // Kalıcı ret yeniden sorulamaz; tek çıkış sistem ayarlarıdır.
      expect(find.text('qibla.openAppSettings'.tr()), findsOneWidget);
      expect(find.text('qibla.retry'.tr()), findsNothing);
    });

    testWidgets('kapalı servis konum ayarlarına yönlendirir', (tester) async {
      await pumpWith(
        tester,
        const QiblaLocationError(QiblaLocationFailure.serviceDisabled),
      );

      expect(find.text('qibla.openLocationSettings'.tr()), findsOneWidget);
    });
  });

  group('pusula', () {
    testWidgets('konum hazırken uzaklık gösterilir', (tester) async {
      await pumpWith(
        tester,
        const QiblaLocationReady(bearing: 152.1, distanceKm: 2397),
      );
      await tester.pump();

      expect(
        find.text('qibla.distance'.tr(args: ['2397'])),
        findsOneWidget,
      );
    });

    testWidgets('taşma olmadan çizilir', (tester) async {
      await pumpWith(
        tester,
        const QiblaLocationReady(bearing: 152.1, distanceKm: 2397),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}

/// Durumu sabit tutan sahte notifier.
///
/// Gerçek olanı konum servisine gider; testte yalnızca ekranın verilen
/// duruma nasıl karşılık verdiği sınanır.
class _FixedLocationNotifier extends QiblaLocationNotifier {
  _FixedLocationNotifier(QiblaLocation initial) {
    state = initial;
  }

  @override
  Future<void> locate() async {}

  @override
  Future<void> openSettings() async {}

  @override
  Future<void> openLocationSettings() async {}
}
