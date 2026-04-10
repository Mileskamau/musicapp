// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lyrics_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LyricsModelAdapter extends TypeAdapter<LyricsModel> {
  @override
  final int typeId = 4;

  @override
  LyricsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LyricsModel(
      songId: fields[0] as String,
      lyricsText: fields[1] as String?,
      lrcLines: (fields[2] as List?)?.cast<LyricLine>(),
      isUserProvided: fields[3] as bool? ?? false,
      source: fields[4] as int? ?? 0,
      fetchedAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LyricsModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.songId)
      ..writeByte(1)
      ..write(obj.lyricsText)
      ..writeByte(2)
      ..write(obj.lrcLines)
      ..writeByte(3)
      ..write(obj.isUserProvided)
      ..writeByte(4)
      ..write(obj.source)
      ..writeByte(5)
      ..write(obj.fetchedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LyricsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LyricLineAdapter extends TypeAdapter<LyricLine> {
  @override
  final int typeId = 5;

  @override
  LyricLine read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LyricLine(
      timestamp: fields[0] as Duration,
      text: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LyricLine obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.text);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LyricLineAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}