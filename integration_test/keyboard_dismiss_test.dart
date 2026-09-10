import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kuran_turkce_meal/core/providers/app_providers.dart';
import 'package:kuran_turkce_meal/core/router/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Boşluğa dokununca klavyenin kapanması.
///
/// iOS'ta klavyeyi kapatmanın yerleşik yolu yok; bu davranış olmadan
/// kullanıcı bir alana yazdıktan sonra içeriğin yarısı örtülü kalıyor.
/// Kabukta vardı ama kabuk dışı ekranlarda (okuma, asistan) yoktu.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await EasyLocalization.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('boşluğa dokunmak odağı düşürür', (tester) async {
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
    await tester.pumpAndSettle(const Duration(seconds: 8));

    appRouter.go('/ara');
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(
      FocusManager.instance.primaryFocus?.hasPrimaryFocus,
      isTrue,
      reason: 'alan odakta olmalı',
    );

    // Ekranın ortasına, alanın dışına dokun.
    await tester.tapAt(tester.getCenter(find.byType(Scaffold).first));
    await tester.pumpAndSettle();

    final focus = FocusManager.instance.primaryFocus;
    final stillEditing = focus?.context?.widget is EditableText;
    expect(stillEditing, isFalse, reason: 'klavye odağı düşmeliydi');
  });
}
