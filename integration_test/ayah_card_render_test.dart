import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kuran_turkce_meal/features/reader/share/ayah_card.dart';
import 'package:kuran_turkce_meal/features/reader/share/ayah_card_renderer.dart';

/// Ayet kartının görsele çevrilmesi.
///
/// Bu doğrulama widget testinde yapılamıyor: `toImage` gerçek bir raster
/// hattı istiyor ve `flutter test` ortamında öyle bir hat yok. Bu yüzden
/// kartın gerçekten çizilip çizilmediği ancak cihazda/öykünücüde koşan bir
/// bütünleşme testiyle görülebilir.
///
/// Testin biçimi de buna göre kuruldu: çizim başlatılır ama `await`
/// edilmeden önce `pump` ile kareler sürülür. Test ortamında kareleri
/// yalnızca `pump` üretir; çizimi bekleyip sonra pompalamak, hiç gelmeyecek
/// bir kareyi beklemek olurdu. Uygulamanın kendisinde böyle bir kısıt yok,
/// kareler kendiliğinden akıyor.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('kart gerçek PNG üretir', (tester) async {
    final png = await _render(
      tester,
      const AyahCard(
        text: 'Rabbimiz! Bize dünyada da iyilik ver, ahirette de iyilik '
            've bizi ateşin azabından koru.',
        surahName: 'Bakara',
        verseLabel: '201',
        appName: "Kur'an",
      ),
    );

    expect(png, isNotNull, reason: 'kart çizilemedi');

    // PNG imzası: dosyanın gerçekten bir görsel olduğunu doğrular.
    final bytes = png!;
    expect(bytes.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);

    // Boş bir kart da PNG imzası taşır; bayt sayısı içeriğin gerçekten
    // çizildiğini gösterir. Tek renk 1080×1080 zemin bile sıkıştırma
    // sonrası birkaç kilobayt; metin ve çizgiler bunu belirgin büyütür.
    expect(bytes.length, greaterThan(10000), reason: 'kart boş görünüyor');
  });

  testWidgets('Arapça metinli kart da çizilir', (tester) async {
    final png = await _render(
      tester,
      const AyahCard(
        text: 'Rahman ve Rahim olan Allah\'ın adıyla.',
        surahName: 'Fâtiha',
        verseLabel: '1',
        appName: "Kur'an",
        arabic: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        isDark: true,
      ),
    );

    expect(png, isNotNull);
    expect(png!.length, greaterThan(10000));
  });
}

/// Kartı çizer ve baytları döndürür.
///
/// Çizim `await` edilmeden başlatılır, sonra kareler pompalanır: test
/// ortamında kareleri yalnızca `pump` üretiyor, dolayısıyla önce beklemek
/// hiç gelmeyecek bir kareyi beklemek olurdu.
///
/// Barındırıcı uygulama da burada kurulur; `BuildContext`'i test gövdesine
/// taşımak, onu asenkron bir boşluğun ötesinde kullanmak olurdu.
Future<Uint8List?> _render(WidgetTester tester, AyahCard card) async {
  late BuildContext context;

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (builderContext) {
          context = builderContext;
          return const Scaffold(body: SizedBox());
        },
      ),
    ),
  );

  Uint8List? result;
  var done = false;

  // `pumpWidget` asenkron ama ağacı kurup döner; context o an geçerli ve
  // bu çağrı senkron olarak onu kullanır. Uyarı burada geçerli değil —
  // arada widget'ı ağaçtan kaldıran bir bekleme yok.
  final future = AyahCardRenderer.toPng(
    // ignore: use_build_context_synchronously
    context: context,
    size: AyahCard.size,
    card: card,
  ).then((bytes) {
    result = bytes;
    done = true;
  });

  // Çizim bitene kadar kare sür. Üst sınır, hata durumunda testin sonsuza
  // kadar dönmesini engeller.
  for (var i = 0; i < 120 && !done; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }

  await future;
  return result;
}
