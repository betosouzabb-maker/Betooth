import '../repositories/playback_repository.dart';

class SeekUsecase {
  const SeekUsecase(this._repository);
  final PlaybackRepository _repository;
  Future<void> call(Duration position) => _repository.seek(position);
}
