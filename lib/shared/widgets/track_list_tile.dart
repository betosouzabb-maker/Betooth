import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../models/track_model.dart';

class TrackListTile extends StatelessWidget {
  const TrackListTile({
    required this.track,
    super.key,
    this.onTap,
    this.onMorePressed,
    this.trailing,
    this.showIndex,
  });

  final TrackModel track;
  final VoidCallback? onTap;
  final VoidCallback? onMorePressed;
  final Widget? trailing;
  final int? showIndex;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            if (showIndex != null)
              SizedBox(
                width: 28,
                child: Text(
                  '$showIndex',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            _TrackThumbnail(url: track.thumbnailUrl, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (track.isExplicit) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            'E',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          track.artist.name,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else ...[
              Text(
                track.formattedDuration,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (onMorePressed != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 18),
                  color: AppColors.textSecondary,
                  onPressed: onMorePressed,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _TrackThumbnail extends StatelessWidget {
  const _TrackThumbnail({this.url, required this.size});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: size,
        height: size,
        child: url != null
            ? CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                placeholder: (_, __) => _GradientPlaceholder(size: size),
                errorWidget: (_, __, ___) => _GradientPlaceholder(size: size),
              )
            : _GradientPlaceholder(size: size),
      ),
    );
  }
}

class _GradientPlaceholder extends StatelessWidget {
  const _GradientPlaceholder({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.card, AppColors.surface],
        ),
      ),
      child: const Icon(Icons.music_note_rounded, color: AppColors.textSecondary, size: 20),
    );
  }
}
