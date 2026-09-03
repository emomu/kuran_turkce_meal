/// Arama metnini Türkçe'ye uygun biçimde normalleştirir.
///
/// İki sorunu çözer:
///
/// 1. **Şapkalı harfler.** Meal metinlerinde "adâlet", "hâlik", "îmân" gibi
///    düzeltme işaretli yazımlar geçer. Kullanıcı bunları klavyeden yazmaz.
///    Şapkalar düşürülerek "adalet" araması "adâlet" geçen ayeti bulur.
///
/// 2. **Türkçe'ye özgü küçültme.** Dart'ın `toLowerCase()` metodu "I" harfini
///    "i" yapar; Türkçe'de karşılığı "ı" olmalıdır. Aksi halde "IŞIK" araması
///    "ışık" kelimesini bulamaz. Bu yüzden küçültme elle yapılır.
///
/// Aynı fonksiyon hem veritabanı doldurulurken hem de kullanıcı sorgusunda
/// çalıştırılır; iki taraf aynı biçime indiği için eşleşme tutar.
abstract final class SearchNormalizer {
  /// Türkçe'ye özgü büyük→küçük eşlemesi. Dart'ın varsayılanının yanıldığı
  /// harfler burada elle karşılanır.
  static const _turkishLowercase = <String, String>{
    'I': 'ı',
    'İ': 'i',
    'Ş': 'ş',
    'Ğ': 'ğ',
    'Ü': 'ü',
    'Ö': 'ö',
    'Ç': 'ç',
  };

  /// Düzeltme işaretli harflerin sade karşılıkları.
  static const _diacriticFolding = <String, String>{
    'â': 'a', 'Â': 'a',
    'î': 'i', 'Î': 'i',
    'û': 'u', 'Û': 'u',
    'ê': 'e', 'Ê': 'e',
    'ô': 'o', 'Ô': 'o',
    'ā': 'a', 'ī': 'i', 'ū': 'u',
    'ʾ': '', 'ʿ': '', '’': '', '\'': '',
  };

  /// Metni arama biçimine indirger.
  static String normalize(String input) {
    final buffer = StringBuffer();

    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);

      // Önce şapka/kesme işareti sadeleştirmesi.
      final folded = _diacriticFolding[ch];
      if (folded != null) {
        buffer.write(folded);
        continue;
      }

      // Sonra Türkçe küçültme.
      final lowered = _turkishLowercase[ch];
      buffer.write(lowered ?? ch.toLowerCase());
    }

    return buffer.toString();
  }

  /// Aramada göz ardı edilen bağlaç ve edatlar.
  ///
  /// Kelimeler AND ile bağlandığı için, ayet metninde tek başına token olarak
  /// geçmeyen bir bağlaç tüm sonuçları siler: kullanıcı "rahmet ve merhamet"
  /// yazdığında "ve" yüzünden hiç sonuç dönmemesi gerçek bir sorundur.
  /// FTS5'in kendi işleçleri de (AND, OR, NOT, NEAR) buraya dahildir; tırnak
  /// içine alındıkları için sözdizimi bozmazlar ama terim olarak aranıp
  /// sonucu boşaltırlardı.
  static const _stopWords = <String>{
    've', 'ile', 'ya', 'ki', 'ama', 'fakat', 'veya',
    'and', 'or', 'not', 'near',
  };

  /// Kullanıcı sorgusunu FTS5 MATCH ifadesine çevirir.
  ///
  /// Her kelime önek eşleşmesi (`kelime*`) olarak aranır — kullanıcı yazarken
  /// sonuç görsün diye. Kelimeler AND ile bağlanır: "rahmet melek" araması
  /// her iki kelimeyi de içeren ayetleri getirir.
  ///
  /// FTS5'te anlamı olan karakterler (tırnak, yıldız, parantez, eksi) sorgudan
  /// temizlenir; aksi halde kullanıcının yazdığı bir tırnak sorguyu bozardı.
  static String? toFtsQuery(String rawQuery) {
    final normalized = normalize(rawQuery);

    final words = normalized
        .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
        .where((w) => w.isNotEmpty)
        .toList();

    if (words.isEmpty) return null;

    // Bağlaçlar elenir. Ancak sorgu yalnızca bağlaçtan ibaretse elemede ısrar
    // edilmez — kullanıcı gerçekten o kelimeyi arıyor olabilir.
    final meaningful = words.where((w) => !_stopWords.contains(w)).toList();
    final terms = meaningful.isEmpty ? words : meaningful;

    // Tek harflik sorgular binlerce sonuç döndürür ve yazarken gereksiz yük
    // oluşturur; en az iki harf istenir.
    if (terms.length == 1 && terms.first.length < 2) return null;

    return terms.map((w) => '"$w"*').join(' AND ');
  }

  /// Sonuç listesinde eşleşen kelimeleri kalın göstermek için, ham metinde
  /// vurgulanacak aralıkları bulur.
  ///
  /// Normalleştirme karakter sayısını koruyacak şekilde yapıldığı için
  /// (tek istisna kesme işaretleri) indeksler ham metinle hizalanır; kısa
  /// kaymalar vurguyu bir harf kaydırabilir, sonucu bozmaz.
  static List<(int start, int end)> matchRanges(String text, String query) {
    final normalizedText = normalize(text);
    final words = normalize(query)
        .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
        .where((w) => w.length >= 2)
        .toList();

    final ranges = <(int, int)>[];

    for (final word in words) {
      var from = 0;
      while (true) {
        final index = normalizedText.indexOf(word, from);
        if (index == -1) break;
        ranges.add((index, index + word.length));
        from = index + word.length;
      }
    }

    if (ranges.isEmpty) return ranges;

    // Çakışan aralıkları birleştir — iki kelime yan yana eşleşmişse tek
    // vurgu olarak çizilir.
    ranges.sort((a, b) => a.$1.compareTo(b.$1));
    final merged = <(int, int)>[ranges.first];

    for (final range in ranges.skip(1)) {
      final last = merged.last;
      if (range.$1 <= last.$2) {
        merged[merged.length - 1] = (last.$1, range.$2 > last.$2 ? range.$2 : last.$2);
      } else {
        merged.add(range);
      }
    }

    return merged;
  }
}
