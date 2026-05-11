import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/models/pagination_model.dart';
import '../../../../shared/models/track_model.dart';

final libraryRemoteDatasourceProvider = Provider<LibraryRemoteDatasource>(
  (ref) => LibraryRemoteDatasource(ref.watch(dioProvider)),
);

class LibraryItemData {
  const LibraryItemData({
    required this.id,
    required this.addedAt,
    required this.track,
    this.source,
  });

  final String id;
  final DateTime addedAt;
  final TrackModel track;
  final String? source;

  factory LibraryItemData.fromJson(Map<String, dynamic> json) {
    return LibraryItemData(
      id: json['id'] as String? ?? '',
      addedAt: DateTime.tryParse(json['addedAt'] as String? ?? '') ?? DateTime.now(),
      source: json['source'] as String?,
      track: TrackModel.fromJson(json['track'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class LibraryListResult {
  const LibraryListResult({required this.items, required this.pagination});

  final List<LibraryItemData> items;
  final PaginationModel pagination;
}

class LibraryRemoteDatasource {
  LibraryRemoteDatasource(this._dio);

  final Dio _dio;

  Future<LibraryListResult> getLibrary({
    int page = 1,
    int limit = 20,
    String? sort,
    String? filter,
    String? artistId,
    String? albumId,
    String? genreId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'visibility': 'public',
        if (sort != null) 'sort': sort,
        if (filter != null) 'filter': filter,
        if (artistId != null) 'artistId': artistId,
        if (albumId != null) 'albumId': albumId,
        if (genreId != null) 'genreId': genreId,
      };

      final response = await _dio.get<Map<String, dynamic>>(
        '/users/me/library',
        queryParameters: queryParams,
      );

      final data = _unwrapList(response.data);
      final meta = response.data?['meta'] as Map<String, dynamic>?;
      final paginationJson = meta?['pagination'] as Map<String, dynamic>? ?? {};

      return LibraryListResult(
        items: data.map((e) => LibraryItemData.fromJson(e)).toList(),
        pagination: PaginationModel.fromJson(paginationJson),
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<LibraryItemData> addTrack(String trackId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/library/tracks/$trackId/add',
      );
      final data = _unwrapMap(response.data);
      return LibraryItemData.fromJson(data);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> removeTrack(String trackId) async {
    try {
      await _dio.delete<Map<String, dynamic>>('/library/tracks/$trackId');
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  List<Map<String, dynamic>> _unwrapList(Map<String, dynamic>? payload) {
    final data = payload?['data'];
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
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
