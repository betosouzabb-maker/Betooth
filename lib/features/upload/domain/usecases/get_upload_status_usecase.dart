import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entities/upload_entity.dart';
import '../repositories/upload_repository.dart';
import '../../data/repositories/upload_repository_impl.dart';

final getUploadStatusUsecaseProvider = Provider<GetUploadStatusUsecase>(
  (ref) => GetUploadStatusUsecase(ref.watch(uploadRepositoryProvider)),
);

class GetUploadStatusUsecase {
  const GetUploadStatusUsecase(this._repository);

  final UploadRepository _repository;

  Future<UploadEntity> call(String uploadId) =>
      _repository.getUploadStatus(uploadId);
}
