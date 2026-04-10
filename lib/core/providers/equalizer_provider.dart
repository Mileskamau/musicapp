import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/equalizer_service.dart';
import '../services/audio_output_service.dart';

// Audio Output Service Provider
final audioOutputServiceProvider = Provider<AudioOutputService>((ref) {
  return AudioOutputService();
});

// Current Output Device Provider
final currentOutputDeviceProvider = StreamProvider<OutputDevice>((ref) {
  final service = ref.watch(audioOutputServiceProvider);
  return service.currentDeviceStream;
});

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

// Equalizer Supported Provider - checks if equalizer is available for current audio output
final equalizerSupportedProvider = StreamProvider<bool>((ref) async* {
  final eqService = ref.watch(equalizerServiceProvider);
  
  // Initial check - return false for iOS
  if (!Platform.isAndroid) {
    yield false;
    return;
  }
  
  yield eqService.isSupported();
  
  // Listen to audio output changes
  ref.listen<AsyncValue<OutputDevice>>(currentOutputDeviceProvider, (prev, next) {
    next.whenData((device) {
      eqService.updateCurrentDevice(device);
    });
  });
});
