/// Yazım hatasına dayanıklı kelime eşleştirme.
///
/// Kural tabanlı bir sınıflandırıcının en kırılgan yeri tam eşleşmedir:
/// "sabır" tanınır ama "sabir", "sabr", "sabırr" tanınmaz ve kullanıcı
/// hiçbir şey yapmadığı hâlde "anlayamadım" cevabı alır. Klavyede harf
/// atlamak, iki harfi yer değiştirmek ya da şapkayı unutmak sık olur.
///
/// Buradaki eşik, dil modeli yerine ölçülebilir bir kural koyar: bir
/// kelime hedeften en fazla belirli sayıda düzenleme uzaklıktaysa aynı
/// kelime sayılır. Uzaklık kelime uzunluğuna göre ayarlanır — kısa
/// kelimelerde bir harflik hata anlamı tamamen değiştirir ("kul"/"kül"),
/// uzun kelimelerde değiştirmez ("peygamberlik"/"peygamberlk").
///
/// Deterministik kalır: aynı girdi hep aynı sonucu verir ve neden
/// eşleştiği hesaplanabilir.
library;

/// Bulanık eşleştirme yardımcıları.
abstract final class FuzzyMatch {
  /// Bir kelimede kaç düzenlemeye izin verildiği.
  ///
  /// Kısa kelimelerde hiç izin verilmez: üç harfli "kul" ile "kül"
  /// arasındaki tek harf gerçek bir anlam farkıdır, yazım hatası değil.
  /// Beş harften sonra bir, dokuz harften sonra iki hata bağışlanır.
  static int toleranceFor(int length) {
    if (length < 5) return 0;
    if (length < 9) return 1;
    return 2;
  }

  /// İki kelime arasındaki Damerau-Levenshtein uzaklığı.
  ///
  /// Klasik Levenshtein'a yer değiştirme (transpozisyon) eklenmiş hâli:
  /// "sarbı" → "sabrı" tek hatadır, çünkü klavyede iki harf sık yer
  /// değiştirir. Düz Levenshtein bunu iki hata sayardı ve kısa kelimelerde
  /// eşiği aşardı.
  ///
  /// [maxDistance] verilirse hesap erken kesilir: eşiği aşan bir çift için
  /// tam uzaklığı bilmeye gerek yok, aşıldığını bilmek yeter. 6236 ayetlik
  /// bir sözlükte her kelimeyi her tetikleyiciyle karşılaştırdığımız için
  /// bu kesme, işi belirgin biçimde hızlandırır.
  static int distance(String a, String b, {int? maxDistance}) {
    if (identical(a, b) || a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    // Uzunluk farkı tek başına bir alt sınırdır; eşiği aşıyorsa hesaba
    // hiç girilmez.
    final lengthGap = (a.length - b.length).abs();
    if (maxDistance != null && lengthGap > maxDistance) return maxDistance + 1;

    final aCodes = a.runes.toList();
    final bCodes = b.runes.toList();

    // Üç satır yeterli: bir önceki, ondan önceki (transpozisyon için) ve
    // hesaplanan. Tam matris tutmanın anlamı yok.
    var twoBack = List<int>.filled(bCodes.length + 1, 0);
    var oneBack = List<int>.generate(bCodes.length + 1, (i) => i);
    var current = List<int>.filled(bCodes.length + 1, 0);

    for (var i = 1; i <= aCodes.length; i++) {
      current[0] = i;
      var rowMin = current[0];

      for (var j = 1; j <= bCodes.length; j++) {
        final cost = aCodes[i - 1] == bCodes[j - 1] ? 0 : 1;

        var value = _min3(
          current[j - 1] + 1, // ekleme
          oneBack[j] + 1, // silme
          oneBack[j - 1] + cost, // değiştirme
        );

        // Yer değiştirme: "ab" → "ba" tek hata.
        if (i > 1 &&
            j > 1 &&
            aCodes[i - 1] == bCodes[j - 2] &&
            aCodes[i - 2] == bCodes[j - 1]) {
          final transposed = twoBack[j - 2] + cost;
          if (transposed < value) value = transposed;
        }

        current[j] = value;
        if (value < rowMin) rowMin = value;
      }

      // Satırdaki en küçük değer bile eşiği aşıyorsa sonuç da aşacaktır.
      if (maxDistance != null && rowMin > maxDistance) return maxDistance + 1;

      final rotated = twoBack;
      twoBack = oneBack;
      oneBack = current;
      current = rotated;
    }

    return oneBack[bCodes.length];
  }

  /// İki kelime yazım hatası payıyla aynı sayılır mı.
  ///
  /// Eşik iki kelimenin kısasına göre belirlenir: uzun kelimenin cömert
  /// eşiğiyle kısa bir kelimeyi yakalamak yanlış eşleşme üretirdi.
  static bool isNear(String a, String b) {
    if (a == b) return true;

    final shorter = a.length < b.length ? a.length : b.length;
    final tolerance = toleranceFor(shorter);
    if (tolerance == 0) return false;

    return distance(a, b, maxDistance: tolerance) <= tolerance;
  }

  /// Kelime hedefin ekli bir biçimi mi ("sabırla" → "sabır").
  ///
  /// Türkçe eklemeli bir dildir ve kullanıcı kökü çıplak yazmaz. Önek
  /// eşleşmesi bunu karşılar; hataya da izin verilir ki "sabrla" da
  /// tanınsın. Yalnızca hedefin kendisi yeterince uzunsa denenir — üç
  /// harfli bir hedefin öneki olmak bir şey söylemez.
  static bool matchesWithSuffix(String word, String target) {
    if (target.length < 4) return word == target;
    if (word.startsWith(target)) return true;

    // Kökün yazımı hatalıysa önek eşleşmesi de kaçar; kelimenin hedef
    // uzunluğundaki başlangıcı hedefe yakın mı diye bakılır.
    if (word.length <= target.length) return isNear(word, target);

    final head = word.substring(0, target.length);
    return isNear(head, target);
  }

  static int _min3(int a, int b, int c) {
    final ab = a < b ? a : b;
    return ab < c ? ab : c;
  }
}
