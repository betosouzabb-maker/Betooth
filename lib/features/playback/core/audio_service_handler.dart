import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

final audioHandlerProvider = Provider<BetoothAudioHandler>((ref) {
  throw UnimplementedError(
    'audioHandlerProvider must be overridden in main.dart via ProviderScope overrides.',
  );
});

class BetoothAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  BetoothAudioHandler() {
    _init();
  }

  AudioPlayer get player => _player;

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    _player.playbackEventStream.listen(
      _broadcastState,
      onError: (Object e, StackTrace st) {},
    );

    _player.currentIndexStream.listen((index) {
      final items = queue.value;
      if (index != null && index < items.length) {
        mediaItem.add(items[index]);
      }
    });

    _player.processingStateStream.listen((state) async {
      if (state == ProcessingState.completed) {
        final idx = _player.currentIndex ?? 0;
        final total = queue.value.length;
        if (idx < total - 1) {
          await skipToNext();
        } else if (_player.loopMode == LoopMode.all && total > 0) {
          await _player.seek(Duration.zero, index: 0);
          await _player.play();
        }
      }
    });
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    final idx = _player.currentIndex ?? 0;
    final total = queue.value.length;
    if (idx < total - 1) {
      await _player.seek(Duration.zero, index: idx + 1);
      if (!_player.playing) await _player.play();
    } else if (_player.loopMode == LoopMode.all && total > 0) {
      await _player.seek(Duration.zero, index: 0);
      if (!_player.playing) await _player.play();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    final idx = _player.currentIndex ?? 0;
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else if (idx > 0) {
      await _player.seek(Duration.zero, index: idx - 1);
      if (!_player.playing) await _player.play();
    } else {
      await _player.seek(Duration.zero);
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    await _player.seek(Duration.zero, index: index);
    await _player.play();
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(LoopMode.off);
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        await _player.setLoopMode(LoopMode.all);
    }
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await _player.setShuffleModeEnabled(
      shuffleMode != AudioServiceShuffleMode.none,
    );
    playbackState.add(playbackState.value.copyWith(shuffleMode: shuffleMode));
  }

  Future<void> loadQueue(List<MediaItem> items, int initialIndex) async {
    if (items.isEmpty) return;
    queue.add(items);
    mediaItem.add(items[initialIndex.clamp(0, items.length - 1)]);

    final sources = items.map(_toAudioSource).toList();
    await _player.setAudioSources(
      sources,
      initialIndex: initialIndex.clamp(0, items.length - 1),
      initialPosition: Duration.zero,
    );
    await _player.play();
  }

  AudioSource _toAudioSource(MediaItem item) {
    final localPath = item.extras?['localPath'] as String?;
    final streamUrl = item.extras?['streamUrl'] as String?;

    if (localPath != null && localPath.isNotEmpty) {
      return AudioSource.uri(Uri.file(localPath), tag: item);
    }
    if (streamUrl != null && streamUrl.isNotEmpty) {
      return AudioSource.uri(Uri.parse(streamUrl), tag: item);
    }
    return AudioSource.uri(Uri.parse(''), tag: item);
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ),
    );
  }

  @override
  Future<void> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {
    if (name == 'dispose') {
      await _player.dispose();
      super.stop();
    }
  }
}
