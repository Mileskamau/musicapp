import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart' hide SongModel;
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/song_model.dart';
import '../../../core/providers/music_provider.dart';
import '../../../core/services/audio_service.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final filteredSongs = ref.watch(filteredSongsProvider);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Search',
                style: AppTheme.headlineMedium.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ).animate().fadeIn(duration: AppConstants.normalAnimation),
              titlePadding: const EdgeInsets.only(
                left: AppConstants.spacingL,
                bottom: AppConstants.spacingM,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: _buildSearchBar(),
            ),
          ),

          if (searchQuery.isEmpty)
            _buildBrowseCategories()
          else
            _buildSearchResults(filteredSongs),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          ref.read(searchQueryProvider.notifier).state = value;
        },
        style: AppTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Search songs, artists, albums...',
          hintStyle: AppTheme.bodyMedium,
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppTheme.textSecondary,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear_rounded,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(searchQueryProvider.notifier).state = '';
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingL,
            vertical: AppConstants.spacingM,
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildBrowseCategories() {
    final categories = [
      {'name': 'Pop', 'color': AppTheme.primaryColor, 'icon': Icons.music_note_rounded},
      {'name': 'Rock', 'color': AppTheme.errorColor, 'icon': Icons.music_note_rounded},
      {'name': 'Hip Hop', 'color': AppTheme.warningColor, 'icon': Icons.music_note_rounded},
      {'name': 'Electronic', 'color': AppTheme.accentColor, 'icon': Icons.music_note_rounded},
      {'name': 'Jazz', 'color': AppTheme.successColor, 'icon': Icons.music_note_rounded},
      {'name': 'Classical', 'color': AppTheme.primaryColor, 'icon': Icons.music_note_rounded},
      {'name': 'R&B', 'color': AppTheme.errorColor, 'icon': Icons.music_note_rounded},
      {'name': 'Country', 'color': AppTheme.warningColor, 'icon': Icons.music_note_rounded},
      {'name': 'Metal', 'color': AppTheme.accentColor, 'icon': Icons.music_note_rounded},
      {'name': 'Indie', 'color': AppTheme.successColor, 'icon': Icons.music_note_rounded},
      {'name': 'Podcasts', 'color': AppTheme.primaryColor, 'icon': Icons.podcasts_rounded},
      {'name': 'Live', 'color': AppTheme.errorColor, 'icon': Icons.live_tv_rounded},
    ];

    return SliverPadding(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppConstants.spacingM,
          crossAxisSpacing: AppConstants.spacingM,
          childAspectRatio: 1.5,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final category = categories[index];
            return _buildCategoryCard(
              category['name'] as String,
              category['color'] as Color,
              category['icon'] as IconData,
              index,
            );
          },
          childCount: categories.length,
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String name, Color color, IconData icon, int index) {
    return GestureDetector(
      onTap: () {
        _searchController.text = name;
        ref.read(searchQueryProvider.notifier).state = name;
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.3),
              color.withOpacity(0.1),
            ],
          ),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: AppConstants.spacingM,
              left: AppConstants.spacingM,
              child: Text(
                name,
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Positioned(
              bottom: -10,
              right: -10,
              child: Transform.rotate(
                angle: 0.3,
                child: Icon(
                  icon,
                  size: 80,
                  color: color.withOpacity(0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (300 + index * 50).ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildSearchResults(AsyncValue<List<SongModel>> songsAsync) {
    return songsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppConstants.spacingXXL),
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          ),
        ),
      ),
      error: (error, _) => SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingXXL),
            child: Text('Error searching songs', style: AppTheme.bodyMedium),
          ),
        ),
      ),
      data: (songs) {
        if (songs.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingXXL),
                child: Column(
                  children: [
                    const Icon(Icons.search_off_rounded, color: AppTheme.textSecondary, size: 64),
                    const SizedBox(height: AppConstants.spacingM),
                    Text('No results found', style: AppTheme.titleMedium),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final song = songs[index];
              return _buildSearchResultTile(song, index);
            },
            childCount: songs.length,
          ),
        );
      },
    );
  }

  Widget _buildSearchResultTile(SongModel song, int index) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingL,
        vertical: AppConstants.spacingS,
      ),
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          color: AppTheme.cardColor,
        ),
        child: QueryArtworkWidget(
          id: int.tryParse(song.id) ?? 0,
          type: ArtworkType.AUDIO,
          nullArtworkWidget: const Icon(
            Icons.music_note_rounded,
            color: AppTheme.textSecondary,
          ),
          artworkBorder: BorderRadius.circular(AppConstants.borderRadius),
          artworkFit: BoxFit.cover,
          artworkWidth: AppConstants.artworkCacheWidth.toDouble(),
          artworkHeight: AppConstants.artworkCacheHeight.toDouble(),
        ),
      ),
      title: Text(
        song.title,
        style: AppTheme.titleMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${song.artist} • ${song.album}',
        style: AppTheme.bodySmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert_rounded),
        onPressed: () {
          _showSongOptions(song);
        },
      ),
      onTap: () => _playSong(song),
    ).animate().fadeIn(delay: (index * 30).ms).slideX(begin: 0.1);
  }

  Future<void> _playSong(SongModel song) async {
    if (!song.fileExists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File not found: ${song.title}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    final songs = ref.read(allSongsProvider).valueOrNull ?? [];
    final index = songs.indexWhere((s) => s.id == song.id);
    if (index == -1) return;

    final audioService = AudioEngineService();
    await audioService.loadPlaylist(songs, initialIndex: index);
    await audioService.play();

    if (mounted) {
      Navigator.pushNamed(context, '/now-playing');
    }
  }

  void _showSongOptions(SongModel song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow_rounded),
              title: const Text('Play'),
              onTap: () {
                Navigator.pop(context);
                _playSong(song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.queue_music_rounded),
              title: const Text('Add to Queue'),
              onTap: () async {
                Navigator.pop(context);
                if (!song.fileExists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('File not found: ${song.title}'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                  return;
                }
                final audioService = AudioEngineService();
                await audioService.addToQueue(song);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added "${song.title}" to queue')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('Song Info'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(song.title),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Artist: ${song.artist}'),
                        Text('Album: ${song.album}'),
                        Text('Duration: ${song.formattedDuration}'),
                        Text('Size: ${song.formattedSize}'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
