import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/models/pagination_model.dart';
import '../../../../shared/models/track_model.dart';

final historyRemoteDatasourceProvider = Provider<HistoryRemoteDatasource>(
  (ref) => HistoryRemoteDatasource(ref.watch(dioProvider)),
);

class HistoryItemData {
  const HistoryItemData({
    required this.id,
    required this.playedAt,
    required this.track,
  });

  final String id;
  final DateTime playedAt;
  final TrackModel track;

  factory HistoryItemData.fromJson(Map<String, dynamic> json) {
    return HistoryItemData(
      id: json['id'] as String? ?? '',
      playedAt:
          DateTime.tryParse(json['playedAt'] as String? ?? '') ?? DateTime.now(),
      track: TrackModel.fromJson(
          json['track'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class HistoryListResult {
  const HistoryListResult({required this.items, required this.pagination});

  final List<HistoryItemData> items;
  final PaginationModel pagination;
}

class HistoryRemoteDatasource {
  HistoryRemoteDatasource(this._dio);

  final Dio _dio;

  Future<HistoryListResult> getHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/users/me/history',
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = _unwrapList(response.data);
      final meta = response.data?['meta'] as Map<String, dynamic>?;
      final paginationJson =
          meta?['pagination'] as Map<String, dynamic>? ?? {};

      return HistoryListResult(
        items: data.map(HistoryItemData.fromJson).toList(),
        pagination: PaginationModel.fromJson(paginationJson),
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> addToHistory(String trackId) async {
    try {
      await _dio.post<void>('/users/me/history', data: {'trackId': trackId});
    } on DioException catch (_) {
      // History recording errors are non-critical; swallow silently.
    }
  }

  Future<void> clearHistory() async {
    try {
      await _dio.delete<void>('/users/me/history');
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
      final msg =
          (responseData['error'] as Map<String, dynamic>?)?['message']
              as String?;
      if (msg != null && msg.isNotEmpty) return AppException(msg);
    }
    return const AppException('Não foi possível carregar o histórico.');
  }
}
