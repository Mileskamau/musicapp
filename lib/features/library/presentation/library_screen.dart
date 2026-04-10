import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart' hide SongModel;
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/song_model.dart';
import '../../../core/providers/music_provider.dart';
import '../../../core/services/audio_engine.dart';
import '../../../core/services/music_query_service.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Your Library',
                  style: AppTheme.headlineMedium.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ).animate().fadeIn(duration: AppConstants.normalAnimation),
                titlePadding: const EdgeInsets.only(
                  left: AppConstants.spacingL,
                  bottom: AppConstants.spacingM,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.sort_rounded),
                  onPressed: () {
                    _showSortOptions();
                  },
                ).animate().scale(delay: 100.ms),
                IconButton(
                  icon: const Icon(Icons.search_rounded),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Use the Search tab below'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ).animate().scale(delay: 200.ms),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryColor,
                indicatorWeight: 3,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textTertiary,
                labelStyle: AppTheme.labelMedium,
                unselectedLabelStyle: AppTheme.labelMedium,
                tabs: const [
                  Tab(text: 'Songs'),
                  Tab(text: 'Albums'),
                  Tab(text: 'Artists'),
                  Tab(text: 'Folders'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildSongsTab(),
            _buildAlbumsTab(),
            _buildArtistsTab(),
            _buildFoldersTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSongsTab() {
    final songsAsync = ref.watch(paginatedSongsProvider);

    return songsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
      error: (error, stack) => _buildPermissionError(error),
      data: (songs) {
        if (songs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.music_off_rounded, color: AppTheme.textSecondary, size: 64),
                const SizedBox(height: AppConstants.spacingM),
                Text('No music found', style: AppTheme.titleMedium),
                const SizedBox(height: AppConstants.spacingS),
                Text(
                  'Add MP3 files to your device\'s Music folder',
                  style: AppTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.spacingM),
                ElevatedButton.icon(
                  onPressed: () => ref.read(paginatedSongsProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Rescan'),
                ),
              ],
            ),
          );
        }

        final notifier = ref.read(paginatedSongsProvider.notifier);

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollEndNotification) {
              final metrics = notification.metrics;
              if (metrics.pixels >= metrics.maxScrollExtent - 200) {
                notifier.loadNextPage();
              }
            }
            return false;
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(
              top: AppConstants.spacingM,
              bottom: AppConstants.miniPlayerHeight + AppConstants.bottomNavHeight,
            ),
            itemCount: songs.length + (notifier.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == songs.length) {
                return const Padding(
                  padding: EdgeInsets.all(AppConstants.spacingM),
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  ),
                );
              }
              final song = songs[index];
              return _buildSongTile(song, index);
            },
          ),
        );
      },
    );
  }

  Widget _buildPermissionError(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, color: AppTheme.errorColor, size: 64),
            const SizedBox(height: AppConstants.spacingM),
            Text('Permission Required', style: AppTheme.titleMedium),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              'MusicPly needs access to your music library. '
              'Please grant storage permission in your device settings.',
              style: AppTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingM),
            ElevatedButton.icon(
              onPressed: () async {
                final status = await Permission.audio.request();
                if (status.isPermanentlyDenied && mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Permission Needed'),
                      content: const Text(
                        'Storage permission was permanently denied. '
                        'Please open your device Settings > Apps > MusicPly > Permissions '
                        'and enable Storage/Music access.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            openAppSettings();
                            Navigator.pop(context);
                          },
                          child: const Text('Open Settings'),
                        ),
                      ],
                    ),
                  );
                } else {
                  ref.invalidate(allSongsProvider);
                }
              },
              icon: const Icon(Icons.settings_rounded),
              label: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumsTab() {
    final albumsAsync = ref.watch(albumsProvider);

    return albumsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 48),
            const SizedBox(height: AppConstants.spacingM),
            Text('Error loading albums', style: AppTheme.titleMedium),
            const SizedBox(height: AppConstants.spacingM),
            ElevatedButton(
              onPressed: () => ref.invalidate(albumsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (albums) {
        if (albums.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.album_rounded, color: AppTheme.textSecondary, size: 64),
                const SizedBox(height: AppConstants.spacingM),
                Text('No albums found', style: AppTheme.titleMedium),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppConstants.spacingM,
            crossAxisSpacing: AppConstants.spacingM,
            childAspectRatio: 0.8,
          ),
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];
            return _buildAlbumCard(album, index);
          },
        );
      },
    );
  }

  Widget _buildArtistsTab() {
    final artistsAsync = ref.watch(artistsProvider);

    return artistsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 48),
            const SizedBox(height: AppConstants.spacingM),
            Text('Error loading artists', style: AppTheme.titleMedium),
            const SizedBox(height: AppConstants.spacingM),
            ElevatedButton(
              onPressed: () => ref.invalidate(artistsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (artists) {
        if (artists.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_rounded, color: AppTheme.textSecondary, size: 64),
                const SizedBox(height: AppConstants.spacingM),
                Text('No artists found', style: AppTheme.titleMedium),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(
            top: AppConstants.spacingM,
            bottom: AppConstants.miniPlayerHeight + AppConstants.bottomNavHeight,
          ),
          itemCount: artists.length,
          itemBuilder: (context, index) {
            final artist = artists[index];
            return _buildArtistTile(artist, index);
          },
        );
      },
    );
  }

  Widget _buildFoldersTab() {
    final foldersAsync = ref.watch(foldersProvider);

    return foldersAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 48),
            const SizedBox(height: AppConstants.spacingM),
            Text('Error loading folders', style: AppTheme.titleMedium),
            const SizedBox(height: AppConstants.spacingM),
            ElevatedButton(
              onPressed: () => ref.invalidate(foldersProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (folders) {
        if (folders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder_rounded, color: AppTheme.textSecondary, size: 64),
                const SizedBox(height: AppConstants.spacingM),
                Text('No folders found', style: AppTheme.titleMedium),
                const SizedBox(height: AppConstants.spacingS),
                Text('Add music to your device to see folders', style: AppTheme.bodySmall),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(
            top: AppConstants.spacingM,
            bottom: AppConstants.miniPlayerHeight + AppConstants.bottomNavHeight,
          ),
          itemCount: folders.length,
          itemBuilder: (context, index) {
            final folder = folders[index];
            final folderName = folder.path.split(RegExp(r'[/\\]')).last;
            final songs = MusicQueryService().getSongsByFolder(folder.path);

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
                child: const Icon(
                  Icons.folder_rounded,
                  color: AppTheme.warningColor,
                  size: 28,
                ),
              ),
              title: Text(
                folderName.isNotEmpty ? folderName : folder.path,
                style: AppTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${songs.length} songs',
                style: AppTheme.bodySmall,
              ),
              onTap: () {
                _showFolderSongs(folder.path, songs);
              },
            );
          },
        );
      },
    );
  }

  void _showFolderSongs(String folderPath, List<SongModel> songs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Column(
                children: [
                  Text(
                    folderPath.split(RegExp(r'[/\\]')).last,
                    style: AppTheme.headlineSmall,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text('${songs.length} songs', style: AppTheme.bodySmall),
                  const SizedBox(height: AppConstants.spacingM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _playSongsInFolder(songs);
                        },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Play All'),
                      ),
                      const SizedBox(width: AppConstants.spacingM),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          final shuffled = List<SongModel>.from(songs)..shuffle();
                          _playSongsInFolder(shuffled);
                        },
                        icon: const Icon(Icons.shuffle_rounded),
                        label: const Text('Shuffle'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  return ListTile(
                    leading: const Icon(Icons.music_note_rounded, color: AppTheme.textSecondary),
                    title: Text(song.title, style: AppTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(song.artist, style: AppTheme.bodySmall),
                    trailing: Text(song.formattedDuration, style: AppTheme.bodySmall),
                    onTap: () {
                      Navigator.pop(context);
                      final allSongs = ref.read(allSongsProvider).valueOrNull ?? [];
                      final globalIndex = allSongs.indexWhere((s) => s.id == song.id);
                      if (globalIndex != -1) _playSong(globalIndex);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _playSongsInFolder(List<SongModel> songs) async {
    if (songs.isEmpty) return;
    final audioService = AudioEngineService();
    await audioService.loadPlaylist(songs, initialIndex: 0);
    await audioService.play();
    if (mounted) {
      Navigator.pushNamed(context, '/now-playing');
    }
  }

  Widget _buildSongTile(SongModel song, int index) {
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            song.formattedDuration,
            style: AppTheme.bodySmall,
          ),
          const SizedBox(width: AppConstants.spacingS),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {
              _showSongOptions(song);
            },
          ),
        ],
      ),
      onTap: () => _playSong(index),
    );
  }

  Widget _buildAlbumCard(AlbumModel album, int index) {
    return GestureDetector(
      onTap: () {
        _showAlbumSongs(album);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          color: AppTheme.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppConstants.borderRadius),
                  ),
                ),
                child: QueryArtworkWidget(
                  id: album.id,
                  type: ArtworkType.ALBUM,
                  nullArtworkWidget: const Icon(
                    Icons.album_rounded,
                    size: 48,
                    color: AppTheme.textSecondary,
                  ),
                  artworkBorder: const BorderRadius.vertical(
                    top: Radius.circular(AppConstants.borderRadius),
                  ),
                  artworkFit: BoxFit.cover,
                  artworkWidth: AppConstants.artworkCacheWidth.toDouble(),
                  artworkHeight: AppConstants.artworkCacheHeight.toDouble(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingS),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.album,
                    style: AppTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    album.artist ?? 'Unknown Artist',
                    style: AppTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistTile(ArtistModel artist, int index) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingL,
        vertical: AppConstants.spacingS,
      ),
      leading: QueryArtworkWidget(
        id: artist.id,
        type: ArtworkType.ARTIST,
        nullArtworkWidget: CircleAvatar(
          radius: 28,
          backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
          child: Text(
            (artist.artist.isNotEmpty ? artist.artist[0] : '?').toUpperCase(),
            style: AppTheme.headlineSmall.copyWith(
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        artworkBorder: BorderRadius.circular(28),
        artworkHeight: 56,
        artworkWidth: 56,
      ),
      title: Text(
        artist.artist,
        style: AppTheme.titleMedium,
      ),
      subtitle: Text(
        '${artist.numberOfAlbums} albums • ${artist.numberOfTracks} songs',
        style: AppTheme.bodySmall,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert_rounded),
        onPressed: () {
          _showArtistOptions(artist);
        },
      ),
      onTap: () {
        _showArtistSongs(artist);
      },
    );
  }

  Future<void> _playSong(int index) async {
    final songs = ref.read(allSongsProvider).valueOrNull ?? [];
    if (songs.isEmpty) return;

    final audioService = AudioEngineService();
    await audioService.loadPlaylist(songs, initialIndex: index);
    await audioService.play();

    if (mounted) {
      Navigator.pushNamed(context, '/now-playing');
    }
  }

  void _showSortOptions() {
    final currentSort = ref.read(songSortProvider);
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
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Text('Sort by', style: AppTheme.headlineSmall),
            ),
            _buildSortOption('Title', Icons.sort_by_alpha_rounded, SongSortOption.title, currentSort),
            _buildSortOption('Artist', Icons.person_rounded, SongSortOption.artist, currentSort),
            _buildSortOption('Album', Icons.album_rounded, SongSortOption.album, currentSort),
            _buildSortOption('Duration', Icons.access_time_rounded, SongSortOption.duration, currentSort),
            _buildSortOption('Date Added', Icons.calendar_today_rounded, SongSortOption.dateAdded, currentSort),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, IconData icon, SongSortOption option, SongSortOption currentSort) {
    final isSelected = option == currentSort;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.primaryColor : null),
      title: Text(label, style: TextStyle(color: isSelected ? AppTheme.primaryColor : null)),
      trailing: isSelected ? const Icon(Icons.check_rounded, color: AppTheme.primaryColor) : null,
      onTap: () {
        Navigator.pop(context);
        ref.read(songSortProvider.notifier).state = option;
      },
    );
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
                if (song.fileExists != true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('File not found: ${song.title}'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                  return;
                }
                final songs = ref.read(allSongsProvider).valueOrNull ?? [];
                final index = songs.indexWhere((s) => s.id == song.id);
                if (index != -1) _playSong(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.queue_music_rounded),
              title: const Text('Add to Queue'),
              onTap: () async {
                Navigator.pop(context);
                if (song.fileExists != true) {
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
              leading: Icon(
                isFavorite(ref, song.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              ),
              title: Text(isFavorite(ref, song.id) ? 'Remove from Favorites' : 'Add to Favorites'),
              onTap: () {
                Navigator.pop(context);
                toggleFavorite(ref, song.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isFavorite(ref, song.id)
                            ? 'Removed from favorites'
                            : 'Added to favorites',
                      ),
                    ),
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
                        Text('Path: ${song.uri}'),
                        Text('Exists: ${song.fileExists == true ? "Yes" : (song.fileExists == false ? "No" : "Unknown")}'),
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

  void _showAlbumSongs(AlbumModel album) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Column(
                children: [
                  Text(album.album, style: AppTheme.headlineSmall, textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text(album.artist ?? 'Unknown Artist', style: AppTheme.bodySmall),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<SongModel>>(
                future: MusicQueryService().querySongsByAlbum(album.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                  }
                  final songs = snapshot.data ?? [];
                  if (songs.isEmpty) {
                    return const Center(child: Text('No songs in this album'));
                  }
                  return ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      return ListTile(
                        leading: const Icon(Icons.music_note_rounded, color: AppTheme.textSecondary),
                        title: Text(song.title, style: AppTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(song.artist, style: AppTheme.bodySmall),
                        trailing: Text(song.formattedDuration, style: AppTheme.bodySmall),
                        onTap: () {
                          Navigator.pop(context);
                          if (song.fileExists != true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('File not found: ${song.title}'),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                            return;
                          }
                          final allSongs = ref.read(allSongsProvider).valueOrNull ?? [];
                          final globalIndex = allSongs.indexWhere((s) => s.id == song.id);
                          if (globalIndex != -1) _playSong(globalIndex);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showArtistOptions(ArtistModel artist) {
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
              title: Text('Play ${artist.artist}'),
              onTap: () async {
                Navigator.pop(context);
                final songs = await MusicQueryService().querySongsByArtist(artist.id);
                if (songs.isNotEmpty && context.mounted) {
                  final audioService = AudioEngineService();
                  await audioService.loadPlaylist(songs, initialIndex: 0);
                  await audioService.play();
                  if (context.mounted) {
                    Navigator.pushNamed(context, '/now-playing');
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.shuffle_rounded),
              title: const Text('Shuffle'),
              onTap: () async {
                Navigator.pop(context);
                final songs = await MusicQueryService().querySongsByArtist(artist.id);
                if (songs.isNotEmpty && context.mounted) {
                  songs.shuffle();
                  final audioService = AudioEngineService();
                  await audioService.loadPlaylist(songs, initialIndex: 0);
                  await audioService.play();
                  if (context.mounted) {
                    Navigator.pushNamed(context, '/now-playing');
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showArtistSongs(ArtistModel artist) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Column(
                children: [
                  Text(artist.artist, style: AppTheme.headlineSmall, textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text('${artist.numberOfAlbums} albums • ${artist.numberOfTracks} songs', style: AppTheme.bodySmall),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<SongModel>>(
                future: MusicQueryService().querySongsByArtist(artist.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                  }
                  final songs = snapshot.data ?? [];
                  if (songs.isEmpty) {
                    return const Center(child: Text('No songs for this artist'));
                  }
                  return ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      return ListTile(
                        leading: const Icon(Icons.music_note_rounded, color: AppTheme.textSecondary),
                        title: Text(song.title, style: AppTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(song.album, style: AppTheme.bodySmall),
                        trailing: Text(song.formattedDuration, style: AppTheme.bodySmall),
                        onTap: () {
                          Navigator.pop(context);
                          if (song.fileExists != true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('File not found: ${song.title}'),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                            return;
                          }
                          final allSongs = ref.read(allSongsProvider).valueOrNull ?? [];
                          final globalIndex = allSongs.indexWhere((s) => s.id == song.id);
                          if (globalIndex != -1) _playSong(globalIndex);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
