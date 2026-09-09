import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulamanın cihaz diline göre açılması.
///
/// `main()` içinde `startLocale` verilmiyor; dil şu sırayla belirleniyor:
/// kullanıcının önceki seçimi, yoksa cihazın dili, o da desteklenmiyorsa
/// `fallbackLocale` (Türkçe). Bu davranış tek bir satırın **yokluğuna**
/// bağlı: `startLocale` eklenirse İngilizce telefonlar da Türkçe açılır ve
/// kimse fark etmez.
///
/// Tek bir test var çünkü `easy_localization` seçilen dili statik olarak
/// saklıyor ve aynı süreçte ikinci bir dil çözümlemesi ilkinin sonucunu
/// döndürüyor. Bölünmüş testler birbirinin durumunu ölçerdi.
void main() {
  testWidgets('cihaz dili İngilizceyken uygulama İngilizce açılır',
      (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    // Cihaz dili ağaç kurulmadan önce verilmeli: başlangıç dili ilk çizimde
    // belirleniyor. `en_US` bilinçli — telefonlar dili çoğunlukla bölgeyle
    // birlikte bildirir, desteklenen listede ise sade `en` var. Eşleşme dil
    // kodu üzerinden kurulmazsa bu cihazlar Türkçeye düşerdi.
    tester.platformDispatcher.localesTestValue = [const Locale('en', 'US')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await EasyLocalization.ensureInitialized();

    late Locale resolved;
    await tester.pumpWidget(
      EasyLocalization(
        // main.dart ile aynı yapılandırma; `startLocale` bilerek yok.
        supportedLocales: const [Locale('tr'), Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('tr'),
        child: Builder(
          builder: (context) {
            resolved = context.locale;
            return MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      resolved.languageCode,
      'en',
      reason: 'İngilizce cihaz Türkçeye düşerse startLocale eklenmiş olabilir',
    );
  });
}
