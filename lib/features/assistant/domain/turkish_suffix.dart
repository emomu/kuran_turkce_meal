/// Türkçe ek uyumu.
///
/// Asistan cevapları şablondan kurulur ve şablonlara sure adı, sayı, konu adı
/// gibi değerler girer. "Bakara'da" ile "Kehf'te" arasındaki fark ünlü ve
/// ünsüz uyumundan gelir; ek elle yazılamaz, hesaplanmalıdır. Aksi hâlde
/// cevaplar "Kehf'da" gibi çıkar ve asistan hemen ucuzlar.
///
/// Kapsam bilinçli olarak dar: asistanın gerçekten kullandığı ekler var,
/// genel bir Türkçe morfoloji kütüphanesi değil.
library;

/// Ek getirme kuralları.
abstract final class TurkishSuffix {
  static const _backVowels = 'aıouâû';
  static const _vowels = 'aeıioöuüâîû';

  /// Ekin sertleşmesine yol açan ünsüzler (fıstıkçı şahap).
  static const _voiceless = 'fstkçşhp';

  /// Kelimenin son ünlüsü. Yoksa null.
  static String? _lastVowel(String word) {
    for (var i = word.length - 1; i >= 0; i--) {
      final ch = word[i].toLowerCase();
      if (_vowels.contains(ch)) return ch;
    }
    return null;
  }

  /// Son ses kalın mı. Ünlü bulunamazsa kalın varsayılır.
  static bool _isBack(String word) {
    final v = _lastVowel(word);
    if (v == null) return true;
    return _backVowels.contains(v);
  }

  /// Kelime ünsüzle mi bitiyor.
  static bool _endsWithConsonant(String word) {
    if (word.isEmpty) return true;
    final last = _stripFinal(word);
    return !_vowels.contains(last);
  }

  /// Son harf — kesme işareti ve boşluk atlanarak.
  static String _stripFinal(String word) {
    var w = word.trimRight();
    while (w.isNotEmpty && (w.endsWith("'") || w.endsWith('’'))) {
      w = w.substring(0, w.length - 1);
    }
    return w.isEmpty ? '' : w[w.length - 1].toLowerCase();
  }

  /// Son ses sert ünsüz mü. Bulunma/ayrılma eklerini sertleştirir.
  static bool _isVoiceless(String word) =>
      _voiceless.contains(_stripFinal(word));

  /// Bulunma hâli: "Bakara'da", "Kehf'te".
  ///
  /// Özel ad olduğu için kesme işaretiyle ayrılır — sure adları özel addır.
  static String locative(String name) {
    final d = _isVoiceless(name) ? 't' : 'd';
    final v = _isBack(name) ? 'a' : 'e';
    return "$name'$d$v";
  }

  /// Ayrılma hâli: "Bakara'dan", "Kehf'ten".
  static String ablative(String name) {
    final d = _isVoiceless(name) ? 't' : 'd';
    final v = _isBack(name) ? 'a' : 'e';
    return "$name'$d${v}n";
  }

  /// Yönelme hâli: "Bakara'ya", "Kehf'e".
  static String dative(String name) {
    final v = _isBack(name) ? 'a' : 'e';
    final buffer = _endsWithConsonant(name) ? '' : 'y';
    return "$name'$buffer$v";
  }

  /// Belirtme hâli: "Bakara'yı", "Kehf'i".
  static String accusative(String name) {
    final v = _isBack(name) ? 'ı' : 'i';
    final buffer = _endsWithConsonant(name) ? '' : 'y';
    return "$name'$buffer$v";
  }

  /// İlgi hâli: "Bakara'nın", "Kehf'in".
  static String genitive(String name) {
    final v = _isBack(name) ? 'ı' : 'i';
    final buffer = _endsWithConsonant(name) ? '' : 'n';
    return "$name'$buffer${v}n";
  }

  /// Konu adına bulunma eki — özel ad değil, kesmesiz: "sabırda".
  ///
  /// Sure adlarından ayrı tutulur çünkü kesme işareti yalnızca özel adlara
  /// gelir; "sabır'da" yanlış olurdu.
  static String locativeCommon(String word) {
    final d = _isVoiceless(word) ? 't' : 'd';
    final v = _isBack(word) ? 'a' : 'e';
    return '$word$d$v';
  }

  /// Konu adına ilgi eki, kesmesiz: "sabrın" değil "sabırın" — ünlü düşmesi
  /// uygulanmaz, çünkü sözlükteki adlar zaten yalın hâlde yazılmıştır ve
  /// istisnaları tahmin etmek yanlış üretmekten kötüdür.
  static String aboutCommon(String word) {
    final v = _isBack(word) ? 'ı' : 'i';
    final buffer = _endsWithConsonant(word) ? '' : 'n';
    return '$word$buffer${v}n';
  }

  /// "ile" bağlacının ekleşmiş hâli: "sabırla", "ilimle", "dua ile" → "duayla".
  static String withSuffix(String word) {
    final v = _isBack(word) ? 'a' : 'e';
    final buffer = _endsWithConsonant(word) ? '' : 'y';
    return '$word${buffer}l$v';
  }
}
