import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/audio_service_handler.dart';
import '../../data/repositories/playback_repository_impl.dart';
import '../../domain/entities/track_entity.dart';
import '../../domain/repositories/playback_repository.dart';
import '../../domain/usecases/pause_usecase.dart';
import '../../domain/usecases/play_track_usecase.dart';
import '../../domain/usecases/resume_usecase.dart';
import '../../domain/usecases/seek_usecase.dart';
import '../../domain/usecases/set_repeat_usecase.dart';
import '../../domain/usecases/set_shuffle_usecase.dart';
import '../../domain/usecases/skip_next_usecase.dart';
import '../../domain/usecases/skip_previous_usecase.dart';

// ── Usecase providers ────────────────────────────────────────────────────────

final _playbackRepoProvider = Provider<PlaybackRepository>(
  (ref) => ref.watch(playbackRepositoryImplProvider),
);

final _playTrackUsecaseProvider = Provider<PlayTrackUsecase>(
  (ref) => PlayTrackUsecase(ref.watch(_playbackRepoProvider)),
);

final _pauseUsecaseProvider = Provider<PauseUsecase>(
  (ref) => PauseUsecase(ref.watch(_playbackRepoProvider)),
);

final _resumeUsecaseProvider = Provider<ResumeUsecase>(
  (ref) => ResumeUsecase(ref.watch(_playbackRepoProvider)),
);

final _skipNextUsecaseProvider = Provider<SkipNextUsecase>(
  (ref) => SkipNextUsecase(ref.watch(_playbackRepoProvider)),
);

final _skipPreviousUsecaseProvider = Provider<SkipPreviousUsecase>(
  (ref) => SkipPreviousUsecase(ref.watch(_playbackRepoProvider)),
);

final _seekUsecaseProvider = Provider<SeekUsecase>(
  (ref) => SeekUsecase(ref.watch(_playbackRepoProvider)),
);

final _setShuffleUsecaseProvider = Provider<SetShuffleUsecase>(
  (ref) => SetShuffleUsecase(ref.watch(_playbackRepoProvider)),
);

final _setRepeatUsecaseProvider = Provider<SetRepeatUsecase>(
  (ref) => SetRepeatUsecase(ref.watch(_playbackRepoProvider)),
);

// ── Controller provider ───────────────────────────────────────────────────────

final playbackControllerProvider =
    StateNotifierProvider<PlaybackController, PlayerState>((ref) {
  return PlaybackController(
    audioHandler: ref.watch(audioHandlerProvider),
    playTrackUsecase: ref.watch(_playTrackUsecaseProvider),
    pauseUsecase: ref.watch(_pauseUsecaseProvider),
    resumeUsecase: ref.watch(_resumeUsecaseProvider),
    skipNextUsecase: ref.watch(_skipNextUsecaseProvider),
    skipPreviousUsecase: ref.watch(_skipPreviousUsecaseProvider),
    seekUsecase: ref.watch(_seekUsecaseProvider),
    setShuffleUsecase: ref.watch(_setShuffleUsecaseProvider),
    setRepeatUsecase: ref.watch(_setRepeatUsecaseProvider),
  );
});

// ── State ─────────────────────────────────────────────────────────────────────

class PlayerState {
  const PlayerState({
    this.currentTrack,
    this.queue = const <TrackEntity>[],
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isPlaying = false,
    this.isBuffering = false,
    this.isShuffleEnabled = false,
    this.repeatMode = RepeatMode.off,
    this.currentIndex = 0,
  });

  final TrackEntity? currentTrack;
  final List<TrackEntity> queue;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool isBuffering;
  final bool isShuffleEnabled;
  final RepeatMode repeatMode;
  final int currentIndex;

  PlayerState copyWith({
    TrackEntity? currentTrack,
    bool clearCurrentTrack = false,
    List<TrackEntity>? queue,
    Duration? position,
    Duration? duration,
    bool? isPlaying,
    bool? isBuffering,
    bool? isShuffleEnabled,
    RepeatMode? repeatMode,
    int? currentIndex,
  }) {
    return PlayerState(
      currentTrack:
          clearCurrentTrack ? null : (currentTrack ?? this.currentTrack),
      queue: queue ?? this.queue,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      isShuffleEnabled: isShuffleEnabled ?? this.isShuffleEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

// ── Controller ────────────────────────────────────────────────────────────────

class PlaybackController extends StateNotifier<PlayerState> {
  PlaybackController({
    required BetoothAudioHandler audioHandler,
    required PlayTrackUsecase playTrackUsecase,
    required PauseUsecase pauseUsecase,
    required ResumeUsecase resumeUsecase,
    required SkipNextUsecase skipNextUsecase,
    required SkipPreviousUsecase skipPreviousUsecase,
    required SeekUsecase seekUsecase,
    required SetShuffleUsecase setShuffleUsecase,
    required SetRepeatUsecase setRepeatUsecase,
  })  : _audioHandler = audioHandler,
        _playTrackUsecase = playTrackUsecase,
        _pauseUsecase = pauseUsecase,
        _resumeUsecase = resumeUsecase,
        _skipNextUsecase = skipNextUsecase,
        _skipPreviousUsecase = skipPreviousUsecase,
        _seekUsecase = seekUsecase,
        _setShuffleUsecase = setShuffleUsecase,
        _setRepeatUsecase = setRepeatUsecase,
        super(const PlayerState()) {
    _listen();
  }

  final BetoothAudioHandler _audioHandler;
  final PlayTrackUsecase _playTrackUsecase;
  final PauseUsecase _pauseUsecase;
  final ResumeUsecase _resumeUsecase;
  final SkipNextUsecase _skipNextUsecase;
  final SkipPreviousUsecase _skipPreviousUsecase;
  final SeekUsecase _seekUsecase;
  final SetShuffleUsecase _setShuffleUsecase;
  final SetRepeatUsecase _setRepeatUsecase;

  final List<StreamSubscription<dynamic>> _subs = [];

  void _listen() {
    _subs.add(
      _audioHandler.player.positionStream.listen((p) {
        if (mounted) state = state.copyWith(position: p);
      }),
    );

    _subs.add(
      _audioHandler.player.durationStream.listen((d) {
        if (mounted) state = state.copyWith(duration: d ?? Duration.zero);
      }),
    );

    _subs.add(
      _audioHandler.playbackState.listen((s) {
        if (!mounted) return;
        state = state.copyWith(
          isPlaying: s.playing,
          isBuffering: s.processingState == AudioProcessingState.loading ||
              s.processingState == AudioProcessingState.buffering,
        );
      }),
    );

    _subs.add(
      _audioHandler.mediaItem.listen((item) {
        if (!mounted || item == null) return;
        final track = TrackEntity.fromMediaItem(item);
        final idx = _audioHandler.queue.value.indexOf(item);
        state = state.copyWith(
          currentTrack: track,
          currentIndex: idx >= 0 ? idx : 0,
        );
      }),
    );

    _subs.add(
      _audioHandler.queue.listen((items) {
        if (!mounted) return;
        state = state.copyWith(
          queue: items.map(TrackEntity.fromMediaItem).toList(),
        );
      }),
    );

    _subs.add(
      _audioHandler.player.shuffleModeEnabledStream.listen((enabled) {
        if (mounted) state = state.copyWith(isShuffleEnabled: enabled);
      }),
    );

    _subs.add(
      _audioHandler.player.loopModeStream.listen((mode) {
        if (!mounted) return;
        state = state.copyWith(
          repeatMode: switch (mode) {
            LoopMode.off => RepeatMode.off,
            LoopMode.one => RepeatMode.one,
            LoopMode.all => RepeatMode.all,
          },
        );
      }),
    );
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  Future<void> playTrack(TrackEntity track) => _playTrackUsecase(track);

  Future<void> playQueue(List<TrackEntity> tracks, int startIndex) async {
    final items = tracks.map((t) => t.toMediaItem()).toList();
    await _audioHandler.loadQueue(items, startIndex);
  }

  Future<void> pause() => _pauseUsecase();
  Future<void> resume() => _resumeUsecase();
  Future<void> skipNext() => _skipNextUsecase();
  Future<void> skipPrevious() => _skipPreviousUsecase();
  Future<void> seek(Duration position) => _seekUsecase(position);
  Future<void> setShuffle(bool enabled) => _setShuffleUsecase(enabled);
  Future<void> setRepeat(RepeatMode mode) => _setRepeatUsecase(mode);

  void togglePlayPause() {
    if (state.isPlaying) {
      _pauseUsecase();
    } else {
      _resumeUsecase();
    }
  }

  void cycleRepeat() {
    final next = switch (state.repeatMode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };
    setRepeat(next);
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
