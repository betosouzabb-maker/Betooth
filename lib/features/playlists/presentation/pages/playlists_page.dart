import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../shared/widgets/playlist_card.dart';
import '../controllers/playlists_controller.dart';
import '../widgets/create_playlist_dialog.dart';

class PlaylistsPage extends ConsumerStatefulWidget {
  const PlaylistsPage({super.key});

  @override
  ConsumerState<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends ConsumerState<PlaylistsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (ref.read(playlistsControllerProvider).hasMore) {
        ref.read(playlistsControllerProvider.notifier).load();
      }
    }
  }

  Future<void> _openCreateDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) => const CreatePlaylistDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playlistsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.background,
              pinned: true,
              title: Text('Playlists', style: Theme.of(context).textTheme.headlineSmall),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_rounded),
                  color: AppColors.primaryAccent,
                  onPressed: _openCreateDialog,
                  tooltip: 'Nova playlist',
                ),
              ],
            ),
            if (state.isLoading && state.items.isEmpty)
              const SliverFillRemaining(child: _SkeletonGrid())
            else if (state.errorMessage != null && state.items.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      Text(state.errorMessage!, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              )
            else if (state.items.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.queue_music_rounded, size: 64, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      Text('Nenhuma playlist ainda', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        'Toque em + para criar sua primeira playlist.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _openCreateDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Criar Playlist'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final playlist = state.items[index];
                      return PlaylistCard(
                        playlist: playlist,
                        onTap: () => context.push('/playlists/${playlist.id}'),
                        onMorePressed: () => _showPlaylistMenu(context, playlist.id),
                      )
                          .animate(delay: Duration(milliseconds: 50 * index))
                          .fadeIn(duration: 250.ms)
                          .scale(begin: const Offset(0.95, 0.95), duration: 250.ms);
                    },
                    childCount: state.items.length,
                  ),
                ),
              ),
              if (state.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryAccent,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
      floatingActionButton: state.items.isNotEmpty
          ? FloatingActionButton(
              onPressed: _openCreateDialog,
              backgroundColor: AppColors.primaryAccent,
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }

  void _showPlaylistMenu(BuildContext context, String playlistId) {
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
            leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
            title: const Text('Excluir playlist'),
            onTap: () {
              Navigator.pop(context);
              ref.read(playlistsControllerProvider.notifier).deletePlaylist(playlistId);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: 6,
      itemBuilder: (_, index) => Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
      )
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 1200.ms, color: AppColors.surface.withAlpha(180)),
    );
  }
}
