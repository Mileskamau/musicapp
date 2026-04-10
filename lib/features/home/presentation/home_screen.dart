import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart' hide SongModel;
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/song_model.dart';
import '../../../core/providers/music_provider.dart';
import '../../../core/services/audio_engine.dart';
import '../../../core/services/music_query_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  StreamSubscription<String>? _errorSubscription;

  @override
  void initState() {
    super.initState();
    // Listen for playback errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioService = AudioEngineService();
      _errorSubscription = audioService.playbackErrorStream.listen((error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: AppTheme.errorColor,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _errorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final songsAsync = ref.watch(allSongsProvider);

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
                'Good ${_getGreeting()}',
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
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Rescanning library...'),
                      duration: Duration(seconds: 5),
                    ),
                  );
                  await MusicQueryService().rescanSongs();
                  ref.invalidate(allSongsProvider);
                  if (mounted) {
                    messenger.clearSnackBars();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Library refreshed'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ).animate().scale(delay: 50.ms),
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No new notifications'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ).animate().scale(delay: 100.ms),
              IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ).animate().scale(delay: 200.ms),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: songsAsync.when(
                loading: () => _buildLoadingShimmer(),
                error: (error, _) => _buildErrorState(error),
                data: (songs) => _buildHomeContent(songs),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.primaryColor),
            const SizedBox(height: AppConstants.spacingM),
            Text('Scanning music library...', style: AppTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 48),
            const SizedBox(height: AppConstants.spacingM),
            Text('Could not load music', style: AppTheme.titleMedium),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              error.toString(),
              style: AppTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingM),
            ElevatedButton(
              onPressed: () => ref.invalidate(allSongsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent(List<SongModel> songs) {
    if (songs.isEmpty) {
      return SizedBox(
        height: 400,
        child: Center(
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
                onPressed: () => ref.invalidate(allSongsProvider),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Rescan'),
              ),
            ],
          ),
        ),
      );
    }

    // Recently Added: sorted by date descending
    final recentSongs = (List<SongModel>.from(songs)
          ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded)))
        .take(10)
        .toList();

    // All Songs: shuffled for variety
    final allSongsSample = (List<SongModel>.from(songs)..shuffle()).take(10).toList();

    // Newest: songs added within the last 30 days
    final now = DateTime.now().millisecondsSinceEpoch;
    final thirtyDaysAgo = now - (30 * 24 * 60 * 60 * 1000);
    final newestSongs = (List<SongModel>.from(songs)
          ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded)))
        .where((s) => s.dateAdded > thirtyDaysAgo)
        .take(10)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Play Section
        _buildQuickPlaySection(songs),

        const SizedBox(height: AppConstants.spacingXL),

        // Newest
        if (newestSongs.isNotEmpty) ...[
          _buildSectionTitle('Newest'),
          const SizedBox(height: AppConstants.spacingM),
          _buildSongHorizontalList(newestSongs),
          const SizedBox(height: AppConstants.spacingXL),
        ],

        // All Songs
        _buildSectionTitle('All Songs'),
        const SizedBox(height: AppConstants.spacingM),
        _buildSongHorizontalList(allSongsSample),

        const SizedBox(height: AppConstants.spacingXL),

        // Newest
        _buildSectionTitle('Newest'),
        const SizedBox(height: AppConstants.spacingM),
        _buildSongHorizontalList(newestSongs),

        const SizedBox(height: AppConstants.spacingXXL),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Widget _buildQuickPlaySection(List<SongModel> songs) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppConstants.spacingM,
      crossAxisSpacing: AppConstants.spacingM,
      childAspectRatio: 3,
      children: [
        _buildQuickPlayCard('All Songs', Icons.music_note_rounded, AppTheme.primaryColor, () {
          _playAllSongs(songs);
        }),
        _buildQuickPlayCard('Recently Added', Icons.new_releases_rounded, AppTheme.accentColor, () {
          final recent = List<SongModel>.from(songs)
            ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
          _playAllSongs(recent.take(20).toList());
        }),
        _buildQuickPlayCard('Shuffle All', Icons.shuffle_rounded, AppTheme.warningColor, () {
          final shuffled = List<SongModel>.from(songs)..shuffle();
          _playAllSongs(shuffled, shuffle: true);
        }),
        _buildQuickPlayCard('${songs.length} Songs', Icons.library_music_rounded, AppTheme.successColor, null),
      ],
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildQuickPlayCard(String title, IconData icon, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.3),
              color.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.all(AppConstants.spacingS),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: AppConstants.spacingS),
            Expanded(
              child: Text(
                title,
                style: AppTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTheme.headlineSmall,
        ),
        TextButton(
          onPressed: () {
            final songs = ref.read(allSongsProvider).valueOrNull ?? [];
            if (songs.isEmpty) return;
            showModalBottomSheet(
              context: context,
              backgroundColor: AppTheme.cardColor,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (context) => SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppConstants.spacingL),
                      child: Text(title, style: AppTheme.headlineSmall),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: songs.length,
                        itemBuilder: (context, index) {
                          final song = songs[index];
                          return ListTile(
                            leading: const Icon(Icons.music_note_rounded, color: AppTheme.textSecondary),
                            title: Text(song.title, style: AppTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(song.artist, style: AppTheme.bodySmall),
                            onTap: () {
                              Navigator.pop(context);
                              _playSong(song);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          child: Text(
            'See All',
            style: AppTheme.labelMedium.copyWith(
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildSongHorizontalList(List<SongModel> songs) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return _buildSongCard(song, index)
              .animate()
              .fadeIn(delay: (500 + index * 50).ms)
              .slideX(begin: 0.1);
        },
      ),
    );
  }

  Widget _buildSongCard(SongModel song, int index) {
    return GestureDetector(
      onTap: () => _playSong(song),
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                color: AppTheme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: QueryArtworkWidget(
                      id: int.tryParse(song.id) ?? 0,
                      type: ArtworkType.AUDIO,
                      nullArtworkWidget: const Icon(
                        Icons.music_note_rounded,
                        size: 48,
                        color: AppTheme.textSecondary,
                      ),
                      artworkBorder: BorderRadius.circular(AppConstants.borderRadius),
                      artworkFit: BoxFit.cover,
                      artworkWidth: AppConstants.artworkCacheWidth.toDouble(),
                      artworkHeight: AppConstants.artworkCacheHeight.toDouble(),
                    ),
                  ),
                  Positioned(
                    bottom: AppConstants.spacingS,
                    right: AppConstants.spacingS,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: AppTheme.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              song.title,
              style: AppTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              song.artist,
              style: AppTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _playSong(SongModel song) async {
    // Check if file exists before playing
    if (song.fileExists != true) {
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

  Future<void> _playAllSongs(List<SongModel> songs, {bool shuffle = false}) async {
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
}
