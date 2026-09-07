import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/core/providers/app_providers.dart';
import 'package:kuran_turkce_meal/core/theme/app_typography.dart';
import 'package:kuran_turkce_meal/features/settings/view/settings_screen.dart';
import 'package:kuran_turkce_meal/data/models/reader_preferences.dart';
import 'package:kuran_turkce_meal/features/settings/providers/preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/localized_app.dart';

/// Okuma ayarları: kaydırıcı görünümü ve canlı önizleme.
void main() async {
  await TestApp.ensureInitialized();

  late SharedPreferences sp;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sp = await SharedPreferences.getInstance();
  });

  Future<void> pumpSettings(WidgetTester tester) => TestApp.pump(
        tester,
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
          child: const SettingsScreen(),
        ),
      );

  testWidgets('okuma ayarlarının canlı örneği gösterilir', (tester) async {
    await pumpSettings(tester);

    // Punto ve satır aralığı soyut sayılar; sonucu gösteren bir örnek olmalı.
    expect(find.text('ÖRNEK'), findsOneWidget);
    expect(find.textContaining('Rabbimiz'), findsOneWidget);
  });

  testWidgets('örnek metin seçili punto ve satır aralığını kullanır',
      (tester) async {
    await pumpSettings(tester);

    // Metne en yakın olan bizim önizleme sarmalayıcımız; ata zincirinde
    // Flutter'ın kendi AnimatedDefaultTextStyle'ları da bulunuyor.
    final preview = tester.widget<AnimatedDefaultTextStyle>(
      find.ancestor(
        of: find.textContaining('Rabbimiz'),
        matching: find.byType(AnimatedDefaultTextStyle),
      ).first,
    );

    // Varsayılanlar: fontScale 1.0 (17pt taban), lineHeight 1.7.
    expect(preview.style.fontSize, 17);
    expect(preview.style.height, 1.7);
  });

  testWidgets('kaydırıcı adım noktaları çizmez', (tester) async {
    await pumpSettings(tester);

    final sliderTheme = tester.widget<SliderTheme>(
      find.ancestor(
        of: find.byType(Slider).first,
        matching: find.byType(SliderTheme),
      ).first,
    );

    // Benekli ray temadan kopuktu; ray tek sakin çizgi olmalı.
    expect(sliderTheme.data.tickMarkShape, SliderTickMarkShape.noTickMark);
    expect(sliderTheme.data.trackHeight, 3);
  });

  testWidgets('topuz vurgu renginde, beyaz değil', (tester) async {
    await pumpSettings(tester);

    final context = tester.element(find.byType(Slider).first);
    final sliderTheme = tester.widget<SliderTheme>(
      find.ancestor(
        of: find.byType(Slider).first,
        matching: find.byType(SliderTheme),
      ).first,
    );

    // Beyaz topuz koyu temada parlıyordu.
    expect(
      sliderTheme.data.thumbColor,
      Theme.of(context).colorScheme.primary,
    );
  });

  testWidgets('değer rozeti punto yüzdesini gösterir', (tester) async {
    await pumpSettings(tester);
    expect(find.text('%100'), findsOneWidget);
    expect(find.text('1.7'), findsOneWidget);
  });

  testWidgets('örnek kutusuna ayırıcı çizgi değmez', (tester) async {
    await pumpSettings(tester);

    // Örnek metnin kendi zemini var. Bölüm ayırıcısı bu kutunun üst
    // kenarına yapışıp çakışıyordu; ayırıcı iki düz satırı ayırmak için,
    // zaten çerçevesi olan bir öğenin sınırını çizmek için değil.
    final box = tester.getRect(
      find.ancestor(
        of: find.text('ÖRNEK'),
        matching: find.byType(Container),
      ).first,
    );

    for (final divider in find.byType(Divider).evaluate()) {
      final line = tester.getRect(find.byWidget(divider.widget));

      // Yatay olarak kesişmiyorsa zaten sorun yok.
      final overlapsHorizontally =
          line.right > box.left && line.left < box.right;
      if (!overlapsHorizontally) continue;

      // Kesişme değil, aradaki boşluk ölçülür: ayırıcı kutunun üst kenarına
      // sıfır boşlukla yapıştığında piksel olarak çakışmıyor ama ekranda
      // kutunun çerçevesiymiş gibi duruyordu.
      final gap = line.top >= box.bottom
          ? line.top - box.bottom
          : box.top - line.bottom;

      expect(gap, greaterThanOrEqualTo(Insets.sm),
          reason: 'ayırıcı ($line) örnek kutusuna ($box) yapışık');
    }
  });

  group('varsayılan tercihler', () {
    /// Varsayılanlar üç yerde tanımlı: model sabiti, ilk okuma
    /// (`SharedPreferences` boşken) ve "okuma ayarlarını sıfırla". Üçü
    /// ayrışırsa kullanıcı sıfırladığında ilk açılıştakinden farklı bir
    /// duruma düşer.
    test('Arapça metin varsayılan olarak açık', () {
      // Uygulama bir Kur'an uygulaması; kullanıcıların çoğu orijinal metni
      // görmeyi bekliyor ve kapalı başlarsa özelliğin varlığı ayarlara
      // girmeden fark edilmiyor.
      expect(const ReaderPreferences().showArabic, isTrue);
    });

    test('depo boşken de Arapça açık gelir', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = PreferencesNotifier(prefs);

      expect(notifier.state.showArabic, isTrue);
    });

    test('kapatılan tercih korunur', () async {
      // Varsayılanın açık olması, kullanıcının kapatma kararını ezmemeli.
      SharedPreferences.setMockInitialValues({'show_arabic': false});
      final prefs = await SharedPreferences.getInstance();
      final notifier = PreferencesNotifier(prefs);

      expect(notifier.state.showArabic, isFalse);
    });

    test('sıfırlama model varsayılanıyla aynı sonucu verir', () async {
      SharedPreferences.setMockInitialValues({'show_arabic': false});
      final prefs = await SharedPreferences.getInstance();
      final notifier = PreferencesNotifier(prefs)..resetReadingDefaults();

      const defaults = ReaderPreferences();
      expect(notifier.state.showArabic, defaults.showArabic);
      expect(notifier.state.fontScale, defaults.fontScale);
      expect(notifier.state.lineHeight, defaults.lineHeight);
    });
  });
}
