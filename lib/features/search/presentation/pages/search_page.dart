import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../shared/widgets/track_list_tile.dart';
import '../../../../shared/models/playlist_model.dart';
import '../../data/datasources/search_remote_datasource.dart';
import '../controllers/search_controller.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _focusNode = FocusNode();
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider);
    final controller = ref.read(searchControllerProvider.notifier);

    // Sync text controller with state
    if (_textController.text != state.query) {
      _textController.value = TextEditingValue(
        text: state.query,
        selection: TextSelection.collapsed(offset: state.query.length),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        onChanged: controller.onQueryChanged,
                        onSubmitted: controller.search,
                        style: Theme.of(context).textTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Músicas, artistas, álbuns...',
                          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                          suffixIcon: state.query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary),
                                  onPressed: () {
                                    _textController.clear();
                                    controller.clear();
                                    _focusNode.unfocus();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filter chips (shown when query is not empty)
            if (state.query.isNotEmpty)
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    ('all', 'Tudo'),
                    ('track', 'Músicas'),
                    ('artist', 'Artistas'),
                    ('album', 'Álbuns'),
                    ('playlist', 'Playlists'),
                  ].map((item) {
                    final (value, label) = item;
                    final isActive = value == 'all'
                        ? state.activeType == null
                        : state.activeType == value;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(label),
                        selected: isActive,
                        onSelected: (_) => controller.setFilter(value == 'all' ? null : value),
                        backgroundColor: AppColors.card,
                        selectedColor: AppColors.primaryAccent,
                        labelStyle: TextStyle(
                          color: isActive ? Colors.white : AppColors.textSecondary,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        ),
                        side: BorderSide.none,
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 4),

            // Main content area
            Expanded(
              child: _buildContent(context, state, controller),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    SearchState state,
    SearchController controller,
  ) {
    // Loading state
    if (state.isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryAccent, strokeWidth: 2),
      );
    }

    // Suggestions dropdown (query but not searched yet)
    if (state.query.isNotEmpty && !state.hasSearched && state.suggestions.isNotEmpty) {
      return _SuggestionsList(
        suggestions: state.suggestions,
        onSelect: (q) {
          _textController.text = q;
          controller.search(q);
          _focusNode.unfocus();
        },
      );
    }

    // Search results
    if (state.hasSearched && state.results != null) {
      if (state.results!.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off_rounded, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'Nenhum resultado para "${state.query}"',
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tente termos diferentes.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      }
      return _SearchResults(results: state.results!);
    }

    // Empty query: show history
    return _SearchHistory(
      history: state.history,
      isLoading: state.isLoadingHistory,
      onSelect: (q) {
        _textController.text = q;
        _textController.selection = TextSelection.collapsed(offset: q.length);
        controller.selectHistoryItem(q);
        _focusNode.unfocus();
      },
      onClear: controller.clearHistory,
    );
  }
}

class _SuggestionsList extends StatelessWidget {
  const _SuggestionsList({required this.suggestions, required this.onSelect});

  final List<String> suggestions;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return ListTile(
          leading: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 18),
          title: Text(suggestion, style: Theme.of(context).textTheme.bodyMedium),
          onTap: () => onSelect(suggestion),
        )
            .animate(delay: Duration(milliseconds: 30 * index))
            .fadeIn(duration: 150.ms);
      },
    );
  }
}

class _SearchHistory extends StatelessWidget {
  const _SearchHistory({
    required this.history,
    required this.isLoading,
    required this.onSelect,
    required this.onClear,
  });

  final List<SearchHistoryItem> history;
  final bool isLoading;
  final ValueChanged<String> onSelect;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent, strokeWidth: 2));
    }

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.manage_search_rounded, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text('Busque por músicas', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Artistas, álbuns e playlists também.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text('Buscas recentes', style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              TextButton(
                onPressed: onClear,
                child: Text(
                  'Limpar',
                  style: TextStyle(color: AppColors.primaryAccent, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return ListTile(
                leading: const Icon(Icons.history_rounded, color: AppColors.textSecondary, size: 18),
                title: Text(item.query, style: Theme.of(context).textTheme.bodyMedium),
                onTap: () => onSelect(item.query),
              )
                  .animate(delay: Duration(milliseconds: 30 * index))
                  .fadeIn(duration: 150.ms);
            },
          ),
        ),
      ],
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.results});

  final SearchResults results;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        if (results.tracks.isNotEmpty) ...[
          _SectionHeader(title: 'Músicas (${results.tracks.length})'),
          ...results.tracks.asMap().entries.map(
                (entry) => TrackListTile(
                  track: entry.value,
                )
                    .animate(delay: Duration(milliseconds: 30 * entry.key))
                    .fadeIn(duration: 200.ms),
              ),
        ],
        if (results.artists.isNotEmpty) ...[
          _SectionHeader(title: 'Artistas (${results.artists.length})'),
          ...results.artists.asMap().entries.map(
                (entry) => _ArtistTile(artist: entry.value)
                    .animate(delay: Duration(milliseconds: 30 * entry.key))
                    .fadeIn(duration: 200.ms),
              ),
        ],
        if (results.albums.isNotEmpty) ...[
          _SectionHeader(title: 'Álbuns (${results.albums.length})'),
          ...results.albums.asMap().entries.map(
                (entry) => _AlbumTile(album: entry.value)
                    .animate(delay: Duration(milliseconds: 30 * entry.key))
                    .fadeIn(duration: 200.ms),
              ),
        ],
        if (results.playlists.isNotEmpty) ...[
          _SectionHeader(title: 'Playlists (${results.playlists.length})'),
          ...results.playlists.asMap().entries.map(
                (entry) => _PlaylistTile(
                  playlist: entry.value,
                  onTap: (id) {},
                )
                    .animate(delay: Duration(milliseconds: 30 * entry.key))
                    .fadeIn(duration: 200.ms),
              ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _ArtistTile extends StatelessWidget {
  const _ArtistTile({required this.artist});

  final SearchArtistResult artist;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.card,
        backgroundImage: artist.imageUrl != null
            ? CachedNetworkImageProvider(artist.imageUrl!)
            : null,
        child: artist.imageUrl == null
            ? const Icon(Icons.person_rounded, color: AppColors.textSecondary)
            : null,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(artist.name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          ),
          if (artist.isVerified) ...[
            const SizedBox(width: 4),
            const Icon(Icons.verified_rounded, size: 14, color: AppColors.primaryAccent),
          ],
        ],
      ),
      subtitle: Text(artist.artistType, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _AlbumTile extends StatelessWidget {
  const _AlbumTile({required this.album});

  final SearchAlbumResult album;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 48,
          height: 48,
          child: album.coverUrl != null
              ? CachedNetworkImage(imageUrl: album.coverUrl!, fit: BoxFit.cover)
              : Container(
                  color: AppColors.card,
                  child: const Icon(Icons.album_rounded, color: AppColors.textSecondary),
                ),
        ),
      ),
      title: Text(album.title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(album.artist.name, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  const _PlaylistTile({required this.playlist, required this.onTap});

  final PlaylistModel playlist;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 48,
          height: 48,
          child: playlist.coverUrl != null
              ? CachedNetworkImage(imageUrl: playlist.coverUrl!, fit: BoxFit.cover)
              : Container(
                  color: AppColors.card,
                  child: const Icon(Icons.queue_music_rounded, color: AppColors.textSecondary),
                ),
        ),
      ),
      title: Text(playlist.title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${playlist.itemCount} músicas', style: Theme.of(context).textTheme.bodySmall),
      onTap: () => onTap(playlist.id),
    );
  }
}
