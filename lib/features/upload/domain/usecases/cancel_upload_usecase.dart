import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/upload_repository.dart';
import '../../data/repositories/upload_repository_impl.dart';

final cancelUploadUsecaseProvider = Provider<CancelUploadUsecase>(
  (ref) => CancelUploadUsecase(ref.watch(uploadRepositoryProvider)),
);

class CancelUploadUsecase {
  const CancelUploadUsecase(this._repository);

  final UploadRepository _repository;

  Future<void> call(String uploadId) => _repository.cancelUpload(uploadId);
}
