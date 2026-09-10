/// Soruyu arama sorgusuna indirger.
///
/// Kullanıcı arama kutusuna değil bir asistana yazıyor ve cümle kuruyor:
/// "sabır hakkında ne diyor", "bana adalet ile ilgili ayet var mı". Bu
/// cümlenin yarısı soru kalıbıdır, mealde geçmez. Kelimeler AND ile
/// bağlandığı için tek bir "hakkında" bütün sonuçları siler.
///
/// Burası o farkı kapatır: soru kalıbını atar, geriye kullanıcının
/// gerçekten aradığı kelimeleri bırakır. Attığı kelimeleri de söyler, ki
/// cevapta "şu kelimeyle aradım" denebilsin — kullanıcı neden o sonuçları
/// gördüğünü bilmeli.
library;

/// Sorgu temizleme sonucu.
class CleanedQuery {
  const CleanedQuery({
    required this.terms,
    required this.original,
  });

  /// Aramaya gidecek kelimeler. Sırası korunur.
  final List<String> terms;

  /// Temizlik öncesi hâli.
  final String original;

  /// Aranacak bir şey kaldı mı.
  bool get isEmpty => terms.isEmpty;

  /// Arama metni olarak birleştirilmiş hâli.
  String get query => terms.join(' ');

  /// Temizlik sorguyu değiştirdi mi. Cevapta not düşmek için.
  bool get wasReduced => terms.join(' ') != original.trim().toLowerCase();
}

/// Soru kalıplarını temizler.
abstract final class QueryCleaner {
  /// Mealde aranmayacak kelimeler.
  ///
  /// İki kümeden oluşur: soru kalıpları ("hakkında", "ne diyor") ve
  /// dilbilgisi taşıyıcıları ("bir", "bu", "için"). İkisi de meal
  /// metninde geçebilir ama kullanıcının aradığı şey değildir; AND
  /// zincirinde yalnızca sonucu daraltırlar.
  ///
  /// Liste bilinçli olarak dar tutuldu. Anlam taşıyabilecek hiçbir kelime
  /// burada değil: "rahmet", "kul", "hak" gibi kelimeler mealde konudur,
  /// atılmaz.
  static const _stopWords = <String>{
    // Soru kalıpları.
    'hakkinda', 'hakkında', 'ilgili', 'dair', 'üzerine', 'uzerine',
    'ne', 'nedir', 'neler', 'nasil', 'nasıl', 'niye', 'neden', 'niçin',
    'nicin', 'hangi', 'kim', 'kimdir', 'nerede', 'nereye', 'kac', 'kaç',
    'mi', 'mı', 'mu', 'mü', 'midir', 'mıdır', 'var', 'yok', 'varmi',
    'diyor', 'der', 'denir', 'geçiyor', 'geciyor', 'geçer', 'gecer',
    'geçen', 'gecen', 'geçtiği', 'gectigi',
    'anlatiyor', 'anlatıyor', 'söylüyor', 'soyluyor', 'buyuruyor',
    'bahsediyor', 'bahseder', 'yazıyor', 'yaziyor',

    // İstek kalıpları.
    'bana', 'bize', 'göster', 'goster', 'söyle', 'soyle', 'anlat',
    'bul', 'bulur', 'getir', 'ver', 'oku', 'okur', 'istiyorum',
    'isterim', 'lutfen', 'lütfen', 'acaba',

    // Alan kelimeleri. Kullanıcı "ayet" yazar ama her ayet bir ayettir;
    // aramada ayırt edici değildir.
    'ayet', 'ayetler', 'ayeti', 'ayetleri', 'ayette', 'ayetlerde',
    'sure', 'suresi', 'surede', 'kuran', 'kuranda', "kur'an", "kur'anda",
    'mealde', 'meal', 'meali',

    // Dilbilgisi taşıyıcıları.
    'bir', 'bu', 'şu', 'su', 'o', 'ki', 'de', 'da', 'ise', 'ile',
    've', 'veya', 'ya', 'ama', 'fakat', 'için', 'icin', 'gibi',
    'daha', 'çok', 'cok', 'en', 'her', 'hep', 'tüm', 'tum', 'bütün',
    'butun', 'olan', 'olarak', 'diye',

    // İngilizce karşılıkları.
    'about', 'regarding', 'concerning', 'what', 'which', 'who', 'where',
    'when', 'why', 'how', 'does', 'do', 'did', 'is', 'are', 'was',
    'were', 'say', 'says', 'said', 'tell', 'show', 'find', 'give',
    'me', 'us', 'please', 'the', 'a', 'an', 'of', 'in', 'on', 'to',
    'for', 'with', 'and', 'or', 'any', 'some', 'verse', 'verses', 'it',
    'surah', 'chapter', 'quran', "qur'an", 'there', 'that', 'this',
  };

  /// Kelime tek başına anlamlı bir arama terimi mi.
  static bool isStopWord(String word) => _stopWords.contains(word);

  /// Soru cümlesinden arama terimlerini çıkarır.
  ///
  /// [normalized] normalleştirilmiş (küçük harfli, şapkasız) sorgu.
  ///
  /// Her şey elenirse temizlikte ısrar edilmez: kullanıcı gerçekten
  /// "ne" kelimesini arıyor olabilir ve boş sonuç, alakasız sonuçtan
  /// daha kötüdür.
  static CleanedQuery clean(String normalized) {
    final words = normalized
        .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
        .where((w) => w.isNotEmpty)
        .toList();

    if (words.isEmpty) {
      return CleanedQuery(terms: const [], original: normalized);
    }

    final kept = words.where((w) => !isStopWord(w) && w.length > 1).toList();

    return CleanedQuery(
      terms: kept.isEmpty ? words : kept,
      original: normalized,
    );
  }
}
