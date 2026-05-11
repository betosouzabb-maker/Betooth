import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/datasources/library_remote_datasource.dart';

final libraryControllerProvider =
    StateNotifierProvider<LibraryController, LibraryState>((ref) {
  return LibraryController(ref.watch(libraryRemoteDatasourceProvider));
});

class LibraryState {
  const LibraryState({
    required this.items,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.activeFilter,
    required this.activeSort,
    required this.page,
    this.errorMessage,
  });

  const LibraryState.initial()
      : items = const [],
        isLoading = false,
        isLoadingMore = false,
        hasMore = false,
        activeFilter = 'all',
        activeSort = 'recent',
        page = 1,
        errorMessage = null;

  final List<LibraryItemData> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String activeFilter;
  final String activeSort;
  final int page;
  final String? errorMessage;

  LibraryState copyWith({
    List<LibraryItemData>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? activeFilter,
    String? activeSort,
    int? page,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LibraryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      activeFilter: activeFilter ?? this.activeFilter,
      activeSort: activeSort ?? this.activeSort,
      page: page ?? this.page,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class LibraryController extends StateNotifier<LibraryState> {
  LibraryController(this._datasource) : super(const LibraryState.initial()) {
    load();
  }

  final LibraryRemoteDatasource _datasource;

  Future<void> load({bool refresh = false}) async {
    if (state.isLoading || state.isLoadingMore) return;

    state = state.copyWith(
      isLoading: refresh || state.items.isEmpty,
      isLoadingMore: !refresh && state.items.isNotEmpty,
      clearError: true,
    );

    try {
      final result = await _datasource.getLibrary(
        page: refresh ? 1 : state.page,
        sort: state.activeSort == 'recent' ? null : state.activeSort,
        filter: state.activeFilter == 'all' ? null : state.activeFilter,
      );

      final newItems = refresh ? result.items : [...state.items, ...result.items];
      state = state.copyWith(
        items: newItems,
        isLoading: false,
        isLoadingMore: false,
        hasMore: result.pagination.hasMore,
        page: refresh ? 2 : state.page + 1,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        errorMessage: error is AppException ? error.message : 'Erro ao carregar biblioteca.',
      );
    }
  }

  Future<void> refresh() => load(refresh: true);

  Future<void> loadMore() {
    if (!state.hasMore || state.isLoadingMore) return Future.value();
    return load();
  }

  void setFilter(String filter) {
    if (state.activeFilter == filter) return;
    state = state.copyWith(activeFilter: filter, items: [], page: 1, hasMore: false);
    load(refresh: true);
  }

  void setSort(String sort) {
    if (state.activeSort == sort) return;
    state = state.copyWith(activeSort: sort, items: [], page: 1, hasMore: false);
    load(refresh: true);
  }

  Future<void> addTrack(String trackId) async {
    try {
      await _datasource.addTrack(trackId);
      await refresh();
    } catch (_) {}
  }

  Future<void> removeTrack(String trackId) async {
    try {
      await _datasource.removeTrack(trackId);
      state = state.copyWith(
        items: state.items.where((i) => i.track.id != trackId).toList(),
      );
    } catch (_) {}
  }
}
