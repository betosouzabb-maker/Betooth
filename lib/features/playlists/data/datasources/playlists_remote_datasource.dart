import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/models/pagination_model.dart';
import '../../../../shared/models/playlist_model.dart';

final playlistsRemoteDatasourceProvider = Provider<PlaylistsRemoteDatasource>(
  (ref) => PlaylistsRemoteDatasource(ref.watch(dioProvider)),
);

class PlaylistsListResult {
  const PlaylistsListResult({required this.items, required this.pagination});
  final List<PlaylistModel> items;
  final PaginationModel pagination;
}

class PlaylistsRemoteDatasource {
  PlaylistsRemoteDatasource(this._dio);
  final Dio _dio;

  Future<PlaylistsListResult> getPlaylists({int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/playlists',
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = _unwrapList(response.data);
      final meta = response.data?['meta'] as Map<String, dynamic>?;
      final paginationJson = meta?['pagination'] as Map<String, dynamic>? ?? {};
      return PlaylistsListResult(
        items: data.map((e) => PlaylistModel.fromJson(e)).toList(),
        pagination: PaginationModel.fromJson(paginationJson),
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<PlaylistDetailModel> getPlaylistDetail(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/playlists/$id');
      final data = _unwrapMap(response.data);
      return PlaylistDetailModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<PlaylistModel> createPlaylist({
    required String name,
    String? description,
    bool isPublic = false,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/playlists',
        data: {'name': name, 'description': description, 'isPublic': isPublic},
      );
      final data = _unwrapMap(response.data);
      return PlaylistModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<PlaylistModel> updatePlaylist(
    String id, {
    String? name,
    String? description,
    bool? isPublic,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/playlists/$id',
        data: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (isPublic != null) 'isPublic': isPublic,
        },
      );
      final data = _unwrapMap(response.data);
      return PlaylistModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> deletePlaylist(String id) async {
    try {
      await _dio.delete<Map<String, dynamic>>('/playlists/$id');
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> addTrackToPlaylist(String playlistId, String trackId) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/playlists/$playlistId/items',
        data: {'trackId': trackId},
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> removeItemFromPlaylist(String playlistId, String itemId) async {
    try {
      await _dio.delete<Map<String, dynamic>>('/playlists/$playlistId/items/$itemId');
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> reorderItems(String playlistId, List<String> orderedIds) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        '/playlists/$playlistId/items/reorder',
        data: {'orderedIds': orderedIds},
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  List<Map<String, dynamic>> _unwrapList(Map<String, dynamic>? payload) {
    final data = payload?['data'];
    if (data is List) return data.cast<Map<String, dynamic>>();
    throw const AppException('Resposta inválida da API.');
  }

  Map<String, dynamic> _unwrapMap(Map<String, dynamic>? payload) {
    final data = payload?['data'];
    if (data is Map<String, dynamic>) return data;
    throw const AppException('Resposta inválida da API.');
  }

  AppException _mapError(DioException error) {
    if (error.error is AppException) return error.error! as AppException;
    final responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final msg = (responseData['error'] as Map<String, dynamic>?)?['message'] as String?;
      if (msg != null && msg.isNotEmpty) return AppException(msg);
    }
    return const AppException('Não foi possível concluir a operação.');
  }
}
