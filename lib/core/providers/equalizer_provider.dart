import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/equalizer_service.dart';

// Equalizer Service Provider
final equalizerServiceProvider = Provider<EqualizerService>((ref) {
  return EqualizerService();
});

// Equalizer Enabled Provider
final equalizerEnabledProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(equalizerServiceProvider);
  return service.enabledStream;
});

// Current Preset Provider
final currentPresetProvider = StreamProvider<String>((ref) {
  final service = ref.watch(equalizerServiceProvider);
  return service.presetStream;
});

// Band Values Provider
final bandValuesProvider = StreamProvider<List<double>>((ref) {
  final service = ref.watch(equalizerServiceProvider);
  return service.bandValuesStream;
});

// Bass Boost Provider
final bassBoostProvider = StreamProvider<double>((ref) {
  final service = ref.watch(equalizerServiceProvider);
  return service.bassBoostStream;
});

// Virtualizer Provider
final virtualizerProvider = StreamProvider<double>((ref) {
  final service = ref.watch(equalizerServiceProvider);
  return service.virtualizerStream;
});

// Loudness Enhancer Provider
final loudnessEnhancerProvider = StreamProvider<double>((ref) {
  final service = ref.watch(equalizerServiceProvider);
  return service.loudnessStream;
});

// Available Presets Provider
final availablePresetsProvider = Provider<List<String>>((ref) {
  final service = ref.watch(equalizerServiceProvider);
  return service.availablePresets;
});
