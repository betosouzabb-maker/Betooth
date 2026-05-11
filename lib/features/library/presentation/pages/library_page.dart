import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../shared/widgets/track_list_tile.dart';
import '../controllers/library_controller.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  final _scrollController = ScrollController();

  static const _filters = [
    ('all', 'Todos'),
    ('favorites', 'Favoritos'),
    ('recent', 'Recentes'),
  ];

  static const _sorts = [
    ('recent', 'Recentes'),
    ('title', 'Título'),
    ('artist', 'Artista'),
  ];

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
      ref.read(libraryControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.background,
              pinned: true,
              title: Text(
                'Biblioteca',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(88),
                child: Column(
                  children: [
                    _FilterChips(
                      filters: _filters,
                      active: state.activeFilter,
                      onSelected: (f) =>
                          ref.read(libraryControllerProvider.notifier).setFilter(f),
                    ),
                    _SortRow(
                      sorts: _sorts,
                      active: state.activeSort,
                      onSelected: (s) =>
                          ref.read(libraryControllerProvider.notifier).setSort(s),
                    ),
                  ],
                ),
              ),
            ),
            if (state.isLoading && state.items.isEmpty)
              const SliverFillRemaining(child: _SkeletonList())
            else if (state.errorMessage != null && state.items.isEmpty)
              SliverFillRemaining(child: _ErrorView(message: state.errorMessage!))
            else if (state.items.isEmpty)
              const SliverFillRemaining(child: _EmptyView())
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
                      onMorePressed: () => _showTrackMenu(context, item.track.id),
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

  void _showTrackMenu(BuildContext context, String trackId) {
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
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
            title: const Text('Remover da biblioteca'),
            onTap: () {
              Navigator.pop(context);
              ref.read(libraryControllerProvider.notifier).removeTrack(trackId);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.filters,
    required this.active,
    required this.onSelected,
  });

  final List<(String, String)> filters;
  final String active;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (value, label) = filters[index];
          final isActive = active == value;
          return FilterChip(
            label: Text(label),
            selected: isActive,
            onSelected: (_) => onSelected(value),
            backgroundColor: AppColors.card,
            selectedColor: AppColors.primaryAccent,
            labelStyle: TextStyle(
              color: isActive ? Colors.white : AppColors.textSecondary,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          );
        },
      ),
    );
  }
}

class _SortRow extends StatelessWidget {
  const _SortRow({
    required this.sorts,
    required this.active,
    required this.onSelected,
  });

  final List<(String, String)> sorts;
  final String active;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text('Ordenar:', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(width: 8),
          ...sorts.map((sort) {
            final (value, label) = sort;
            final isActive = active == value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSelected(value),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isActive ? AppColors.primaryAccent : AppColors.textSecondary,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      ),
                ),
              ),
            );
          }),
        ],
      ),
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
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 12,
                    width: 120,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
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

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.library_music_outlined, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text('Biblioteca vazia', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Adicione músicas à sua biblioteca para vê-las aqui.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(message, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
