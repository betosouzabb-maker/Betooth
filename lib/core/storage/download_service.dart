import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../network/dio_client.dart';
import '../errors/app_exception.dart';
import '../logging/app_logger.dart';

final downloadServiceProvider = Provider<DownloadService>(
  (ref) => DownloadService(ref.watch(dioProvider)),
);

class DownloadResult {
  const DownloadResult({
    required this.localPath,
    required this.trackId,
    required this.fileName,
  });

  final String localPath;
  final String trackId;
  final String fileName;
}

class DownloadService {
  DownloadService(this._dio);

  final Dio _dio;

  Future<DownloadResult> downloadTrack(
    String trackId, {
    void Function(double progress)? onProgress,
  }) async {
    // 1. Get signed download URL from backend
    final urlResponse = await _dio.get<Map<String, dynamic>>(
      '/tracks/$trackId/download-url',
    );

    final data = urlResponse.data?['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const AppException('Não foi possível obter URL de download.');
    }

    final signedUrl = data['url'] as String?;
    if (signedUrl == null || signedUrl.isEmpty) {
      throw const AppException('URL de download inválida.');
    }

    final trackInfo = data['track'] as Map<String, dynamic>?;
    final trackTitle = (trackInfo?['title'] as String?) ?? trackId;

    // 2. Determine local file path
    final downloadsDir = await _getDownloadsDirectory();
    final sanitizedTitle = trackTitle.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    final fileName = '$sanitizedTitle-$trackId.mp3';
    final localPath = p.join(downloadsDir.path, fileName);

    // 3. Download file with progress
    onProgress?.call(0.0);

    final directDio = Dio();
    await directDio.download(
      signedUrl,
      localPath,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          onProgress?.call(received / total);
        }
      },
      options: Options(
        receiveTimeout: const Duration(minutes: 10),
      ),
    );

    onProgress?.call(1.0);

    // 4. Verify integrity
    final valid = await _verifyFile(localPath);
    if (!valid) {
      await File(localPath).delete().catchError((_) => File(localPath));
      throw const AppException('Verificação de integridade falhou após download.');
    }

    appLogger.i('Download concluído: $localPath');

    return DownloadResult(
      localPath: localPath,
      trackId: trackId,
      fileName: fileName,
    );
  }

  Future<Directory> _getDownloadsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory(p.join(appDir.path, 'downloads'));
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    return downloadsDir;
  }

  Future<bool> _verifyFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return false;
    final size = await file.length();
    return size > 0;
  }

  Future<bool> isDownloaded(String trackId) async {
    final downloadsDir = await _getDownloadsDirectory();
    final files = await downloadsDir.list().toList();
    return files.any((f) => f.path.contains(trackId));
  }

  Future<String?> getLocalPath(String trackId) async {
    final downloadsDir = await _getDownloadsDirectory();
    final files = await downloadsDir.list().toList();
    final match = files.whereType<File>().where((f) => f.path.contains(trackId));
    if (match.isEmpty) return null;
    return match.first.path;
  }

  Future<void> deleteLocalTrack(String trackId) async {
    final path = await getLocalPath(trackId);
    if (path != null) {
      await File(path).delete().catchError((_) => File(path));
    }
  }
}
