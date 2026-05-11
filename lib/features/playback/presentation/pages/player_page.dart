import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../domain/repositories/playback_repository.dart';
import '../controllers/playback_controller.dart';

class PlayerPage extends ConsumerWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playbackControllerProvider);
    final ctrl = ref.read(playbackControllerProvider.notifier);

    final coverUrl = state.currentTrack?.coverUrl;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Blurred album art background ──────────────────────────────────
          if (coverUrl != null)
            CachedNetworkImage(
              imageUrl: coverUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorWidget: (_, __, ___) =>
                  const ColoredBox(color: AppColors.background),
            )
          else
            const ColoredBox(color: AppColors.background),

          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
            child: Container(
              color: AppColors.background.withValues(alpha: 0.72),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  _Header(),
                  const SizedBox(height: 24),
                  _AlbumArt(coverUrl: coverUrl),
                  const SizedBox(height: 28),
                  _TrackInfo(state: state),
                  const SizedBox(height: 20),
                  _ProgressBar(state: state, ctrl: ctrl),
                  const SizedBox(height: 8),
                  _Controls(state: state, ctrl: ctrl),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textPrimary,
            size: 32,
          ),
        ),
        const Expanded(
          child: Text(
            'Tocando agora',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

class _AlbumArt extends StatelessWidget {
  const _AlbumArt({this.coverUrl});
  final String? coverUrl;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: coverUrl != null
            ? CachedNetworkImage(
                imageUrl: coverUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _PlaceholderArt(),
              )
            : _PlaceholderArt(),
      ),
    );
  }
}

class _PlaceholderArt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.card,
      child: const Center(
        child: Icon(
          Icons.album_rounded,
          size: 80,
          color: AppColors.primaryAccent,
        ),
      ),
    );
  }
}

class _TrackInfo extends StatelessWidget {
  const _TrackInfo({required this.state});
  final PlayerState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          state.currentTrack?.title ?? 'Nenhuma faixa',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          state.currentTrack?.artist ?? '—',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.state, required this.ctrl});
  final PlayerState state;
  final PlaybackController ctrl;

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final maxMs = state.duration.inMilliseconds.toDouble();
    final posMs = state.position.inMilliseconds
        .toDouble()
        .clamp(0.0, maxMs > 0 ? maxMs : 1.0);

    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: AppColors.primaryAccent,
            inactiveTrackColor: AppColors.card,
            thumbColor: AppColors.textPrimary,
            overlayColor: AppColors.primaryAccent.withValues(alpha: 0.24),
          ),
          child: Slider(
            value: posMs,
            max: maxMs > 0 ? maxMs : 1.0,
            onChanged: (v) => ctrl.seek(Duration(milliseconds: v.toInt())),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _fmt(state.position),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                _fmt(state.duration),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.state, required this.ctrl});
  final PlayerState state;
  final PlaybackController ctrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Shuffle
        IconButton(
          onPressed: () => ctrl.setShuffle(!state.isShuffleEnabled),
          icon: Icon(
            Icons.shuffle_rounded,
            size: 22,
            color: state.isShuffleEnabled
                ? AppColors.primaryAccent
                : AppColors.textSecondary,
          ),
        ),

        // Previous
        IconButton(
          onPressed: ctrl.skipPrevious,
          icon: const Icon(
            Icons.skip_previous_rounded,
            size: 36,
            color: AppColors.textPrimary,
          ),
        ),

        // Play / Pause
        GestureDetector(
          onTap: ctrl.togglePlayPause,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.primaryAccent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryAccent.withValues(alpha: 0.40),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: state.isBuffering
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.textPrimary,
                        ),
                      )
                    : Icon(
                        state.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        key: ValueKey(state.isPlaying),
                        size: 38,
                        color: AppColors.textPrimary,
                      ),
              ),
            ),
          ),
        ),

        // Next
        IconButton(
          onPressed: ctrl.skipNext,
          icon: const Icon(
            Icons.skip_next_rounded,
            size: 36,
            color: AppColors.textPrimary,
          ),
        ),

        // Repeat
        IconButton(
          onPressed: ctrl.cycleRepeat,
          icon: Icon(
            state.repeatMode == RepeatMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            size: 22,
            color: state.repeatMode != RepeatMode.off
                ? AppColors.primaryAccent
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
