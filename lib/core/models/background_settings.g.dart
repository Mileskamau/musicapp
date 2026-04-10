// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'background_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BackgroundSettingsAdapter extends TypeAdapter<BackgroundSettings> {
  @override
  final int typeId = 3;

  @override
  BackgroundSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BackgroundSettings(
      modeIndex: fields[0] as int? ?? 0,
      customImagePath: fields[1] as String?,
      blurIntensity: fields[2] as double? ?? 10.0,
      darkOverlayOpacity: fields[3] as double? ?? 0.5,
      enableParallax: fields[4] as bool? ?? true,
      syncWithAlbumColors: fields[5] as bool? ?? false,
      enableParticles: fields[6] as bool? ?? false,
      lockedAlbumArtPath: fields[7] as String?,
      enableTimeBasedBackground: fields[8] as bool? ?? false,
      morningImagePath: fields[9] as String?,
      afternoonImagePath: fields[10] as String?,
      eveningImagePath: fields[11] as String?,
      nightImagePath: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BackgroundSettings obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.modeIndex)
      ..writeByte(1)
      ..write(obj.customImagePath)
      ..writeByte(2)
      ..write(obj.blurIntensity)
      ..writeByte(3)
      ..write(obj.darkOverlayOpacity)
      ..writeByte(4)
      ..write(obj.enableParallax)
      ..writeByte(5)
      ..write(obj.syncWithAlbumColors)
      ..writeByte(6)
      ..write(obj.enableParticles)
      ..writeByte(7)
      ..write(obj.lockedAlbumArtPath)
      ..writeByte(8)
      ..write(obj.enableTimeBasedBackground)
      ..writeByte(9)
      ..write(obj.morningImagePath)
      ..writeByte(10)
      ..write(obj.afternoonImagePath)
      ..writeByte(11)
      ..write(obj.eveningImagePath)
      ..writeByte(12)
      ..write(obj.nightImagePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackgroundSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}