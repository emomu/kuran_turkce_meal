import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../data/models/root.dart';

/// Bir ayetteki köklü kelimeler, kök kayıtlarıyla eşleştirilmiş.
///
/// Kelime seçim yaprağı her kelimenin Türkçe anlamını da gösterir; anlam
/// kelimede değil kök kaydında durduğu için ikisi burada birleştirilir.
final verseWordsProvider =
    FutureProvider.family<List<AnalysedWord>, (int, int)>((ref, key) async {
  final repo = await ref.watch(rootDataProvider.future);
  return [
    for (final word in repo.wordsOfVerse(key.$1, key.$2))
      AnalysedWord(word: word, root: repo.rootOf(word.root)),
  ];
});

/// Bir kelime ve ait olduğu kök kaydı.
class AnalysedWord {
  const AnalysedWord({required this.word, required this.root});

  final RootWord word;

  /// Kök kaydı. Sözlükte bulunmayan bir kök gelirse null olabilir.
  final QuranRoot? root;

  /// Kelimenin altında gösterilecek kısa Türkçe karşılık.
  String get meaning => root?.primaryMeaning ?? '';
}

/// Kök harflerinden kök kaydı ve geçişleri.
final rootDetailProvider =
    FutureProvider.family<RootDetail?, String>((ref, arabicRoot) async {
  final repo = await ref.watch(rootDataProvider.future);
  final root = repo.rootOf(arabicRoot);
  if (root == null) return null;
  return RootDetail(root: root, occurrences: repo.occurrencesOf(root));
});

/// Kök detayında gösterilen veri: kökün kendisi ve geçtiği kelimeler.
class RootDetail {
  const RootDetail({required this.root, required this.occurrences});

  final QuranRoot root;
  final List<RootWord> occurrences;
}

/// Kök arama ekranının durumu.
///
/// Arama bellekte çalıştığı için gecikme (debounce) konmadı: 1651 kök
/// üzerinde tarama tuş başına bir kaç milisaniye sürer, sonucu beklemek
/// yazma akışını bozardı. Meal aramasında gecikme var çünkü orası diske
/// gidiyor.
class RootSearchNotifier extends StateNotifier<RootSearchState> {
  RootSearchNotifier(this._ref) : super(const RootSearchState());

  final Ref _ref;

  void updateQuery(String query) {
    state = state.copyWith(query: query);
    _recompute();
  }

  /// Harf filtresinde bir harfi açar/kapatır.
  void toggleLetter(String letter) {
    final next = Set<String>.from(state.selectedLetters);
    if (!next.remove(letter)) next.add(letter);
    state = state.copyWith(selectedLetters: next);
    _recompute();
  }

  void clearLetters() {
    if (state.selectedLetters.isEmpty) return;
    state = state.copyWith(selectedLetters: const {});
    _recompute();
  }

  void clear() {
    state = const RootSearchState();
  }

  void _recompute() {
    final repo = _ref.read(rootRepositoryProvider);
    if (!repo.isLoaded) return;

    final query = state.query.trim();
    final letters = state.selectedLetters;

    // Sorgu ve harf filtresi birlikte çalışır: harf seçiliyken yazılan metin
    // yalnızca o harfleri içeren kökler arasında aranır.
    if (query.isEmpty && letters.isEmpty) {
      state = state.copyWith(results: const []);
      return;
    }

    List<QuranRoot> results;
    if (query.isEmpty) {
      results = repo.byLetters(letters);
    } else {
      results = repo.search(query);
      if (letters.isNotEmpty) {
        results = results
            .where((r) => letters.every((l) => r.letters.contains(l)))
            .toList();
      }
    }

    state = state.copyWith(results: results);
  }
}

class RootSearchState {
  const RootSearchState({
    this.query = '',
    this.selectedLetters = const {},
    this.results = const [],
  });

  final String query;
  final Set<String> selectedLetters;
  final List<QuranRoot> results;

  bool get isActive => query.trim().isNotEmpty || selectedLetters.isNotEmpty;
  bool get isEmpty => isActive && results.isEmpty;

  RootSearchState copyWith({
    String? query,
    Set<String>? selectedLetters,
    List<QuranRoot>? results,
  }) => RootSearchState(
    query: query ?? this.query,
    selectedLetters: selectedLetters ?? this.selectedLetters,
    results: results ?? this.results,
  );
}

final rootSearchProvider =
    StateNotifierProvider<RootSearchNotifier, RootSearchState>(
  (ref) => RootSearchNotifier(ref),
);
