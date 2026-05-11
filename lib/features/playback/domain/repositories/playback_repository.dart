import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entities/track_entity.dart';

enum RepeatMode { off, one, all }

abstract class PlaybackRepository {
  Future<void> playTrack(TrackEntity track);
  Future<void> playQueue(List<TrackEntity> tracks, int startIndex);
  Future<void> pause();
  Future<void> resume();
  Future<void> skipToNext();
  Future<void> skipToPrevious();
  Future<void> seek(Duration position);
  Future<void> setShuffle(bool enabled);
  Future<void> setRepeat(RepeatMode mode);
}

// Keep provider here so usecases can watch it
final playbackRepositoryProvider = Provider<PlaybackRepository>((ref) {
  throw UnimplementedError('playbackRepositoryProvider must be overridden');
});
