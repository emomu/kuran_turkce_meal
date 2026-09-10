import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/data/models/prophet.dart';
import 'package:kuran_turkce_meal/data/models/surah.dart';
import 'package:kuran_turkce_meal/features/assistant/data/assistant_intent.dart';
import 'package:kuran_turkce_meal/features/assistant/domain/intent_classifier.dart';
import 'package:kuran_turkce_meal/features/search/data/verse_reference.dart';

/// Sınıflandırıcı saf bir fonksiyondur: veritabanı, ağ ya da widget ağacı
/// gerektirmez. Bu yüzden asistanın davranışı burada baştan sona
/// denetlenebiliyor — hangi sorunun nereye gittiği tahmin değil, test.
void main() {
  final surahs = [
    const Surah(
      number: 2,
      name: 'Bakara',
      meaning: 'İnek',
      ayahCount: 286,
      revelationOrder: 87,
      revelationPlace: RevelationPlace.medine,
    ),
    const Surah(
      number: 18,
      name: 'Kehf',
      meaning: 'Mağara',
      ayahCount: 110,
      revelationOrder: 69,
      revelationPlace: RevelationPlace.mekke,
    ),
    // Muhammed hem 47. surenin hem bir peygamberin adı; çakışma testleri
    // bu girdiye dayanıyor.
    const Surah(
      number: 47,
      name: 'Muhammed',
      meaning: 'Muhammed',
      ayahCount: 38,
      revelationOrder: 95,
      revelationPlace: RevelationPlace.medine,
    ),
    const Surah(
      number: 36,
      name: 'Yâsîn',
      meaning: 'Yâsîn',
      ayahCount: 83,
      revelationOrder: 41,
      revelationPlace: RevelationPlace.mekke,
    ),
  ];

  const prophets = [
    Prophet(
      id: 'muhammed',
      name: 'Muhammed',
      nameEn: 'Muhammad',
      ayahIds: [1, 2, 3],
      mentionIds: [1, 2, 3, 4, 5, 6, 7, 8],
    ),
    Prophet(
      id: 'yusuf',
      name: 'Yûsuf',
      nameEn: 'Joseph',
      ayahIds: [10, 11],
    ),
  ];

  final classifier = IntentClassifier(
    surahs: surahs,
    prophets: prophets,
    foldName: foldSurahName,
  );

  AssistantIntent classify(String q, {bool hasResults = false}) =>
      classifier.classify(q, hasPreviousResults: hasResults).intent;

  group('ayet referansı', () {
    test('"2:255" referansa çözülür', () {
      final intent = classify('2:255');
      expect(intent, isA<ReferenceIntent>());
      expect((intent as ReferenceIntent).surah.number, 2);
      expect(intent.ayahNumber, 255);
    });

    test('"bakara 255" referansa çözülür', () {
      final intent = classify('bakara 255');
      expect(intent, isA<ReferenceIntent>());
      expect((intent as ReferenceIntent).ayahNumber, 255);
    });

    test('sure sınırı dışındaki numara referans sayılmaz', () {
      // Kehf 110 ayet; 999 yok. Kullanıcıyı var olmayan bir ayete
      // göndermektense aramaya bırakmak doğru.
      expect(classify('kehf 999'), isNot(isA<ReferenceIntent>()));
    });

    test('yalnızca sure adı ayet numarasız çözülür', () {
      final intent = classify('yasin');
      expect(intent, isA<ReferenceIntent>());
      expect((intent as ReferenceIntent).ayahNumber, isNull);
    });
  });

  group('peygamber', () {
    test('ad tek başına anılma niyetine gider', () {
      final intent = classify('muhammed');
      expect(intent, isA<ProphetIntent>());
      expect((intent as ProphetIntent).wantsStory, isFalse);
    });

    test('"kıssası" denince kıssa istenir', () {
      final intent = classify('yusuf kıssası');
      expect(intent, isA<ProphetIntent>());
      expect((intent as ProphetIntent).wantsStory, isTrue);
    });

    test('ad cümlenin içinde de bulunur', () {
      expect(classify('yusuf kimdir'), isA<ProphetIntent>());
    });

    test('şapkalı ad şapkasız yazımla bulunur', () {
      final intent = classify('yusuf');
      expect((intent as ProphetIntent).prophet.id, 'yusuf');
    });

    // Altı ad ikisine birden ait: Yûnus, Hûd, Yûsuf, İbrâhim, Muhammed, Nûh.
    // Ayrım niyete bakılarak yapılır ve yönü önemli: "Muhammed" yazan
    // kullanıcı 38 ayetlik sure künyesini değil, adının geçtiği 140 ayeti
    // bekler. Tersi bir dönem böyleydi ve arama eksik görünüyordu.
    test('ad tek başına peygamberi getirir, sureyi değil', () {
      final intent = classify('muhammed');
      expect(intent, isA<ProphetIntent>());
      expect((intent as ProphetIntent).prophet.id, 'muhammed');
    });

    test('çakışan adda sureye giden yol korunur', () {
      final intent = classify('muhammed') as ProphetIntent;
      expect(intent.sameNameSurah, isNotNull);
      expect(intent.sameNameSurah!.number, 47);
    });

    test('ayet numarası verilince sure kazanır', () {
      // "Muhammed 5" bir yere gitme isteğidir; kişi sorusu değil.
      final intent = classify('muhammed 5');
      expect(intent, isA<ReferenceIntent>());
      expect((intent as ReferenceIntent).surah.number, 47);
      expect(intent.ayahNumber, 5);
    });

    test('çakışmayan peygamberde sure alanı boş', () {
      final intent = classify('yusuf') as ProphetIntent;
      expect(intent.sameNameSurah, isNull);
    });
  });

  group('sure künyesi', () {
    test('"kehf kaç ayet" ayet sayısını sorar', () {
      final intent = classify('kehf kaç ayet');
      expect(intent, isA<SurahInfoIntent>());
      expect((intent as SurahInfoIntent).facet, SurahFacet.ayahCount);
    });

    test('"bakara nerede indi" iniş yerini sorar', () {
      final intent = classify('bakara nerede indi');
      expect(intent, isA<SurahInfoIntent>());
      expect((intent as SurahInfoIntent).facet, SurahFacet.revelationPlace);
    });
  });

  group('konu ve durum', () {
    test('kavram sözlükten bulunur', () {
      final intent = classify('sabır');
      expect(intent, isA<TopicIntent>());
      expect((intent as TopicIntent).topicLabel, 'sabır');
      expect(intent.isSituational, isFalse);
    });

    test('durum ifadesi durum konusuna gider', () {
      final intent = classify('zor zamandayım');
      expect(intent, isA<TopicIntent>());
      expect((intent as TopicIntent).isSituational, isTrue);
    });

    test('sözlükte olmayan kelime serbest aramaya düşer', () {
      final intent = classify('deve');
      expect(intent, isA<TopicIntent>());
      expect((intent as TopicIntent).query, 'deve');
    });

    test('en uzun tetikleyici kazanır', () {
      // "ölüm korkusu" hem korku hem ölüm konusuna değer; uzun olan daha
      // belirlidir.
      final intent = classify('ölüm korkusu') as TopicIntent;
      expect(intent.isSituational, isTrue);
    });
  });

  group('alan sınırı', () {
    test('alan dışı soru reddedilir', () {
      final intent = classify('hava durumu nasıl');
      expect(intent, isA<OutOfScopeIntent>());
      expect((intent as OutOfScopeIntent).reason, OutOfScopeReason.offTopic);
    });

    test('kod sorusu reddedilir', () {
      expect(classify('python kod yaz'), isA<OutOfScopeIntent>());
    });

    test('hüküm sorusu fetva olarak işaretlenir', () {
      final intent = classify('faiz haram mı');
      expect(intent, isA<OutOfScopeIntent>());
      expect(
        (intent as OutOfScopeIntent).reason,
        OutOfScopeReason.religiousRuling,
      );
    });

    test('boş sorgu anlaşılamadı sayılır', () {
      final intent = classify('   ');
      expect(intent, isA<OutOfScopeIntent>());
      expect((intent as OutOfScopeIntent).reason, OutOfScopeReason.unclear);
    });
  });

  group('takip ifadeleri', () {
    test('"daha fazla" önceki sonuç varken devam ister', () {
      expect(classify('daha fazla', hasResults: true),
          isA<MoreResultsIntent>());
    });

    test('"daha fazla" sonuç yokken konu araması olur', () {
      expect(classify('daha fazla', hasResults: false),
          isNot(isA<MoreResultsIntent>()));
    });

    test('sıra ifadesi indise çözülür', () {
      final intent = classify('ikincisini aç', hasResults: true);
      expect(intent, isA<OpenResultIntent>());
      expect((intent as OpenResultIntent).index, 1);
    });

    test('"daha fazla sabır" konu aramasıdır, takip değil', () {
      // Tam eşleşme aranır: "daha" takip ifadesidir ama içinde geçtiği
      // her cümle takip değildir.
      final intent = classify('daha fazla sabır', hasResults: true);
      expect(intent, isA<TopicIntent>());
    });
  });

  group('selam ve yardım', () {
    test('selamlama tanınır', () {
      expect(classify('selam'), isA<GreetingIntent>());
    });

    test('yardım isteği tanınır', () {
      expect(classify('ne yapabilirsin'), isA<HelpIntent>());
    });
  });

  group('normalleştirme', () {
    test('büyük harf ve şapka fark etmez', () {
      expect(classify('SABIR'), isA<TopicIntent>());
      expect(classify('Sabır'), isA<TopicIntent>());
    });

    test('noktalama sorguyu bozmaz', () {
      final intent = classify('Kehf kaç ayet?');
      expect(intent, isA<SurahInfoIntent>());
    });
  });
}
