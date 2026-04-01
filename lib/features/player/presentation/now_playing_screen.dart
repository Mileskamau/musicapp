import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' show LoopMode;
import 'package:on_audio_query/on_audio_query.dart' hide SongModel;
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/audio_provider.dart';
import '../../../core/providers/music_provider.dart';
import '../../../core/models/song_model.dart';
import '../../../core/services/audio_service.dart';
import 'equalizer_screen.dart';

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: AppConstants.normalAnimation,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = ref.watch(currentSongProvider);
    final isPlaying = ref.watch(isPlayingProvider).valueOrNull ?? false;
    final position = ref.watch(positionProvider).valueOrNull ?? Duration.zero;
    final duration = ref.watch(durationProvider).valueOrNull ?? Duration.zero;
    final shuffleEnabled = ref.watch(shuffleProvider).valueOrNull ?? false;
    final loopMode = ref.watch(loopModeProvider).valueOrNull ?? LoopMode.off;
    final audioService = AudioEngineService();

    // Sync favorite state from provider
    final isFavoriteSong = currentSong != null && isFavorite(ref, currentSong.id);

    if (isPlaying && !_rotationController.isAnimating) {
      _rotationController.repeat();
    } else if (!isPlaying && _rotationController.isAnimating) {
      _rotationController.stop();
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withOpacity(0.3),
              AppTheme.backgroundColor,
              AppTheme.backgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                flex: 3,
                child: _buildAlbumArt(currentSong),
              ),
              _buildSongInfo(currentSong, isFavoriteSong),
              _buildProgressBar(position, duration, audioService),
              _buildControls(isPlaying, audioService, shuffleEnabled, loopMode),
              _buildExtraControls(audioService),
              const SizedBox(height: AppConstants.spacingL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            onPressed: () {
              Navigator.pop(context);
            },
          ).animate().fadeIn().slideY(begin: -0.1),
          Column(
            children: [
              Text(
                'NOW PLAYING',
                style: AppTheme.labelSmall.copyWith(
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 100.ms),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {
              _showMoreOptions();
            },
          ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.1),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(SongModel? song) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final audioService = AudioEngineService();
        if (details.velocity.pixelsPerSecond.dx > 0) {
          audioService.previous();
        } else if (details.velocity.pixelsPerSecond.dx < 0) {
          audioService.next();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingXXL),
        child: AnimatedBuilder(
          animation: _rotationController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationController.value * 2 * 3.14159,
              child: child,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withOpacity(0.5),
                  AppTheme.accentColor.withOpacity(0.5),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.backgroundColor,
                ),
                child: song != null
                    ? QueryArtworkWidget(
                        id: int.tryParse(song.id) ?? 0,
                        type: ArtworkType.AUDIO,
                        nullArtworkWidget: const Icon(
                          Icons.music_note_rounded,
                          size: 48,
                          color: AppTheme.textSecondary,
                        ),
                        artworkBorder: BorderRadius.circular(50),
                        artworkFit: BoxFit.cover,
                        artworkWidth: AppConstants.artworkCacheWidthLarge.toDouble(),
                        artworkHeight: AppConstants.artworkCacheHeightLarge.toDouble(),
                      )
                    : const Icon(
                        Icons.music_note_rounded,
                        size: 48,
                        color: AppTheme.textSecondary,
                      ),
              ),
            ),
          ),
        ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.8, 0.8)),
      ),
    );
  }

  Widget _buildSongInfo(SongModel? song, bool isFavoriteSong) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song?.title ?? 'No song playing',
                  style: AppTheme.headlineSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  song?.artist ?? '',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              isFavoriteSong ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFavoriteSong ? AppTheme.errorColor : AppTheme.textSecondary,
            ),
            onPressed: () {
              if (song != null) {
                toggleFavorite(ref, song.id);
              }
            },
          ).animate().scale(delay: 400.ms),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildProgressBar(Duration position, Duration duration, AudioEngineService audioService) {
    final maxMs = duration.inMilliseconds > 0 ? duration.inMilliseconds : 1;
    final value = (position.inMilliseconds / maxMs).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
      child: Column(
        children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: AppTheme.primaryColor,
              inactiveTrackColor: AppTheme.surfaceColor,
              thumbColor: AppTheme.primaryColor,
              overlayColor: AppTheme.primaryColor.withOpacity(0.2),
            ),
            child: Slider(
              value: value,
              onChanged: (v) {
                final seekTo = Duration(milliseconds: (v * maxMs).round());
                audioService.seek(seekTo);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingS),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(position),
                  style: AppTheme.bodySmall,
                ),
                Text(
                  _formatDuration(duration),
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildControls(bool isPlaying, AudioEngineService audioService, bool shuffleEnabled, LoopMode loopMode) {
    final shuffleColor = shuffleEnabled ? AppTheme.primaryColor : AppTheme.textSecondary;
    final repeatColor = loopMode != LoopMode.off ? AppTheme.primaryColor : AppTheme.textSecondary;
    IconData repeatIcon;
    switch (loopMode) {
      case LoopMode.one:
        repeatIcon = Icons.repeat_one_rounded;
        break;
      case LoopMode.all:
      case LoopMode.off:
        repeatIcon = Icons.repeat_rounded;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingL,
        vertical: AppConstants.spacingM,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.shuffle_rounded),
            color: shuffleColor,
            onPressed: () => audioService.toggleShuffle(),
          ).animate().fadeIn(delay: 600.ms).scale(),
          IconButton(
            icon: const Icon(Icons.skip_previous_rounded),
            iconSize: 36,
            onPressed: () => audioService.previous(),
          ).animate().fadeIn(delay: 700.ms).scale(),
          GestureDetector(
            onTap: () {
              if (isPlaying) {
                audioService.pause();
              } else {
                audioService.play();
              }
            },
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 36,
                color: AppTheme.textPrimary,
              ),
            ),
          ).animate().fadeIn(delay: 800.ms).scale(),
          IconButton(
            icon: const Icon(Icons.skip_next_rounded),
            iconSize: 36,
            onPressed: () => audioService.next(),
          ).animate().fadeIn(delay: 900.ms).scale(),
          IconButton(
            icon: Icon(repeatIcon),
            color: repeatColor,
            onPressed: () => audioService.cycleLoopMode(),
          ).animate().fadeIn(delay: 1000.ms).scale(),
        ],
      ),
    );
  }

  Widget _buildExtraControls(AudioEngineService audioService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.devices_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No output devices available'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ).animate().fadeIn(delay: 1100.ms),
          IconButton(
            icon: const Icon(Icons.queue_music_rounded),
            onPressed: () {
              _showReorderableQueue(audioService);
            },
          ).animate().fadeIn(delay: 1200.ms),
          IconButton(
            icon: const Icon(Icons.equalizer_rounded),
            onPressed: () {
              _showEqualizer(audioService);
            },
          ).animate().fadeIn(delay: 1300.ms),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              final song = audioService.currentSong;
              if (song != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Now playing: ${song.title} by ${song.artist}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ).animate().fadeIn(delay: 1400.ms),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showMoreOptions() {
    final audioService = AudioEngineService();
    final currentSong = audioService.currentSong;

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
              leading: const Icon(Icons.playlist_add_rounded),
              title: const Text('Add to Playlist'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Playlist feature coming soon')),
                );
              },
            ),
            ListTile(
              leading: Icon(
                currentSong != null && isFavorite(ref, currentSong.id)
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
              ),
              title: const Text('Toggle Favorite'),
              onTap: () {
                Navigator.pop(context);
                if (currentSong != null) {
                  toggleFavorite(ref, currentSong.id);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('Song Info'),
              onTap: () {
                Navigator.pop(context);
                if (currentSong != null) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(currentSong.title),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Artist: ${currentSong.artist}'),
                          Text('Album: ${currentSong.album}'),
                          Text('Duration: ${currentSong.formattedDuration}'),
                          Text('Size: ${currentSong.formattedSize}'),
                          Text('Path: ${currentSong.uri}'),
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
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer_rounded),
              title: const Text('Sleep Timer'),
              onTap: () {
                Navigator.pop(context);
                _showSleepTimerDialog(audioService);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSleepTimerDialog(AudioEngineService audioService) {
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
              child: Text('Sleep Timer', style: AppTheme.headlineSmall),
            ),
            if (audioService.sleepTimerRemaining != null) ...[
              ListTile(
                leading: const Icon(Icons.timer_rounded, color: AppTheme.warningColor),
                title: Text(
                  'Remaining: ${_formatDuration(audioService.sleepTimerRemaining!)}',
                  style: const TextStyle(color: AppTheme.warningColor),
                ),
                onTap: () {
                  audioService.cancelSleepTimer();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sleep timer cancelled')),
                  );
                },
              ),
              const Divider(height: 1),
            ],
            ...AppConstants.sleepTimerOptions.map((minutes) => ListTile(
              title: Text('$minutes minutes'),
              onTap: () {
                audioService.setSleepTimer(Duration(minutes: minutes));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sleep timer set: $minutes minutes')),
                );
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showReorderableQueue(AudioEngineService audioService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: _ReorderableQueueSheet(audioService: audioService),
      ),
    );
  }

  void _showEqualizer(AudioEngineService audioService) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const EqualizerScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: AppConstants.normalAnimation,
      ),
    );
  }
}

/// Reorderable queue sheet with drag-to-reorder support.
class _ReorderableQueueSheet extends StatefulWidget {
  final AudioEngineService audioService;
  const _ReorderableQueueSheet({required this.audioService});

  @override
  State<_ReorderableQueueSheet> createState() => _ReorderableQueueSheetState();
}

class _ReorderableQueueSheetState extends State<_ReorderableQueueSheet> {
  @override
  Widget build(BuildContext context) {
    final audioService = widget.audioService;
    final queue = audioService.songQueue;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Queue (${queue.length} songs)', style: AppTheme.headlineSmall),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: queue.isEmpty
              ? const Center(child: Text('Queue is empty'))
              : ReorderableListView.builder(
                  itemCount: queue.length,
                  onReorder: (oldIndex, newIndex) {
                    // Adjust index for reorder
                    if (newIndex > oldIndex) newIndex--;
                    audioService.moveInQueue(oldIndex, newIndex);
                    setState(() {});
                  },
                  itemBuilder: (context, index) {
                    final song = queue[index];
                    final isCurrent = index == audioService.currentIndex;
                    return ListTile(
                      key: ValueKey(song.id),
                      leading: Icon(
                        isCurrent ? Icons.play_arrow_rounded : Icons.drag_handle_rounded,
                        color: isCurrent ? AppTheme.primaryColor : AppTheme.textTertiary,
                      ),
                      title: Text(
                        song.title,
                        style: AppTheme.titleMedium.copyWith(
                          color: isCurrent ? AppTheme.primaryColor : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(song.artist, style: AppTheme.bodySmall),
                      trailing: IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () async {
                          await audioService.removeFromQueue(index);
                          setState(() {});
                        },
                      ),
                      onTap: () async {
                        await audioService.seekToIndex(index);
                        await audioService.play();
                        if (context.mounted) Navigator.pop(context);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}


