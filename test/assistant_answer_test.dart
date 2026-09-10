import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/data/models/prophet.dart';
import 'package:kuran_turkce_meal/data/models/surah.dart';
import 'package:kuran_turkce_meal/features/assistant/data/assistant_intent.dart';
import 'package:kuran_turkce_meal/features/assistant/data/assistant_message.dart';
import 'package:kuran_turkce_meal/features/assistant/domain/answer_composer.dart';
import 'package:kuran_turkce_meal/features/assistant/domain/turkish_suffix.dart';

/// Cevap metinlerinin kuruluşu.
///
/// Bestecinin tek işi şablonu veriyle doldurmak; ürettiği her cümle burada
/// denetlenebilir. Asistanın "uydurmadığı" iddiasının karşılığı budur:
/// çıktı, girdiden hesaplanır ve test edilebilir.
void main() {
  const bakara = Surah(
    number: 2,
    name: 'Bakara',
    meaning: 'İnek',
    ayahCount: 286,
    revelationOrder: 87,
    revelationPlace: RevelationPlace.medine,
  );

  const kehf = Surah(
    number: 18,
    name: 'Kehf',
    meaning: 'Mağara',
    ayahCount: 110,
    revelationOrder: 69,
    revelationPlace: RevelationPlace.mekke,
  );

  group('sure künyesi', () {
    test('ayet sayısı doğru yazılır', () {
      final answer = AnswerComposer().surahInfo(
        const SurahInfoIntent(surah: kehf, facet: SurahFacet.ayahCount),
      );
      expect(answer.text, contains('110'));
      expect(answer.text, contains('Kehf'));
    });

    test('iniş yeri enum\'dan okunur', () {
      final mekki = AnswerComposer().surahInfo(
        const SurahInfoIntent(surah: kehf, facet: SurahFacet.revelationPlace),
      );
      expect(mekki.text, contains('Mekke'));

      final medeni = AnswerComposer().surahInfo(
        const SurahInfoIntent(
          surah: bakara,
          facet: SurahFacet.revelationPlace,
        ),
      );
      expect(medeni.text, contains('Medine'));
    });

    test('künye cevabı sureyi açan eylem taşır', () {
      final answer = AnswerComposer().surahInfo(
        const SurahInfoIntent(surah: bakara, facet: SurahFacet.overview),
      );
      expect(answer.actions, isNotEmpty);
      expect(answer.actions.first.route, '/sure/2');
    });
  });

  group('konu cevabı', () {
    test('sözlük konusunda sonuç yoksa cevap bir şey iddia etmez', () {
      // Sözlükten gelen konu meşrudur; sonuç çıkmadıysa sorun aramadadır
      // ve kullanıcıya başka kelime denemesi önerilir.
      final answer = AnswerComposer().topic(
        intent: const TopicIntent(
          query: 'sabır',
          topicLabel: 'sabır',
          terms: ['sabr'],
        ),
        ayahs: const [],
        totalFound: 0,
        shownSoFar: 0,
      );
      expect(answer.ayahs, isEmpty);
      expect(answer.text.toLowerCase(), contains('bulamadım'));
    });

    test('serbest aramada sonuç yoksa sınır hatırlatılır', () {
      // Sözlükte olmayan ve mealde hiç geçmeyen bir kelime, büyük
      // olasılıkla alan dışıdır. "Başka kelime dene" demek kullanıcıyı
      // olmayan bir sonucun peşinde dolaştırırdı.
      final answer = AnswerComposer().topic(
        intent: const TopicIntent(query: 'xyz', topicLabel: 'xyz'),
        ayahs: const [],
        totalFound: 0,
        shownSoFar: 0,
      );
      expect(answer.ayahs, isEmpty);
      expect(answer.text.toLowerCase(), contains('geçmiyor'));
      expect(answer.text.toLowerCase(), contains('yalnızca'));
    });

    test('hüküm sorusunda fetva verilmez', () {
      final answer =
          AnswerComposer().outOfScope(OutOfScopeReason.religiousRuling);
      expect(answer.text, contains('hüküm veremem'));
      expect(answer.ayahs, isEmpty);
      expect(answer.note, isNotNull);
    });

    test('alan dışı cevabı ayet taşımaz', () {
      final answer = AnswerComposer().outOfScope(OutOfScopeReason.offTopic);
      expect(answer.ayahs, isEmpty);
      expect(answer.text, contains('yalnızca'));
    });
  });

  group('peygamber cevabı', () {
    const muhammed = Prophet(
      id: 'muhammed',
      name: 'Muhammed',
      nameEn: 'Muhammad',
      ayahIds: [1, 2, 3],
      mentionIds: [1, 2, 3, 4, 5],
    );

    const yusuf = Prophet(
      id: 'yusuf',
      name: 'Yûsuf',
      nameEn: 'Joseph',
      ayahIds: [10, 11],
    );

    test('anılma sayısı kıssa sayısından ayrı anlatılır', () {
      final answer = AnswerComposer().prophet(
        intent: const ProphetIntent(prophet: muhammed, wantsStory: false),
        ayahs: const [],
        totalFound: 5,
        shownSoFar: 3,
      );
      // Kullanıcı adını arattığında beklediği sayı anılma sayısıdır.
      expect(answer.text, contains('5 ayet'));
      expect(answer.text, contains('3 ayet'));
    });

    test('kıssa istendiğinde kıssa sayısı anlatılır', () {
      final answer = AnswerComposer().prophet(
        intent: const ProphetIntent(prophet: muhammed, wantsStory: true),
        ayahs: const [],
        totalFound: 3,
        shownSoFar: 3,
      );
      expect(answer.text, contains('kıssası'));
      expect(answer.text, contains('3 ayet'));
    });

    test('ayrımı olmayan peygamberde tek sayı anlatılır', () {
      final answer = AnswerComposer().prophet(
        intent: const ProphetIntent(prophet: yusuf, wantsStory: false),
        ayahs: const [],
        totalFound: 2,
        shownSoFar: 2,
      );
      expect(answer.text, contains('2 ayet'));
      expect(answer.text, isNot(contains('birlikte')));
    });

    test('gösterilenden fazlası varsa tümünü açan eylem eklenir', () {
      final answer = AnswerComposer().prophet(
        intent: const ProphetIntent(prophet: muhammed, wantsStory: false),
        ayahs: const [],
        totalFound: 5,
        shownSoFar: 3,
      );
      expect(
        answer.actions.any((a) => a.kind == AssistantActionKind.openAll),
        isTrue,
      );
    });
  });

  group('sayı ifadesi', () {
    test('bir ayet tekil yazılır', () {
      final answer = AnswerComposer().surahInfo(
        const SurahInfoIntent(surah: kehf, facet: SurahFacet.ayahCount),
      );
      // "1 ayet" değil "bir ayet" — sayı ifadeleri şablonda dilbilgisine
      // uyar; asistanın konuşuyor gibi durmasının küçük ama gerekli parçası.
      expect(answer.text, isNot(contains('1 ayettir')));
    });
  });

  group('Türkçe ek uyumu', () {
    test('bulunma hâli ünsüz sertliğine uyar', () {
      expect(TurkishSuffix.locative('Bakara'), "Bakara'da");
      expect(TurkishSuffix.locative('Kehf'), "Kehf'te");
      expect(TurkishSuffix.locative('Yâsîn'), "Yâsîn'de");
    });

    test('yönelme hâli ünlüden sonra kaynaştırma alır', () {
      expect(TurkishSuffix.dative('Bakara'), "Bakara'ya");
      expect(TurkishSuffix.dative('Kehf'), "Kehf'e");
    });

    test('ayrılma hâli sertleşir', () {
      expect(TurkishSuffix.ablative('Bakara'), "Bakara'dan");
      expect(TurkishSuffix.ablative('Kehf'), "Kehf'ten");
    });

    test('ilgi hâli kaynaştırma alır', () {
      expect(TurkishSuffix.genitive('Bakara'), "Bakara'nın");
      expect(TurkishSuffix.genitive('Kehf'), "Kehf'in");
    });

    test('cins ad kesme işareti almaz', () {
      // Kesme yalnızca özel ada gelir; "sabır'da" yanlış olurdu.
      expect(TurkishSuffix.locativeCommon('sabır'), 'sabırda');
      expect(TurkishSuffix.locativeCommon('borç'), 'borçta');
      expect(TurkishSuffix.locativeCommon('adalet'), 'adalette');
    });

    test('şapkalı ünlü kalınlık belirler', () {
      // "â" kalın sayılır; ince varsayılsa "Mûsâ'de" çıkardı.
      expect(TurkishSuffix.locative('Mûsâ'), "Mûsâ'da");
    });
  });
}
