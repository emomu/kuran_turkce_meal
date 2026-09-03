import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/core/providers/app_providers.dart';
import 'package:kuran_turkce_meal/data/models/ayah.dart';
import 'package:kuran_turkce_meal/data/repositories/root_repository.dart';
import 'package:kuran_turkce_meal/features/roots/view/root_detail_screen.dart';
import 'package:kuran_turkce_meal/features/roots/widgets/word_picker_sheet.dart';
import 'package:kuran_turkce_meal/data/db/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/localized_app.dart';

/// Kelime seçiminden kök detayına gezinme.
///
/// Yaprak kapandıktan sonra gezinmenin çalışması bu akışın kırılgan noktası:
/// gezinme yaprağın kendi context'iyle yapılırsa, yaprak ağaçtan çıktığı için
/// `Navigator.of` başarısız olur. Akışı uçtan uca çizmeden bu hata görünmez.
void main() async {
  await TestApp.ensureInitialized();

  // Kök detayı geçtiği ayetlerin mealini veritabanından çeker; test ortamında
  // sqflite'ın masaüstü uyarlaması kurulmalı.
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Uygulama artık paketlenmiş SQLite'ı ve `path_provider` ile bulunan bir
  // dizini kullanıyor. Testte platform kanalı yok; motor ve yol doğrudan
  // verilir, böylece veritabanı bellekte açılır.
  AppDatabase.factoryOverride = databaseFactoryFfi;
  // Her test dosyası kendi veritabanı dizinini kullanır. Test dosyaları
  // paralel çalışıyor; ortak bir dosyayı paylaştıklarında SQLite
  // "disk I/O error" verip rastgele testleri düşürüyordu.
  AppDatabase.pathOverride =
      Directory.systemTemp.createTempSync('root_navigation_db_').path;

  late RootRepository repo;

  setUpAll(() async {
    repo = RootRepository();
    await repo.ensureLoaded();
  });

  const fatihaAyah = Ayah(
    id: 1,
    surahNumber: 1,
    ayahNumber: 1,
    translation: 'Rahmân ve Rahîm olan Allah\'ın ismiyle',
    arabic: 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ',
  );

  /// Okuma ekranındaki açılış kalıbının aynısı.
  Widget buildTrigger({Ayah ayah = fatihaAyah}) {
    return Builder(
      builder: (context) => ElevatedButton(
        onPressed: () {
          // Gezingen, yaprak açılmadan önce ekranın context'inden alınır.
          final navigator = Navigator.of(context);
          showModalBottomSheet<void>(
            context: context,
            builder: (_) => WordPickerSheet(
              ayah: ayah,
              surahName: 'Fâtiha',
              onSelect: (word) => navigator.push(
                MaterialPageRoute<void>(
                  builder: (_) => RootDetailScreen(
                    rootArabic: word.root,
                    focusSurah: word.surahNumber,
                    focusAyah: word.ayahNumber,
                  ),
                ),
              ),
            ),
          );
        },
        child: const Text('Kök analizi'),
      ),
    );
  }

  testWidgets('uzun ayette yaprak ekranı kaplamaz', (tester) async {
    // Bakara 170'te 13 köklü kelime var; sınır olmasaydı liste ekranın
    // tamamını kaplar ve altındaki ayet görünmezdi.
    const longAyah = Ayah(
      id: 177,
      surahNumber: 2,
      ayahNumber: 170,
      translation: 'Onlara "Allah\'ın indirdiğine uyun" denildiğinde...',
      arabic: 'وَإِذَا قِيلَ لَهُمُ ٱتَّبِعُواْ مَآ أَنزَلَ ٱللَّهُ قَالُواْ '
          'بَلۡ نَتَّبِعُ مَآ أَلۡفَيۡنَا عَلَيۡهِ ءَابَآءَنَآۚ أَوَلَوۡ '
          'كَانَ ءَابَآؤُهُمۡ لَا يَعۡقِلُونَ شَيۡـࣰٔ ا وَلَا يَهۡتَدُونَ',
    );

    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [rootRepositoryProvider.overrideWithValue(repo)],
          child: TestApp.wrap(buildTrigger(ayah: longAyah)),
        ),
      );
      await tester.pump();
    });
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kök analizi'));
    await tester.pumpAndSettle();

    final sheetHeight = tester.getSize(find.byType(WordPickerSheet)).height;
    final screenHeight = tester.getSize(find.byType(MaterialApp)).height;

    // Yaprak ekranın en fazla yarısından biraz fazlasını kaplamalı.
    expect(sheetHeight, lessThanOrEqualTo(screenHeight * 0.6));

    // Liste kaydırılabilir olmalı; kelimeler kesilmemeli, gizlenmemeli.
    expect(
      find.descendant(
        of: find.byType(WordPickerSheet),
        matching: find.byType(ListView),
      ),
      findsOneWidget,
    );
  });

  testWidgets('kelime seçilince kök detayına gidilir', (tester) async {
    // ProviderScope MaterialApp'in de üstünde olmalı: modal yapraklar kök
    // gezingende açılır ve uygulamanın alt ağacındaki bir scope'u göremez.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [rootRepositoryProvider.overrideWithValue(repo)],
          child: TestApp.wrap(buildTrigger()),
        ),
      );
      await tester.pump();
    });
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kök analizi'));
    await tester.pumpAndSettle();

    // Yaprak açıldı: ayetin kelimeleri kökleriyle listelenir.
    expect(find.text('Kökünü görmek istediğin kelimeye dokun'), findsOneWidget);

    // "بِسۡمِ" kelimesinin kökü سمو; kelimenin altında kök etiketi çizilir.
    final rootChip = find.text('سمو');
    expect(rootChip, findsOneWidget);

    await tester.tap(rootChip);
    await tester.pumpAndSettle();

    // Yaprak kapandıktan sonra gezinme çalışmalı, çökmemeli.
    expect(tester.takeException(), isNull);
    expect(find.byType(RootDetailScreen), findsOneWidget);
  });

  testWidgets('kelime satırı Türkçe anlamı ve tam genişliği kullanır',
      (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [rootRepositoryProvider.overrideWithValue(repo)],
          child: TestApp.wrap(buildTrigger()),
        ),
      );
      await tester.pump();
    });
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kök analizi'));
    await tester.pumpAndSettle();

    // Kelimenin Türkçe karşılığı satırda görünmeli — kullanıcının asıl
    // aradığı bilgi bu; yalnızca Arapça kök yeterli değil.
    // Fâtiha 1'de "ٱللَّهِ" kelimesinin kökü أله, ilk karşılığı "ilah".
    expect(find.textContaining('ilah'), findsWidgets);
    // "ٱلرَّحۡمَٰنِ" kökü رحم, ilk karşılığı "rahmet".
    expect(find.textContaining('rahmet'), findsWidgets);

    // Yaprak kullanılabilir genişliği kaplamalı, içeriğe göre daralmamalı.
    // Flutter modal yapraklara 640pt üst sınır uygular; telefon
    // genişliklerinde (390pt) bu sınır devreye girmez, yaprak ekranı kaplar.
    final sheetWidth = tester.getSize(find.byType(WordPickerSheet)).width;
    final screenWidth = tester.getSize(find.byType(MaterialApp)).width;
    expect(sheetWidth, screenWidth < 640 ? screenWidth : 640.0);

    // Asıl sınanan: yaprak içeriğine göre büzülmüyor. Kelime satırları da
    // aynı genişliği doldurur. (InkWell'ler arasından yaprağın içindekiler
    // seçilir; tetikleyici buton da bir InkWell barındırır.)
    final rowWidth = tester
        .getSize(
          find.descendant(
            of: find.byType(WordPickerSheet),
            matching: find.byType(InkWell),
          ).first,
        )
        .width;
    expect(rowWidth, sheetWidth);
  });
}
