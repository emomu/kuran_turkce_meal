import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/features/legal/data/legal_texts.dart';
import 'package:kuran_turkce_meal/features/legal/view/legal_document_screen.dart';

import 'helpers/localized_app.dart';

/// Yasal metinler mağaza incelemesinin denetlediği yerlerden biri: politika
/// erişilebilir olmalı, uygulamanın gerçek davranışını anlatmalı ve iki dilde
/// de bulunmalı. Bu testler metnin varlığını ve ekranın çizildiğini doğrular.
void main() {
  setUp(TestApp.reset);

  group('Yasal metinler', () {
    test('gizlilik politikası iki dilde de dolu', () {
      for (final code in ['tr', 'en']) {
        final text = LegalTexts.privacy(code);
        expect(text.trim(), isNotEmpty, reason: '$code gizlilik metni boş');
        expect(text.length, greaterThan(500));
      }
    });

    test('kullanım şartları iki dilde de dolu', () {
      for (final code in ['tr', 'en']) {
        final text = LegalTexts.terms(code);
        expect(text.trim(), isNotEmpty, reason: '$code şartlar metni boş');
        expect(text.length, greaterThan(500));
      }
    });

    test('kaynak bildirimi kök verisinin lisansını anar', () {
      // Quranic Arabic Corpus GPL ile dağıtılır ve atıf şart koşar.
      expect(LegalTexts.sources('tr'), contains('Quranic Arabic Corpus'));
      expect(LegalTexts.sources('en'), contains('Quranic Arabic Corpus'));
    });

    test('gizlilik metni veri toplanmadığını açıkça söyler', () {
      // Mağaza formundaki "veri toplanmıyor" beyanıyla metin tutarlı olmalı;
      // ikisi çeliştiğinde inceleme reddeder.
      expect(LegalTexts.privacy('tr'), contains('toplamaz'));
      expect(LegalTexts.privacy('en'), contains('collects no information'));
    });

    test('bilinmeyen dil kodu Türkçeye düşer', () {
      expect(LegalTexts.privacy('de'), LegalTexts.privacy('tr'));
    });

    test('iletişim adresi her belgede bulunur', () {
      for (final code in ['tr', 'en']) {
        expect(LegalTexts.privacy(code), contains(LegalTexts.contactEmail));
        expect(LegalTexts.terms(code), contains(LegalTexts.contactEmail));
      }
    });
  });

  group('LegalDocumentScreen', () {
    testWidgets('başlık ve gövde çizilir', (tester) async {
      await TestApp.pump(
        tester,
        const LegalDocumentScreen(
          title: 'Gizlilik Politikası',
          body: '# Başlık\n\nBir paragraf.\n\n## Alt başlık\n\n- İlk madde\n- İkinci madde',
        ),
      );

      expect(find.text('Başlık'), findsOneWidget);
      expect(find.text('Alt başlık'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('kalın işaretlemesi metne gömülür, yıldız görünmez',
        (tester) async {
      await TestApp.pump(
        tester,
        const LegalDocumentScreen(
          title: 'Şartlar',
          body: 'Bu **önemli** bir cümledir.',
        ),
      );

      // `**` kaldırılmalı; ham işaretleme kullanıcıya gösterilmez.
      final rich = tester.widget<RichText>(
        find.byType(RichText).at(1),
      );
      expect(rich.text.toPlainText(), isNot(contains('**')));
    });

    testWidgets('gerçek gizlilik metni taşma olmadan çizilir', (tester) async {
      await TestApp.pump(
        tester,
        LegalDocumentScreen(
          title: 'Gizlilik',
          body: LegalTexts.privacy('tr'),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('koyu temada da çizilir', (tester) async {
      await TestApp.pump(
        tester,
        LegalDocumentScreen(
          title: 'Şartlar',
          body: LegalTexts.terms('tr'),
        ),
        theme: ThemeData.dark(),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Ses hakkında metni', () {
    test('iki dilde de dolu', () {
      // Metin boş kalırsa ayarlardaki satır boş bir sayfa açar; mağaza
      // incelemesinde de kaynak belirtilmemiş sayılır.
      expect(LegalTexts.audioInfo('tr').trim(), isNotEmpty);
      expect(LegalTexts.audioInfo('en').trim(), isNotEmpty);
    });

    test('ses kaynağını adıyla belirtir', () {
      // Kayıtların nereden geldiğini söylemek telif açısından gerekli.
      expect(LegalTexts.audioInfo('tr'), contains('EveryAyah'));
      expect(LegalTexts.audioInfo('en'), contains('EveryAyah'));
    });

    test('çevrimdışı vaadinin sınırını açıkça söyler', () {
      // Uygulamanın "tamamen çevrimdışı" iddiası var; sesin bu kuralın tek
      // istisnası olduğu kullanıcıdan gizlenmemeli.
      expect(LegalTexts.audioInfo('tr'), contains('tek yerdir'));
      expect(LegalTexts.audioInfo('en'), contains('only place'));
    });

    test('dosyaların nasıl silineceğini anlatır', () {
      expect(LegalTexts.audioInfo('tr').toLowerCase(), contains('sil'));
      expect(LegalTexts.audioInfo('en').toLowerCase(), contains('delete'));
    });

    test('bilinmeyen dil Türkçeye düşer', () {
      expect(LegalTexts.audioInfo('de'), LegalTexts.audioInfo('tr'));
    });
  });
}
