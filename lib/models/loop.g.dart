// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loop.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LoopAdapter extends TypeAdapter<Loop> {
  @override
  final typeId = 5;

  @override
  Loop read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Loop(
      id: fields[0] as String,
      type: fields[1] as TimerType,
      duration: (fields[2] as num).toInt(),
      startTime: fields[3] as DateTime,
      endTime: fields[4] as DateTime?,
      completed: fields[5] == null ? false : fields[5] as bool,
      skipped: fields[6] == null ? false : fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Loop obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.duration)
      ..writeByte(3)
      ..write(obj.startTime)
      ..writeByte(4)
      ..write(obj.endTime)
      ..writeByte(5)
      ..write(obj.completed)
      ..writeByte(6)
      ..write(obj.skipped);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoopAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
