import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../models/track_model.dart';

class TrackCard extends StatelessWidget {
  const TrackCard({
    required this.track,
    super.key,
    this.onTap,
    this.onMorePressed,
    this.onFavoriteToggle,
    this.isFavorited = false,
    this.width = 150,
  });

  final TrackModel track;
  final VoidCallback? onTap;
  final VoidCallback? onMorePressed;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorited;
  final double width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: track.thumbnailUrl != null
                        ? CachedNetworkImage(
                            imageUrl: track.thumbnailUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _GradientPlaceholder(),
                            errorWidget: (_, __, ___) => _GradientPlaceholder(),
                          )
                        : _GradientPlaceholder(),
                  ),
                ),
                if (onFavoriteToggle != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _FavoriteButton(
                      isFavorited: isFavorited,
                      onPressed: onFavoriteToggle!,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.artist.name,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (track.isExplicit)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            'E',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          track.formattedDuration,
                          style: Theme.of(context).textTheme.labelSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (onMorePressed != null)
                        GestureDetector(
                          onTap: onMorePressed,
                          child: const Icon(
                            Icons.more_vert,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isFavorited, required this.onPressed});

  final bool isFavorited;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(120),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: isFavorited ? Colors.redAccent : AppColors.textPrimary,
          size: 18,
        ),
      ),
    );
  }
}

class _GradientPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.card, AppColors.surface],
        ),
      ),
      child: const Center(
        child: Icon(Icons.music_note_rounded, color: AppColors.textSecondary, size: 36),
      ),
    );
  }
}
