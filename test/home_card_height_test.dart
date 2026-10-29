import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/core/theme/app_theme.dart';
import 'package:kuran_turkce_meal/data/models/surah.dart';
import 'package:kuran_turkce_meal/features/home/providers/home_provider.dart';
import 'package:kuran_turkce_meal/features/home/widgets/home_cards.dart';

import 'helpers/localized_app.dart';

const _surah = Surah(
  number: 36,
  name: 'Yâsîn',
  nameEn: 'Ya-Sin',
  meaning: 'Yâsîn',
  meaningEn: 'Ya-Sin',
  revelationOrder: 41,
  revelationPlace: RevelationPlace.mekke,
  ayahCount: 83,
);

void main() async {
  await TestApp.ensureInitialized();
  setUp(TestApp.reset);

  group('kaldığın yer kartı', () {
    /// Kartı 390pt genişlikte (iPhone 13 taban ölçüsü) çizer ve yüksekliğini
    /// döndürür.
    Future<double> cardHeight(WidgetTester tester, {String? longName}) async {
      await TestApp.pump(
        tester,
        Center(
          child: SizedBox(
            width: 350, // 390 - 2*20 ekran kenar boşluğu
            child: ContinueReadingCard(
              lastRead: LastRead(
                surah: longName == null
                    ? _surah
                    : Surah(
                        number: 3,
                        name: longName,
                        meaning: 'İmran Ailesi',
                        revelationOrder: 89,
                        revelationPlace: RevelationPlace.medine,
                        ayahCount: 200,
                      ),
                ayahNumber: 4,
              ),
              onTap: () {},
            ),
          ),
        ),
        theme: AppTheme.light,
      );

      return tester.getSize(find.byType(ContinueReadingCard)).height;
    }

    testWidgets('kart ekranın üçte birini kaplamaz', (tester) async {
      // Kart, altındaki günün ayeti kartını ve sure listesini ekranda
      // bırakmalı. Dikey yığılmış düzende 145pt'ye çıkıyordu ve ana ekranda
      // liste görünmeden önce iki kart tüm alanı yiyordu.
      //
      // Künye tek satıra indirildikten sonra 71pt; sınır 80 tutuldu ki
      // bir satır daha eklenirse test uyarsın.
      final height = await cardHeight(tester);

      expect(height, lessThan(80));
    });

    testWidgets('rozet, sure adı ve ayet bilgisi aynı hizada', (tester) async {
      await cardHeight(tester);

      // Üç öğe tek satırda durur; biri diğerlerinden kayarsa satır
      // dağınık görünür. Dikey merkezleri karşılaştırılır — yazı
      // boyutları farklı olduğu için üst/alt kenarlar zaten eşit olmaz.
      final badge = tester.getRect(find.text('Devam Et'));
      final name = tester.getRect(find.text('Yâsîn'));
      final counter = tester.getRect(find.textContaining('4/'));

      expect(badge.center.dy, closeTo(name.center.dy, 2.0),
          reason: 'rozet sure adından kaymış');
      expect(counter.center.dy, closeTo(name.center.dy, 2.0),
          reason: 'ayet bilgisi sure adından kaymış');
    });

    testWidgets('uzun sure adı kartı büyütmez', (tester) async {
      // "Âl-i İmrân" gibi uzun adlar tek satırda kırpılır; sarmasına izin
      // verilseydi kart o surelerde bir satır uzar ve düzenin ritmi
      // kullanıcının nerede kaldığına göre değişirdi.
      final normal = await cardHeight(tester);
      final long = await cardHeight(
        tester,
        longName: 'Âl-i İmrân Suresi Çok Uzun Bir Ad',
      );

      expect(long, normal);
    });

    testWidgets('ilerleme çubuğu ve künye birlikte görünür', (tester) async {
      await cardHeight(tester);

      expect(find.text('Yâsîn'), findsOneWidget);
      // Ayet bilgisi sure adının yanında kesirli biçimde: "4/83". Uzun
      // yazım ("4. ayet · 83 ayetten") kartı bir satır uzatıyordu.
      expect(find.textContaining('4/'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      // Devam etme işareti kartın ne yaptığını etiketten hızlı anlatır.
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });
  });
}
