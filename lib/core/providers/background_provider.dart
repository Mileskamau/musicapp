import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/background_settings.dart';
import '../constants/app_constants.dart';

enum PerformanceTier { low, mid, high }

final performanceTierProvider = StateProvider<PerformanceTier>((ref) => PerformanceTier.high);

final batterySaverProvider = StateProvider<BatterySaverMode>((ref) => BatterySaverMode.off);

enum BatterySaverMode { off, auto, on }

final backgroundSettingsProvider =
    StateNotifierProvider<BackgroundSettingsNotifier, BackgroundSettings>((ref) {
  return BackgroundSettingsNotifier(ref);
});

class BackgroundSettingsNotifier extends StateNotifier<BackgroundSettings> {
  final Ref ref;
  
  BackgroundSettingsNotifier(this.ref) : super(BackgroundSettings()) {
    _loadSettings();
    _detectPerformanceTier();
  }

  void _detectPerformanceTier() {
    // Auto-detect would happen here based on device info
    // For now, default to high
    ref.read(performanceTierProvider.notifier).state = PerformanceTier.high;
  }

  Future<void> _loadSettings() async {
    try {
      final box = await Hive.openBox<BackgroundSettings>(AppConstants.backgroundBox);
      final settings = box.get('settings');
      if (settings != null) {
        state = settings;
      }
    } catch (e) {
      // Failed to load settings, use defaults
    }
  }

  Future<void> _saveSettings() async {
    try {
      final box = await Hive.openBox<BackgroundSettings>(AppConstants.backgroundBox);
      await box.put('settings', state);
    } catch (e) {
      // Failed to save settings
    }
  }

  void setMode(BackgroundMode mode) {
    state = state.copyWith(modeIndex: mode.index);
    _saveSettings();
  }

  void setCustomImagePath(String? path) {
    state = state.copyWith(customImagePath: path);
    _saveSettings();
  }

  void setBlurIntensity(double value) {
    state = state.copyWith(blurIntensity: value);
    _saveSettings();
  }

  void setDarkOverlayOpacity(double value) {
    state = state.copyWith(darkOverlayOpacity: value);
    _saveSettings();
  }

  void setEnableParallax(bool value) {
    state = state.copyWith(enableParallax: value);
    _saveSettings();
  }

  void setSyncWithAlbumColors(bool value) {
    state = state.copyWith(syncWithAlbumColors: value);
    _saveSettings();
  }

  void setEnableParticles(bool value) {
    state = state.copyWith(enableParticles: value);
    _saveSettings();
  }

  void setLockedAlbumArtPath(String? path) {
    state = state.copyWith(lockedAlbumArtPath: path);
    _saveSettings();
  }

  void setEnableTimeBasedBackground(bool value) {
    state = state.copyWith(enableTimeBasedBackground: value);
    _saveSettings();
  }

  void setTimeBasedImages({
    String? morning,
    String? afternoon,
    String? evening,
    String? night,
  }) {
    state = state.copyWith(
      morningImagePath: morning,
      afternoonImagePath: afternoon,
      eveningImagePath: evening,
      nightImagePath: night,
    );
    _saveSettings();
  }

  void clearCustomImage() {
    state = BackgroundSettings(
      modeIndex: state.modeIndex,
      blurIntensity: state.blurIntensity,
      darkOverlayOpacity: state.darkOverlayOpacity,
      enableParallax: state.enableParallax,
      syncWithAlbumColors: state.syncWithAlbumColors,
      enableParticles: state.enableParticles,
    );
    _saveSettings();
  }

  void applyPerformanceSettings() {
    final tier = ref.read(performanceTierProvider);
    final batteryMode = ref.read(batterySaverProvider);
    
    if (batteryMode == BatterySaverMode.on || 
        (batteryMode == BatterySaverMode.auto && _isLowBattery())) {
      state = state.copyWith(
        enableParticles: false,
        blurIntensity: 5.0,
        enableParallax: false,
        syncWithAlbumColors: false,
      );
      return;
    }
    
    switch (tier) {
      case PerformanceTier.low:
        state = state.copyWith(
          enableParticles: false,
          blurIntensity: 5.0,
          enableParallax: false,
          syncWithAlbumColors: false,
        );
        break;
      case PerformanceTier.mid:
        state = state.copyWith(
          enableParticles: true,
          blurIntensity: 15.0,
          enableParallax: true,
          syncWithAlbumColors: true,
        );
        break;
      case PerformanceTier.high:
        // Use full settings
        break;
    }
  }

  bool _isLowBattery() {
    return false;
  }

  void setPerformanceTierOverride(PerformanceTier tier) {
    ref.read(performanceTierProvider.notifier).state = tier;
    applyPerformanceSettings();
  }

  void setBatterySaverMode(BatterySaverMode mode) {
    ref.read(batterySaverProvider.notifier).state = mode;
    applyPerformanceSettings();
  }
}
