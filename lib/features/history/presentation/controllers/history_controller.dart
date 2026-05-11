import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/history_remote_datasource.dart';
import '../../../../shared/models/pagination_model.dart';

final historyControllerProvider =
    StateNotifierProvider.autoDispose<HistoryController, HistoryState>(
  (ref) => HistoryController(ref.watch(historyRemoteDatasourceProvider)),
);

class HistoryState {
  const HistoryState({
    this.items = const [],
    this.pagination,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final List<HistoryItemData> items;
  final PaginationModel? pagination;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;

  HistoryState copyWith({
    List<HistoryItemData>? items,
    PaginationModel? pagination,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HistoryState(
      items: items ?? this.items,
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class HistoryController extends StateNotifier<HistoryState> {
  HistoryController(this._datasource) : super(const HistoryState()) {
    load();
  }

  final HistoryRemoteDatasource _datasource;
  int _currentPage = 1;

  Future<void> load() async {
    _currentPage = 1;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _datasource.getHistory(page: 1);
      state = state.copyWith(
        isLoading: false,
        items: result.items,
        pagination: result.pagination,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao carregar histórico.',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore) return;
    final pagination = state.pagination;
    if (pagination == null || !pagination.hasMore) return;

    _currentPage++;
    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await _datasource.getHistory(page: _currentPage);
      state = state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...result.items],
        pagination: result.pagination,
      );
    } catch (_) {
      _currentPage--;
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> clearHistory() async {
    try {
      await _datasource.clearHistory();
      state = state.copyWith(items: [], pagination: null);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Não foi possível limpar o histórico.');
    }
  }
}
