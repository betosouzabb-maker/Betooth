import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/dio_client.dart';

final reportsRemoteDatasourceProvider = Provider<ReportsRemoteDatasource>(
  (ref) => ReportsRemoteDatasource(ref.watch(dioProvider)),
);

enum ReportReason {
  inappropriate,
  copyright,
  spam,
  hateSpeech,
  other,
}

extension ReportReasonLabel on ReportReason {
  String get label {
    switch (this) {
      case ReportReason.inappropriate:
        return 'Conteúdo inapropriado';
      case ReportReason.copyright:
        return 'Violação de direitos autorais';
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.hateSpeech:
        return 'Discurso de ódio';
      case ReportReason.other:
        return 'Outro';
    }
  }

  String get value {
    switch (this) {
      case ReportReason.inappropriate:
        return 'INAPPROPRIATE';
      case ReportReason.copyright:
        return 'COPYRIGHT';
      case ReportReason.spam:
        return 'SPAM';
      case ReportReason.hateSpeech:
        return 'HATE_SPEECH';
      case ReportReason.other:
        return 'OTHER';
    }
  }
}

class ReportsRemoteDatasource {
  ReportsRemoteDatasource(this._dio);

  final Dio _dio;

  Future<void> reportTrack({
    required String trackId,
    required ReportReason reason,
    String? description,
  }) async {
    try {
      await _dio.post<void>(
        '/reports/tracks/$trackId',
        data: {
          'reason': reason.value,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> reportUser({
    required String userId,
    required ReportReason reason,
    String? description,
  }) async {
    try {
      await _dio.post<void>(
        '/reports/users/$userId',
        data: {
          'reason': reason.value,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> reportPlaylist({
    required String playlistId,
    required ReportReason reason,
    String? description,
  }) async {
    try {
      await _dio.post<void>(
        '/reports/playlists/$playlistId',
        data: {
          'reason': reason.value,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  AppException _mapError(DioException error) {
    if (error.error is AppException) return error.error! as AppException;
    final responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final msg =
          (responseData['error'] as Map<String, dynamic>?)?['message'] as String?;
      if (msg != null && msg.isNotEmpty) return AppException(msg);
    }
    return const AppException('Não foi possível enviar a denúncia.');
  }
}
