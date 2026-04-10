import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import '../constants/app_constants.dart';
import 'equalizer_service.dart';

class AudioEngineService {
  static final AudioEngineService _instance = AudioEngineService._internal();
  factory AudioEngineService() => _instance;

  final AndroidEqualizer _equalizer = AndroidEqualizer();
  final AndroidLoudnessEnhancer _loudnessEnhancer = AndroidLoudnessEnhancer();

  late final AudioPlayer _audioPlayer;

  AudioEngineService._internal() {
    _audioPlayer = AudioPlayer(
      audioPipeline: AudioPipeline(
        androidAudioEffects: [_equalizer, _loudnessEnhancer],
      ),
    );
  }

  final ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(children: []);

  bool _isInitialized = false;
  final List<StreamSubscription> _subscriptions = [];

  List<SongModel> _songQueue = [];
  int _currentIndex = 0;
  bool _isShuffleEnabled = false;
  LoopMode _loopMode = LoopMode.off;
  double _playbackSpeed = 1.0;
  double _volume = 1.0;

  final _currentIndexController = StreamController<int>.broadcast();
  final _songQueueController = StreamController<List<SongModel>>.broadcast();
  final _shuffleController = StreamController<bool>.broadcast();
  final _loopModeController = StreamController<LoopMode>.broadcast();
  final _playbackSpeedController = StreamController<double>.broadcast();
  final _playbackErrorController = StreamController<String>.broadcast();

  Timer? _sleepTimer;
  Duration? _sleepTimerRemaining;
  final _sleepTimerController = StreamController<Duration?>.broadcast();

  Function(SongModel song)? onSongPlayed;

  AudioPlayer get songPlayer => _audioPlayer;
  List<SongModel> get songQueue => _songQueue;
  int get currentIndex => _currentIndex;
  bool get isShuffleEnabled => _isShuffleEnabled;
  LoopMode get loopMode => _loopMode;
  double get playbackSpeed => _playbackSpeed;
  double get songVolume => _volume;
  Duration? get sleepTimerRemaining => _sleepTimerRemaining;

  Stream<int> get currentIndexStream => _currentIndexController.stream;
  Stream<List<SongModel>> get songQueueStream => _songQueueController.stream;
  Stream<bool> get shuffleStream => _shuffleController.stream;
  Stream<LoopMode> get loopModeStream => _loopModeController.stream;
  Stream<double> get playbackSpeedStream => _playbackSpeedController.stream;
  Stream<String> get playbackErrorStream => _playbackErrorController.stream;
  Stream<Duration?> get sleepTimerStream => _sleepTimerController.stream;

  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<bool> get playingStream => _audioPlayer.playingStream;
  Stream<ProcessingState> get processingStateStream => _audioPlayer.processingStateStream;

  SongModel? get currentSong {
    if (_songQueue.isEmpty) return null;
    if (_currentIndex < 0 || _currentIndex >= _songQueue.length) {
      return null;
    }
    return _songQueue[_currentIndex];
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _subscriptions.add(_audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _handlePlaybackCompletion();
      }
    }));

    _subscriptions.add(_audioPlayer.playingStream.listen((playing) {
      if (playing && currentSong != null) {
        onSongPlayed?.call(currentSong!);
      }
    }));

    _isInitialized = true;
  }

  Future<void> setQueue(List<SongModel> songs, {int initialIndex = 0}) async {
    _songQueue = songs;
    _currentIndex = initialIndex;
    
    final audioSources = songs.map((song) => AudioSource.uri(
      Uri.parse(song.uri),
      tag: MediaItem(
        id: song.id,
        title: song.title,
        artist: song.artist,
        album: song.album,
        duration: Duration(milliseconds: song.duration),
        artUri: song.albumArt != null ? Uri.file(song.albumArt!) : null,
      ),
    )).toList();

    await _playlist.addAll(audioSources);
    await _audioPlayer.setAudioSource(_playlist, initialIndex: initialIndex);

    _songQueueController.add(_songQueue);
    _currentIndexController.add(_currentIndex);
  }

  Future<void> loadPlaylist(List<SongModel> songs, {int initialIndex = 0}) async {
    await setQueue(songs, initialIndex: initialIndex);
    await play();
  }

  Future<void> play() async {
    await _audioPlayer.play();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  Future<void> playNext() async {
    if (_songQueue.isEmpty) return;
    
    if (_isShuffleEnabled) {
      _currentIndex = _getRandomIndex();
    } else if (_currentIndex < _songQueue.length - 1) {
      _currentIndex++;
    } else if (_loopMode == LoopMode.all) {
      _currentIndex = 0;
    } else {
      return;
    }

    await _audioPlayer.seek(Duration.zero, index: _currentIndex);
    await _audioPlayer.play();
    _currentIndexController.add(_currentIndex);
  }

  Future<void> playPrevious() async {
    if (_songQueue.isEmpty) return;
    
    if (_audioPlayer.position.inSeconds > 3) {
      await _audioPlayer.seek(Duration.zero);
    } else if (_isShuffleEnabled) {
      _currentIndex = _getRandomIndex();
    } else if (_currentIndex > 0) {
      _currentIndex--;
    } else if (_loopMode == LoopMode.all) {
      _currentIndex = _songQueue.length - 1;
    } else {
      await _audioPlayer.seek(Duration.zero);
      return;
    }

    await _audioPlayer.seek(Duration.zero, index: _currentIndex);
    await _audioPlayer.play();
    _currentIndexController.add(_currentIndex);
  }

  int _getRandomIndex() {
    if (_songQueue.length <= 1) return 0;
    int newIndex;
    do {
      newIndex = DateTime.now().millisecondsSinceEpoch % _songQueue.length;
    } while (newIndex == _currentIndex && _songQueue.length > 1);
    return newIndex;
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _audioPlayer.setVolume(_volume);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed.clamp(0.5, 2.0);
    await _audioPlayer.setSpeed(_playbackSpeed);
    _playbackSpeedController.add(_playbackSpeed);
  }

  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;
    _shuffleController.add(_isShuffleEnabled);
  }

  void toggleLoopMode() {
    switch (_loopMode) {
      case LoopMode.off:
        _loopMode = LoopMode.all;
        break;
      case LoopMode.all:
        _loopMode = LoopMode.one;
        break;
      case LoopMode.one:
        _loopMode = LoopMode.off;
        break;
    }
    _audioPlayer.setLoopMode(_loopMode);
    _loopModeController.add(_loopMode);
  }

  void _handlePlaybackCompletion() {
    switch (_loopMode) {
      case LoopMode.one:
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.play();
        break;
      case LoopMode.all:
        playNext();
        break;
      case LoopMode.off:
        if (_currentIndex < _songQueue.length - 1) {
          playNext();
        }
        break;
    }
  }

  Future<void> playSongAt(int index) async {
    if (index < 0 || index >= _songQueue.length) return;
    
    _currentIndex = index;
    await _audioPlayer.seek(Duration.zero, index: index);
    await _audioPlayer.play();
    _currentIndexController.add(_currentIndex);
  }

  Future<void> addToQueue(SongModel song) async {
    _songQueue.add(song);
    await _playlist.add(AudioSource.uri(
      Uri.parse(song.uri),
      tag: MediaItem(
        id: song.id,
        title: song.title,
        artist: song.artist,
        album: song.album,
        duration: Duration(milliseconds: song.duration),
      ),
    ));
    _songQueueController.add(_songQueue);
  }

  Future<void> setSleepTimer(Duration duration) async {
    _sleepTimer?.cancel();
    _sleepTimerRemaining = duration;
    _sleepTimerController.add(_sleepTimerRemaining);
    
    _sleepTimer = Timer(duration, () async {
      await pause();
      _sleepTimerRemaining = null;
      _sleepTimerController.add(null);
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sleepTimerRemaining == null) {
        timer.cancel();
        return;
      }
      _sleepTimerRemaining = _sleepTimerRemaining! - const Duration(seconds: 1);
      _sleepTimerController.add(_sleepTimerRemaining);
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimerRemaining = null;
    _sleepTimerController.add(null);
  }

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

  Future<void> next() async {
    if (_audioPlayer.hasNext) {
      await _audioPlayer.seekToNext();
    } else if (_loopMode == LoopMode.all && _songQueue.isNotEmpty) {
      await _audioPlayer.seek(const Duration(milliseconds: 0), index: 0);
    }
  }

  Future<void> seekToIndex(int index) async {
    if (index >= 0 && index < _songQueue.length) {
      await _audioPlayer.seek(const Duration(milliseconds: 0), index: index);
    }
  }

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

  Future<void> setLoopMode(LoopMode mode) async {
    _loopMode = mode;
    _loopModeController.add(_loopMode);
    await _audioPlayer.setLoopMode(mode);
  }

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

  Future<void> moveInQueue(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || newIndex < 0 || oldIndex >= _songQueue.length || newIndex >= _songQueue.length) return;
    if (oldIndex == newIndex) return;

    final song = _songQueue.removeAt(oldIndex);
    _songQueue.insert(newIndex, song);

    await _playlist.move(oldIndex, newIndex);

    if (oldIndex == _currentIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex--;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex++;
    }

    _songQueueController.add(_songQueue);
    _currentIndexController.add(_currentIndex);
  }

  Future<void> dispose() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _sleepTimer?.cancel();
    await _audioPlayer.dispose();
    await _currentIndexController.close();
    await _songQueueController.close();
    await _shuffleController.close();
    await _loopModeController.close();
    await _playbackSpeedController.close();
    await _playbackErrorController.close();
    await _sleepTimerController.close();
  }
}

class MediaItem {
  final String id;
  final String title;
  final String? artist;
  final String? album;
  final Duration? duration;
  final Uri? artUri;

  MediaItem({
    required this.id,
    required this.title,
    this.artist,
    this.album,
    this.duration,
    this.artUri,
  });
}
