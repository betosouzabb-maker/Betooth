import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/upload_entity.dart';
import '../../domain/repositories/upload_repository.dart';
import '../datasources/upload_remote_datasource.dart';
import '../datasources/upload_local_datasource.dart';

final uploadRepositoryProvider = Provider<UploadRepository>(
  (ref) => UploadRepositoryImpl(
    ref.watch(uploadRemoteDatasourceProvider),
    ref.watch(uploadLocalDatasourceProvider),
  ),
);

class UploadRepositoryImpl implements UploadRepository {
  UploadRepositoryImpl(this._remote, this._local);

  final UploadRemoteDatasource _remote;
  final UploadLocalDatasource _local;

  @override
  Future<UploadEntity> startUpload({
    required String filePath,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
    required String checksum,
    String? title,
    String? artist,
    String? album,
    String? genre,
    String? privacy,
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0.0);

    final initData = await _remote.initUpload(
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      checksum: checksum,
      title: title,
      artist: artist,
      album: album,
      genre: genre,
      privacy: privacy,
    );

    final uploadId = initData['uploadId'] as String;

    final pending = PendingUpload(
      id: uploadId,
      filePath: filePath,
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      checksum: checksum,
      title: title,
      artist: artist,
      album: album,
      genre: genre,
      privacy: privacy,
    );
    await _local.savePendingUpload(pending);

    await _remote.uploadChunks(uploadId, filePath, onProgress: onProgress);

    final completeData = await _remote.completeUpload(uploadId, checksum);
    await _local.removePendingUpload(uploadId);

    onProgress?.call(1.0);

    return UploadEntity(
      id: uploadId,
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      status: UploadStatus.completed,
      progress: 1.0,
      trackId: completeData['trackId'] as String?,
    );
  }

  @override
  Future<void> cancelUpload(String uploadId) async {
    await _remote.cancelUpload(uploadId);
    await _local.removePendingUpload(uploadId);
  }

  @override
  Future<UploadEntity> getUploadStatus(String uploadId) async {
    final data = await _remote.getUploadStatus(uploadId);
    return UploadEntity(
      id: uploadId,
      fileName: data['originalName'] as String? ?? '',
      mimeType: data['mimeType'] as String? ?? '',
      sizeBytes: (data['sizeBytes'] as num?)?.toInt() ?? 0,
      status: UploadRemoteDatasource.mapStatus(data['status'] as String?),
      trackId: data['trackId'] as String?,
      errorMessage: data['errorMessage'] as String?,
    );
  }
}
