/// Niyet ve veriden cevap metni kurar.
///
/// Asistanın "konuşan" katmanı. Kurallar tek cümlede: metin ya şablondan
/// gelir ya ayetten alıntıdır. Üçüncü bir kaynak yok — yani asistanın
/// uydurabileceği bir yer yok. Bir ayeti yanlış seçebilir, ama var olmayan
/// bir şey söyleyemez.
///
/// Şablonlar birkaç varyantlıdır ve sırayla dönülür: aynı soruyu iki kez
/// soran kullanıcı aynı cümleyi görmez. Rastgelelik yerine sıra kullanıldı,
/// böylece testler öngörülebilir kalır.
///
/// İKİ DİL
/// -------
/// Şablonlar `easy_localization` yerine burada tutulur. Sebep dilbilgisi:
/// cevaplar sayıya, ada ve ek uyumuna göre kuruluyor ("Kehf'te", "3 ayet",
/// "bir ayet") ve bunlar çeviri dosyasında yer değiştiren birer dizge
/// değil, hesaplanan parçalar. Arayüz etiketleri (başlık, ipucu, düğme)
/// yine çeviri dosyasında; orada hesap yok.
library;

import '../../../data/models/surah.dart';
import '../data/assistant_intent.dart';
import '../data/assistant_message.dart';
import 'turkish_suffix.dart';

/// Cevap metni ve eklentileri.
class ComposedAnswer {
  const ComposedAnswer({
    required this.text,
    this.ayahs = const [],
    this.actions = const [],
    this.note,
    this.highlightTerms = const [],
    this.sections = const [],
  });

  final String text;
  final List<AnswerAyah> ayahs;
  final List<AssistantAction> actions;
  final String? note;

  /// Ayet metninde vurgulanacak kelimeler.
  ///
  /// Kullanıcı sonucun neden geldiğini görmeli: "sabır" arandıysa ayette
  /// o kelime kalın çıkar. Eşleşmeyi göstermek, sonucu savunmanın en
  /// kısa yolu — asistan neden bu ayeti seçtiğini kelimeyle söyler.
  final List<String> highlightTerms;

  /// Çoklu konu cevabında bölümler. Boşsa cevap tek parçadır.
  final List<AnswerSection> sections;
}

/// Çoklu konu cevabında tek bir bölüm.
///
/// "sabır ve şükür" sorusunda iki bölüm olur; her biri kendi başlığı ve
/// kendi ayetleriyle sunulur. Ayetleri tek listede toplamak sorunun
/// karşılaştırma yanını kaybettirirdi.
class AnswerSection {
  const AnswerSection({
    required this.label,
    required this.ayahs,
    required this.totalFound,
  });

  /// Bölümün adı: "sabır", "Yusuf".
  final String label;

  /// Bu bölümde gösterilen ayetler.
  final List<AnswerAyah> ayahs;

  /// Bu konuda toplam kaç ayet bulundu.
  final int totalFound;
}

/// Şablon bestecisi.
class AnswerComposer {
  AnswerComposer({this.languageCode = 'tr'});

  /// Cevapların kurulacağı dil. Arayüz diliyle aynı olmalı.
  final String languageCode;

  bool get _en => languageCode == 'en';

  /// Varyant sayacı. Her çağrıda artar; şablonlar sırayla döner.
  int _turn = 0;

  /// Sıradaki varyantı seçer.
  String _pick(List<String> variants) =>
      variants[(_turn++) % variants.length];

  /// Dile göre varyant listesi seçip sıradakini verir.
  String _pickFor({required List<String> tr, required List<String> en}) =>
      _pick(_en ? en : tr);

  /// Yardım isteme eylemi — iki dilde.
  AssistantAction get _helpAction => AssistantAction(
        label: _en ? 'What can I ask?' : 'Ne sorabilirim?',
        kind: AssistantActionKind.ask,
        followUpQuery: _en ? 'what can you do' : 'ne yapabilirsin',
      );

  /// "Tümünü gör" eylemi.
  ///
  /// Eskiden sohbete üç ayet daha ekliyordu; 60 sonuçlu bir aramada bu,
  /// balonun altına yirmi kez basmak demekti. Liste artık kendi sayfasında
  /// açılıyor ve sohbet cevabın özeti olarak kalıyor.
  AssistantAction _openAllAction(int total) => AssistantAction(
        label: _en ? 'See all ($total)' : 'Tümünü gör ($total)',
        kind: AssistantActionKind.openAll,
      );

  /// Ayetlerin bir bölümünü sunan cevap.
  ///
  /// [ayahs] gösterilecek ayetler, [totalFound] arama toplamı. Toplam
  /// gösterilenden fazlaysa "daha var" eylemi eklenir.
  ComposedAnswer topic({
    required TopicIntent intent,
    required List<AnswerAyah> ayahs,
    required int totalFound,
    required int shownSoFar,
    List<String>? narrowedTo,
    List<String> highlightTerms = const [],
  }) {
    if (ayahs.isEmpty) {
      // Sözlükten gelen bir konuda sonuç yoksa sorun aramadadır; kullanıcı
      // meşru bir konu sordu. Serbest aramada sonuç yoksa sorulan şey
      // büyük olasılıkla mealde hiç geçmiyor — o zaman sınırı hatırlatmak,
      // "başka kelime dene" demekten dürüst. Kullanıcıyı olmayan bir
      // sonucun peşinde dolaştırmamak gerekir.
      if (intent.isFromLexicon) {
        return ComposedAnswer(
          text: _pickFor(
            tr: [
              'Bu konuda ayet bulamadım. Başka bir kelimeyle dener misin?',
              'Aradığın kelimeyi mealde bulamadım. Farklı bir ifade '
                  'deneyebilirsin.',
            ],
            en: [
              'I could not find any verse on this. Try another word?',
              'I could not find that word in the translation. Try a '
                  'different phrase.',
            ],
          ),
          actions: [_helpAction],
        );
      }

      return ComposedAnswer(
        text: _en
            ? 'I could not find "${intent.topicLabel}" anywhere in the '
                'translation. I only search the Qur\'an translation — if '
                'you meant something else, try a topic, a verse number or '
                'a surah name.'
            : '"${intent.topicLabel}" mealin hiçbir yerinde geçmiyor. Ben '
                'yalnızca Kur\'an mealinde arama yapıyorum — başka bir şey '
                'kastettiysen bir konu, ayet numarası ya da sure adı '
                'yazabilirsin.',
        actions: [_helpAction],
      );
    }

    // Sorgu gevşetildiyse bu söylenir. Kullanıcının yazdığından başka bir
    // şeyi aramak meşrudur — boş sonuç dönmekten iyidir — ama sessizce
    // yapılmaz: neden bu ayetleri gördüğünü bilmeli.
    //
    // Vurgu terimlerinden ayrı tutulur: vurgu her cevapta yapılır,
    // bu not yalnızca sorgu gerçekten değiştiğinde düşülür.
    final narrowNote = narrowedTo == null || narrowedTo.isEmpty
        ? null
        : _en
            ? 'No verse contained all your words, so I searched for: '
                '${narrowedTo.join(', ')}.'
            : 'Kelimelerinin hepsini içeren ayet yoktu; '
                '${narrowedTo.join(', ')} ile aradım.';

    final label = intent.topicLabel;
    final first = ayahs.first;
    final buffer = StringBuffer();

    // Açılış cümlesi. Durum sorularında farklı kurulur: kullanıcı bilgi
    // değil dayanak arıyordur ve cevabın ona göre başlaması gerekir.
    if (intent.isSituational) {
      buffer.write(_pickFor(
        tr: [
          'Bu hâlde okunabilecek ayetler var.',
          'Kur\'an bu duruma değinir.',
          'Bu konuda dayanak olabilecek ayetler şunlar.',
        ],
        en: [
          'There are verses you can read in this state.',
          'The Qur\'an speaks to this.',
          'Here are verses that may steady you.',
        ],
      ));
    } else if (_en) {
      buffer.write(_pick([
        'I found ${_countPhrase(totalFound)} on $label.',
        '$label appears in ${_countPhrase(totalFound)}.',
        'There ${totalFound == 1 ? 'is' : 'are'} '
            '${_countPhrase(totalFound)} about $label.',
      ]));
    } else {
      // Türkçe'de ek uyumu hesaplanır: "sabırda", "borçta".
      final about = TurkishSuffix.locativeCommon(label);
      buffer.write(_pick([
        '$label üzerine ${_countPhrase(totalFound)} buldum.',
        'Mealde ${_countPhrase(totalFound)} $about geçiyor.',
        '$label konusunda ${_countPhrase(totalFound)} var.',
      ]));
    }

    // İlk ayeti adıyla anmak cevabı listeden ayırır ve kullanıcıya bir
    // başlangıç noktası verir.
    buffer.write(' ');
    buffer.write(_pickFor(
      tr: [
        'İlki ${first.label}:',
        '${first.label} ile başlayabilirsin:',
        'Şuradan başlayabilirsin — ${first.label}:',
      ],
      en: [
        'The first is ${first.label}:',
        'You can start with ${first.label}:',
        'Start here — ${first.label}:',
      ],
    ));

    final actions = <AssistantAction>[];
    if (totalFound > shownSoFar) actions.add(_openAllAction(totalFound));

    return ComposedAnswer(
      text: buffer.toString(),
      ayahs: ayahs,
      actions: actions,
      // Kavram aramalarında uyarı düşülür: gösterilen ayetler kelime
      // eşleşmesiyle bulundu, konunun tamamı değil. Sorgu gevşetildiyse
      // önce o söylenir — kullanıcı için daha yeni bir bilgi.
      note: narrowNote ??
          (intent.isSituational
              ? null
              : _en
                  ? 'These verses were found by word match; they may not '
                      'cover the whole subject.'
                  : 'Bu ayetler kelime eşleşmesiyle bulundu; konunun '
                      'tamamını kapsamayabilir.'),
      highlightTerms: highlightTerms,
    );
  }

  /// Doğrudan bir ayete gidiliyor.
  ComposedAnswer reference({
    required ReferenceIntent intent,
    required List<AnswerAyah> ayahs,
  }) {
    final surah = intent.surah;
    final name = surah.nameFor(languageCode);

    if (intent.ayahNumber == null) {
      final place = _placeName(surah.revelationPlace);
      final meaning = surah.meaningFor(languageCode);

      return ComposedAnswer(
        text: _en
            ? 'Surah $name has ${surah.ayahCount} verses. It was revealed in '
                '$place, ${_ordinal(surah.revelationOrder)} in order. '
                'Its name means: $meaning.'
            : '$name suresi ${surah.ayahCount} ayet. '
                '$place döneminde, ${surah.revelationOrder}. sırada indi. '
                'Adının anlamı: $meaning.',
        ayahs: ayahs,
        actions: [
          AssistantAction(
            label: _en ? 'Open Surah $name' : '$name suresini aç',
            kind: AssistantActionKind.navigate,
            route: '/sure/${surah.number}',
          ),
        ],
      );
    }

    return ComposedAnswer(
      text: _pickFor(
        tr: [
          'İşte $name ${intent.ayahNumber}:',
          '$name suresinin ${intent.ayahNumber}. ayeti:',
        ],
        en: [
          'Here is $name ${intent.ayahNumber}:',
          'Verse ${intent.ayahNumber} of Surah $name:',
        ],
      ),
      ayahs: ayahs,
      actions: [
        AssistantAction(
          label: _en ? 'Read in surah' : 'Surede oku',
          kind: AssistantActionKind.navigate,
          route: '/sure/${surah.number}?ayet=${intent.ayahNumber}',
        ),
      ],
    );
  }

  /// Bir peygamber soruldu.
  ComposedAnswer prophet({
    required ProphetIntent intent,
    required List<AnswerAyah> ayahs,
    required int totalFound,
    required int shownSoFar,
  }) {
    final p = intent.prophet;
    final name = p.nameFor(languageCode);
    final text = StringBuffer();

    // Hz. Muhammed'de iki sayı vardır ve farkları anlamlıdır: adının geçtiği
    // ayetler ile ona seslenilen ayetler. Kullanıcı adını arattığında ikinci
    // sayıyı bekler.
    if (intent.wantsStory) {
      text.write(_en
          ? 'The story of $name appears in ${_countPhrase(p.ayahCount)}, '
              'ordered by revelation:'
          : '$name kıssası mealde ${_countPhrase(p.ayahCount)} '
              'geçiyor. Ayetler iniş sırasına göre dizili:');
    } else if (p.hasSeparateMentions) {
      text.write(_en
          ? '$name is mentioned in ${_countPhrase(p.mentionCount)} — both '
              'where the name appears and where he is addressed. '
              '${_countPhrase(p.ayahCount)} name him directly:'
          : '$name mealde ${_countPhrase(p.mentionCount)} anılıyor — '
              'adının geçtiği ayetler ve ona seslenilen ayetler birlikte. '
              '${_countPhrase(p.ayahCount)} adı doğrudan geçiyor:');
    } else {
      text.write(_en
          ? '$name is mentioned in ${_countPhrase(p.mentionCount)}, '
              'ordered by revelation:'
          : '$name mealde ${_countPhrase(p.mentionCount)} anılıyor. '
              'İniş sırasına göre:');
    }

    final actions = <AssistantAction>[
      AssistantAction(
        label: _en ? 'Open the story of $name' : '$name kıssasını aç',
        kind: AssistantActionKind.navigate,
        route: '/kissa/${p.id}',
      ),
    ];

    // Aynı adı taşıyan bir sure varsa oraya da yol açılır: adı yazan
    // kullanıcıya kişiyi verdik, sureyi isteyen bir dokunuşla ulaşsın.
    final surah = intent.sameNameSurah;
    if (surah != null) {
      final surahName = surah.nameFor(languageCode);
      actions.add(AssistantAction(
        label: _en ? 'Open Surah $surahName' : '$surahName suresini aç',
        kind: AssistantActionKind.navigate,
        route: '/sure/${surah.number}',
      ));
    }

    if (totalFound > shownSoFar) {
      actions.insert(0, _openAllAction(totalFound));
    }

    return ComposedAnswer(
      text: text.toString(),
      ayahs: ayahs,
      actions: actions,
    );
  }

  /// Sure künyesi soruldu.
  ComposedAnswer surahInfo(SurahInfoIntent intent) {
    final s = intent.surah;
    final name = s.nameFor(languageCode);
    final meaning = s.meaningFor(languageCode);
    final place = _placeName(s.revelationPlace);

    final text = _en
        ? switch (intent.facet) {
            SurahFacet.ayahCount =>
              'Surah $name has ${s.ayahCount} verses.',
            SurahFacet.revelationPlace =>
              'Surah $name was revealed in $place.',
            SurahFacet.revelationOrder =>
              'Surah $name is ${_ordinal(s.revelationOrder)} by revelation '
                  'and ${_ordinal(s.number)} in the mushaf.',
            SurahFacet.meaning => 'The name $name means: $meaning.',
            SurahFacet.overview =>
              'Surah $name has ${s.ayahCount} verses. It was revealed in '
                  '$place, ${_ordinal(s.revelationOrder)} in order. '
                  'Its name means: $meaning.',
          }
        : switch (intent.facet) {
            SurahFacet.ayahCount => '$name suresi ${s.ayahCount} ayettir.',
            SurahFacet.revelationPlace =>
              '$name suresi $place döneminde indi.',
            SurahFacet.revelationOrder =>
              '$name suresi iniş sırasına göre ${s.revelationOrder}. sırada, '
                  'mushaf sırasına göre ${s.number}. suredir.',
            SurahFacet.meaning => '$name adının anlamı: $meaning.',
            SurahFacet.overview =>
              '$name suresi ${s.ayahCount} ayet. $place döneminde, '
                  '${s.revelationOrder}. sırada indi. Adının anlamı: $meaning.',
          };

    return ComposedAnswer(
      text: text,
      actions: [
        AssistantAction(
          label: _en ? 'Open Surah $name' : '$name suresini aç',
          kind: AssistantActionKind.navigate,
          route: '/sure/${s.number}',
        ),
      ],
    );
  }

  /// Önceki cevaptan bir ayet açıldı.
  ComposedAnswer openResult(AnswerAyah target) => ComposedAnswer(
        text: '${target.label}:',
        ayahs: [target],
        actions: [
          AssistantAction(
            label: _en ? 'Read in surah' : 'Surede oku',
            kind: AssistantActionKind.navigate,
            route: '/sure/${target.ayah.surahNumber}'
                '?ayet=${target.ayah.ayahNumber}',
          ),
        ],
      );

  /// İstenen sırada sonuç yok.
  ComposedAnswer noSuchResult() => ComposedAnswer(
        text: _en
            ? 'There is no verse at that position. Tell me a number from '
                'the list.'
            : 'O sırada bir ayet yok. Listedeki bir numarayı söyleyebilirsin.',
      );

  /// Devam istendi ama sonuç kalmadı.
  ComposedAnswer noMoreResults() => ComposedAnswer(
        text: _pickFor(
          tr: [
            'Bu konuda gösterebileceğim başka ayet kalmadı.',
            'Hepsi bu kadar. Başka bir konu sorabilirsin.',
          ],
          en: [
            'I have no more verses to show on this.',
            'That is all of them. You can ask about something else.',
          ],
        ),
      );

  /// Devam eden sayfa.
  ComposedAnswer continuation(
    List<AnswerAyah> page, {
    List<String> terms = const [],
  }) =>
      ComposedAnswer(
        text: _en ? 'Continued:' : 'Devamı:',
        ayahs: page,
        highlightTerms: terms,
      );

  /// Selamlama.
  ComposedAnswer greeting() => ComposedAnswer(
        text: _pickFor(
          tr: [
            'Merhaba. Kur\'an\'da bir konu, bir ayet ya da bir peygamber '
                'sorabilirsin.',
            'Selam. Aklına takılan bir konuyu ya da ayeti sorabilirsin.',
          ],
          en: [
            'Hello. You can ask about a topic, a verse or a prophet in the '
                'Qur\'an.',
            'Peace. Ask me about a topic or a verse on your mind.',
          ],
        ),
        actions: [_helpAction],
      );

  /// Yardım metni.
  ///
  /// Asistanın sınırını kullanıcıya baştan göstermek, sonradan reddetmekten
  /// iyidir: ne sorabileceğini bilen kullanıcı hayal kırıklığına uğramaz.
  ComposedAnswer help() => ComposedAnswer(
        text: _en
            ? 'I search the translation and show you the verses I find. '
                'You can ask about:\n\n'
                '• A topic — "patience", "justice", "debt"\n'
                '• A state — "I am going through a hard time", "I am sad"\n'
                '• A verse — "2:255", "Al-Baqarah 255"\n'
                '• A surah — "how many verses in Al-Kahf"\n'
                '• A prophet — "Joseph", "Muhammad"\n\n'
                'I do not interpret and I do not issue rulings: I only find '
                'the verses and show them as they are.'
            : 'Mealde arama yapıyorum ve bulduğum ayetleri gösteriyorum. '
                'Şunları sorabilirsin:\n\n'
                '• Bir konu — "sabır", "adalet", "borç"\n'
                '• Bir durum — "zor zamandayım", "üzgünüm"\n'
                '• Bir ayet — "2:255", "Bakara 255"\n'
                '• Bir sure — "Kehf kaç ayet", "Yasin nerede indi"\n'
                '• Bir peygamber — "Yusuf", "Muhammed"\n\n'
                'Yorum yapmam, hüküm vermem: yalnızca ayetleri bulur, '
                'olduğu gibi gösteririm.',
        actions: [
          AssistantAction(
            label: _en ? 'Patience' : 'Sabır',
            kind: AssistantActionKind.ask,
            followUpQuery: _en ? 'patience' : 'sabır',
          ),
          AssistantAction(
            label: _en ? 'Al-Baqarah 255' : 'Bakara 255',
            kind: AssistantActionKind.ask,
            followUpQuery: _en ? 'Al-Baqarah 255' : 'Bakara 255',
          ),
        ],
      );

  /// Birden fazla konu soruldu.
  ///
  /// Cevap bölümler hâlinde kurulur; her bölüm kendi başlığını taşır.
  /// Metin yalnızca giriş cümlesidir — asıl ayrım arayüzde bölüm
  /// başlıklarıyla yapılır, çünkü iki konuyu tek paragrafta anlatmak
  /// karşılaştırmayı zorlaştırır.
  ComposedAnswer multiTopic(
    List<AnswerSection> sections, {
    List<String> highlightTerms = const [],
  }) {
    final labels = sections.map((s) => s.label).toList();
    final withResults = sections.where((s) => s.ayahs.isNotEmpty).toList();

    if (withResults.isEmpty) {
      return ComposedAnswer(
        text: _en
            ? 'I could not find verses for ${_joinLabels(labels)}.'
            : '${_joinLabels(labels)} için ayet bulamadım.',
        actions: [_helpAction],
      );
    }

    final text = _en
        ? 'Here is what I found on ${_joinLabels(labels)}, side by side:'
        : '${_joinLabels(labels)} konularında bulduklarım, yan yana:';

    final total = sections.fold(0, (sum, s) => sum + s.totalFound);
    final shown = sections.fold(0, (sum, s) => sum + s.ayahs.length);

    return ComposedAnswer(
      text: text,
      sections: withResults,
      highlightTerms: highlightTerms,
      actions: [if (total > shown) _openAllAction(total)],
      note: _en
          ? 'Each heading is searched separately; the verses are not a '
              'comparison, only what matched each word.'
          : 'Her başlık ayrı arandı; ayetler bir karşılaştırma değil, '
              'her kelimeye karşılık bulunanlardır.',
    );
  }

  /// Bir ayet kaydedildi ya da kayıttan çıkarıldı.
  ComposedAnswer savedAyah(AnswerAyah target, {required bool isSaved}) =>
      ComposedAnswer(
        text: isSaved
            ? (_en
                ? '${target.label} is saved. You can find it under Saved.'
                : '${target.label} kaydedildi. Kaydedilenler bölümünde '
                    'bulabilirsin.')
            : (_en
                ? '${target.label} is no longer saved.'
                : '${target.label} kayıtlardan çıkarıldı.'),
        ayahs: [target],
        actions: [
          AssistantAction(
            label: _en ? 'Open Saved' : 'Kaydedilenleri aç',
            kind: AssistantActionKind.navigate,
            route: '/kaydedilenler',
          ),
        ],
      );

  /// Bir ayet paylaşıldı.
  ///
  /// Paylaşım sayfası sistemin elinde; asistan yalnızca açtığını söyler.
  /// Kullanıcı vazgeçmiş de olabilir, o yüzden "paylaşıldı" değil
  /// "paylaşım açıldı" denir — olmayan bir şeyi iddia etmemek burada da
  /// geçerli.
  ComposedAnswer sharedAyah(AnswerAyah target) => ComposedAnswer(
        text: _en
            ? 'I opened the share sheet for ${target.label}.'
            : '${target.label} için paylaşım penceresini açtım.',
        ayahs: [target],
      );

  /// Bir ayetin suredeki komşuları gösterildi.
  ComposedAnswer sameSurah({
    required AnswerAyah anchor,
    required List<AnswerAyah> ayahs,
    required int surahNumber,
  }) =>
      ComposedAnswer(
        text: _en
            ? '${anchor.label} in its surrounding verses:'
            : '${anchor.label} ve çevresindeki ayetler:',
        ayahs: ayahs,
        actions: [
          AssistantAction(
            label: _en ? 'Read in surah' : 'Surede oku',
            kind: AssistantActionKind.navigate,
            route: '/sure/$surahNumber?ayet=${anchor.ayah.ayahNumber}',
          ),
        ],
      );

  /// Etiketleri okunur biçimde birleştirir: "sabır ve şükür".
  String _joinLabels(List<String> labels) {
    if (labels.length == 1) return labels.first;
    final head = labels.sublist(0, labels.length - 1).join(', ');
    return _en ? '$head and ${labels.last}' : '$head ve ${labels.last}';
  }

  /// Alan dışı soru.
  ///
  /// Reddetme metni kısa ve suçlayıcı olmayan bir dille kurulur; kullanıcı
  /// yanlış bir şey yapmadı, yalnızca asistanın alanı dar.
  ComposedAnswer outOfScope(OutOfScopeReason reason) => switch (reason) {
        OutOfScopeReason.offTopic => ComposedAnswer(
            text: _en
                ? 'I can only help with the Qur\'an translation. Ask me about '
                    'a topic, a verse or a surah.'
                : 'Ben yalnızca Kur\'an meali üzerine yardımcı olabiliyorum. '
                    'Bir konu, ayet ya da sure sorabilirsin.',
            actions: [_helpAction],
          ),
        OutOfScopeReason.religiousRuling => ComposedAnswer(
            text: _en
                ? 'I cannot issue a religious ruling — for that you should '
                    'consult a scholar. If you like, I can show the verses on '
                    'the subject and leave the judgement to you.'
                : 'Dinî hüküm veremem — bunun için bir ilim ehline '
                    'başvurman gerekir. İstersen konuyla ilgili ayetleri '
                    'gösterebilirim; kararı sana bırakırım.',
            note: _en
                ? 'The assistant searches the translation text; it does not '
                    'issue rulings.'
                : 'Asistan meal metninde arama yapar; fetva vermez.',
          ),
        OutOfScopeReason.unclear => ComposedAnswer(
            text: _en
                ? 'I did not quite understand that. Write a topic, a verse '
                    'number or a surah name and I can help.'
                : 'Bunu tam anlayamadım. Bir konu adı, ayet numarası ya da '
                    'sure adı yazarsan yardımcı olabilirim.',
            actions: [_helpAction],
          ),
      };

  /// "3 ayet" / "bir ayet" — sayı ifadesi.
  ///
  /// Tekil biçim yazıyla verilir: "1 ayet" bir sayaç çıktısı gibi durur,
  /// "bir ayet" cümlenin parçası olur. Asistanın konuşuyor gibi durmasının
  /// küçük ama gerekli parçalarından biri.
  String _countPhrase(int n) {
    if (_en) return n == 1 ? 'one verse' : '$n verses';
    return n == 1 ? 'bir ayet' : '$n ayet';
  }

  /// İngilizce sıra sayısı: 1st, 2nd, 3rd, 4th…
  ///
  /// Türkçe'de "87. sırada" yazımı yeterli olduğu için yalnızca İngilizce
  /// tarafta gerekiyor.
  static String _ordinal(int n) {
    if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
    return switch (n % 10) {
      1 => '${n}st',
      2 => '${n}nd',
      3 => '${n}rd',
      _ => '${n}th',
    };
  }

  /// İniş yerinin okunur adı.
  String _placeName(RevelationPlace place) {
    final isMecca = place == RevelationPlace.mekke;
    if (_en) return isMecca ? 'Mecca' : 'Medina';
    return isMecca ? 'Mekke' : 'Medine';
  }
}
