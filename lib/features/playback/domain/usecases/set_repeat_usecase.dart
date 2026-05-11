import '../repositories/playback_repository.dart';

class SetRepeatUsecase {
  const SetRepeatUsecase(this._repository);
  final PlaybackRepository _repository;
  Future<void> call(RepeatMode mode) => _repository.setRepeat(mode);
}
