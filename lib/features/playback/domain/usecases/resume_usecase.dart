import '../repositories/playback_repository.dart';

class ResumeUsecase {
  const ResumeUsecase(this._repository);
  final PlaybackRepository _repository;
  Future<void> call() => _repository.resume();
}
