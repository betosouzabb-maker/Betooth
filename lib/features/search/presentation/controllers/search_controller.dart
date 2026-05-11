import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/datasources/search_remote_datasource.dart';

final searchControllerProvider =
    StateNotifierProvider<SearchController, SearchState>((ref) {
  return SearchController(ref.watch(searchRemoteDatasourceProvider));
});

class SearchState {
  const SearchState({
    required this.query,
    required this.suggestions,
    required this.history,
    required this.results,
    required this.isSearching,
    required this.isLoadingHistory,
    required this.hasSearched,
    this.errorMessage,
    this.activeType,
  });

  const SearchState.initial()
      : query = '',
        suggestions = const [],
        history = const [],
        results = null,
        isSearching = false,
        isLoadingHistory = false,
        hasSearched = false,
        errorMessage = null,
        activeType = null;

  final String query;
  final List<String> suggestions;
  final List<SearchHistoryItem> history;
  final SearchResults? results;
  final bool isSearching;
  final bool isLoadingHistory;
  final bool hasSearched;
  final String? errorMessage;
  final String? activeType;

  SearchState copyWith({
    String? query,
    List<String>? suggestions,
    List<SearchHistoryItem>? history,
    SearchResults? results,
    bool? isSearching,
    bool? isLoadingHistory,
    bool? hasSearched,
    String? errorMessage,
    bool clearError = false,
    String? activeType,
    bool clearType = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      suggestions: suggestions ?? this.suggestions,
      history: history ?? this.history,
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      hasSearched: hasSearched ?? this.hasSearched,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      activeType: clearType ? null : activeType ?? this.activeType,
    );
  }
}

class SearchController extends StateNotifier<SearchState> {
  SearchController(this._datasource) : super(const SearchState.initial()) {
    loadHistory();
  }

  final SearchRemoteDatasource _datasource;
  Timer? _debounceTimer;
  Timer? _suggestionsTimer;

  Future<void> loadHistory() async {
    state = state.copyWith(isLoadingHistory: true);
    final history = await _datasource.getHistory();
    state = state.copyWith(history: history, isLoadingHistory: false);
  }

  void onQueryChanged(String query) {
    state = state.copyWith(query: query);

    _suggestionsTimer?.cancel();
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      state = state.copyWith(suggestions: [], results: null, hasSearched: false, clearError: true);
      return;
    }

    // Suggestions after 200ms
    _suggestionsTimer = Timer(const Duration(milliseconds: 200), () async {
      final suggestions = await _datasource.getSuggestions(query.trim());
      if (mounted) state = state.copyWith(suggestions: suggestions);
    });

    // Search after 500ms (debounce)
    _debounceTimer = Timer(const Duration(milliseconds: 500), () => search(query));
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;

    _debounceTimer?.cancel();
    _suggestionsTimer?.cancel();

    state = state.copyWith(
      query: query,
      isSearching: true,
      suggestions: [],
      clearError: true,
    );

    try {
      final results = await _datasource.search(
        query.trim(),
        type: state.activeType,
      );
      state = state.copyWith(
        results: results,
        isSearching: false,
        hasSearched: true,
      );
      // Reload history after search
      unawaited(loadHistory());
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        hasSearched: true,
        errorMessage: e is AppException ? e.message : 'Erro ao buscar.',
      );
    }
  }

  void setFilter(String? type) {
    if (state.activeType == type) {
      state = state.copyWith(clearType: true);
    } else {
      state = state.copyWith(activeType: type);
    }
    if (state.query.isNotEmpty) {
      search(state.query);
    }
  }

  void selectHistoryItem(String query) {
    state = state.copyWith(query: query);
    search(query);
  }

  Future<void> clearHistory() async {
    await _datasource.clearHistory();
    state = state.copyWith(history: []);
  }

  void clear() {
    _debounceTimer?.cancel();
    _suggestionsTimer?.cancel();
    state = const SearchState.initial();
    loadHistory();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _suggestionsTimer?.cancel();
    super.dispose();
  }
}
