// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_message.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AudioMessageAdapter extends TypeAdapter<AudioMessage> {
  @override
  final int typeId = 1;

  @override
  AudioMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AudioMessage(
      id: fields[0] as String,
      filePath: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AudioMessage obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.filePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
