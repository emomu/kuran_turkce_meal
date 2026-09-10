/// Kullanıcının sorusundan çözülen niyet.
///
/// Asistan bir dil modeli çalıştırmaz. Bunun yerine soruyu sonlu sayıda
/// niyete indirger, her niyeti mevcut veri katmanından karşılar ve cevabı
/// şablonla kurar. Bu, uygulamanın çevrimdışı ve hesapsız çalışma sözünü
/// bozmadan asistan davranışı vermenin yolu — ve daha önemlisi, gösterilen
/// her cümlenin kaynağı bellidir: ya şablondan ya ayetten gelir. Uydurma
/// üretebilecek bir katman yok.
///
/// Yeni bir niyet eklemek üç adımdır: buraya bir alt sınıf, sınıflandırıcıya
/// bir kural, besteciye bir dal.
library;

import '../../../data/models/ayah.dart';
import '../../../data/models/prophet.dart';
import '../../../data/models/surah.dart';

/// Sorunun hangi tür cevabı istediği.
sealed class AssistantIntent {
  const AssistantIntent();
}

/// Doğrudan bir ayete gidiliyor: "2:255", "bakara 255", "yasin".
class ReferenceIntent extends AssistantIntent {
  const ReferenceIntent({
    required this.surah,
    required this.ayahNumber,
  });

  final Surah surah;

  /// Hedef ayet. Yalnızca sure adı yazıldıysa null.
  final int? ayahNumber;
}

/// Bir peygamber soruluyor: "Yusuf kimdir", "Muhammed".
class ProphetIntent extends AssistantIntent {
  const ProphetIntent({
    required this.prophet,
    required this.wantsStory,
    this.sameNameSurah,
  });

  final Prophet prophet;

  /// Aynı adı taşıyan sure, varsa.
  ///
  /// Altı ad ikisine birden ait: Yûnus, Hûd, Yûsuf, İbrâhim, Muhammed, Nûh.
  /// Adı tek başına yazan kullanıcı kişiyi soruyor sayılır — "Muhammed"
  /// arayan 38 ayetlik sure künyesini değil, adının geçtiği 140 ayeti
  /// bekler. Sureye gitmek isteyene de yol kalsın diye künye burada
  /// taşınır ve cevaba bir eylem olarak eklenir.
  final Surah? sameNameSurah;

  /// Kıssa akışı mı isteniyor, yoksa anıldığı ayetler mi.
  ///
  /// "Yusuf kıssası" kıssayı, "Muhammed geçen ayetler" anılmaları ister.
  /// Ayrım Hz. Muhammed'de belirgindir: kıssası 10 ayet, anıldığı 140.
  final bool wantsStory;
}

/// Bir sure hakkında künye bilgisi: "Kehf kaç ayet", "Bakara nerede indi".
class SurahInfoIntent extends AssistantIntent {
  const SurahInfoIntent({
    required this.surah,
    required this.facet,
  });

  final Surah surah;

  /// Sorunun hangi ayrıntıyı istediği.
  final SurahFacet facet;
}

/// Sure künyesinin sorulabilir yanları.
enum SurahFacet {
  /// Ayet sayısı.
  ayahCount,

  /// İniş yeri (Mekke/Medine).
  revelationPlace,

  /// Kaçıncı sırada indiği.
  revelationOrder,

  /// Adının anlamı.
  meaning,

  /// Ayrım yoksa hepsi birden.
  overview,
}

/// Bir konu ya da durum soruluyor: "sabır", "zor zamanlarda ne yapmalıyım".
///
/// Asistanın en sık karşılaşacağı niyet. Sorgu arama katmanına gider;
/// bulunan ayetler alaka sırasıyla sunulur.
class TopicIntent extends AssistantIntent {
  const TopicIntent({
    required this.query,
    required this.topicLabel,
    this.terms = const [],
    this.isSituational = false,
  });

  /// Serbest aramada kullanıcının yazdığı sorgu.
  ///
  /// Sözlükten gelen konularda kullanılmaz; orada [terms] geçerlidir.
  final String query;

  /// Sözlükten gelen arama terimleri. OR ile bağlanır.
  ///
  /// Boşsa sorgu sözlükte yok demektir ve [query] ham hâliyle aranır.
  /// Ayrım önemli: sözlük terimleri alternatiftir ("sabr" ya da "katlan"),
  /// kullanıcının yazdığı kelimeler ise birlikte aranır.
  final List<String> terms;

  /// Sözlükten mi geldi.
  bool get isFromLexicon => terms.isNotEmpty;

  /// Cevapta anılacak konu adı: "sabır", "borç".
  final String topicLabel;

  /// Soru bir durum anlatıyor mu ("zor zamandayım") yoksa konu mu ("sabır").
  ///
  /// Durum sorularında cevap farklı açılır: kullanıcı bilgi değil dayanak
  /// arıyordur.
  final bool isSituational;
}

/// Önceki cevabın devamı isteniyor: "daha fazla", "devamı".
class MoreResultsIntent extends AssistantIntent {
  const MoreResultsIntent();
}

/// Önceki cevaptaki bir ayet açılmak isteniyor: "ikincisini aç".
class OpenResultIntent extends AssistantIntent {
  const OpenResultIntent(this.index);

  /// Kaçıncı sonuç. 0'dan başlar.
  final int index;
}

/// Asistanın ne yapabildiği soruluyor: "ne yapabilirsin", "yardım".
class HelpIntent extends AssistantIntent {
  const HelpIntent();
}

/// Selamlama: "selam", "merhaba".
class GreetingIntent extends AssistantIntent {
  const GreetingIntent();
}

/// Soru Kur'an alanının dışında.
///
/// Asistanın sınırı burada çizilir ve bu sınırı bir dil modeli değil kod
/// korur: alan dışı bir soru cevap üretecek katmana hiç ulaşmaz.
class OutOfScopeIntent extends AssistantIntent {
  const OutOfScopeIntent(this.reason);

  final OutOfScopeReason reason;
}

/// Sorunun neden karşılanamadığı. Cevap metnini bu belirler.
enum OutOfScopeReason {
  /// Konu Kur'an dışı: hava durumu, matematik, kod.
  offTopic,

  /// Fetva / hüküm isteniyor. Asistan hüküm vermez.
  religiousRuling,

  /// Soru anlaşılamadı.
  unclear,
}

/// Sınıflandırma sonucu: niyet ve onu tetikleyen normalleştirilmiş metin.
class IntentResult {
  const IntentResult({
    required this.intent,
    required this.normalizedQuery,
  });

  final AssistantIntent intent;

  /// Sınıflandırıcının üzerinde çalıştığı sadeleştirilmiş sorgu. Test ve
  /// hata ayıklamada işe yarar.
  final String normalizedQuery;
}

/// Asistanın bir soruya verdiği cevabın taşıdığı ayetler.
///
/// Cevap metni bu listeye bakarak kurulur; liste boşsa cevap da "bulamadım"
/// olur. Metnin ayetlerden bağımsız bir iddia taşıması mümkün değil.
class AnswerAyah {
  const AnswerAyah({
    required this.ayah,
    required this.surahName,
  });

  final Ayah ayah;
  final String surahName;

  /// Kartta gösterilen başlık: "Bakara 255".
  String get label => '$surahName ${ayah.numberLabel}';
}
