import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../data/models/prophet.dart';
import '../../../data/models/surah.dart';
import '../../../data/repositories/quran_repository.dart';
import '../../home/providers/home_provider.dart';
import '../data/verse_reference.dart';

/// Arama sorgusu ve sonuçları.
///
/// Kullanıcı yazarken her tuşta veritabanına gitmemek için sorgu 250 ms
/// geciktirilir. Bu süre yazma temposunun altında kalır ama gereksiz
/// sorguların çoğunu eler.
class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier(this._ref) : super(const SearchState());

  final Ref _ref;
  Timer? _debounce;

  /// Sonuçların hangi sorguya ait olduğunu izler; yavaş dönen eski bir
  /// sorgunun yeni sonuçların üstüne yazmasını engeller.
  int _requestId = 0;

  /// Arayüz dili; hangi dilin arama dizininde arama yapılacağını belirler.
  String _languageCode = 'tr';

  set languageCode(String code) {
    if (_languageCode == code) return;
    _languageCode = code;
    // Dil değişince eldeki sonuçlar başka dile ait; sorgu varsa yenilenir.
    if (state.hasQuery) _run(state.query);
  }

  void updateQuery(String query) {
    state = state.copyWith(query: query);

    _debounce?.cancel();

    if (query.trim().length < 2) {
      state = state.copyWith(
        results: const [],
        reference: null,
        prophet: null,
        hasReference: true,
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true);
    _debounce = Timer(const Duration(milliseconds: 250), () => _run(query));
  }

  Future<void> _run(String query) async {
    final id = ++_requestId;

    final reference = await _resolveReference(query);
    final prophet = await _resolveProphet(query);
    final results = await _ref
        .read(quranRepositoryProvider)
        .search(query, languageCode: _languageCode);

    // Bu sorgu artık güncel değilse sonucu at.
    if (id != _requestId || !mounted) return;

    state = state.copyWith(
      results: results,
      reference: reference,
      prophet: prophet,
      hasReference: true,
      isLoading: false,
    );
  }

  /// Sorgu bir peygamber adına karşılık geliyor mu.
  ///
  /// Karşılık geliyorsa arama sonuçlarının üstünde, o peygamberin anıldığı
  /// ayetlere iniş sırasıyla götüren bir kart gösterilir. Tam metin sonuçları
  /// yerini korur: "Yûsuf" hem bir kıssa hem de mealde geçen bir kelime.
  Future<Prophet?> _resolveProphet(String query) async {
    final repo = await _ref.read(prophetDataProvider.future);
    return repo.byName(query, fold: foldSurahName);
  }

  /// Sorguyu bir ayet referansına çözer ("2:255", "bakara 255", "36").
  ///
  /// Sure künyesi de döndürülür: sonuç kartında sure adı gösterilir ve ayet
  /// numarasının sure sınırları içinde olup olmadığı ancak burada denetlenir.
  /// Aralık dışı bir numara (örn. "1:99") referans sayılmaz — kullanıcıyı
  /// var olmayan bir ayete göndermektense arama sonuçlarına bırakmak yeğdir.
  Future<ReferenceHit?> _resolveReference(String query) async {
    final surahs = await _ref.read(surahListProvider.future);

    final parsed = parseVerseReference(
      query,
      resolveSurahName: (name) => _surahNumberByName(surahs, name),
    );
    if (parsed == null) return null;

    final surah = surahs.where((s) => s.number == parsed.surahNumber);
    if (surah.isEmpty) return null;

    final target = surah.first;
    final ayahNumber = parsed.ayahNumber;
    if (ayahNumber != null && ayahNumber > target.ayahCount) return null;

    return ReferenceHit(
      surah: target,
      ayahNumber: ayahNumber,
      isExplicitAyah: parsed.isExplicitAyah,
    );
  }

  /// Yazılan adı sure numarasına çevirir.
  ///
  /// Türkçe ad, İngilizce ad ve ad anlamı denenir. Tam eşleşme bulunamazsa
  /// başlangıç eşleşmesine düşülür — kullanıcı "bakar" yazmış olabilir.
  int? _surahNumberByName(List<Surah> surahs, String name) {
    final needle = foldSurahName(name);
    if (needle.length < 2) return null;

    for (final s in surahs) {
      final candidates = [
        s.name,
        s.nameEn ?? '',
        s.meaning,
        s.meaningEn ?? '',
      ].map(foldSurahName);
      if (candidates.any((c) => c == needle)) return s.number;
    }

    for (final s in surahs) {
      final candidates = [s.name, s.nameEn ?? ''].map(foldSurahName);
      if (candidates.any((c) => c.isNotEmpty && c.startsWith(needle))) {
        return s.number;
      }
    }

    return null;
  }

  void clear() {
    _debounce?.cancel();
    _requestId++;
    state = const SearchState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

/// Sorgunun çözüldüğü ayet referansı ve hedef sure künyesi.
class ReferenceHit {
  const ReferenceHit({
    required this.surah,
    required this.ayahNumber,
    required this.isExplicitAyah,
  });

  final Surah surah;

  /// Gidilecek ayet. Yalnızca sure adı yazıldıysa null; sure baştan açılır.
  final int? ayahNumber;

  /// Kullanıcı ayet numarasını kendisi yazdı mı.
  final bool isExplicitAyah;

  /// Kartta gösterilen referans: "2:255" ya da "Bakara".
  String get label => ayahNumber == null
      ? surah.name
      : '${surah.name} ${ayahNumber!}';
}

class SearchState {
  const SearchState({
    this.query = '',
    this.results = const [],
    this.reference,
    this.prophet,
    this.hasReference = false,
    this.isLoading = false,
  });

  final String query;
  final List<SearchHit> results;

  /// Sorgu bir ayet referansına çözüldüyse hedefi.
  final ReferenceHit? reference;

  /// Sorgu bir peygamber adına karşılık geliyorsa o peygamber.
  final Prophet? prophet;

  /// Referans çözümlemesi tamamlandı mı.
  ///
  /// `reference == null` tek başına "referans yok" demek değil: sorgu daha
  /// çözülmemiş de olabilir. Boş durum mesajı bu ikisini ayırmadan doğru
  /// gösterilemez.
  final bool hasReference;

  final bool isLoading;

  bool get hasQuery => query.trim().length >= 2;

  /// Ne arama sonucu ne de referans bulundu.
  bool get isEmpty =>
      hasQuery &&
      !isLoading &&
      results.isEmpty &&
      reference == null &&
      prophet == null;

  SearchState copyWith({
    String? query,
    List<SearchHit>? results,
    ReferenceHit? reference,
    Prophet? prophet,
    bool? hasReference,
    bool? isLoading,
  }) => SearchState(
    query: query ?? this.query,
    results: results ?? this.results,
    // Referans ve peygamber bilinçli olarak taşınmaz: yeni sorguda eski kart
    // ekranda kalırsa kullanıcı alakasız bir yere yönlendirilir.
    reference: reference,
    prophet: prophet,
    hasReference: hasReference ?? this.hasReference,
    isLoading: isLoading ?? this.isLoading,
  );
}

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>(
  (ref) => SearchNotifier(ref),
);
