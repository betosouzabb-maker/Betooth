import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../shared/models/playlist_model.dart';
import '../../../../shared/widgets/track_list_tile.dart';
import '../controllers/playlists_controller.dart';

class PlaylistDetailPage extends ConsumerWidget {
  const PlaylistDetailPage({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playlistDetailControllerProvider(id));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background,
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: state.detail != null
                  ? Text(
                      state.detail!.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    )
                  : null,
              background: state.detail?.coverUrl != null
                  ? Image.network(state.detail!.coverUrl!, fit: BoxFit.cover)
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF2A1A5E), AppColors.background],
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.queue_music_rounded, size: 64, color: AppColors.textSecondary),
                      ),
                    ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => ref.read(playlistDetailControllerProvider(id).notifier).refresh(),
              ),
            ],
          ),
          if (state.isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primaryAccent, strokeWidth: 2),
              ),
            )
          else if (state.errorMessage != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    Text(state.errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () =>
                          ref.read(playlistDetailControllerProvider(id).notifier).refresh(),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            )
          else if (state.detail == null || state.detail!.items.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.music_off_rounded, size: 64, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    Text('Playlist vazia', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Adicione músicas para preencher esta playlist.',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            _PlaylistItems(
              items: state.detail!.items,
              playlistId: id,
              isRemoving: state.isRemoving,
            ),
        ],
      ),
    );
  }
}

class _PlaylistItems extends ConsumerWidget {
  const _PlaylistItems({
    required this.items,
    required this.playlistId,
    required this.isRemoving,
  });

  final List<PlaylistItemModel> items;
  final String playlistId;
  final bool isRemoving;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Text(
                    '${items.length} músicas',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  if (isRemoving)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryAccent),
                    ),
                ],
              ),
            );
          }
          final item = items[index - 1];
          return Dismissible(
            key: ValueKey(item.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.redAccent.withAlpha(40),
              child: const Icon(Icons.delete_outline, color: Colors.redAccent),
            ),
            onDismissed: (_) {
              ref.read(playlistDetailControllerProvider(playlistId).notifier).removeItem(item.id);
            },
            child: TrackListTile(
              track: item.track,
              showIndex: index,
              onMorePressed: () => _showItemMenu(context, ref, item.id),
            )
                .animate(delay: Duration(milliseconds: 30 * index))
                .fadeIn(duration: 200.ms)
                .slideX(begin: 0.05, duration: 200.ms),
          );
        },
        childCount: items.length + 1,
      ),
    );
  }

  void _showItemMenu(BuildContext context, WidgetRef ref, String itemId) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
            title: const Text('Remover da playlist'),
            onTap: () {
              Navigator.pop(context);
              ref.read(playlistDetailControllerProvider(playlistId).notifier).removeItem(itemId);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
