import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/datasources/favorites_remote_datasource.dart';

final favoritesControllerProvider =
    StateNotifierProvider<FavoritesController, FavoritesState>((ref) {
  return FavoritesController(ref.watch(favoritesRemoteDatasourceProvider));
});

class FavoritesState {
  const FavoritesState({
    required this.items,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.page,
    this.errorMessage,
    this.pendingToggleIds = const {},
  });

  const FavoritesState.initial()
      : items = const [],
        isLoading = false,
        isLoadingMore = false,
        hasMore = false,
        page = 1,
        errorMessage = null,
        pendingToggleIds = const {};

  final List<FavoriteItemData> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String? errorMessage;
  final Set<String> pendingToggleIds;

  bool isFavorited(String trackId) => items.any((i) => i.track.id == trackId);
  bool isPending(String trackId) => pendingToggleIds.contains(trackId);

  FavoritesState copyWith({
    List<FavoriteItemData>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? errorMessage,
    bool clearError = false,
    Set<String>? pendingToggleIds,
  }) {
    return FavoritesState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      pendingToggleIds: pendingToggleIds ?? this.pendingToggleIds,
    );
  }
}

class FavoritesController extends StateNotifier<FavoritesState> {
  FavoritesController(this._datasource) : super(const FavoritesState.initial()) {
    load();
  }

  final FavoritesRemoteDatasource _datasource;

  Future<void> load({bool refresh = false}) async {
    if (state.isLoading || state.isLoadingMore) return;

    state = state.copyWith(
      isLoading: refresh || state.items.isEmpty,
      isLoadingMore: !refresh && state.items.isNotEmpty,
      clearError: true,
    );

    try {
      final result = await _datasource.getFavorites(
        page: refresh ? 1 : state.page,
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
        errorMessage: error is AppException ? error.message : 'Erro ao carregar favoritos.',
      );
    }
  }

  Future<void> refresh() => load(refresh: true);

  Future<void> loadMore() {
    if (!state.hasMore || state.isLoadingMore) return Future.value();
    return load();
  }

  Future<void> toggleFavorite(String trackId) async {
    final wasFavorited = state.isFavorited(trackId);
    final pending = {...state.pendingToggleIds, trackId};
    state = state.copyWith(pendingToggleIds: pending);

    // Optimistic update
    if (wasFavorited) {
      state = state.copyWith(
        items: state.items.where((i) => i.track.id != trackId).toList(),
      );
    }

    try {
      if (wasFavorited) {
        await _datasource.removeFavorite(trackId);
      } else {
        await _datasource.addFavorite(trackId);
        await refresh();
      }
    } catch (_) {
      // Rollback: reload
      await refresh();
    } finally {
      final newPending = {...state.pendingToggleIds}..remove(trackId);
      state = state.copyWith(pendingToggleIds: newPending);
    }
  }
}
