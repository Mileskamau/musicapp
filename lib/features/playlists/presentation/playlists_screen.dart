import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/song_model.dart';
import '../../../core/providers/music_provider.dart';
import '../../../core/services/audio_engine.dart';

class PlaylistsScreen extends ConsumerStatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  ConsumerState<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends ConsumerState<PlaylistsScreen> {
  @override
  Widget build(BuildContext context) {
    final userPlaylists = ref.watch(userPlaylistsProvider);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Playlists',
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
                icon: const Icon(Icons.add_rounded),
                onPressed: () {
                  _showCreatePlaylistDialog();
                },
              ).animate().scale(delay: 100.ms),
            ],
          ),

          // Smart Playlists
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Smart Playlists',
                    style: AppTheme.headlineSmall,
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: AppConstants.spacingM),
                  _buildSmartPlaylists(),

                  const SizedBox(height: AppConstants.spacingXL),

                  Text(
                    'Your Playlists (${userPlaylists.length})',
                    style: AppTheme.headlineSmall,
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: AppConstants.spacingM),
                ],
              ),
            ),
          ),

          // User Playlists
          if (userPlaylists.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingXXL),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.queue_music_rounded, color: AppTheme.textSecondary, size: 64),
                      const SizedBox(height: AppConstants.spacingM),
                      Text('No playlists yet', style: AppTheme.titleMedium),
                      const SizedBox(height: AppConstants.spacingS),
                      Text('Tap + to create your first playlist', style: AppTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final playlist = userPlaylists[index];
                    return _buildPlaylistTile(playlist, index)
                        .animate()
                        .fadeIn(delay: (500 + index * 50).ms)
                        .slideX(begin: 0.1);
                  },
                  childCount: userPlaylists.length,
                ),
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: AppConstants.miniPlayerHeight + AppConstants.bottomNavHeight),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartPlaylists() {
    final smartPlaylists = [
      {'name': 'Recently Played', 'icon': Icons.history_rounded, 'color': AppTheme.primaryColor},
      {'name': 'Most Played', 'icon': Icons.trending_up_rounded, 'color': AppTheme.accentColor},
      {'name': 'Favorites', 'icon': Icons.favorite_rounded, 'color': AppTheme.errorColor},
      {'name': 'Recently Added', 'icon': Icons.new_releases_rounded, 'color': AppTheme.warningColor},
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppConstants.spacingM,
      crossAxisSpacing: AppConstants.spacingM,
      childAspectRatio: 1.5,
      children: smartPlaylists.asMap().entries.map((entry) {
        final index = entry.key;
        final playlist = entry.value;
        return _buildSmartPlaylistCard(
          playlist['name'] as String,
          playlist['icon'] as IconData,
          playlist['color'] as Color,
          index,
        );
      }).toList(),
    );
  }

  Widget _buildSmartPlaylistCard(String name, IconData icon, Color color, int index) {
    return GestureDetector(
      onTap: () {
        _openSmartPlaylist(name);
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                  const SizedBox(height: AppConstants.spacingS),
                  Text(
                    name,
                    style: AppTheme.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: -10,
              right: -10,
              child: Icon(
                icon,
                size: 80,
                color: color.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (300 + index * 100).ms).scale(begin: const Offset(0.9, 0.9));
  }

  void _openSmartPlaylist(String name) {
    List<SongModel> songs;
    switch (name) {
      case 'Recently Played':
        songs = ref.read(recentlyPlayedProvider);
        break;
      case 'Most Played':
        songs = ref.read(mostPlayedProvider);
        break;
      case 'Favorites':
        songs = ref.read(favoritesProvider);
        break;
      case 'Recently Added':
        songs = ref.read(recentlyAddedProvider);
        break;
      default:
        songs = [];
    }

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
                  Text(name, style: AppTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text('${songs.length} songs', style: AppTheme.bodySmall),
                  if (songs.isNotEmpty) ...[
                    const SizedBox(height: AppConstants.spacingM),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _playSmartPlaylist(songs);
                          },
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Play All'),
                        ),
                        const SizedBox(width: AppConstants.spacingM),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            final shuffled = List<SongModel>.from(songs)..shuffle();
                            _playSmartPlaylist(shuffled, shuffle: true);
                          },
                          icon: const Icon(Icons.shuffle_rounded),
                          label: const Text('Shuffle'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: songs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            name == 'Favorites' ? Icons.favorite_border_rounded : Icons.music_off_rounded,
                            color: AppTheme.textSecondary,
                            size: 48,
                          ),
                          const SizedBox(height: AppConstants.spacingM),
                          Text(
                            name == 'Favorites'
                                ? 'No favorites yet. Tap the heart icon on songs to add them!'
                                : 'No songs in this playlist yet. Play some music first!',
                            style: AppTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: songs.length,
                      itemBuilder: (context, index) {
                        final song = songs[index];
                        return ListTile(
                          leading: const Icon(Icons.music_note_rounded, color: AppTheme.textSecondary),
                          title: Text(song.title, style: AppTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(song.artist, style: AppTheme.bodySmall),
                          trailing: name == 'Most Played'
                              ? Text('${song.playCount} plays', style: AppTheme.bodySmall)
                              : Text(song.formattedDuration, style: AppTheme.bodySmall),
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
                            _playSmartPlaylistAt(songs, index);
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

  Future<void> _playSmartPlaylist(List<SongModel> songs, {bool shuffle = false}) async {
    if (songs.isEmpty) return;
    final audioService = AudioEngineService();
    await audioService.loadPlaylist(songs, initialIndex: 0);
    if (shuffle) {
      audioService.toggleShuffle();
    }
    await audioService.play();
    if (mounted) {
      Navigator.pushNamed(context, '/now-playing');
    }
  }

  Future<void> _playSmartPlaylistAt(List<SongModel> songs, int index) async {
    if (songs.isEmpty) return;
    final audioService = AudioEngineService();
    await audioService.loadPlaylist(songs, initialIndex: index);
    await audioService.play();
    if (mounted) {
      Navigator.pushNamed(context, '/now-playing');
    }
  }

  Widget _buildPlaylistTile(PlaylistEntry playlist, int index) {
    final allSongs = ref.read(allSongsProvider).valueOrNull ?? [];
    final songCount = playlist.songIds.length;

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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.3),
              AppTheme.accentColor.withOpacity(0.3),
            ],
          ),
        ),
        child: const Icon(
          Icons.queue_music_rounded,
          color: AppTheme.textSecondary,
          size: 28,
        ),
      ),
      title: Text(
        playlist.name,
        style: AppTheme.titleMedium,
      ),
      subtitle: Text(
        '$songCount songs',
        style: AppTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.play_arrow_rounded),
            onPressed: () {
              final songs = _resolvePlaylistSongs(playlist, allSongs);
              if (songs.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Playlist is empty')),
                );
                return;
              }
              _playSmartPlaylist(songs);
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {
              _showPlaylistOptions(playlist);
            },
          ),
        ],
      ),
      onTap: () {
        _showPlaylistDetail(playlist);
      },
    );
  }

  List<SongModel> _resolvePlaylistSongs(PlaylistEntry playlist, List<SongModel> allSongs) {
    final songs = <SongModel>[];
    for (final id in playlist.songIds) {
      final match = allSongs.where((s) => s.id == id);
      if (match.isNotEmpty && match.first.fileExists == true) {
        songs.add(match.first);
      }
    }
    return songs;
  }

  void _showCreatePlaylistDialog() {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Playlist'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'Playlist name',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                nameController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  final playlists = ref.read(userPlaylistsProvider.notifier);
                  final current = ref.read(userPlaylistsProvider);
                  playlists.state = [
                    ...current,
                    PlaylistEntry(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                    ),
                  ];
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Created "$name"')),
                  );
                }
                nameController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    ).then((_) => nameController.dispose());
  }

  void _showPlaylistOptions(PlaylistEntry playlist) {
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
              title: Text('Play ${playlist.name}'),
              onTap: () {
                Navigator.pop(context);
                final allSongs = ref.read(allSongsProvider).valueOrNull ?? [];
                final songs = _resolvePlaylistSongs(playlist, allSongs);
                if (songs.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Playlist is empty')),
                  );
                  return;
                }
                _playSmartPlaylist(songs);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shuffle_rounded),
              title: const Text('Shuffle'),
              onTap: () {
                Navigator.pop(context);
                final allSongs = ref.read(allSongsProvider).valueOrNull ?? [];
                final songs = _resolvePlaylistSongs(playlist, allSongs);
                if (songs.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Playlist is empty')),
                  );
                  return;
                }
                songs.shuffle();
                _playSmartPlaylist(songs);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(playlist);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor),
              title: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
              onTap: () {
                Navigator.pop(context);
                final playlists = ref.read(userPlaylistsProvider.notifier);
                playlists.state = playlists.state.where((p) => p.id != playlist.id).toList();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted "${playlist.name}"')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(PlaylistEntry playlist) {
    final controller = TextEditingController(text: playlist.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'New name'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final playlists = ref.read(userPlaylistsProvider.notifier);
                playlists.state = playlists.state
                    .map((p) => p.id == playlist.id ? p.copyWith(name: newName) : p)
                    .toList();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Renamed to "$newName"')),
                );
              }
              controller.dispose();
              Navigator.pop(context);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  void _showPlaylistDetail(PlaylistEntry playlist) {
    final allSongs = ref.read(allSongsProvider).valueOrNull ?? [];
    final songs = _resolvePlaylistSongs(playlist, allSongs);

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
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.3),
                          AppTheme.accentColor.withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: const Icon(Icons.queue_music_rounded, size: 40, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  Text(playlist.name, style: AppTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text('${songs.length} songs', style: AppTheme.bodySmall),
                  if (songs.isNotEmpty) ...[
                    const SizedBox(height: AppConstants.spacingM),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _playSmartPlaylist(songs);
                          },
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Play All'),
                        ),
                        const SizedBox(width: AppConstants.spacingM),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            final shuffled = List<SongModel>.from(songs)..shuffle();
                            _playSmartPlaylist(shuffled, shuffle: true);
                          },
                          icon: const Icon(Icons.shuffle_rounded),
                          label: const Text('Shuffle'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: songs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.music_off_rounded, color: AppTheme.textSecondary, size: 48),
                          const SizedBox(height: AppConstants.spacingM),
                          Text('No songs in this playlist', style: AppTheme.bodySmall),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: songs.length,
                      itemBuilder: (context, index) {
                        final song = songs[index];
                        return ListTile(
                          leading: const Icon(Icons.music_note_rounded, color: AppTheme.textSecondary),
                          title: Text(song.title, style: AppTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(song.artist, style: AppTheme.bodySmall),
                          trailing: IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.textTertiary),
                            onPressed: () {
                              final playlists = ref.read(userPlaylistsProvider.notifier);
                              final updatedIds = List<String>.from(playlist.songIds)..remove(song.id);
                              playlists.state = playlists.state
                                  .map((p) => p.id == playlist.id ? p.copyWith(songIds: updatedIds) : p)
                                  .toList();
                              Navigator.pop(context);
                              _showPlaylistDetail(
                                playlists.state.firstWhere((p) => p.id == playlist.id),
                              );
                            },
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _playSmartPlaylistAt(songs, index);
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
