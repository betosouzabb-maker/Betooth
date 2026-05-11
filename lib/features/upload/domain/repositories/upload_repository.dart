import '../entities/upload_entity.dart';

abstract class UploadRepository {
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
  });

  Future<void> cancelUpload(String uploadId);

  Future<UploadEntity> getUploadStatus(String uploadId);
}
