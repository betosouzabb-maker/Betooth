import '../repositories/playback_repository.dart';

class SkipPreviousUsecase {
  const SkipPreviousUsecase(this._repository);
  final PlaybackRepository _repository;
  Future<void> call() => _repository.skipToPrevious();
}
