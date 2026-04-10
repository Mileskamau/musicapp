import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musiq/core/models/lyrics_model.dart';
import 'package:musiq/core/models/song_model.dart';
import 'package:musiq/core/services/lyrics_service.dart';
import 'package:musiq/core/providers/audio_provider.dart';
import 'package:musiq/core/theme/app_theme.dart';
import 'package:musiq/core/constants/app_constants.dart';

final currentLyricsProvider = FutureProvider.family<LyricsModel?, String>((ref, songId) async {
  final lyricsService = ref.watch(lyricsServiceProvider);
  final song = ref.watch(currentSongProvider);
  if (song == null) return null;
  return lyricsService.fetchLyrics(song);
});

final lyricsAutoScrollProvider = StateProvider<bool>((ref) => true);

class LyricsViewer extends ConsumerStatefulWidget {
  final SongModel song;

  const LyricsViewer({super.key, required this.song});

  @override
  ConsumerState<LyricsViewer> createState() => _LyricsViewerState();
}

class _LyricsViewerState extends ConsumerState<LyricsViewer> {
  final ScrollController _scrollController = ScrollController();
  LyricsModel? _lyrics;
  bool _isLoading = true;
  int _currentLineIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadLyrics();
    _setupPositionListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _setupPositionListener() {
    ref.listen<AsyncValue<Duration>>(positionProvider, (previous, next) {
      if (next.hasValue && _lyrics?.hasLrc == true) {
        _updateCurrentLine(next.value!);
      }
    });
  }

  void _updateCurrentLine(Duration position) {
    if (_lyrics?.lrcLines == null) return;

    int newIndex = -1;
    for (int i = 0; i < _lyrics!.lrcLines!.length; i++) {
      if (_lyrics!.lrcLines![i].timestamp <= position) {
        newIndex = i;
      } else {
        break;
      }
    }

    if (newIndex != _currentLineIndex && newIndex >= 0) {
      setState(() {
        _currentLineIndex = newIndex;
      });

      if (ref.read(lyricsAutoScrollProvider) && newIndex >= 0) {
        _scrollToLine(newIndex);
      }
    }
  }

  void _scrollToLine(int index) {
    if (!_scrollController.hasClients) return;
    final itemHeight = 60.0;
    final targetOffset = index * itemHeight - 100;
    _scrollController.animateTo(
      targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: AppConstants.normalAnimation,
      curve: Curves.easeOut,
    );
  }

  Future<void> _loadLyrics() async {
    setState(() => _isLoading = true);
    
    final lyricsService = ref.read(lyricsServiceProvider);
    final lyrics = await lyricsService.fetchLyrics(widget.song);
    
    if (mounted) {
      setState(() {
        _lyrics = lyrics;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_lyrics == null || !_lyrics!.hasLyrics) {
      return _buildNoLyricsView();
    }

    if (_lyrics!.hasLrc) {
      return _buildSyncLyricsView();
    }

    return _buildPlainLyricsView();
  }

  Widget _buildNoLyricsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lyrics_outlined,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              'No lyrics available',
              style: AppTheme.titleMedium.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              'Try searching manually or add your own lyrics',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textTertiary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingL),
            ElevatedButton.icon(
              onPressed: () => _showAddLyricsDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Lyrics'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncLyricsView() {
    final lines = _lyrics!.lrcLines!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingM,
            vertical: AppConstants.spacingS,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Synchronized Lyrics',
                style: AppTheme.labelMedium,
              ),
              Row(
                children: [
                  Text(
                    'Auto-scroll',
                    style: AppTheme.labelSmall,
                  ),
                  Switch(
                    value: ref.watch(lyricsAutoScrollProvider),
                    onChanged: (value) {
                      ref.read(lyricsAutoScrollProvider.notifier).state = value;
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
            itemCount: lines.length,
            itemBuilder: (context, index) {
              final line = lines[index];
              final isActive = index == _currentLineIndex;

              return AnimatedContainer(
                duration: AppConstants.fastAnimation,
                padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingS),
                child: AnimatedDefaultTextStyle(
                  duration: AppConstants.fastAnimation,
                  style: AppTheme.bodyLarge.copyWith(
                    color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    fontSize: isActive ? 18 : 16,
                  ),
                  child: Text(
                    line.text,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlainLyricsView() {
    final text = _lyrics!.lyricsText!;
    final lines = text.split('\n');

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      itemCount: lines.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingXS),
          child: Text(
            lines[index],
            style: AppTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  void _showAddLyricsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddLyricsBottomSheet(song: widget.song),
    );
  }
}

class AddLyricsBottomSheet extends ConsumerStatefulWidget {
  final SongModel song;

  const AddLyricsBottomSheet({super.key, required this.song});

  @override
  ConsumerState<AddLyricsBottomSheet> createState() => _AddLyricsBottomSheetState();
}

class _AddLyricsBottomSheetState extends ConsumerState<AddLyricsBottomSheet> {
  final TextEditingController _lyricsController = TextEditingController();
  bool _isLrcFormat = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _lyricsController.dispose();
    super.dispose();
  }

  Future<void> _saveLyrics() async {
    if (_lyricsController.text.isEmpty) return;

    setState(() => _isSaving = true);

    final lyricsService = ref.read(lyricsServiceProvider);
    await lyricsService.saveUserLyrics(
      widget.song,
      _lyricsController.text,
      isLrc: _isLrcFormat,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lyrics saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppConstants.spacingL,
        right: AppConstants.spacingL,
        top: AppConstants.spacingL,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppConstants.spacingL,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Lyrics', style: AppTheme.headlineSmall),
          const SizedBox(height: AppConstants.spacingM),
          Row(
            children: [
              Text('LRC format', style: AppTheme.labelMedium),
              Switch(
                value: _isLrcFormat,
                onChanged: (value) => setState(() => _isLrcFormat = value),
                activeColor: AppTheme.primaryColor,
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingS),
          TextField(
            controller: _lyricsController,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: _isLrcFormat 
                  ? '[00:12.00]First line\n[00:17.50]Second line'
                  : 'Enter lyrics here...',
              filled: true,
              fillColor: AppTheme.surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveLyrics,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}