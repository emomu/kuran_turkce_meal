import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../db/search_normalizer.dart';
import '../models/root.dart';

/// Kök verisine erişim. Salt okunur.
///
/// Veri tek seferde belleğe alınır ve orada kalır (~4 MB JSON, çözümlenmiş
/// halde daha fazlası). SQLite'a aktarılmadı çünkü:
///  - Kök arama her tuşta çalışır; disk sorgusu gereksiz gecikme katardı.
///  - Bir kökün geçiş listesi zaten diziyle geliyor, ilişkisel sorguya
///    ihtiyaç yok.
///  - Veri salt okunur ve sürüm başına sabit; şema göçü gerektirmez.
class RootRepository {
  RootRepository();

  static const _assetPath = 'assets/data/roots.json';

  List<QuranRoot>? _roots;
  List<RootWord>? _words;
  List<ArabicLetter>? _letters;

  /// (sure, ayet) -> o ayetteki köklü kelimeler. Okuma ekranı bir ayetin
  /// kelimelerini bununla çözer.
  Map<int, List<RootWord>>? _byVerse;

  /// Kök harfleri -> kök. Kelimeden köke gitmek için.
  Map<String, QuranRoot>? _byRoot;

  Future<void>? _loading;

  /// Veri yüklendi mi.
  bool get isLoaded => _roots != null;

  /// Veriyi belleğe alır. Birden çok kez çağrılsa da tek kez çalışır.
  Future<void> ensureLoaded() {
    if (_roots != null) return Future.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    final String raw;
    try {
      raw = await rootBundle.loadString(_assetPath);
    } on FlutterError {
      // Kök verisi pakete eklenmemişse özellik sessizce kapanır; uygulamanın
      // geri kalanı çalışmaya devam eder.
      _roots = const [];
      _words = const [];
      _letters = const [];
      _byVerse = const {};
      _byRoot = const {};
      return;
    }

    // Çözümleme ana iş parçacığını kilitlemesin; 4 MB JSON'da fark edilir.
    final parsed = await compute(_parse, raw);

    _roots = parsed.roots;
    _words = parsed.words;
    _letters = parsed.letters;
    _byRoot = {for (final r in parsed.roots) r.arabic: r};

    final byVerse = <int, List<RootWord>>{};
    for (final w in parsed.words) {
      byVerse.putIfAbsent(_verseKey(w.surahNumber, w.ayahNumber), () => [])
          .add(w);
    }
    _byVerse = byVerse;
  }

  static int _verseKey(int surah, int ayah) => surah * 1000 + ayah;

  static _ParsedRoots _parse(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return _ParsedRoots(
      roots: (json['roots'] as List)
          .map((e) => QuranRoot.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      words: (json['words'] as List)
          .map((e) => RootWord.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      letters: ((json['letters'] as List?) ?? const [])
          .map((e) => ArabicLetter.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  /// Tüm kökler, geçiş sayısına göre azalan sırada.
  List<QuranRoot> get allRoots => _roots ?? const [];

  /// Harf filtresinde gösterilecek harfler.
  List<ArabicLetter> get letters => _letters ?? const [];

  /// Bir ayetteki köklü kelimeler, kelime sırasına göre.
  List<RootWord> wordsOfVerse(int surahNumber, int ayahNumber) {
    final list = _byVerse?[_verseKey(surahNumber, ayahNumber)];
    if (list == null) return const [];
    return List.of(list)..sort((a, b) => a.wordIndex.compareTo(b.wordIndex));
  }

  /// Kök harflerinden kök kaydını bulur.
  QuranRoot? rootOf(String arabicRoot) => _byRoot?[arabicRoot];

  /// Bir kökün geçtiği tüm kelimeler.
  List<RootWord> occurrencesOf(QuranRoot root) {
    final words = _words;
    if (words == null) return const [];
    return [
      for (final i in root.occurrences)
        if (i >= 0 && i < words.length) words[i],
    ];
  }

  /// Kök arama.
  ///
  /// Tek bir arama kutusu üç yazım biçimini birden karşılar:
  ///  - Türkçe anlam ya da okunuş: "elçi", "resul"
  ///  - Arapça kök: "رسل"
  ///  - Latin iskelet: "rsl", "r-s-l", "r s l"
  ///
  /// Ayrı bir mod seçtirmek yerine hepsi tek kutuda denenir; kullanıcı hangi
  /// biçimi bildiğini düşünmek zorunda kalmaz. Sonuçlar eşleşmenin gücüne,
  /// eşitlikte geçiş sayısına göre sıralanır.
  List<QuranRoot> search(String query, {int limit = 80}) {
    final roots = _roots;
    if (roots == null || roots.isEmpty) return const [];

    final raw = query.trim();
    if (raw.isEmpty) return const [];

    final isArabic = _arabicPattern.hasMatch(raw);
    // Latin sorgularda ayraçlar atılır: "r-s-l" ile "rsl" aynı aramadır.
    final latin = SearchNormalizer.normalize(raw)
        .replaceAll(RegExp(r'[^a-zçğıöşü]'), '');
    final normalizedMeaning = SearchNormalizer.normalize(raw);
    final arabicQuery = isArabic ? _normalizeArabic(raw) : '';

    if (!isArabic && latin.length < 2 && normalizedMeaning.trim().length < 2) {
      return const [];
    }

    final scored = <(int score, QuranRoot root)>[];

    for (final root in roots) {
      final score = _score(
        root,
        isArabic: isArabic,
        arabicQuery: arabicQuery,
        latin: latin,
        meaningQuery: normalizedMeaning,
      );
      if (score > 0) scored.add((score, root));
    }

    scored.sort((a, b) {
      final byScore = b.$1.compareTo(a.$1);
      return byScore != 0 ? byScore : b.$2.count.compareTo(a.$2.count);
    });

    return [for (final s in scored.take(limit)) s.$2];
  }

  /// Verilen harflerin tamamını içeren kökler.
  ///
  /// Harf filtresi çoklu seçime izin verir; seçilen her harf sonucu daraltır
  /// (VE mantığı). Tek harf seçimi o harfle ilgili tüm kökleri getirir.
  List<QuranRoot> byLetters(Set<String> selected, {int limit = 400}) {
    final roots = _roots;
    if (roots == null || selected.isEmpty) return const [];

    final wanted = selected.map(_normalizeArabic).toSet();

    final matches = <QuranRoot>[];
    for (final root in roots) {
      if (wanted.every((l) => root.letters.contains(l))) {
        matches.add(root);
        if (matches.length >= limit) break;
      }
    }
    return matches;
  }

  static final _arabicPattern = RegExp(r'[؀-ۿ]');

  static String _normalizeArabic(String input) {
    var s = input;
    // Harekeler ve duraklama işaretleri atılır.
    s = s.replaceAll(RegExp(r'[ؐ-ًؚ-ٰٟۖ-ۭـ]'), '');
    // Hemze ve elif varyantları tek biçime indirgenir.
    const folding = {
      'آ': 'ا', 'أ': 'ا', 'إ': 'ا', 'ٱ': 'ا',
      'ؤ': 'ء', 'ئ': 'ء',
      'ى': 'ي', 'ة': 'ه',
    };
    folding.forEach((from, to) => s = s.replaceAll(from, to));
    return s.trim();
  }

  /// Bir kökün sorguya uygunluk puanı. 0 ise eşleşme yok.
  ///
  /// Puanlama, kullanıcının en çok beklediği eşleşmeyi öne alır: tam
  /// eşleşme > baştan eşleşme > içinde geçme.
  int _score(
    QuranRoot root, {
    required bool isArabic,
    required String arabicQuery,
    required String latin,
    required String meaningQuery,
  }) {
    if (isArabic) {
      if (arabicQuery.isEmpty) return 0;
      if (root.normalized == arabicQuery) return 1000;
      if (root.normalized.startsWith(arabicQuery)) return 700;
      if (root.normalized.contains(arabicQuery)) return 400;
      return 0;
    }

    var best = 0;

    // Türkçe okunuş — "resul" yazan kullanıcı رسل köküne ulaşmalı.
    for (final reading in root.readings) {
      if (reading == latin) {
        best = best < 950 ? 950 : best;
      } else if (reading.startsWith(latin)) {
        best = best < 650 ? 650 : best;
      } else if (reading.contains(latin)) {
        best = best < 300 ? 300 : best;
      }
    }

    // Latin iskelet — "rsl", "r-s-l".
    for (final t in root.translitterations) {
      if (t == latin) {
        best = best < 900 ? 900 : best;
      } else if (t.startsWith(latin)) {
        best = best < 600 ? 600 : best;
      }
    }

    // Türkçe anlam — "elçi", "peygamber".
    if (root.hasMeaning && meaningQuery.isNotEmpty) {
      final meaning = SearchNormalizer.normalize(root.meaning);
      if (meaning == meaningQuery) {
        best = best < 980 ? 980 : best;
      } else {
        // Anlam virgülle ayrılmış karşılıklardan oluşur; her karşılık ayrı
        // değerlendirilir ki "elçi" araması "göndermek, elçi" içinde tam
        // eşleşme sayılsın.
        for (final part in meaning.split(',')) {
          final p = part.trim();
          if (p.isEmpty) continue;
          if (p == meaningQuery) {
            best = best < 850 ? 850 : best;
          } else if (p.startsWith(meaningQuery)) {
            best = best < 500 ? 500 : best;
          } else if (p.contains(meaningQuery)) {
            best = best < 250 ? 250 : best;
          }
        }
      }
    }

    return best;
  }
}

class _ParsedRoots {
  const _ParsedRoots({
    required this.roots,
    required this.words,
    required this.letters,
  });

  final List<QuranRoot> roots;
  final List<RootWord> words;
  final List<ArabicLetter> letters;
}
