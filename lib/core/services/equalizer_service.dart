import 'dart:async';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'audio_output_service.dart';

/// Service that manages the Android equalizer, bass boost, virtualizer,
/// and loudness enhancer effects from just_audio.
///
/// All settings are persisted via SharedPreferences and restored on init.
class EqualizerService {
  static final EqualizerService _instance = EqualizerService._internal();
  factory EqualizerService() => _instance;
  EqualizerService._internal();

  AndroidEqualizer? _equalizer;
  AndroidLoudnessEnhancer? _loudnessEffect;
  OutputDevice _currentDevice = OutputDevice.speaker();
  bool _deviceChanged = false;

  bool _isEnabled = false;
  String _currentPreset = 'Normal';
  List<double> _bandValues = [0.0, 0.0, 0.0, 0.0, 0.0];
  double _bassBoost = 0.0;
  double _virtualizer = 0.0;
  double _loudnessValue = 0.0;
  int _currentPresetIndex = 0;

  // Stream controllers for reactive state
  final _enabledController = StreamController<bool>.broadcast();
  final _presetController = StreamController<String>.broadcast();
  final _bandValuesController = StreamController<List<double>>.broadcast();
  final _bassBoostController = StreamController<double>.broadcast();
  final _virtualizerController = StreamController<double>.broadcast();
  final _loudnessController = StreamController<double>.broadcast();
  final _bandsController = StreamController<List<AndroidEqualizerBand>>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  // Getters
  bool get isEnabled => _isEnabled;
  String get currentPreset => _currentPreset;
  List<double> get bandValues => List.unmodifiable(_bandValues);
  double get bassBoost => _bassBoost;
  double get virtualizer => _virtualizer;
  double get loudnessEnhancer => _loudnessValue;
  int get currentPresetIndex => _currentPresetIndex;
  AndroidEqualizer? get equalizer => _equalizer;
  AndroidLoudnessEnhancer? get loudnessEffect => _loudnessEffect;

  // Streams
  Stream<bool> get enabledStream => _enabledController.stream;
  Stream<String> get presetStream => _presetController.stream;
  Stream<List<double>> get bandValuesStream => _bandValuesController.stream;
  Stream<double> get bassBoostStream => _bassBoostController.stream;
  Stream<double> get virtualizerStream => _virtualizerController.stream;
  Stream<double> get loudnessStream => _loudnessController.stream;
  Stream<List<AndroidEqualizerBand>> get bandsStream => _bandsController.stream;
  Stream<String> get errorStream => _errorController.stream;

  /// Initialize the equalizer with pre-created audio effects.
  /// The effects must already be attached to the AudioPlayer via AudioPipeline.
  /// Call [createEffects] before creating the AudioPlayer, then pass the
  /// effects to AudioPipeline, and finally call this method to load settings.
  Future<void> init(AndroidEqualizer equalizer, AndroidLoudnessEnhancer loudnessEffect) async {
    try {
      _equalizer = equalizer;
      _loudnessEffect = loudnessEffect;

      // Load saved settings
      await _loadSettings();

      // Apply saved settings
      await _applySettings();
    } catch (e) {
      _errorController.add('Failed to initialize equalizer: $e');
    }
  }

  /// Check if equalizer is available on this device.
  bool get isAvailable => _equalizer != null;

  /// Check if equalizer is supported with the current audio output.
  /// Equalizer is typically not supported with Bluetooth audio output.
  /// Returns false on iOS (not supported).
  bool isSupported() {
    if (!Platform.isAndroid) return false;
    if (_equalizer == null) return false;
    
    // Equalizer may not work properly with Bluetooth
    // This is a platform limitation
    return _currentDevice.type != OutputDeviceType.bluetooth;
  }

  /// Update the current audio output device to check for equalizer support.
  void updateCurrentDevice(OutputDevice device) {
    final wasSupported = isSupported();
    _currentDevice = device;
    final isNowSupported = isSupported();
    
    if (wasSupported != isNowSupported) {
      _errorController.add(
        isNowSupported 
          ? 'Equalizer is now available' 
          : 'Equalizer is not supported with current audio output',
      );
    }
  }

  /// Get the list of available equalizer bands.
  Future<List<AndroidEqualizerBand>?> getBands() async {
    if (_equalizer == null) return null;
    final params = await _equalizer!.parameters;
    return params.bands;
  }

  /// Enable or disable the equalizer.
  Future<void> setEnabled(bool enabled) async {
    if (!Platform.isAndroid || _equalizer == null) {
      return;
    }
    
    _isEnabled = enabled;
    _enabledController.add(_isEnabled);

    if (enabled) {
      if (!isSupported()) {
        return;
      }
      await _applySettings();
    } else {
      // Reset all bands to flat when disabled
      final bands = await getBands();
      if (bands != null) {
        for (final band in bands) {
          await band.setGain(0.0);
        }
      }
    }

    await _saveSettings();
  }

  /// Set the equalizer preset by name.
  Future<void> setPreset(String presetName) async {
    if (!Platform.isAndroid || !isSupported()) {
      return;
    }
    
    _currentPreset = presetName;

    if (AppConstants.equalizerPresets.containsKey(presetName)) {
      _bandValues = List.from(AppConstants.equalizerPresets[presetName]!);
      _currentPresetIndex = AppConstants.equalizerPresets.keys.toList().indexOf(presetName);
    }

    _presetController.add(_currentPreset);
    _bandValuesController.add(_bandValues);

    if (_isEnabled) {
      await _applyBandValues();
    }

    await _saveSettings();
  }

  /// Set the equalizer preset by index.
  Future<void> setPresetByIndex(int index) async {
    final presets = AppConstants.equalizerPresets.keys.toList();
    if (index >= 0 && index < presets.length) {
      await setPreset(presets[index]);
    }
  }

  /// Set a specific band value (in dB, range -12.0 to 12.0).
  Future<void> setBandValue(int bandIndex, double valueDb) async {
    if (!Platform.isAndroid || !isSupported()) return;
    if (bandIndex < 0 || bandIndex >= _bandValues.length) return;

    _bandValues[bandIndex] = valueDb;
    _currentPreset = 'Custom';
    _presetController.add(_currentPreset);
    _bandValuesController.add(_bandValues);

    if (_isEnabled && _equalizer != null) {
      final bands = await getBands();
      if (bands != null && bandIndex < bands.length) {
        // Convert dB to millibels (1 dB = 100 millibels)
        await bands[bandIndex].setGain(valueDb * 100);
      }
    }

    await _saveSettings();
  }

  /// Set the bass boost strength (0.0 to 1000.0).
  Future<void> setBassBoost(double value) async {
    _bassBoost = value.clamp(AppConstants.bassBoostMin, AppConstants.bassBoostMax);
    _bassBoostController.add(_bassBoost);
    await _saveSettings();
  }

  /// Set the virtualizer strength (0.0 to 1000.0).
  Future<void> setVirtualizer(double value) async {
    _virtualizer = value.clamp(AppConstants.virtualizerMin, AppConstants.virtualizerMax);
    _virtualizerController.add(_virtualizer);
    await _saveSettings();
  }

  /// Set the loudness enhancer value (in millibels).
  Future<void> setLoudnessEnhancer(double value) async {
    _loudnessValue = value.clamp(
      AppConstants.loudnessEnhancerMin,
      AppConstants.loudnessEnhancerMax,
    );
    _loudnessController.add(_loudnessValue);

    if (_loudnessEffect != null) {
      await _loudnessEffect!.setTargetGain(_loudnessValue);
    }

    await _saveSettings();
  }

  /// Reset all equalizer settings to defaults.
  Future<void> reset() async {
    _isEnabled = false;
    _currentPreset = 'Normal';
    _bandValues = [0.0, 0.0, 0.0, 0.0, 0.0];
    _bassBoost = 0.0;
    _virtualizer = 0.0;
    _loudnessValue = 0.0;
    _currentPresetIndex = 0;

    _enabledController.add(_isEnabled);
    _presetController.add(_currentPreset);
    _bandValuesController.add(_bandValues);
    _bassBoostController.add(_bassBoost);
    _virtualizerController.add(_virtualizer);
    _loudnessController.add(_loudnessValue);

    if (_equalizer != null) {
      final bands = await getBands();
      if (bands != null) {
        for (final band in bands) {
          await band.setGain(0.0);
        }
      }
    }

    await _saveSettings();
  }

  /// Apply the current band values to the native equalizer.
  Future<void> _applyBandValues() async {
    if (_equalizer == null) return;

    final bands = await getBands();
    if (bands == null) return;

    for (int i = 0; i < bands.length && i < _bandValues.length; i++) {
      await bands[i].setGain(_bandValues[i] * 100);
    }
  }

  /// Apply all saved settings to the native effects.
  Future<void> _applySettings() async {
    if (_isEnabled) {
      await _applyBandValues();
    }
  }

  /// Load settings from SharedPreferences.
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _isEnabled = prefs.getBool(AppConstants.equalizerEnabledKey) ?? false;
      _currentPreset = prefs.getString(AppConstants.equalizerPresetKey) ?? 'Normal';
      _bassBoost = prefs.getDouble(AppConstants.bassBoostKey) ?? 0.0;
      _virtualizer = prefs.getDouble(AppConstants.virtualizerKey) ?? 0.0;
      _loudnessValue = prefs.getDouble(AppConstants.loudnessEnhancerKey) ?? 0.0;

      // Load band values
      final bandValuesStr = prefs.getStringList(AppConstants.equalizerBandValuesKey);
      if (bandValuesStr != null && bandValuesStr.length == 5) {
        _bandValues = bandValuesStr.map((e) => double.tryParse(e) ?? 0.0).toList();
      } else if (AppConstants.equalizerPresets.containsKey(_currentPreset)) {
        _bandValues = List.from(AppConstants.equalizerPresets[_currentPreset]!);
      }

      // Update preset index
      _currentPresetIndex = AppConstants.equalizerPresets.keys.toList().indexOf(_currentPreset);
      if (_currentPresetIndex < 0) _currentPresetIndex = 0;
    } catch (e) {
      // If loading fails, use defaults
    }
  }

  /// Save settings to SharedPreferences.
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(AppConstants.equalizerEnabledKey, _isEnabled);
      await prefs.setString(AppConstants.equalizerPresetKey, _currentPreset);
      await prefs.setStringList(
        AppConstants.equalizerBandValuesKey,
        _bandValues.map((e) => e.toString()).toList(),
      );
      await prefs.setDouble(AppConstants.bassBoostKey, _bassBoost);
      await prefs.setDouble(AppConstants.virtualizerKey, _virtualizer);
      await prefs.setDouble(AppConstants.loudnessEnhancerKey, _loudnessValue);
    } catch (e) {
      _errorController.add('Failed to save equalizer settings: $e');
    }
  }

  /// Get available preset names.
  List<String> get availablePresets => AppConstants.equalizerPresets.keys.toList();

  /// Clean up resources.
  void dispose() {
    _enabledController.close();
    _presetController.close();
    _bandValuesController.close();
    _bassBoostController.close();
    _virtualizerController.close();
    _loudnessController.close();
    _bandsController.close();
    _errorController.close();
  }
}
