import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../shared/widgets/track_list_tile.dart';
import '../controllers/favorites_controller.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
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
      ref.read(favoritesControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(favoritesControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.background,
              pinned: true,
              title: Text('Favoritos', style: Theme.of(context).textTheme.headlineSmall),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  color: AppColors.textSecondary,
                  onPressed: () =>
                      ref.read(favoritesControllerProvider.notifier).refresh(),
                ),
              ],
            ),
            if (state.isLoading && state.items.isEmpty)
              const SliverFillRemaining(child: _SkeletonList())
            else if (state.errorMessage != null && state.items.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      Text(state.errorMessage!, style: Theme.of(context).textTheme.bodyMedium),
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
                      const Icon(Icons.favorite_outline, size: 64, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      Text('Nenhum favorito ainda', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        'Toque no coração de uma música para favoritá-la.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == state.items.length) {
                      return state.isLoadingMore
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryAccent,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : const SizedBox.shrink();
                    }
                    final item = state.items[index];
                    return TrackListTile(
                      track: item.track,
                      trailing: _HeartButton(
                        trackId: item.track.id,
                        isFavorited: state.isFavorited(item.track.id),
                        isPending: state.isPending(item.track.id),
                        onToggle: () => ref
                            .read(favoritesControllerProvider.notifier)
                            .toggleFavorite(item.track.id),
                      ),
                    )
                        .animate(delay: Duration(milliseconds: 30 * index))
                        .fadeIn(duration: 250.ms)
                        .slideX(begin: 0.05, duration: 250.ms);
                  },
                  childCount: state.items.length + 1,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeartButton extends StatelessWidget {
  const _HeartButton({
    required this.trackId,
    required this.isFavorited,
    required this.isPending,
    required this.onToggle,
  });

  final String trackId;
  final bool isFavorited;
  final bool isPending;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    if (isPending) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryAccent),
      );
    }
    return IconButton(
      icon: Icon(
        isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: isFavorited ? Colors.redAccent : AppColors.textSecondary,
      ),
      onPressed: onToggle,
    )
        .animate(key: ValueKey('heart_$trackId$isFavorited'))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.3, 1.3),
          duration: 150.ms,
        )
        .then()
        .scale(
          begin: const Offset(1.3, 1.3),
          end: const Offset(1, 1),
          duration: 100.ms,
        );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 8,
      itemBuilder: (_, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 6),
                  Container(height: 12, width: 100, decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
          ],
        ),
      )
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 1200.ms, color: AppColors.surface.withAlpha(180)),
    );
  }
}
