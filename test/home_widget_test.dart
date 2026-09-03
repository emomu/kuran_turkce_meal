import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/core/widgets_bridge/home_widget_data.dart';
import 'package:kuran_turkce_meal/core/widgets_bridge/home_widget_keys.dart';
import 'package:kuran_turkce_meal/core/router/app_router.dart';
import 'package:kuran_turkce_meal/core/widgets_bridge/home_widget_service.dart';

/// Ana ekran araçlarının veri sözleşmesi.
///
/// Araçlar native tarafta çizilir; testler o tarafı çalıştıramaz. Doğrulanan
/// şey aradaki sözleşme: hangi anahtarlara ne yazıldığı, boş durumların eski
/// veriyi temizlediği ve araçtan gelen bağlantının doğru yola çevrildiği.
///
/// Bu sözleşme sessizce bozulabilen türden: Dart tarafında bir anahtar adı
/// değişse Kotlin/Swift derlenmeye devam eder, araç yalnızca boş görünür.
/// Testler o sessiz bozulmayı yakalar.
void main() {
  group('HomeWidgetPayload', () {
    test('dolu veri beklenen anahtarlara yazılır', () {
      final payload = HomeWidgetPayload(
        languageCode: 'tr',
        dailyAyah: const DailyAyahWidgetData(
          text: 'Allah, kendisinden başka ilah olmayandır.',
          reference: 'Bakara 255',
          route: '/sure/2?ayet=255',
          dayNumber: 20000,
        ),
        continueReading: const ContinueReadingWidgetData(
          surahName: 'Bakara',
          ayahLabel: '12. ayet',
          route: '/sure/2?ayet=12',
          percent: 4,
        ),
        streak: const StreakWidgetData(
          planName: '30 Günde Hatim',
          current: 7,
          longest: 12,
          route: '/plan/mushaf_30',
          todayDone: true,
        ),
      );

      final map = payload.toMap();

      expect(map[HomeWidgetKeys.languageCode], 'tr');
      expect(map[HomeWidgetKeys.dailyAyahReference], 'Bakara 255');
      expect(map[HomeWidgetKeys.dailyAyahRoute], '/sure/2?ayet=255');
      expect(map[HomeWidgetKeys.dailyAyahDayNumber], 20000);
      expect(map[HomeWidgetKeys.continueSurahName], 'Bakara');
      expect(map[HomeWidgetKeys.continuePercent], 4);
      expect(map[HomeWidgetKeys.streakCurrent], 7);
      expect(map[HomeWidgetKeys.streakTodayDone], isTrue);
    });

    test('boş bölümler null yazılır — eski veri araçta kalmamalı', () {
      // Kullanıcı son okumasını silerse ya da planı bırakırsa, anahtar
      // atlanırsa araç önceki eşitlemeden kalan veriyi göstermeye devam
      // ederdi. Bu yüzden boş bölümler açıkça null yazılır.
      final map = const HomeWidgetPayload(languageCode: 'en').toMap();

      expect(map.containsKey(HomeWidgetKeys.continueSurahName), isTrue);
      expect(map[HomeWidgetKeys.continueSurahName], isNull);
      expect(map.containsKey(HomeWidgetKeys.streakPlanName), isTrue);
      expect(map[HomeWidgetKeys.streakPlanName], isNull);
      expect(map[HomeWidgetKeys.dailyAyahText], isNull);
    });

    test('havuz kısaldığında artan yuvalar temizlenir', () {
      // Araç havuzda sırayla dolaşıyor; eski bir eşitlemeden kalan ayet
      // yuvada durursa kullanıcı yenile'ye bastığında dünün ayetini görürdü.
      final payload = HomeWidgetPayload(
        languageCode: 'tr',
        dailyAyahPool: const [
          DailyAyahWidgetData(
            text: 'ilk',
            reference: 'Fâtiha 1',
            route: '/sure/1?ayet=1',
            dayNumber: 20000,
          ),
        ],
      );

      final map = payload.toMap();

      expect(map[HomeWidgetKeys.dailyAyahPoolCount], 1);
      expect(map[HomeWidgetKeys.dailyAyahPoolText(0)], 'ilk');

      // Havuzun geri kalanı sonuna kadar temizlenmiş olmalı.
      for (var i = 1; i < HomeWidgetKeys.dailyAyahPoolSize; i++) {
        expect(
          map[HomeWidgetKeys.dailyAyahPoolText(i)],
          isNull,
          reason: '$i. yuva temizlenmedi',
        );
      }
    });

    test('havuz üst sınırı aşan veri yazılmaz', () {
      final map = HomeWidgetPayload(
        languageCode: 'tr',
        dailyAyahPool: [
          for (var i = 0; i < HomeWidgetKeys.dailyAyahPoolSize; i++)
            DailyAyahWidgetData(
              text: 'ayet $i',
              reference: 'Sure $i',
              route: '/sure/1?ayet=$i',
              dayNumber: 20000,
            ),
        ],
      ).toMap();

      expect(
        map.containsKey(
          HomeWidgetKeys.dailyAyahPoolText(HomeWidgetKeys.dailyAyahPoolSize),
        ),
        isFalse,
      );
    });
  });

  group('gün numarası', () {
    test('aynı günün farklı saatleri aynı numarayı verir', () {
      // Araç bayatlık kontrolünü bu numaraya göre yapıyor; saat kayması
      // yüzünden numara değişseydi araç gün içinde boş duruma düşerdi.
      final sabah = DateTime(2026, 3, 14, 6, 30);
      final gece = DateTime(2026, 3, 14, 23, 59);

      expect(
        DailyAyahWidgetData.dayNumberOf(sabah),
        DailyAyahWidgetData.dayNumberOf(gece),
      );
    });

    test('ardışık günler ardışık numara verir', () {
      final bugun = DailyAyahWidgetData.dayNumberOf(DateTime(2026, 3, 14));
      final yarin = DailyAyahWidgetData.dayNumberOf(DateTime(2026, 3, 15));

      expect(yarin - bugun, 1);
    });
  });

  group('araç bağlantısı', () {
    test('Android küçük harfe çevirdiği şemayı da çözer', () {
      // Manifest'te `homeWidget` yazılsa da Android şemayı küçülterek
      // iletiyor. Büyük/küçük harfe duyarlı karşılaştırma yüzünden araca
      // dokunan kullanıcı "Sayfa bulunamadı" ekranını görüyordu.
      expect(
        widgetRouteOf(Uri.parse('homewidget://sure/9?ayet=93')),
        '/sure/9?ayet=93',
      );
      expect(
        widgetRouteOf(Uri.parse('homeWidget://sure/9?ayet=93')),
        '/sure/9?ayet=93',
      );
    });

    test('araç dışı bağlantılar yönlendiriciye bırakılır', () {
      // Yönlendirici her gezinmede bu işlevi çağırıyor; uygulama içi
      // yollara `null` dönmezse olağan gezinme kırılırdı.
      expect(widgetRouteOf(Uri.parse('/sure/2')), isNull);
      expect(widgetRouteOf(Uri.parse('/planlar')), isNull);
      expect(widgetRouteOf(Uri.parse('https://example.com/sure/2')), isNull);
    });

    test('sorgu parametresi korunur', () {
      // Ayet numarası sorgu parametresinde taşınıyor; düşerse araç sureyi
      // açar ama ayete konumlanmaz.
      final route = HomeWidgetService.routeFromUri(
        Uri.parse('homeWidget://sure/2?ayet=255'),
      );

      expect(route, '/sure/2?ayet=255');
    });

    test('sekme yolları çözülür', () {
      expect(
        HomeWidgetService.routeFromUri(Uri.parse('homeWidget://planlar')),
        '/planlar',
      );
    });

    test('boş bağlantı ana sayfaya düşer', () {
      expect(
        HomeWidgetService.routeFromUri(Uri.parse('homeWidget://')),
        '/',
      );
      expect(HomeWidgetService.routeFromUri(null), isNull);
    });
  });
}
