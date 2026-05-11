import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entities/upload_entity.dart';
import '../repositories/upload_repository.dart';
import '../../data/repositories/upload_repository_impl.dart';

final startUploadUsecaseProvider = Provider<StartUploadUsecase>(
  (ref) => StartUploadUsecase(ref.watch(uploadRepositoryProvider)),
);

class StartUploadUsecase {
  const StartUploadUsecase(this._repository);

  final UploadRepository _repository;

  Future<UploadEntity> call({
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
  }) {
    return _repository.startUpload(
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
      onProgress: onProgress,
    );
  }
}
