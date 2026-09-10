import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/data/db/search_normalizer.dart';
import 'package:kuran_turkce_meal/data/models/prophet.dart';
import 'package:kuran_turkce_meal/data/models/surah.dart';
import 'package:kuran_turkce_meal/features/assistant/data/assistant_intent.dart';
import 'package:kuran_turkce_meal/features/assistant/data/topic_lexicon.dart';
import 'package:kuran_turkce_meal/features/assistant/domain/answer_composer.dart';
import 'package:kuran_turkce_meal/features/assistant/domain/intent_classifier.dart';
import 'package:kuran_turkce_meal/features/search/data/verse_reference.dart';

/// Asistanın İngilizce tarafı.
///
/// İngilizce arayüzde cevap cümlelerinin Türkçe kalması, ayetler doğru
/// gelse bile asistanı bozuk gösterirdi. Şablonlar `easy_localization`
/// yerine bestecide tutulduğu için (cevaplar sayı ve ek uyumuna göre
/// hesaplanıyor) iki dilin ayrı ayrı sınanması gerekiyor.
void main() {
  const kehf = Surah(
    number: 18,
    name: 'Kehf',
    nameEn: 'Al-Kahf',
    meaning: 'Mağara',
    meaningEn: 'The Cave',
    ayahCount: 110,
    revelationOrder: 69,
    revelationPlace: RevelationPlace.mekke,
  );

  const bakara = Surah(
    number: 2,
    name: 'Bakara',
    nameEn: 'Al-Baqarah',
    meaning: 'İnek',
    meaningEn: 'The Cow',
    ayahCount: 286,
    revelationOrder: 87,
    revelationPlace: RevelationPlace.medine,
  );

  const prophets = [
    Prophet(
      id: 'muhammed',
      name: 'Muhammed',
      nameEn: 'Muhammad',
      ayahIds: [1, 2, 3],
      mentionIds: [1, 2, 3, 4, 5],
    ),
    Prophet(
      id: 'yusuf',
      name: 'Yûsuf',
      nameEn: 'Joseph',
      ayahIds: [10, 11],
    ),
  ];

  final classifier = IntentClassifier(
    surahs: const [bakara, kehf],
    prophets: prophets,
    foldName: foldSurahName,
    languageCode: 'en',
  );

  AssistantIntent classify(String q, {bool hasResults = false}) =>
      classifier.classify(q, hasPreviousResults: hasResults).intent;

  AnswerComposer composer() => AnswerComposer(languageCode: 'en');

  group('İngilizce sınıflandırma', () {
    test('İngilizce konu tanınır', () {
      final intent = classify('patience');
      expect(intent, isA<TopicIntent>());
      // Etiket de İngilizce gelmeli; cevapta bu ad geçiyor.
      expect((intent as TopicIntent).topicLabel, 'patience');
    });

    test('İngilizce durum ifadesi tanınır', () {
      final intent = classify('I am going through a hard time');
      expect(intent, isA<TopicIntent>());
      expect((intent as TopicIntent).isSituational, isTrue);
    });

    test('İngilizce sözlük İngilizce terimleri verir', () {
      final intent = classify('patience') as TopicIntent;
      // Türkçe terimler İngilizce dizinde hiçbir şey bulmazdı.
      expect(intent.terms, contains('patien'));
      expect(intent.terms, isNot(contains('sabr')));
    });

    test('İngilizce sure künyesi tanınır', () {
      final intent = classify('how many verses in al-kahf');
      expect(intent, isA<SurahInfoIntent>());
      expect((intent as SurahInfoIntent).facet, SurahFacet.ayahCount);
    });

    test('İngilizce selam tanınır', () {
      expect(classify('hello'), isA<GreetingIntent>());
    });

    test('İngilizce yardım tanınır', () {
      expect(classify('what can you do'), isA<HelpIntent>());
    });

    test('İngilizce alan dışı reddedilir', () {
      final intent = classify('what is the weather');
      expect(intent, isA<OutOfScopeIntent>());
      expect((intent as OutOfScopeIntent).reason, OutOfScopeReason.offTopic);
    });

    test('İngilizce hüküm sorusu fetva sayılır', () {
      final intent = classify('is it haram to charge interest');
      expect(intent, isA<OutOfScopeIntent>());
      expect(
        (intent as OutOfScopeIntent).reason,
        OutOfScopeReason.religiousRuling,
      );
    });

    test('İngilizce takip ifadesi tanınır', () {
      expect(classify('more', hasResults: true), isA<MoreResultsIntent>());
      final ordinal = classify('second', hasResults: true);
      expect(ordinal, isA<OpenResultIntent>());
      expect((ordinal as OpenResultIntent).index, 1);
    });

    test('İngilizce arayüzde Türkçe soru da tanınır', () {
      // Kullanıcı arayüzü İngilizce yapmış olsa da Türkçe yazabilir.
      expect(classify('sabır'), isA<TopicIntent>());
    });

    test('İngilizce kıssa isteği tanınır', () {
      final intent = classify('the story of Joseph');
      expect(intent, isA<ProphetIntent>());
      expect((intent as ProphetIntent).wantsStory, isTrue);
    });
  });

  group('İngilizce cevap metni', () {
    test('sure künyesi İngilizce adla kurulur', () {
      final answer = composer().surahInfo(
        const SurahInfoIntent(surah: kehf, facet: SurahFacet.ayahCount),
      );
      expect(answer.text, 'Surah Al-Kahf has 110 verses.');
    });

    test('iniş yeri İngilizce yazılır', () {
      final mekki = composer().surahInfo(
        const SurahInfoIntent(surah: kehf, facet: SurahFacet.revelationPlace),
      );
      expect(mekki.text, contains('Mecca'));
      expect(mekki.text, isNot(contains('Mekke')));

      final medeni = composer().surahInfo(
        const SurahInfoIntent(
          surah: bakara,
          facet: SurahFacet.revelationPlace,
        ),
      );
      expect(medeni.text, contains('Medina'));
    });

    test('anlam İngilizce karşılıktan gelir', () {
      final answer = composer().surahInfo(
        const SurahInfoIntent(surah: kehf, facet: SurahFacet.meaning),
      );
      expect(answer.text, contains('The Cave'));
      expect(answer.text, isNot(contains('Mağara')));
    });

    test('sıra sayısı İngilizce eki alır', () {
      final answer = composer().surahInfo(
        const SurahInfoIntent(
          surah: kehf,
          facet: SurahFacet.revelationOrder,
        ),
      );
      // 69 → 69th, 18 → 18th
      expect(answer.text, contains('69th'));
      expect(answer.text, contains('18th'));
    });

    test('eylem etiketleri İngilizce', () {
      final answer = composer().surahInfo(
        const SurahInfoIntent(surah: kehf, facet: SurahFacet.overview),
      );
      expect(answer.actions.first.label, 'Open Surah Al-Kahf');
    });

    test('peygamber cevabı İngilizce adla kurulur', () {
      final answer = composer().prophet(
        intent: ProphetIntent(prophet: prophets.first, wantsStory: false),
        ayahs: const [],
        totalFound: 5,
        shownSoFar: 3,
      );
      expect(answer.text, contains('Muhammad'));
      expect(answer.text, contains('5 verses'));
      expect(answer.text, isNot(contains('anılıyor')));
    });

    test('tekil sayı yazıyla verilir', () {
      // Kıssası tek ayet olan bir peygamber; sayı "1 verse" değil
      // "one verse" diye yazılmalı — cümlenin parçası, sayaç çıktısı değil.
      const zulkifl = Prophet(
        id: 'zulkifl',
        name: 'Zülkifl',
        nameEn: 'Dhul-Kifl',
        ayahIds: [100],
      );

      final answer = composer().prophet(
        intent: const ProphetIntent(prophet: zulkifl, wantsStory: true),
        ayahs: const [],
        totalFound: 1,
        shownSoFar: 1,
      );
      expect(answer.text, contains('one verse'));
      expect(answer.text, isNot(contains('1 verses')));
    });

    test('sonuçsuz cevap İngilizce', () {
      final answer = composer().topic(
        intent: const TopicIntent(query: 'xyz', topicLabel: 'xyz'),
        ayahs: const [],
        totalFound: 0,
        shownSoFar: 0,
      );
      expect(answer.text, contains('could not find'));
    });

    test('hüküm reddi İngilizce ve notlu', () {
      final answer =
          composer().outOfScope(OutOfScopeReason.religiousRuling);
      expect(answer.text, contains('cannot issue a religious ruling'));
      expect(answer.note, contains('does not'));
      expect(answer.ayahs, isEmpty);
    });

    test('yardım metni İngilizce örnekler verir', () {
      final answer = composer().help();
      expect(answer.text, contains('patience'));
      expect(answer.actions.first.followUpQuery, 'patience');
    });

    test('alan dışı reddi İngilizce', () {
      final answer = composer().outOfScope(OutOfScopeReason.offTopic);
      expect(answer.text, contains('Qur\'an translation'));
      expect(answer.actions.first.label, 'What can I ask?');
    });

    test('Türkçe besteci Türkçe kurar', () {
      // Karşı yön: dil geçişi bir yönde çalışıp diğerinde bozulmamalı.
      final answer = AnswerComposer().surahInfo(
        const SurahInfoIntent(surah: kehf, facet: SurahFacet.ayahCount),
      );
      expect(answer.text, 'Kehf suresi 110 ayettir.');
    });
  });

  group('İngilizce sözlük', () {
    test('her konunun İngilizce tetikleyicisi var', () {
      for (final topic in TopicLexicon.all) {
        expect(topic.triggersEn, isNotEmpty, reason: '${topic.id} EN tetiksiz');
      }
    });

    test('İngilizce tetikleyiciler normalleştirilmiş biçimde', () {
      for (final topic in TopicLexicon.all) {
        for (final trigger in topic.triggersEn) {
          expect(
            SearchNormalizer.normalize(trigger),
            trigger,
            reason: '${topic.id}: "$trigger" normalleştirilmiş değil',
          );
        }
      }
    });

    test('İngilizce terimler geçerli sorgu kurar', () {
      for (final topic in TopicLexicon.all) {
        expect(
          SearchNormalizer.toFtsOrQuery(topic.termsEn),
          isNotNull,
          reason: '${topic.id} EN sorgu kuramadı',
        );
      }
    });

    test('İngilizce ve Türkçe terimler ayrışır', () {
      // Terim listeleri dizine göre ayrı: Türkçe terim İngilizce dizinde
      // hiçbir şey bulmaz. Karışmaları sessiz bir boş sonuç üretirdi.
      for (final topic in TopicLexicon.all) {
        expect(
          topic.terms.toSet().intersection(topic.termsEn.toSet()),
          isEmpty,
          reason: '${topic.id}: terim listeleri örtüşüyor',
        );
      }
    });

    test('dil seçimi doğru listeyi verir', () {
      final sabir = TopicLexicon.byId('sabir')!;
      expect(sabir.termsFor('en'), sabir.termsEn);
      expect(sabir.termsFor('tr'), sabir.terms);
      expect(sabir.labelFor('en'), 'patience');
      expect(sabir.labelFor('tr'), 'sabır');
    });
  });
}
