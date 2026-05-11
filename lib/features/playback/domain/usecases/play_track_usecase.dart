import '../entities/track_entity.dart';
import '../repositories/playback_repository.dart';

class PlayTrackUsecase {
  const PlayTrackUsecase(this._repository);
  final PlaybackRepository _repository;
  Future<void> call(TrackEntity track) => _repository.playTrack(track);
}
