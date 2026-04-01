// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SongModelAdapter extends TypeAdapter<SongModel> {
  @override
  final int typeId = 0;

  @override
  SongModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SongModel(
      id: fields[0] as String,
      title: fields[1] as String,
      artist: fields[2] as String,
      album: fields[3] as String,
      albumId: fields[4] as String,
      uri: fields[5] as String,
      albumArt: fields[6] as String?,
      duration: fields[7] as int,
      size: fields[8] as int,
      displayName: fields[9] as String?,
      mimeType: fields[10] as String?,
      dateAdded: fields[11] as int,
      dateModified: fields[12] as int,
      composer: fields[13] as String?,
      genre: fields[14] as String?,
      track: fields[15] as int,
      year: fields[16] as int,
      isFavorite: fields[17] as bool,
      playCount: fields[18] as int,
      lastPlayed: fields[19] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SongModel obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.artist)
      ..writeByte(3)
      ..write(obj.album)
      ..writeByte(4)
      ..write(obj.albumId)
      ..writeByte(5)
      ..write(obj.uri)
      ..writeByte(6)
      ..write(obj.albumArt)
      ..writeByte(7)
      ..write(obj.duration)
      ..writeByte(8)
      ..write(obj.size)
      ..writeByte(9)
      ..write(obj.displayName)
      ..writeByte(10)
      ..write(obj.mimeType)
      ..writeByte(11)
      ..write(obj.dateAdded)
      ..writeByte(12)
      ..write(obj.dateModified)
      ..writeByte(13)
      ..write(obj.composer)
      ..writeByte(14)
      ..write(obj.genre)
      ..writeByte(15)
      ..write(obj.track)
      ..writeByte(16)
      ..write(obj.year)
      ..writeByte(17)
      ..write(obj.isFavorite)
      ..writeByte(18)
      ..write(obj.playCount)
      ..writeByte(19)
      ..write(obj.lastPlayed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
