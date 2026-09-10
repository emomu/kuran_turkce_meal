/// Arama sonuçlarını alaka sırasına dizer.
///
/// FTS5'in bm25 ölçütü iyi bir başlangıçtır ama tek başına yeterli değil:
/// kelime sıklığına bakar, konuya bakmaz. İki sonucu vardır ve ikisi de
/// asistanın cevabını zayıflatır:
///
/// 1. **Kısa ayet önyargısı.** bm25 terim yoğunluğunu ölçer. Üç kelimelik
///    bir ayette "sabır" geçiyorsa yoğunluk yüksektir ve ayet başa çıkar —
///    oysa konuyu anlatan otuz kelimelik ayet daha aşağıdadır.
///
/// 2. **Tek terim yeterli sayılır.** Konu sözlüğü terimleri OR ile aranır.
///    Beş terimden birini içeren ayetle üçünü içeren ayet aynı sırada
///    değerlendirilir; oysa ikincisi konuya çok daha yakındır.
///
/// Burada yapılan yeniden sıralamadır, yeniden arama değil: sonuç kümesi
/// aynı kalır, yalnızca sırası düzelir. Puanlama açıktır ve elle
/// denetlenebilir — "neden bu ayet başa çıktı" sorusunun cevabı vardır.
library;

import '../../../data/db/search_normalizer.dart';
import '../data/assistant_intent.dart';

/// Sonuç sıralayıcı.
abstract final class ResultRanker {
  /// Ayet metninin makul sayıldığı alt sınır (karakter).
  ///
  /// Bunun altındaki ayetler tek başına okunduğunda bağlam vermez:
  /// "Rahmân ve Rahîm olan Allah'ın adıyla" bir konu cevabı değildir.
  /// Elenmezler — dini metinde sansür olmaz — yalnızca sona doğru
  /// kayarlar.
  static const _shortTextThreshold = 60;

  /// Kaç eşleşen terimden sonra ek puan verilmediği.
  ///
  /// Üç terim eşleşen bir ayet konuya oturmuştur; dördüncü terim aynı
  /// oranda bilgi katmaz. Sınır olmasa uzun ayetler yalnızca uzun
  /// oldukları için öne çıkardı.
  static const _matchCeiling = 3;

  /// Sonuçları alakaya göre yeniden dizer.
  ///
  /// [terms] aramada kullanılan kelimeler; kaçının geçtiğine bakılır.
  /// Boşsa sıralama olduğu gibi bırakılır — dayanak yok demektir.
  ///
  /// Sıra kararlıdır: eşit puanlı iki ayet, arama katmanından geldikleri
  /// sırayı korur. bm25 sıralaması böylece ikincil ölçüt olarak kalır.
  static List<AnswerAyah> rank(
    List<AnswerAyah> results, {
    required List<String> terms,
    String languageCode = 'tr',
  }) {
    if (results.length < 2 || terms.isEmpty) return results;

    final needles = terms
        .map(SearchNormalizer.normalize)
        .where((t) => t.length >= 2)
        .toList();
    if (needles.isEmpty) return results;

    // Puan bir kez hesaplanıp saklanır: karşılaştırma sırasında yeniden
    // hesaplamak, sıralamayı n log n metin taramasına çevirirdi.
    final scored = <(AnswerAyah entry, int order, double score)>[];

    for (var i = 0; i < results.length; i++) {
      final entry = results[i];
      final text = SearchNormalizer.normalize(
        entry.ayah.translationFor(languageCode),
      );
      scored.add((entry, i, _score(text, needles)));
    }

    scored.sort((a, b) {
      final byScore = b.$3.compareTo(a.$3);
      if (byScore != 0) return byScore;
      // Eşitlikte özgün sıra korunur.
      return a.$2.compareTo(b.$2);
    });

    return [for (final s in scored) s.$1];
  }

  /// Bir ayetin alaka puanı.
  ///
  /// Puan üç parçadan gelir ve hepsi aynı yönde çalışır: konuya oturan
  /// ayeti yukarı taşımak.
  static double _score(String text, List<String> needles) {
    var matched = 0;
    for (final needle in needles) {
      if (text.contains(needle)) matched++;
    }

    // Hiç eşleşme yoksa ayet OR aramasının uzak bir dalından gelmiştir
    // (ya da eşleşme önek biçimindeydi ve normalleştirmede kaydı).
    // Elenmez, sona konur.
    if (matched == 0) return 0;

    // 1. Kaç ayrı terim geçti. Asıl ölçüt bu: iki terim geçen ayet,
    //    birini iki kez tekrarlayandan konuya yakındır.
    final coverage = (matched > _matchCeiling ? _matchCeiling : matched) /
        _matchCeiling;

    // 2. Uzunluk cezası. Yalnızca çok kısa ayetlere uygulanır ve tam
    //    eleme değil, bir kademe geri atmadır.
    final lengthFactor =
        text.length < _shortTextThreshold ? 0.55 : 1.0;

    // 3. Erken geçiş küçük bir artı. Konusu ayetin başında anılan
    //    metin, konuyu geçerken anandan daha iyi bir örnektir.
    var earliest = text.length;
    for (final needle in needles) {
      final at = text.indexOf(needle);
      if (at >= 0 && at < earliest) earliest = at;
    }
    final position = text.isEmpty ? 0.0 : 1.0 - (earliest / text.length);

    return (coverage * 10.0 + position) * lengthFactor;
  }
}
