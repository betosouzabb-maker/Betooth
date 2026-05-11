import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/models/pagination_model.dart';
import '../../../../shared/models/track_model.dart';

final favoritesRemoteDatasourceProvider = Provider<FavoritesRemoteDatasource>(
  (ref) => FavoritesRemoteDatasource(ref.watch(dioProvider)),
);

class FavoriteItemData {
  const FavoriteItemData({
    required this.id,
    required this.createdAt,
    required this.track,
  });

  final String id;
  final DateTime createdAt;
  final TrackModel track;

  factory FavoriteItemData.fromJson(Map<String, dynamic> json) {
    return FavoriteItemData(
      id: json['id'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      track: TrackModel.fromJson(json['track'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class FavoritesListResult {
  const FavoritesListResult({required this.items, required this.pagination});

  final List<FavoriteItemData> items;
  final PaginationModel pagination;
}

class FavoritesRemoteDatasource {
  FavoritesRemoteDatasource(this._dio);

  final Dio _dio;

  Future<FavoritesListResult> getFavorites({int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/users/me/favorites',
        queryParameters: {'page': page, 'limit': limit},
      );

      final data = _unwrapList(response.data);
      final meta = response.data?['meta'] as Map<String, dynamic>?;
      final paginationJson = meta?['pagination'] as Map<String, dynamic>? ?? {};

      return FavoritesListResult(
        items: data.map((e) => FavoriteItemData.fromJson(e)).toList(),
        pagination: PaginationModel.fromJson(paginationJson),
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> addFavorite(String trackId) async {
    try {
      await _dio.post<Map<String, dynamic>>('/favorites/$trackId');
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> removeFavorite(String trackId) async {
    try {
      await _dio.delete<Map<String, dynamic>>('/favorites/$trackId');
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  List<Map<String, dynamic>> _unwrapList(Map<String, dynamic>? payload) {
    final data = payload?['data'];
    if (data is List) return data.cast<Map<String, dynamic>>();
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
