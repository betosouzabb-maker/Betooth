import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio_service_handler.dart';
import '../../data/datasources/audio_file_manager.dart';
import '../../data/datasources/playback_local_datasource.dart';
import '../../domain/entities/track_entity.dart';
import '../../domain/repositories/playback_repository.dart';

final playbackRepositoryImplProvider = Provider<PlaybackRepository>((ref) {
  return PlaybackRepositoryImpl(
    audioHandler: ref.watch(audioHandlerProvider),
    localDatasource: ref.watch(playbackLocalDatasourceProvider),
  );
});

class PlaybackRepositoryImpl implements PlaybackRepository {
  PlaybackRepositoryImpl({
    required BetoothAudioHandler audioHandler,
    required PlaybackLocalDatasource localDatasource,
  })  : _handler = audioHandler,
        _localDatasource = localDatasource;

  final BetoothAudioHandler _handler;
  final PlaybackLocalDatasource _localDatasource;

  @override
  Future<void> playTrack(TrackEntity track) async {
    TrackEntity resolved = track;
    if (!track.isDownloaded) {
      final localPath = await _localDatasource.getLocalPath(track.id);
      if (localPath != null) {
        final valid = await AudioFileManager.checkIntegrity(localPath);
        if (valid) {
          resolved = track.copyWith(localPath: localPath, isDownloaded: true);
        }
      }
    }
    await _handler.loadQueue([resolved.toMediaItem()], 0);
  }

  @override
  Future<void> playQueue(List<TrackEntity> tracks, int startIndex) async {
    final items = tracks.map((t) => t.toMediaItem()).toList();
    await _handler.loadQueue(
      items,
      startIndex.clamp(0, items.length - 1),
    );
  }

  @override
  Future<void> pause() => _handler.pause();

  @override
  Future<void> resume() => _handler.play();

  @override
  Future<void> skipToNext() => _handler.skipToNext();

  @override
  Future<void> skipToPrevious() => _handler.skipToPrevious();

  @override
  Future<void> seek(Duration position) => _handler.seek(position);

  @override
  Future<void> setShuffle(bool enabled) => _handler.setShuffleMode(
        enabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
      );

  @override
  Future<void> setRepeat(RepeatMode mode) {
    final audioMode = switch (mode) {
      RepeatMode.off => AudioServiceRepeatMode.none,
      RepeatMode.one => AudioServiceRepeatMode.one,
      RepeatMode.all => AudioServiceRepeatMode.all,
    };
    return _handler.setRepeatMode(audioMode);
  }
}
