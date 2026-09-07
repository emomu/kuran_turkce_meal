/// Arama kutusuna yazılan bir ayet referansı.
///
/// Kullanıcı arama alanına her zaman kelime yazmaz; çoğu zaman aradığı ayetin
/// yerini bilir ve doğrudan oraya gitmek ister. "2:255", "bakara 255",
/// "36" gibi girdiler tam metin araması için anlamsızdır — FTS bunlarda ya
/// hiçbir şey bulmaz ya da alakasız sonuç döker.
class VerseReference {
  const VerseReference({
    required this.surahNumber,
    this.ayahNumber,
    required this.isExplicitAyah,
  });

  final int surahNumber;

  /// İstenen ayet. Yalnızca sure yazıldıysa null.
  final int? ayahNumber;

  /// Kullanıcı ayet numarasını gerçekten yazdı mı.
  ///
  /// [ayahNumber] null olmadığında bile bu bilgi gerekir: "bakara" yazan
  /// kullanıcı sureyi baştan açmak ister, "bakara 1" yazan ise 1. ayete
  /// gitmek — ikisi aynı yere gider ama sonuç kartında farklı şey yazar.
  final bool isExplicitAyah;

  @override
  String toString() => ayahNumber == null
      ? 'VerseReference($surahNumber)'
      : 'VerseReference($surahNumber:$ayahNumber)';

  @override
  bool operator ==(Object other) =>
      other is VerseReference &&
      other.surahNumber == surahNumber &&
      other.ayahNumber == ayahNumber &&
      other.isExplicitAyah == isExplicitAyah;

  @override
  int get hashCode => Object.hash(surahNumber, ayahNumber, isExplicitAyah);
}

/// Arama metnini bir ayet referansına çözmeye çalışır.
///
/// Çözülemezse null döner ve arama normal tam metin aramasına düşer. Bu
/// ayrım bilinçli olarak dar tutuldu: her sayı içeren sorguyu referans
/// saymak, "7 kat gök" arayan kullanıcıyı 7. sureye götürürdü.
///
/// [resolveSurahName] sure adını numaraya çevirir; ad eşleşmesi veri
/// tabanındaki adlara bağlı olduğu için dışarıdan verilir.
VerseReference? parseVerseReference(
  String input, {
  required int? Function(String name) resolveSurahName,
}) {
  final text = input.trim();
  if (text.isEmpty) return null;

  // "2:255", "2/255", "2.255" — mushaf numarası ve ayet.
  //
  // Ayırıcı olarak üçü de kabul edilir: kullanıcı referansı gördüğü yerden
  // kopyalar ve kaynaklar farklı ayırıcı kullanır.
  final numeric = RegExp(r'^(\d{1,3})\s*[:/.]\s*(\d{1,3})$').firstMatch(text);
  if (numeric != null) {
    return _build(
      surahNumber: int.parse(numeric.group(1)!),
      ayahNumber: int.parse(numeric.group(2)!),
    );
  }

  // Yalnızca sayı: "36" -> Yâsîn.
  //
  // 1–114 aralığı dışındaki sayılar referans sayılmaz; "1453" yazan kullanıcı
  // sure aramıyordur.
  final onlyNumber = RegExp(r'^(\d{1,3})$').firstMatch(text);
  if (onlyNumber != null) {
    return _build(surahNumber: int.parse(onlyNumber.group(1)!));
  }

  // "bakara 255" / "âl-i imrân 7" — ad ve ayet numarası.
  //
  // Ad kısmı boşluk içerebildiği için son sayı ayrılır, kalanı ad sayılır.
  final named = RegExp(r'^(.*?)\s+(\d{1,3})$').firstMatch(text);
  if (named != null) {
    final surahNumber = resolveSurahName(named.group(1)!);
    if (surahNumber != null) {
      return _build(
        surahNumber: surahNumber,
        ayahNumber: int.parse(named.group(2)!),
      );
    }
  }

  // Yalnızca sure adı: "bakara".
  //
  // Bu, tam metin aramasıyla çakışabilir — "nur" hem sure adı hem de mealde
  // geçen bir kelime. Referans sonucu listenin başına eklenir, arama
  // sonuçları altında durmaya devam eder; kullanıcı hangisini istiyorsa onu
  // seçer.
  final byName = resolveSurahName(text);
  if (byName != null) return _build(surahNumber: byName);

  return null;
}

/// Sınırları doğrular ve referansı kurar.
///
/// Ayet numarasının sure içinde var olup olmadığı burada bilinemez (ayet
/// sayısı veri tabanından gelir); yalnızca kaba aralık denetimi yapılır.
/// Gerçek doğrulama çağıran tarafta, sure künyesiyle yapılır.
VerseReference? _build({required int surahNumber, int? ayahNumber}) {
  if (surahNumber < 1 || surahNumber > 114) return null;
  if (ayahNumber != null && ayahNumber < 1) return null;

  return VerseReference(
    surahNumber: surahNumber,
    ayahNumber: ayahNumber,
    isExplicitAyah: ayahNumber != null,
  );
}

/// Sure adını karşılaştırma biçimine indirger.
///
/// [SearchNormalizer.normalize] meal metni için tasarlandı ve Türkçe harfleri
/// korur — orada doğru olan da budur: "kalp" ile "kalıp" farklı kelimelerdir.
/// Sure adında ise kullanıcı çoğunlukla harfleri şapkasız ve noktasız yazar:
/// "Mülk" yerine "mulk", "Nûr" yerine "nur", "Şûrâ" yerine "sura". Ad
/// eşleştirmesi bu yüzden daha gevşek bir katlama kullanır.
///
/// Ayrıca ad içindeki tire, kesme ve boşluklar atılır: "Âl-i İmrân" yazımı
/// kaynaktan kaynağa değişir ve kullanıcı "ali imran" da yazabilir.
String foldSurahName(String input) {
  const folding = <String, String>{
    'ı': 'i', 'İ': 'i', 'I': 'i',
    'ü': 'u', 'Ü': 'u',
    'ö': 'o', 'Ö': 'o',
    'ş': 's', 'Ş': 's',
    'ç': 'c', 'Ç': 'c',
    'ğ': 'g', 'Ğ': 'g',
    'â': 'a', 'Â': 'a',
    'î': 'i', 'Î': 'i',
    'û': 'u', 'Û': 'u',
    'ê': 'e', 'Ê': 'e',
    'ô': 'o', 'Ô': 'o',
    'ā': 'a', 'ī': 'i', 'ū': 'u',
  };

  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    final folded = folding[ch];
    if (folded != null) {
      buffer.write(folded);
      continue;
    }
    final lower = ch.toLowerCase();
    // Harf ve rakam dışındaki her şey atılır: tire, kesme, boşluk, nokta.
    if (RegExp(r'[a-z0-9]').hasMatch(lower)) buffer.write(lower);
  }
  return buffer.toString();
}
