import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kuran_turkce_meal/core/providers/app_providers.dart';
import 'package:kuran_turkce_meal/core/router/app_router.dart';
import 'package:kuran_turkce_meal/features/assistant/view/assistant_screen.dart';
import 'package:kuran_turkce_meal/features/assistant/view/widgets/assistant_ayah_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Asistanın gerçek veritabanı üzerinde uçtan uca çalışması.
///
/// Birim testler niyet çözümlemeyi ve şablonları ayrı ayrı doğruluyor ama
/// ikisinin arasındaki yol — sorgunun FTS5'e gidip gerçek ayetle dönmesi —
/// ancak gerçek veritabanıyla görülebilir. Sözlükteki bir terimin mealde
/// hiç geçmemesi tam da burada yakalanır: cevap gelir, ayet gelmez.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await EasyLocalization.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  /// Uygulamayı gerçek yönlendirici ve veritabanıyla kurar, asistanı açar.
  Future<void> openAssistant(WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('tr'), Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('tr'),
        child: ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: Builder(
            builder: (context) => MaterialApp.router(
              routerConfig: appRouter,
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
            ),
          ),
        ),
      ),
    );
    // İlk açılışta meal SQLite'a aktarılıyor; bu uzun sürebilir.
    await tester.pumpAndSettle(const Duration(seconds: 10));

    appRouter.go('/asistan');
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.byType(AssistantScreen), findsOneWidget);
  }

  /// Soruyu yazar, gönderir ve cevabı bekler.
  Future<void> ask(WidgetTester tester, String question) async {
    await tester.enterText(find.byType(TextField), question);
    await tester.pumpAndSettle();

    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  testWidgets('konu sorusu gerçek ayet getirir', (tester) async {
    await openAssistant(tester);
    await ask(tester, 'sabır');

    // Soru akışta görünmeli.
    expect(find.text('sabır'), findsWidgets);

    // Asıl doğrulama: cevap ayet kartı taşıyor. Kart yoksa sözlükteki
    // terimler mealde karşılık bulmamış demektir — asistanın en sinsi
    // hata biçimi tam olarak bu.
    expect(find.byType(AssistantAyahCard), findsWidgets);
  });

  testWidgets('durum sorusu ayet getirir', (tester) async {
    await openAssistant(tester);
    await ask(tester, 'zor zamandayım');

    expect(find.byType(AssistantAyahCard), findsWidgets);
  });

  testWidgets('ayet referansı doğru ayeti getirir', (tester) async {
    await openAssistant(tester);
    await ask(tester, 'Bakara 255');

    expect(find.byType(AssistantAyahCard), findsOneWidget);
    // Ayetü'l-Kürsî'nin künyesi kartta görünmeli.
    expect(find.textContaining('Bakara 255'), findsWidgets);
  });

  testWidgets('Muhammed araması hitap ayetlerini de getirir', (tester) async {
    // Düzeltilen bug: kıssa listesi 10 ayet döndürüyordu, oysa "Ey Muhammed"
    // hitabıyla birlikte 140 ayette anılıyor.
    await openAssistant(tester);
    await ask(tester, 'Muhammed');

    expect(find.byType(AssistantAyahCard), findsWidgets);
    // Cevap metni anılma sayısını söylemeli. Ad aynı zamanda 47. surenin
    // adı; sure künyesi dönerse ad çakışması yeniden kazanmış demektir.
    expect(find.textContaining('anılıyor'), findsOneWidget);
    // Sureye giden yol da kalmalı.
    expect(find.textContaining('suresini aç'), findsOneWidget);
  });

  testWidgets('alan dışı soru ayet getirmez', (tester) async {
    await openAssistant(tester);
    await ask(tester, 'hava durumu nasıl');

    // Reddedilen soruya ayet iliştirilmemeli.
    expect(find.byType(AssistantAyahCard), findsNothing);
    expect(find.textContaining('yalnızca'), findsOneWidget);
  });

  testWidgets('hüküm sorusu fetva vermez', (tester) async {
    await openAssistant(tester);
    await ask(tester, 'faiz haram mı');

    expect(find.byType(AssistantAyahCard), findsNothing);
    expect(find.textContaining('hüküm veremem'), findsOneWidget);
  });

  testWidgets('sure künyesi cevaplanır', (tester) async {
    await openAssistant(tester);
    await ask(tester, 'Kehf kaç ayet');

    expect(find.textContaining('110'), findsWidgets);
  });
}
