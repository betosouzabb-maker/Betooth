import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../shared/models/playlist_model.dart';
import '../../data/datasources/playlists_remote_datasource.dart';

final playlistsControllerProvider =
    StateNotifierProvider<PlaylistsController, PlaylistsState>((ref) {
  return PlaylistsController(ref.watch(playlistsRemoteDatasourceProvider));
});

final playlistDetailControllerProvider = StateNotifierProvider.family<
    PlaylistDetailController, PlaylistDetailState, String>(
  (ref, playlistId) => PlaylistDetailController(
    ref.watch(playlistsRemoteDatasourceProvider),
    playlistId,
  ),
);

// --- Playlists list state ---

class PlaylistsState {
  const PlaylistsState({
    required this.items,
    required this.isLoading,
    required this.hasMore,
    required this.page,
    this.errorMessage,
    this.isCreating = false,
  });

  const PlaylistsState.initial()
      : items = const [],
        isLoading = false,
        hasMore = false,
        page = 1,
        errorMessage = null,
        isCreating = false;

  final List<PlaylistModel> items;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final String? errorMessage;
  final bool isCreating;

  PlaylistsState copyWith({
    List<PlaylistModel>? items,
    bool? isLoading,
    bool? hasMore,
    int? page,
    String? errorMessage,
    bool clearError = false,
    bool? isCreating,
  }) {
    return PlaylistsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isCreating: isCreating ?? this.isCreating,
    );
  }
}

class PlaylistsController extends StateNotifier<PlaylistsState> {
  PlaylistsController(this._datasource) : super(const PlaylistsState.initial()) {
    load();
  }

  final PlaylistsRemoteDatasource _datasource;

  Future<void> load({bool refresh = false}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _datasource.getPlaylists(
        page: refresh ? 1 : state.page,
      );
      final newItems = refresh ? result.items : [...state.items, ...result.items];
      state = state.copyWith(
        items: newItems,
        isLoading: false,
        hasMore: result.pagination.hasMore,
        page: refresh ? 2 : state.page + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is AppException ? e.message : 'Erro ao carregar playlists.',
      );
    }
  }

  Future<void> refresh() => load(refresh: true);

  Future<PlaylistModel?> createPlaylist({
    required String name,
    String? description,
    bool isPublic = false,
  }) async {
    state = state.copyWith(isCreating: true, clearError: true);
    try {
      final playlist = await _datasource.createPlaylist(
        name: name,
        description: description,
        isPublic: isPublic,
      );
      state = state.copyWith(
        items: [playlist, ...state.items],
        isCreating: false,
      );
      return playlist;
    } catch (e) {
      state = state.copyWith(
        isCreating: false,
        errorMessage: e is AppException ? e.message : 'Erro ao criar playlist.',
      );
      return null;
    }
  }

  Future<void> deletePlaylist(String id) async {
    try {
      await _datasource.deletePlaylist(id);
      state = state.copyWith(
        items: state.items.where((p) => p.id != id).toList(),
      );
    } catch (_) {}
  }
}

// --- Playlist detail state ---

class PlaylistDetailState {
  const PlaylistDetailState({
    this.detail,
    required this.isLoading,
    this.errorMessage,
    this.isRemoving = false,
  });

  const PlaylistDetailState.initial()
      : detail = null,
        isLoading = true,
        errorMessage = null,
        isRemoving = false;

  final PlaylistDetailModel? detail;
  final bool isLoading;
  final String? errorMessage;
  final bool isRemoving;

  PlaylistDetailState copyWith({
    PlaylistDetailModel? detail,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? isRemoving,
  }) {
    return PlaylistDetailState(
      detail: detail ?? this.detail,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isRemoving: isRemoving ?? this.isRemoving,
    );
  }
}

class PlaylistDetailController extends StateNotifier<PlaylistDetailState> {
  PlaylistDetailController(this._datasource, this.playlistId)
      : super(const PlaylistDetailState.initial()) {
    load();
  }

  final PlaylistsRemoteDatasource _datasource;
  final String playlistId;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final detail = await _datasource.getPlaylistDetail(playlistId);
      state = state.copyWith(detail: detail, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is AppException ? e.message : 'Erro ao carregar playlist.',
      );
    }
  }

  Future<void> refresh() => load();

  Future<void> removeItem(String itemId) async {
    state = state.copyWith(isRemoving: true);
    try {
      await _datasource.removeItemFromPlaylist(playlistId, itemId);
      if (state.detail != null) {
        final updatedItems =
            state.detail!.items.where((i) => i.id != itemId).toList();
        state = state.copyWith(
          detail: PlaylistDetailModel(
            id: state.detail!.id,
            title: state.detail!.title,
            slug: state.detail!.slug,
            description: state.detail!.description,
            coverUrl: state.detail!.coverUrl,
            visibility: state.detail!.visibility,
            isCollaborative: state.detail!.isCollaborative,
            createdAt: state.detail!.createdAt,
            updatedAt: state.detail!.updatedAt,
            items: updatedItems,
          ),
          isRemoving: false,
        );
      }
    } catch (_) {
      state = state.copyWith(isRemoving: false);
    }
  }

  Future<void> reorderItems(List<String> orderedIds) async {
    try {
      await _datasource.reorderItems(playlistId, orderedIds);
    } catch (_) {}
  }
}
