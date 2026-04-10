import 'dart:ui';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'background_settings.g.dart';

enum BackgroundMode {
  none,
  custom,
  albumArt,
  blurredAlbumArt,
}

@HiveType(typeId: 3)
class BackgroundSettings extends Equatable {
  @HiveField(0)
  final int modeIndex;
  
  @HiveField(1)
  final String? customImagePath;
  
  @HiveField(2)
  final double blurIntensity;
  
  @HiveField(3)
  final double darkOverlayOpacity;
  
  @HiveField(4)
  final bool enableParallax;
  
  @HiveField(5)
  final bool syncWithAlbumColors;
  
  @HiveField(6)
  final bool enableParticles;
  
  @HiveField(7)
  final String? lockedAlbumArtPath;
  
  @HiveField(8)
  final bool enableTimeBasedBackground;
  
  @HiveField(9)
  final String? morningImagePath;
  
  @HiveField(10)
  final String? afternoonImagePath;
  
  @HiveField(11)
  final String? eveningImagePath;
  
  @HiveField(12)
  final String? nightImagePath;

  BackgroundSettings({
    this.modeIndex = 0,
    this.customImagePath,
    this.blurIntensity = 10.0,
    this.darkOverlayOpacity = 0.5,
    this.enableParallax = true,
    this.syncWithAlbumColors = false,
    this.enableParticles = false,
    this.lockedAlbumArtPath,
    this.enableTimeBasedBackground = false,
    this.morningImagePath,
    this.afternoonImagePath,
    this.eveningImagePath,
    this.nightImagePath,
  });

  BackgroundMode get mode => BackgroundMode.values[modeIndex];
  
  BackgroundSettings copyWith({
    int? modeIndex,
    String? customImagePath,
    double? blurIntensity,
    double? darkOverlayOpacity,
    bool? enableParallax,
    bool? syncWithAlbumColors,
    bool? enableParticles,
    String? lockedAlbumArtPath,
    bool? enableTimeBasedBackground,
    String? morningImagePath,
    String? afternoonImagePath,
    String? eveningImagePath,
    String? nightImagePath,
  }) {
    return BackgroundSettings(
      modeIndex: modeIndex ?? this.modeIndex,
      customImagePath: customImagePath ?? this.customImagePath,
      blurIntensity: blurIntensity ?? this.blurIntensity,
      darkOverlayOpacity: darkOverlayOpacity ?? this.darkOverlayOpacity,
      enableParallax: enableParallax ?? this.enableParallax,
      syncWithAlbumColors: syncWithAlbumColors ?? this.syncWithAlbumColors,
      enableParticles: enableParticles ?? this.enableParticles,
      lockedAlbumArtPath: lockedAlbumArtPath ?? this.lockedAlbumArtPath,
      enableTimeBasedBackground: enableTimeBasedBackground ?? this.enableTimeBasedBackground,
      morningImagePath: morningImagePath ?? this.morningImagePath,
      afternoonImagePath: afternoonImagePath ?? this.afternoonImagePath,
      eveningImagePath: eveningImagePath ?? this.eveningImagePath,
      nightImagePath: nightImagePath ?? this.nightImagePath,
    );
  }

  @override
  List<Object?> get props => [
        modeIndex,
        customImagePath,
        blurIntensity,
        darkOverlayOpacity,
        enableParallax,
        syncWithAlbumColors,
        enableParticles,
        lockedAlbumArtPath,
        enableTimeBasedBackground,
        morningImagePath,
        afternoonImagePath,
        eveningImagePath,
        nightImagePath,
      ];
}