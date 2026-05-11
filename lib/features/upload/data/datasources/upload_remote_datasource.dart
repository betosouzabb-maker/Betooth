import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/dio_client.dart';
import '../../domain/entities/upload_entity.dart';

final uploadRemoteDatasourceProvider = Provider<UploadRemoteDatasource>(
  (ref) => UploadRemoteDatasource(ref.watch(dioProvider)),
);

class UploadRemoteDatasource {
  UploadRemoteDatasource(this._dio);

  final Dio _dio;

  static const _chunkSize = 1 * 1024 * 1024; // 1 MB chunks

  Future<Map<String, dynamic>> initUpload({
    required String fileName,
    required String mimeType,
    required int sizeBytes,
    required String checksum,
    String? title,
    String? artist,
    String? album,
    String? genre,
    String? privacy,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/uploads/init',
      data: {
        'fileName': fileName,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
        'checksum': checksum,
        if (title != null) 'title': title,
        if (artist != null) 'artist': artist,
        if (album != null) 'album': album,
        if (genre != null) 'genre': genre,
        if (privacy != null) 'privacy': privacy,
      },
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Resposta inválida ao iniciar upload.');
    return data;
  }

  Future<void> uploadChunks(
    String uploadId,
    String filePath, {
    void Function(double progress)? onProgress,
  }) async {
    final file = File(filePath);
    final totalSize = await file.length();
    int bytesSent = 0;

    final raf = await file.open();
    try {
      while (bytesSent < totalSize) {
        final remaining = totalSize - bytesSent;
        final chunkLen = remaining < _chunkSize ? remaining : _chunkSize;
        final buffer = List<int>.filled(chunkLen, 0);
        await raf.readInto(buffer, 0, chunkLen);

        await _dio.put<void>(
          '/uploads/$uploadId/chunk',
          data: Stream.fromIterable([buffer]),
          options: Options(
            headers: {
              Headers.contentTypeHeader: 'application/octet-stream',
              Headers.contentLengthHeader: '$chunkLen',
            },
          ),
        );

        bytesSent += chunkLen;
        onProgress?.call(bytesSent / totalSize * 0.9);
      }
    } finally {
      await raf.close();
    }
  }

  Future<Map<String, dynamic>> completeUpload(
    String uploadId,
    String checksum,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/uploads/$uploadId/complete',
      data: {'checksum': checksum},
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Resposta inválida ao completar upload.');
    return data;
  }

  Future<Map<String, dynamic>> getUploadStatus(String uploadId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/uploads/$uploadId/status',
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Resposta inválida ao obter status.');
    return data;
  }

  Future<void> cancelUpload(String uploadId) async {
    await _dio.post<void>('/uploads/$uploadId/cancel');
  }

  static UploadStatus mapStatus(String? raw) {
    switch (raw) {
      case 'PENDING':
        return UploadStatus.uploading;
      case 'PROCESSING':
        return UploadStatus.processing;
      case 'COMPLETED':
        return UploadStatus.completed;
      case 'FAILED':
      case 'REJECTED':
        return UploadStatus.failed;
      default:
        return UploadStatus.pending;
    }
  }
}
