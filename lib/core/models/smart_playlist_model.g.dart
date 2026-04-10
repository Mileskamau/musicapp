// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_playlist_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SmartRuleAdapter extends TypeAdapter<SmartRule> {
  @override
  final int typeId = 6;

  @override
  SmartRule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SmartRule(
      fieldIndex: fields[0] as int,
      operatorIndex: fields[1] as int,
      value: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SmartRule obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.fieldIndex)
      ..writeByte(1)
      ..write(obj.operatorIndex)
      ..writeByte(2)
      ..write(obj.value);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmartRuleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SmartPlaylistRuleAdapter extends TypeAdapter<SmartPlaylistRule> {
  @override
  final int typeId = 7;

  @override
  SmartPlaylistRule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SmartPlaylistRule(
      rules: (fields[0] as List).cast<Map<String, dynamic>>(),
      logicIndex: fields[1] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, SmartPlaylistRule obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.rules)
      ..writeByte(1)
      ..write(obj.logicIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmartPlaylistRuleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}