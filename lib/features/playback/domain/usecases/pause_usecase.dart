import '../repositories/playback_repository.dart';

class PauseUsecase {
  const PauseUsecase(this._repository);
  final PlaybackRepository _repository;
  Future<void> call() => _repository.pause();
}
