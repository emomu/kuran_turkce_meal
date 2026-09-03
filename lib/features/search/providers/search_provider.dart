import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../data/repositories/quran_repository.dart';

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
      state = state.copyWith(results: const [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);
    _debounce = Timer(const Duration(milliseconds: 250), () => _run(query));
  }

  Future<void> _run(String query) async {
    final id = ++_requestId;
    final results = await _ref
        .read(quranRepositoryProvider)
        .search(query, languageCode: _languageCode);

    // Bu sorgu artık güncel değilse sonucu at.
    if (id != _requestId || !mounted) return;

    state = state.copyWith(results: results, isLoading: false);
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

class SearchState {
  const SearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
  });

  final String query;
  final List<SearchHit> results;
  final bool isLoading;

  bool get hasQuery => query.trim().length >= 2;
  bool get isEmpty => hasQuery && !isLoading && results.isEmpty;

  SearchState copyWith({
    String? query,
    List<SearchHit>? results,
    bool? isLoading,
  }) => SearchState(
    query: query ?? this.query,
    results: results ?? this.results,
    isLoading: isLoading ?? this.isLoading,
  );
}

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>(
  (ref) => SearchNotifier(ref),
);
