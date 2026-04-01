import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart' hide SongModel;
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/audio_provider.dart';
import '../../../core/models/song_model.dart';
import '../../../core/services/audio_service.dart';

class MiniPlayer extends ConsumerStatefulWidget {
  const MiniPlayer({super.key});

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AppConstants.normalAnimation,
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = ref.watch(currentSongProvider);
    final isPlaying = ref.watch(isPlayingProvider).valueOrNull ?? false;
    final progress = ref.watch(progressProvider);

    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/now-playing');
          },
          child: Container(
            height: AppConstants.miniPlayerHeight,
            margin: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingM,
            ),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppTheme.surfaceColor,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor,
                  ),
                  minHeight: 2,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingM,
                    ),
                    child: Row(
                      children: [
                        _buildAlbumArt(currentSong),
                        const SizedBox(width: AppConstants.spacingM),
                        Expanded(
                          child: _buildSongInfo(currentSong),
                        ),
                        _buildControls(isPlaying),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumArt(SongModel song) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        color: AppTheme.surfaceColor,
      ),
      child: QueryArtworkWidget(
        id: int.tryParse(song.id) ?? 0,
        type: ArtworkType.AUDIO,
        nullArtworkWidget: const Icon(
          Icons.music_note_rounded,
          color: AppTheme.textSecondary,
          size: 24,
        ),
        artworkBorder: BorderRadius.circular(AppConstants.borderRadius),
        artworkFit: BoxFit.cover,
        artworkWidth: AppConstants.artworkCacheWidth.toDouble(),
        artworkHeight: AppConstants.artworkCacheHeight.toDouble(),
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildSongInfo(SongModel song) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          song.title,
          style: AppTheme.titleSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          song.artist,
          style: AppTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1);
  }

  Widget _buildControls(bool isPlaying) {
    final audioService = AudioEngineService();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded),
          iconSize: 24,
          onPressed: () => audioService.previous(),
        ).animate().fadeIn(delay: 200.ms).scale(),
        GestureDetector(
          onTap: () {
            if (isPlaying) {
              audioService.pause();
            } else {
              audioService.play();
            }
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 24,
              color: AppTheme.textPrimary,
            ),
          ),
        ).animate().fadeIn(delay: 300.ms).scale(),
        IconButton(
          icon: const Icon(Icons.skip_next_rounded),
          iconSize: 24,
          onPressed: () => audioService.next(),
        ).animate().fadeIn(delay: 400.ms).scale(),
      ],
    );
  }
}
