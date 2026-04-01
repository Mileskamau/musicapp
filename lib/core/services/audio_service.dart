import 'dart:async';
import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song_model.dart';
import 'equalizer_service.dart';

/// Audio handler that implements [BaseAudioHandler] for background playback,
/// notification controls, media button handling, and audio focus management.
class AudioEngineService extends BaseAudioHandler {
  static final AudioEngineService _instance = AudioEngineService._internal();
  factory AudioEngineService() => _instance;

  // Create audio effects before the player so they can be attached via AudioPipeline
  final AndroidEqualizer _equalizer = AndroidEqualizer();
  final AndroidLoudnessEnhancer _loudnessEnhancer = AndroidLoudnessEnhancer();

  late final AudioPlayer _audioPlayer = AudioPlayer(
    audioPipeline: AudioPipeline(
      androidAudioEffects: [_equalizer, _loudnessEnhancer],
    ),
  );

  AudioEngineService._internal();

  final ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(children: []);

  bool _isInitialized = false;
  final List<StreamSubscription> _subscriptions = [];

  List<SongModel> _songQueue = [];
  int _currentIndex = 0;
  bool _isShuffleEnabled = false;
  LoopMode _loopMode = LoopMode.off;
  double _playbackSpeed = 1.0;
  double _volume = 1.0;

  // Stream controllers for custom state
  final _currentIndexController = StreamController<int>.broadcast();
  final _songQueueController = StreamController<List<SongModel>>.broadcast();
  final _shuffleController = StreamController<bool>.broadcast();
  final _loopModeController = StreamController<LoopMode>.broadcast();
  final _playbackSpeedController = StreamController<double>.broadcast();
  final _playbackErrorController = StreamController<String>.broadcast();

  // Sleep timer
  Timer? _sleepTimer;
  Duration? _sleepTimerRemaining;
  final _sleepTimerController = StreamController<Duration?>.broadcast();

  // Callbacks for tracking play counts
  Function(SongModel song)? onSongPlayed;

  // Getters
  AudioPlayer get songPlayer => _audioPlayer;
  List<SongModel> get songQueue => _songQueue;
  int get currentIndex => _currentIndex;
  bool get isShuffleEnabled => _isShuffleEnabled;
  LoopMode get loopMode => _loopMode;
  double get playbackSpeed => _playbackSpeed;
  double get songVolume => _volume;
  Duration? get sleepTimerRemaining => _sleepTimerRemaining;

  // Streams
  Stream<int> get currentIndexStream => _currentIndexController.stream;
  Stream<List<SongModel>> get songQueueStream => _songQueueController.stream;
  Stream<bool> get shuffleStream => _shuffleController.stream;
  Stream<LoopMode> get loopModeStream => _loopModeController.stream;
  Stream<double> get playbackSpeedStream => _playbackSpeedController.stream;
  Stream<String> get playbackErrorStream => _playbackErrorController.stream;
  Stream<Duration?> get sleepTimerStream => _sleepTimerController.stream;

  // Player state streams
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<bool> get playingStream => _audioPlayer.playingStream;
  Stream<ProcessingState> get processingStateStream => _audioPlayer.processingStateStream;

  // Current song - safe access with bounds checking
  SongModel? get currentSong {
    if (_songQueue.isEmpty) return null;
    if (_currentIndex < 0 || _currentIndex >= _songQueue.length) {
      return null;
    }
    return _songQueue[_currentIndex];
  }

  // Get current position
  Duration get currentPosition => _audioPlayer.position;

  // Get duration
  Duration? get songDuration => _audioPlayer.duration;

  // Check if playing
  bool get isSongPlaying => _audioPlayer.playing;

  // Check if buffering
  bool get isBuffering => _audioPlayer.processingState == ProcessingState.buffering;

  // Check if loading
  bool get isLoading => _audioPlayer.processingState == ProcessingState.loading;

  /// Initialize the audio engine with proper session configuration,
  /// audio focus handling, and media button events.
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      // Audio session may fail if platform channel is not ready on restart.
      // App should still launch without audio session.
      return;
    }

    // Initialize equalizer service with the pre-attached audio effects
    // Wrapped in try-catch: equalizer is optional, don't block playback
    try {
      await EqualizerService().init(_equalizer, _loudnessEnhancer);
    } catch (e) {
      // Equalizer not available on this device, continue without it
    }

    // Handle audio focus changes (pause on call/alarm, resume on regain)
    try {
      final session = await AudioSession.instance;
      _subscriptions.add(
        session.interruptionEventStream.listen((event) {
          if (event.begin) {
            switch (event.type) {
              case AudioInterruptionType.duck:
                _audioPlayer.setVolume(_volume * 0.5);
                break;
              case AudioInterruptionType.pause:
              case AudioInterruptionType.unknown:
                pause();
                break;
            }
          } else {
            switch (event.type) {
              case AudioInterruptionType.duck:
                _audioPlayer.setVolume(_volume);
                break;
              case AudioInterruptionType.pause:
                break;
              case AudioInterruptionType.unknown:
                break;
            }
          }
        }),
      );
    } catch (e) {
      // Non-fatal
    }

    // Handle becoming noisy (headphone disconnect)
    try {
      final session = await AudioSession.instance;
      _subscriptions.add(
        session.becomingNoisyEventStream.listen((_) {
          pause();
        }),
      );
    } catch (e) {
      // Non-fatal
    }

    // Listen to player state changes and update notification
    _subscriptions.add(
      _audioPlayer.playerStateStream.listen((state) {
        _updatePlaybackState();
        if (state.processingState == ProcessingState.completed) {
          _onSongComplete();
        }
      }),
    );

    // Listen to index changes
    _subscriptions.add(
      _audioPlayer.currentIndexStream.listen((index) {
        if (index != null && index != _currentIndex) {
          _currentIndex = index;
          _currentIndexController.add(_currentIndex);
          _updateMediaItem();
          _trackSongPlayed();
        }
      }),
    );

    // Handle playback errors
    _subscriptions.add(
      _audioPlayer.playbackEventStream.listen(
        (event) {},
        onError: (Object error, StackTrace stackTrace) {
          final errorMsg = error.toString();
          _playbackErrorController.add(errorMsg);
          _skipToNextOnFileError();
        },
      ),
    );

    _isInitialized = true;
  }

  /// Load a playlist of songs for playback.
  /// Validates file existence and skips missing files.
  Future<void> loadPlaylist(List<SongModel> songs, {int initialIndex = 0}) async {
    // Filter out songs with missing files
    final validSongs = <SongModel>[];
    final validIndices = <int>[];

    for (int i = 0; i < songs.length; i++) {
      if (songs[i].fileExists) {
        validSongs.add(songs[i]);
        validIndices.add(i);
      }
    }

    if (validSongs.isEmpty) {
      _playbackErrorController.add('No playable files found');
      return;
    }

    // Adjust initial index to point to the nearest valid song
    int adjustedIndex = 0;
    for (int i = 0; i < validIndices.length; i++) {
      if (validIndices[i] >= initialIndex) {
        adjustedIndex = i;
        break;
      }
    }

    _songQueue = List.from(validSongs);
    _currentIndex = adjustedIndex;

    final audioSources = validSongs.map((song) {
      return AudioSource.uri(
        Uri.file(song.uri),
        tag: MediaItem(
          id: song.id,
          album: song.album,
          title: song.title,
          artist: song.artist,
          duration: Duration(milliseconds: song.duration),
          artUri: song.albumArt != null ? Uri.file(song.albumArt!) : null,
        ),
      );
    }).toList();

    await _playlist.clear();
    await _playlist.addAll(audioSources);

    await _audioPlayer.setAudioSource(
      _playlist,
      initialIndex: adjustedIndex,
    );

    _songQueueController.add(_songQueue);
    _currentIndexController.add(_currentIndex);
    _updateMediaItem();
  }

  /// Play audio.
  @override
  Future<void> play() async {
    await _audioPlayer.play();
  }

  /// Pause audio.
  @override
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  /// Stop audio and cancel sleep timer.
  @override
  Future<void> stop() async {
    _cancelSleepTimer();
    await _audioPlayer.stop();
    playbackState.add(playbackState.value.copyWith(
      controls: [],
      processingState: AudioProcessingState.idle,
    ));
  }

  /// Skip to next track.
  @override
  Future<void> skipToNext() async {
    await next();
  }

  /// Skip to previous track.
  @override
  Future<void> skipToPrevious() async {
    await previous();
  }

  /// Seek to a specific position.
  @override
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  /// Skip to a specific queue index.
  @override
  Future<void> skipToQueueItem(int index) async {
    await seekToIndex(index);
  }

  /// Next track
  Future<void> next() async {
    if (_audioPlayer.hasNext) {
      await _audioPlayer.seekToNext();
    } else if (_loopMode == LoopMode.all && _songQueue.isNotEmpty) {
      await _audioPlayer.seek(const Duration(milliseconds: 0), index: 0);
    }
  }

  /// Previous track.
  /// If more than 3 seconds in, restarts current song.
  Future<void> previous() async {
    if (_audioPlayer.position.inSeconds > 3) {
      await _audioPlayer.seek(Duration.zero);
      return;
    }
    if (_audioPlayer.hasPrevious) {
      await _audioPlayer.seekToPrevious();
    } else if (_loopMode == LoopMode.all && _songQueue.isNotEmpty) {
      await _audioPlayer.seek(const Duration(milliseconds: 0), index: _songQueue.length - 1);
    }
  }

  /// Seek to a specific index in the queue.
  Future<void> seekToIndex(int index) async {
    if (index >= 0 && index < _songQueue.length) {
      await _audioPlayer.seek(const Duration(milliseconds: 0), index: index);
    }
  }

  /// Toggle shuffle mode.
  Future<void> toggleShuffle() async {
    _isShuffleEnabled = !_isShuffleEnabled;
    _shuffleController.add(_isShuffleEnabled);
    await _audioPlayer.setShuffleModeEnabled(_isShuffleEnabled);
  }

  /// Set loop mode.
  Future<void> setLoopMode(LoopMode mode) async {
    _loopMode = mode;
    _loopModeController.add(_loopMode);
    await _audioPlayer.setLoopMode(mode);
  }

  /// Cycle through loop modes: off -> all -> one -> off.
  Future<void> cycleLoopMode() async {
    switch (_loopMode) {
      case LoopMode.off:
        await setLoopMode(LoopMode.all);
        break;
      case LoopMode.all:
        await setLoopMode(LoopMode.one);
        break;
      case LoopMode.one:
        await setLoopMode(LoopMode.off);
        break;
    }
  }

  /// Set playback speed (0.5 - 2.0).
  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed.clamp(0.5, 2.0);
    _playbackSpeedController.add(_playbackSpeed);
    await _audioPlayer.setSpeed(_playbackSpeed);
  }

  /// Set volume (0.0 - 1.0).
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _audioPlayer.setVolume(_volume);
  }

  /// Add a song to the end of the queue.
  Future<void> addToQueue(SongModel song) async {
    if (!song.fileExists) return;
    _songQueue.add(song);
    await _playlist.add(AudioSource.uri(
      Uri.file(song.uri),
      tag: MediaItem(
        id: song.id,
        album: song.album,
        title: song.title,
        artist: song.artist,
        duration: Duration(milliseconds: song.duration),
        artUri: song.albumArt != null ? Uri.file(song.albumArt!) : null,
      ),
    ));
    _songQueueController.add(_songQueue);
  }

  /// Remove a song from the queue by index.
  Future<void> removeFromQueue(int index) async {
    if (index >= 0 && index < _songQueue.length) {
      _songQueue.removeAt(index);
      await _playlist.removeAt(index);

      if (index < _currentIndex) {
        _currentIndex--;
      } else if (index == _currentIndex) {
        _currentIndex = _currentIndex.clamp(0, _songQueue.length - 1);
      }

      _songQueueController.add(_songQueue);
      _currentIndexController.add(_currentIndex);
    }
  }

  /// Move a song within the queue (for drag-to-reorder).
  Future<void> moveInQueue(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || newIndex < 0 || oldIndex >= _songQueue.length || newIndex >= _songQueue.length) return;
    if (oldIndex == newIndex) return;

    final song = _songQueue.removeAt(oldIndex);
    _songQueue.insert(newIndex, song);

    await _playlist.move(oldIndex, newIndex);

    // Update current index to track the moved song
    if (oldIndex == _currentIndex) {
      // The currently playing song was moved
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      // A song before current was moved to after current
      _currentIndex--;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      // A song after current was moved to before current
      _currentIndex++;
    }

    _songQueueController.add(_songQueue);
    _currentIndexController.add(_currentIndex);
  }

  /// Clear the entire queue.
  Future<void> clearQueue() async {
    _songQueue.clear();
    await _playlist.clear();
    _currentIndex = 0;
    _songQueueController.add(_songQueue);
    _currentIndexController.add(_currentIndex);
  }

  /// Set a sleep timer for the given duration.
  void setSleepTimer(Duration duration) {
    _cancelSleepTimer();
    _sleepTimerRemaining = duration;
    _sleepTimerController.add(_sleepTimerRemaining);

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sleepTimerRemaining == null || _sleepTimerRemaining!.inSeconds <= 0) {
        _cancelSleepTimer();
        pause();
        return;
      }
      _sleepTimerRemaining = _sleepTimerRemaining! - const Duration(seconds: 1);
      _sleepTimerController.add(_sleepTimerRemaining);
    });
  }

  /// Cancel the sleep timer.
  void cancelSleepTimer() {
    _cancelSleepTimer();
  }

  void _cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerRemaining = null;
    _sleepTimerController.add(null);
  }

  /// Handle song completion.
  void _onSongComplete() {
    // Handled by index change listener
  }

  /// Track that a song was played (called when a new song starts).
  /// Tracks the song at the previous index (the one that just finished).
  void _trackSongPlayed() {
    if (_songQueue.isEmpty) return;
    // Track the song that was playing before the index changed.
    // _currentIndex is now the NEW song, so the finished song is at _currentIndex - 1
    // But if we're at index 0 and just loaded, we track index 0
    final finishedIndex = _currentIndex > 0 ? _currentIndex - 1 : 0;
    if (finishedIndex >= 0 && finishedIndex < _songQueue.length) {
      final song = _songQueue[finishedIndex];
      onSongPlayed?.call(song);
    }
  }

  /// Skip to next track when current file has an error.
  /// Guards against infinite loops by limiting removal attempts.
  int _fileErrorCount = 0;
  static const int _maxFileErrors = 10;

  Future<void> _skipToNextOnFileError() async {
    if (_songQueue.isEmpty) return;

    _fileErrorCount++;
    if (_fileErrorCount > _maxFileErrors) {
      _fileErrorCount = 0;
      await stop();
      _playbackErrorController.add('Too many playback errors – stopped');
      return;
    }

    final problematicSong = currentSong;
    if (problematicSong != null) {
      _playbackErrorController.add('File not found – removed from queue');
      final idx = _currentIndex;
      await removeFromQueue(idx);

      if (_songQueue.isNotEmpty) {
        final nextIndex = idx.clamp(0, _songQueue.length - 1);
        await seekToIndex(nextIndex);
        await play();
      } else {
        await stop();
      }
    }
  }

  /// Update the media item for the notification.
  Future<void> _updateMediaItem() async {
    final song = currentSong;
    if (song == null) return;

    mediaItem.add(MediaItem(
      id: song.id,
      album: song.album,
      title: song.title,
      artist: song.artist,
      duration: Duration(milliseconds: song.duration),
      artUri: song.albumArt != null && song.albumArt!.isNotEmpty
          ? Uri.file(song.albumArt!)
          : null,
    ));
  }

  /// Update playback state for audio_service notification controls.
  void _updatePlaybackState() {
    final playing = _audioPlayer.playing;
    final processingState = _audioPlayer.processingState;

    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: _mapProcessingState(processingState),
      playing: playing,
      updatePosition: _audioPlayer.position,
      bufferedPosition: _audioPlayer.bufferedPosition,
      speed: _audioPlayer.speed,
    ));
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  /// Clean up resources.
  void disposeEngine() {
    _cancelSleepTimer();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _isInitialized = false;
    EqualizerService().dispose();
    _audioPlayer.dispose();
    _currentIndexController.close();
    _songQueueController.close();
    _shuffleController.close();
    _loopModeController.close();
    _playbackSpeedController.close();
    _playbackErrorController.close();
    _sleepTimerController.close();
  }
}
