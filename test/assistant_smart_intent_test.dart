import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/data/models/prophet.dart';
import 'package:kuran_turkce_meal/data/models/surah.dart';
import 'package:kuran_turkce_meal/features/assistant/data/assistant_intent.dart';
import 'package:kuran_turkce_meal/features/assistant/domain/intent_classifier.dart';
import 'package:kuran_turkce_meal/features/search/data/verse_reference.dart';

/// Yazım hatası toleransı, çoklu konu ve yeni takip niyetleri.
///
/// Sınıflandırıcı saf bir fonksiyon olduğu için bu davranışların hepsi
/// veritabanı olmadan denetlenebiliyor.
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
  ];

  const prophets = [
    Prophet(
      id: 'yusuf',
      name: 'Yûsuf',
      nameEn: 'Joseph',
      ayahIds: [10, 11],
    ),
    Prophet(
      id: 'ibrahim',
      name: 'İbrâhim',
      nameEn: 'Abraham',
      ayahIds: [20, 21],
    ),
    Prophet(
      id: 'musa',
      name: 'Mûsâ',
      nameEn: 'Moses',
      ayahIds: [30, 31],
    ),
  ];

  final classifier = IntentClassifier(
    surahs: surahs,
    prophets: prophets,
    foldName: foldSurahName,
  );

  AssistantIntent classify(String q, {bool hasResults = false}) =>
      classifier.classify(q, hasPreviousResults: hasResults).intent;

  group('yazım hatası toleransı', () {
    test('hatalı yazılmış peygamber adı tanınır', () {
      final intent = classify('ibrahm kimdir');
      expect(intent, isA<ProphetIntent>());
      expect((intent as ProphetIntent).prophet.id, 'ibrahim');
    });

    test('doğru yazım bulanık eşleşmeyi yener', () {
      // Tam eşleşme varken hata payına bakılmaz.
      final intent = classify('yusuf');
      expect((intent as ProphetIntent).prophet.id, 'yusuf');
    });

    test('kısa ada hata payı verilmez', () {
      // "musa" dört harf; bir harf değişimi anlamı bozar ve bu ad
      // sıradan kelimelere fazla yakındır.
      final intent = classify('masa');
      expect(intent, isNot(isA<ProphetIntent>()));
    });

    test('hatalı yazılmış konu tetikleyicisi tanınır', () {
      final intent = classify('sabir');
      expect(intent, isA<TopicIntent>());
      expect((intent as TopicIntent).topicLabel, 'sabır');
    });

    test('hatalı yazılmış sure adı referansa çözülür', () {
      final intent = classify('bakra 255');
      expect(intent, isA<ReferenceIntent>());
      expect((intent as ReferenceIntent).surah.number, 2);
    });

    test('hata payı alakasız kelimeyi konuya bağlamaz', () {
      // "kelebekler" hiçbir tetikleyiciye eşik içinde değil; bulanık
      // eşleşme cömertleşip her kelimeyi bir konuya oturtmamalı.
      final intent = classify('kelebekler');
      expect(intent, isA<TopicIntent>());
      expect((intent as TopicIntent).isFromLexicon, isFalse);
    });
  });

  group('sorgu temizliği', () {
    test('soru kalıbı arama teriminden atılır', () {
      // "hakkında ne diyor" mealde geçmez; AND zincirinde sonucu silerdi.
      final intent = classify('kelebekler hakkında ne diyor');
      expect(intent, isA<TopicIntent>());
      expect((intent as TopicIntent).searchTerms, ['kelebekler']);
      expect(intent.termsWereReduced, isTrue);
    });

    test('temizlik gerekmiyorsa değişmez', () {
      final intent = classify('kelebekler');
      expect((intent as TopicIntent).termsWereReduced, isFalse);
    });
  });

  group('çoklu konu', () {
    test('iki konu ayrı ayrı çözülür', () {
      final intent = classify('sabır ve şükür');
      expect(intent, isA<MultiTopicIntent>());
      expect((intent as MultiTopicIntent).parts, hasLength(2));
    });

    test('iki peygamber ayrı ayrı çözülür', () {
      final intent = classify('yusuf ile musa');
      expect(intent, isA<MultiTopicIntent>());

      final parts = (intent as MultiTopicIntent).parts;
      expect(parts.whereType<ProphetIntent>(), hasLength(2));
    });

    test('parçalardan biri çözülemezse bölünmez', () {
      // "anne ve babaya iyilik" bölünürse iki anlamsız parça çıkar;
      // tek konu olarak kalması doğru.
      final intent = classify('anne ve babaya iyilik');
      expect(intent, isNot(isA<MultiTopicIntent>()));
    });

    test('aynı konuya çıkan bölme tekile iner', () {
      final intent = classify('sabır ve sabretmek');
      expect(intent, isNot(isA<MultiTopicIntent>()));
    });

    test('üçten fazla parça kırpılır', () {
      final intent = classify('sabır ve şükür ve namaz ve oruç');
      expect(intent, isA<MultiTopicIntent>());
      expect((intent as MultiTopicIntent).parts.length, lessThanOrEqualTo(3));
    });
  });

  group('yeni takip niyetleri', () {
    test('kaydetme isteği tanınır', () {
      final intent = classify('bunu kaydet', hasResults: true);
      expect(intent, isA<SaveAyahIntent>());
      expect((intent as SaveAyahIntent).index, 0);
    });

    test('sıralı kaydetme isteği tanınır', () {
      final intent = classify('ikincisini kaydet', hasResults: true);
      expect(intent, isA<SaveAyahIntent>());
      expect((intent as SaveAyahIntent).index, 1);
    });

    test('paylaşma isteği tanınır', () {
      expect(classify('bunu paylaş', hasResults: true), isA<ShareAyahIntent>());
    });

    test('aynı suredekiler isteği tanınır', () {
      expect(
        classify('aynı suredeki diğerleri', hasResults: true),
        isA<SameSurahIntent>(),
      );
    });

    test('önceki sonuç yoksa takip niyeti çözülmez', () {
      // Dayanacak bir sonuç olmadan "bunu kaydet" anlamsızdır.
      expect(classify('bunu kaydet'), isNot(isA<SaveAyahIntent>()));
    });

    test('İngilizce takip ifadeleri tanınır', () {
      expect(classify('save this', hasResults: true), isA<SaveAyahIntent>());
      expect(classify('share this', hasResults: true), isA<ShareAyahIntent>());
    });
  });
}
