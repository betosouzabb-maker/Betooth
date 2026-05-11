import '../repositories/playback_repository.dart';

class SetShuffleUsecase {
  const SetShuffleUsecase(this._repository);
  final PlaybackRepository _repository;
  Future<void> call(bool enabled) => _repository.setShuffle(enabled);
}
