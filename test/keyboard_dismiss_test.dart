import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/main.dart';
import 'package:kuran_turkce_meal/shared/widgets/pressable.dart';

/// Boşluğa dokununca klavyenin kapanması.
///
/// iOS'ta klavyeyi kapatmanın yerleşik yolu yok; bu davranış olmadan
/// kullanıcı bir alana yazdıktan sonra içeriğin yarısı örtülü kalıyor.
///
/// Ama her dokunuşta kapatmak da yanlış: düğmeye basmak klavyeyi
/// kapatmamalı. Arama ekranındaki öneri şeridi bunu görünür kıldı — bir
/// öneriye basmak metni kutuya yazıyor ama aynı anda klavyeyi kapatıyor,
/// kullanıcı yazmaya devam edemiyordu.
void main() {
  /// Dokunuşa yanıt veren bir şeyin üstünde mi.
  ///
  /// `keyboardDismissHitsInteractive` uygulamanın kökündeki dinleyicinin
  /// kullandığı denetimin ta kendisi; burada gerçek bir widget ağacı
  /// üzerinde sınanıyor.
  Future<bool> hitsInteractiveAt(WidgetTester tester, Finder finder) async {
    final center = tester.getCenter(finder);
    return keyboardDismissHitsInteractive(center, null);
  }

  testWidgets('düğme isabeti tıklanabilir sayılır', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('bas'),
            ),
          ),
        ),
      ),
    );

    expect(await hitsInteractiveAt(tester, find.text('bas')), isTrue);
  });

  testWidgets('GestureDetector isabeti tıklanabilir sayılır', (tester) async {
    // `Pressable` bunu kullanıyor; öneri şeridindeki chip'ler de öyle.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GestureDetector(
              onTap: () {},
              child: const Text('chip'),
            ),
          ),
        ),
      ),
    );

    expect(await hitsInteractiveAt(tester, find.text('chip')), isTrue);
  });

  testWidgets('metin alanı isabeti tıklanabilir sayılır', (tester) async {
    // Alanın kendisine dokunulduğunda klavye kapanmamalı.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: TextField())),
      ),
    );

    expect(await hitsInteractiveAt(tester, find.byType(TextField)), isTrue);
  });

  testWidgets('boş alan tıklanabilir sayılmaz', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: Text('başlık'),
            ),
          ),
        ),
      ),
    );

    // Ekranın altı: orada dokunuşa yanıt veren hiçbir şey yok.
    final empty = tester.getSize(find.byType(Scaffold));
    expect(
      keyboardDismissHitsInteractive(
        Offset(empty.width / 2, empty.height - 60),
        null,
      ),
      isFalse,
    );
  });

  testWidgets('öneri şeridi chip\'i tıklanabilir sayılır', (tester) async {
    // Bildirilen hata: arama ekranında bir öneriye basmak metni kutuya
    // yazıyor ama aynı anda klavyeyi kapatıyordu. Chip'ler `Pressable`
    // kullanıyor, o da `GestureDetector`.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Pressable(
              onTap: () {},
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text('sabır'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(await hitsInteractiveAt(tester, find.text('sabır')), isTrue);
  });

  testWidgets('düz metin isabeti tıklanabilir sayılmaz', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('sadece yazı'))),
      ),
    );

    expect(await hitsInteractiveAt(tester, find.text('sadece yazı')), isFalse);
  });
}
