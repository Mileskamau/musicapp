import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song_model.dart';
import '../services/audio_service.dart';

// Audio Service Provider
final audioServiceProvider = Provider<AudioEngineService>((ref) {
  return AudioEngineService();
});

// Current Song Provider - properly emits on index changes and queue updates
final currentSongProvider = Provider<SongModel?>((ref) {
  final currentIndex = ref.watch(currentIndexProvider).valueOrNull ?? 0;
  final queue = ref.watch(queueProvider).valueOrNull ?? [];

  if (currentIndex >= 0 && currentIndex < queue.length) {
    return queue[currentIndex];
  }
  return null;
});

// Queue Provider
final queueProvider = StreamProvider<List<SongModel>>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.songQueueStream;
});

// Is Playing Provider
final isPlayingProvider = StreamProvider<bool>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.playingStream;
});

// Position Provider
final positionProvider = StreamProvider<Duration>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.positionStream;
});

// Duration Provider
final durationProvider = StreamProvider<Duration?>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.durationStream;
});

// Shuffle Provider
final shuffleProvider = StreamProvider<bool>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.shuffleStream;
});

// Loop Mode Provider
final loopModeProvider = StreamProvider<LoopMode>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.loopModeStream;
});

// Playback Speed Provider
final playbackSpeedProvider = StreamProvider<double>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.playbackSpeedStream;
});

// Player State Provider
final playerStateProvider = StreamProvider<PlayerState>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.playerStateStream;
});

// Processing State Provider
final processingStateProvider = StreamProvider<ProcessingState>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.processingStateStream;
});

// Current Index Provider
final currentIndexProvider = StreamProvider<int>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.currentIndexStream;
});

// Progress Provider
final progressProvider = Provider<double>((ref) {
  final position = ref.watch(positionProvider).value ?? Duration.zero;
  final duration = ref.watch(durationProvider).value ?? Duration.zero;

  if (duration.inMilliseconds == 0) return 0.0;
  return position.inMilliseconds / duration.inMilliseconds;
});

// Formatted Position Provider
final formattedPositionProvider = Provider<String>((ref) {
  final position = ref.watch(positionProvider).value ?? Duration.zero;
  final minutes = position.inMinutes;
  final seconds = (position.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
});

// Formatted Duration Provider
final formattedDurationProvider = Provider<String>((ref) {
  final duration = ref.watch(durationProvider).value ?? Duration.zero;
  final minutes = duration.inMinutes;
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
});

// Has Next Provider
final hasNextProvider = Provider<bool>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  final currentIndex = ref.watch(currentIndexProvider).value ?? 0;
  final queue = ref.watch(queueProvider).value ?? [];

  return currentIndex < queue.length - 1 || audioService.loopMode == LoopMode.all;
});

// Has Previous Provider
final hasPreviousProvider = Provider<bool>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  final currentIndex = ref.watch(currentIndexProvider).value ?? 0;

  return currentIndex > 0 || audioService.loopMode == LoopMode.all;
});

// Is Buffering Provider
final isBufferingProvider = Provider<bool>((ref) {
  final processingState = ref.watch(processingStateProvider).value;
  return processingState == ProcessingState.buffering;
});

// Is Loading Provider
final isLoadingProvider = Provider<bool>((ref) {
  final processingState = ref.watch(processingStateProvider).value;
  return processingState == ProcessingState.loading;
});

// Sleep Timer Remaining Provider
final sleepTimerProvider = StreamProvider<Duration?>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.sleepTimerStream;
});

// Playback Error Provider
final playbackErrorProvider = StreamProvider<String>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.playbackErrorStream;
});
