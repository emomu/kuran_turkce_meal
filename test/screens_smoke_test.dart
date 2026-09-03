

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/core/providers/app_providers.dart';
import 'package:kuran_turkce_meal/core/theme/app_theme.dart';
import 'package:kuran_turkce_meal/data/models/ayah.dart';
import 'package:kuran_turkce_meal/data/models/surah.dart';
import 'package:kuran_turkce_meal/data/models/user_marks.dart';
import 'package:kuran_turkce_meal/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:kuran_turkce_meal/features/bookmarks/view/bookmarks_screen.dart';
import 'package:kuran_turkce_meal/features/plans/providers/plans_provider.dart';
import 'package:kuran_turkce_meal/features/plans/view/plans_screen.dart';
import 'package:kuran_turkce_meal/features/settings/view/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/localized_app.dart';
const _surah = Surah(
  number: 96,
  name: 'Alak',
  meaning: 'Kan Pıhtısı',
  revelationOrder: 1,
  revelationPlace: RevelationPlace.mekke,
  ayahCount: 19,
);

const _ayah = Ayah(
  id: 1,
  surahNumber: 96,
  ayahNumber: 1,
  translation: 'Yaratan Rabbinin adıyla oku.',
);

/// Ekranı sahte sağlayıcılarla kurar.
Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  List<Override> overrides = const [],
  Brightness brightness = Brightness.light,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  // Çeviriler diskten gerçek asenkron I/O ile okunur; `runAsync` olmadan
  // test zamanlayıcısı bu okumayı beklemez ve ağaç boş kalır.
  await tester.runAsync(() async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        ...overrides,
      ],
      child: TestApp.wrap(
        screen,
        theme: brightness == Brightness.light ? AppTheme.light : AppTheme.dark,
      ),
    ));
    await tester.pump();
  });
  await tester.pumpAndSettle();
}

void main() async {
  await TestApp.ensureInitialized();

  group('PlansScreen', () {
    testWidgets('dört hazır planı listeler', (tester) async {
      await _pump(
        tester,
        const PlansScreen(),
        overrides: [
          planProgressProvider.overrideWith((ref, id) async => 0),
        ],
      );

      expect(find.text('Planlar'), findsOneWidget);
      expect(find.text('Bir Yılda Kronolojik'), findsOneWidget);
      expect(find.text('Otuz Günde Hatim'), findsOneWidget);
      // Sıralama rozetleri her karta düşer.
      expect(find.text('İniş sırası'), findsNWidgets(2));
      expect(find.text('Mushaf'), findsNWidgets(2));
    });

    testWidgets('başlanmamış planda ilerleme çubuğu çizilmez', (tester) async {
      await _pump(
        tester,
        const PlansScreen(),
        overrides: [planProgressProvider.overrideWith((ref, id) async => 0)],
      );
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('başlanmış planda ilerleme görünür', (tester) async {
      await _pump(
        tester,
        const PlansScreen(),
        overrides: [planProgressProvider.overrideWith((ref, id) async => 10)],
      );
      expect(find.byType(LinearProgressIndicator), findsWidgets);
      expect(find.textContaining('10/'), findsWidgets);
    });
  });

  group('BookmarksScreen', () {
    testWidgets('yer imi yokken yönlendirici boş durum gösterir',
        (tester) async {
      await _pump(
        tester,
        const BookmarksScreen(),
        overrides: [
          savedEntriesProvider.overrideWith((ref, tab) async => []),
        ],
      );

      expect(find.text('Henüz yer imi yok'), findsOneWidget);
      expect(find.textContaining('uzun basın'), findsOneWidget);
    });

    testWidgets('kaydedilmiş ayeti sure adıyla listeler', (tester) async {
      await _pump(
        tester,
        const BookmarksScreen(),
        overrides: [
          savedEntriesProvider.overrideWith((ref, tab) async => [
                SavedEntry(
                  ayah: _ayah,
                  surah: _surah,
                  mark: AyahMark(
                    ayahId: 1,
                    isBookmarked: true,
                    updatedAt: DateTime(2026),
                  ),
                ),
              ]),
        ],
      );

      expect(find.text('Alak · 1. ayet'), findsOneWidget);
      expect(find.text('Yaratan Rabbinin adıyla oku.'), findsOneWidget);
    });

    testWidgets('üç sekme de görünür', (tester) async {
      await _pump(
        tester,
        const BookmarksScreen(),
        overrides: [savedEntriesProvider.overrideWith((ref, tab) async => [])],
      );

      expect(find.text('Yer imleri'), findsOneWidget);
      expect(find.text('Notlar'), findsOneWidget);
      expect(find.text('Vurgular'), findsOneWidget);
    });
  });

  group('SettingsScreen', () {
    /// Hedefi görünür yapar.
    ///
    /// Ayarlar listesi kısaldığında kaydırılacak taşma kalmayabilir;
    /// `scrollUntilVisible` o durumda kaydırılabilir öğe bulamayıp hata
    /// verir. Bu yüzden önce ağaçta aranır, yoksa liste elle sürüklenir.
    Future<void> ensureVisible(WidgetTester tester, Finder finder) async {
      if (finder.evaluate().isNotEmpty) return;
      final list = find.byType(Scrollable);
      for (var i = 0; i < 12 && finder.evaluate().isEmpty; i++) {
        await tester.drag(list.first, const Offset(0, -250));
        await tester.pump();
      }
    }

    testWidgets('tüm ayar bölümlerini gösterir', (tester) async {
      await _pump(tester, const SettingsScreen());

      // Üstteki bölümler ilk karede görünür.
      expect(find.text('GÖRÜNÜM'), findsOneWidget);
      expect(find.text('OKUMA'), findsOneWidget);
      expect(find.text('Arapça metin'), findsOneWidget);
      expect(find.text('İniş sırasına göre dizi'), findsOneWidget);

      // Alttaki bölümler için listeyi kaydır; test ekranı gerçek cihazdan
      // kısa olduğu için bunlar henüz çizilmemiş olur.
      await ensureVisible(tester, find.text('GÜNÜN AYETİ'));
      expect(find.text('GÜNÜN AYETİ'), findsOneWidget);

      await ensureVisible(tester, find.text('SIFIRLA'));
      expect(find.text('Okuma ayarlarını sıfırla'), findsOneWidget);
    });

    testWidgets('bildirim kapatılınca saat satırı gizlenir', (tester) async {
      await _pump(tester, const SettingsScreen());

      await ensureVisible(tester, find.text('Bildirim'));
      expect(find.text('Bildirim saati'), findsOneWidget);

      // "Bildirim" anahtarını kapat; saat satırı kaybolmalı.
      final notificationSwitch = find.ancestor(
        of: find.text('Her gün bir ayet hatırlatması'),
        matching: find.byType(Row),
      );
      final toggle = find.descendant(
        of: notificationSwitch.first,
        matching: find.byType(Switch),
      );
      // Anahtar ekranın dışında kalabilir; dokunuş kayıtsız kalmasın.
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(find.text('Bildirim saati'), findsNothing);
    });

    testWidgets('koyu temada taşma olmadan çizilir', (tester) async {
      await _pump(tester, const SettingsScreen(),
          brightness: Brightness.dark);
      expect(tester.takeException(), isNull);
    });

    // Mağazalar gizlilik politikası ve kullanım şartlarının uygulama içinden
    // açılabilmesini şart koşar; bölüm kazara silinirse inceleme reddeder.
    testWidgets('yasal bölüm gizlilik ve şartları listeler', (tester) async {
      await _pump(tester, const SettingsScreen());

      await ensureVisible(tester, find.text('YASAL'));
      expect(find.text('Gizlilik Politikası'), findsOneWidget);
      expect(find.text('Kullanım Şartları'), findsOneWidget);
      expect(find.text('Kaynaklar ve Telif'), findsOneWidget);
      expect(find.text('Açık Kaynak Lisansları'), findsOneWidget);
    });
  });
}
