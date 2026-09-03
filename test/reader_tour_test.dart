import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/core/providers/app_providers.dart';
import 'package:kuran_turkce_meal/data/db/app_database.dart';
import 'package:kuran_turkce_meal/core/theme/app_theme.dart';
import 'package:kuran_turkce_meal/data/models/ayah.dart';
import 'package:kuran_turkce_meal/data/models/surah.dart';
import 'package:kuran_turkce_meal/features/onboarding/providers/tour_provider.dart';
import 'package:kuran_turkce_meal/features/onboarding/widgets/coach_mark.dart';
import 'package:kuran_turkce_meal/features/reader/providers/reader_provider.dart';
import 'package:kuran_turkce_meal/features/reader/view/reader_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/localized_app.dart';

/// Okuma ekranındaki tanıtım turunun gerçek ekran üzerinde denetimi.
///
/// Birim testleri turun mekaniğini doğrular; buradaki asıl soru turun
/// gerçekten *ayetin üstünde* açılıp açılmadığı. Tur ayetler yüklenmeden
/// başlarsa işaret edilecek kare henüz çizilmemiş olur ve delik açılamaz —
/// kullanıcı boş bir karartma görür.
void main() async {
  await TestApp.ensureInitialized();
  setUp(TestApp.reset);

  // Okuma ekranı ayet işaretlerini veritabanından okur; testte platform
  // kanalı yok, bu yüzden sqflite'ın masaüstü uyarlaması bellekte açılır
  // (projedeki diğer ekran testleriyle aynı kurulum).
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  AppDatabase.factoryOverride = databaseFactoryFfi;
  // Her test dosyası kendi veritabanı dizinini kullanır. Test dosyaları
  // paralel çalışıyor; ortak bir dosyayı paylaştıklarında SQLite
  // "disk I/O error" verip rastgele testleri düşürüyordu.
  AppDatabase.pathOverride =
      Directory.systemTemp.createTempSync('reader_tour_db_').path;

  const surah = Surah(
    number: 96,
    name: 'Alak',
    meaning: 'Kan Pıhtısı',
    revelationOrder: 1,
    revelationPlace: RevelationPlace.mekke,
    ayahCount: 19,
  );

  const ayahs = [
    Ayah(
      id: 1,
      surahNumber: 96,
      ayahNumber: 1,
      translation: 'Yaratan Rabbinin adıyla oku.',
    ),
    Ayah(
      id: 2,
      surahNumber: 96,
      ayahNumber: 2,
      translation: 'O, insanı bir kan pıhtısından yarattı.',
    ),
  ];

  Future<void> pumpReader(
    WidgetTester tester, {
    Map<String, Object> initialPrefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(initialPrefs);
    final prefs = await SharedPreferences.getInstance();

    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            readerDataProvider(96).overrideWith(
              (ref) async => const ReaderData(surah: surah, ayahs: ayahs),
            ),
            nextSurahProvider(96).overrideWith((ref) async => null),
          ],
          child: TestApp.wrap(
            const ReaderScreen(surahNumber: 96),
            theme: AppTheme.light,
          ),
        ),
      );
      await tester.pump();
      // İşaretler veritabanından asenkron okunur. Bu okuma test bitmeden
      // tamamlanmazsa sonuç kapatılmış bir sağlayıcıya yazılır ve test
      // "tamamlandıktan sonra" hata verir. Burada bilerek beklenir.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump();
    });
    await tester.pumpAndSettle();
  }

  group('Okuma ekranı turu', () {
    testWidgets('ilk açılışta basılı tutma ipucu gösterilir', (tester) async {
      await pumpReader(tester);

      expect(find.byType(CoachMarkOverlay), findsOneWidget);
      expect(find.text('Ayete basılı tutun'), findsOneWidget);
      expect(find.textContaining('uzun bastığınızda'), findsOneWidget);
    });

    testWidgets('delik gerçekten ilk ayetin üstünde açılır', (tester) async {
      await pumpReader(tester);

      // Turun ölçtüğü kare ile ayetin ekrandaki yeri örtüşmeli.
      //
      // Anahtar `AyahTile`'ın kendisine verildiğinde bu tutmuyordu: o
      // anahtar widget kimliği olarak kullanılıyor, liste öğeleri geri
      // dönüştürdüğü için ölçüm bambaşka bir kareye denk geliyor ve delik
      // ayetin yanında, ekranın dışına taşan bir yerde açılıyordu.
      final overlay = tester.widget<CoachMarkOverlay>(
        find.byType(CoachMarkOverlay),
      );
      final targetKey = overlay.steps.first.targetKey!;
      final targetBox =
          targetKey.currentContext!.findRenderObject() as RenderBox;
      final target = targetBox.localToGlobal(Offset.zero) & targetBox.size;

      final ayahText = tester.getRect(
        find.text('Yaratan Rabbinin adıyla oku.'),
      );

      // Ayet metni deliğin içinde kalmalı.
      expect(target.contains(ayahText.topLeft), isTrue,
          reason: 'Delik ayetin sol üstünü kapsamıyor: $target vs $ayahText');
      expect(target.contains(ayahText.bottomRight - const Offset(1, 1)),
          isTrue,
          reason: 'Delik ayetin sağ altını kapsamıyor: $target vs $ayahText');

      // Ve delik ekranın dışına taşmamalı.
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(target.left, greaterThanOrEqualTo(0));
      expect(target.right, lessThanOrEqualTo(screen.width));
    });

    testWidgets('üç adım sırayla gezilir', (tester) async {
      await pumpReader(tester);

      expect(find.text('Ayete basılı tutun'), findsOneWidget);

      await tester.tap(find.text('Devam'));
      await tester.pumpAndSettle();
      expect(find.text('Yazıyı kendinize göre ayarlayın'), findsOneWidget);

      await tester.tap(find.text('Devam'));
      await tester.pumpAndSettle();
      expect(find.text('Sure bitince durmayın'), findsOneWidget);
      expect(find.text('Anladım'), findsOneWidget);

      await tester.tap(find.text('Anladım'));
      await tester.pumpAndSettle();
      expect(find.byType(CoachMarkOverlay), findsNothing);
    });

    testWidgets('daha önce izlendiyse okuma kesintiye uğramaz',
        (tester) async {
      await pumpReader(
        tester,
        initialPrefs: {TourId.reader.storageKey: true},
      );

      expect(find.byType(CoachMarkOverlay), findsNothing);
      expect(find.text('Yaratan Rabbinin adıyla oku.'), findsOneWidget);
    });

    testWidgets('delik ayet satırının tam genişliğini kapsar', (tester) async {
      // Gerçek cihaz ölçüsü (iPhone 13). Varsayılan test ekranı 800x600
      // kare gibi; oradaki ölçüler gerçek telefonu temsil etmiyor.
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpReader(tester);

      final overlay = tester.widget<CoachMarkOverlay>(
        find.byType(CoachMarkOverlay),
      );
      final targetKey = overlay.steps.first.targetKey!;
      final box = targetKey.currentContext!.findRenderObject() as RenderBox;
      final target = box.localToGlobal(Offset.zero) & box.size;

      final ayahText = tester.getRect(
        find.text('Yaratan Rabbinin adıyla oku.'),
      );



      // Delik ayetin solundan başlamalı; ekranın ortasından başlayıp sağa
      // taşarsa kullanıcı ayeti değil boş bir kutu görür.
      expect(target.left, lessThanOrEqualTo(ayahText.left),
          reason: 'delik=$target ayet=$ayahText');
      expect(target.right, greaterThanOrEqualTo(ayahText.right),
          reason: 'delik=$target ayet=$ayahText');
      expect(target.right, lessThanOrEqualTo(390),
          reason: 'delik ekranın sağına taşıyor: $target');
    });

    testWidgets('yatayda da ekrana sığar', (tester) async {
      // Yatayda yükseklik yarıya iner; baloncuk hedefin altına sığmazsa
      // üstüne geçmeli. Sığmadığı hâlde altta ısrar ederse düğmeleri
      // ekranın dışında kalır ve tur kapatılamaz.
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpReader(tester);

      expect(find.byType(CoachMarkOverlay), findsOneWidget);

      // Düğmeler ekranın içinde olmalı.
      final button = tester.getRect(find.text('Devam'));
      expect(button.top, greaterThanOrEqualTo(0));
      expect(button.bottom, lessThanOrEqualTo(390));

      // Ve gerçekten basılabilmeli.
      await tester.tap(find.text('Devam'));
      await tester.pumpAndSettle();
      expect(find.text('Yazıyı kendinize göre ayarlayın'), findsOneWidget);
    });

    testWidgets('tur kapandıktan sonra ayet uzun basmaya yanıt verir',
        (tester) async {
      await pumpReader(tester);

      await tester.tap(find.text('Atla'));
      await tester.pumpAndSettle();

      // Katman dokunuşları yutuyordu; kapandıktan sonra jest yeniden
      // ayete ulaşmalı, aksi halde tanıttığı özellik çalışmaz olurdu.
      await tester.longPress(find.text('Yaratan Rabbinin adıyla oku.'));
      await tester.pumpAndSettle();

      // Uzun basma ayet işlemleri yaprağını açar.
      expect(find.text('Yer imi ekle'), findsOneWidget);
    });
  });
}
