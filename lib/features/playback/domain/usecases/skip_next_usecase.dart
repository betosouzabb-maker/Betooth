import '../repositories/playback_repository.dart';

class SkipNextUsecase {
  const SkipNextUsecase(this._repository);
  final PlaybackRepository _repository;
  Future<void> call() => _repository.skipToNext();
}
