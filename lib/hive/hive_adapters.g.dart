// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_adapters.dart';

// **************************************************************************
// AdaptersGenerator
// **************************************************************************

class PomodoroPresetAdapter extends TypeAdapter<PomodoroPreset> {
  @override
  final typeId = 0;

  @override
  PomodoroPreset read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PomodoroPreset(
      id: fields[0] as String,
      name: fields[1] as String,
      focusDuration: (fields[2] as num).toInt(),
      breakDuration: (fields[3] as num).toInt(),
      longFocusDuration: (fields[4] as num).toInt(),
      longBreakDuration: (fields[5] as num).toInt(),
      cyclesBeforeLongBreak: fields[6] == null ? 4 : (fields[6] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, PomodoroPreset obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.focusDuration)
      ..writeByte(3)
      ..write(obj.breakDuration)
      ..writeByte(4)
      ..write(obj.longFocusDuration)
      ..writeByte(5)
      ..write(obj.longBreakDuration)
      ..writeByte(6)
      ..write(obj.cyclesBeforeLongBreak);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PomodoroPresetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SessionAdapter extends TypeAdapter<Session> {
  @override
  final typeId = 1;

  @override
  Session read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Session(
      id: fields[0] as String,
      userId: fields[1] as String,
      name: fields[10] as String,
      targetLoops: (fields[11] as num).toInt(),
      startTime: fields[4] as DateTime,
      loops: fields[12] == null ? const [] : (fields[12] as List).cast<Loop>(),
      currentLoopIndex: fields[13] == null ? 0 : (fields[13] as num).toInt(),
      endTime: fields[5] as DateTime?,
      presetName: fields[6] as String?,
      label: fields[7] as String?,
      progressNote: fields[8] as String?,
      completed: fields[9] == null ? false : fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Session obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(4)
      ..write(obj.startTime)
      ..writeByte(5)
      ..write(obj.endTime)
      ..writeByte(6)
      ..write(obj.presetName)
      ..writeByte(7)
      ..write(obj.label)
      ..writeByte(8)
      ..write(obj.progressNote)
      ..writeByte(9)
      ..write(obj.completed)
      ..writeByte(10)
      ..write(obj.name)
      ..writeByte(11)
      ..write(obj.targetLoops)
      ..writeByte(12)
      ..write(obj.loops)
      ..writeByte(13)
      ..write(obj.currentLoopIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final typeId = 2;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      id: fields[0] as String,
      email: fields[1] as String,
      name: fields[2] as String?,
      dailyGoal: fields[3] == null ? 120 : (fields[3] as num).toInt(),
      streak: fields[4] == null ? 0 : (fields[4] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.dailyGoal)
      ..writeByte(4)
      ..write(obj.streak);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TimerTypeAdapter extends TypeAdapter<TimerType> {
  @override
  final typeId = 3;

  @override
  TimerType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TimerType.focus;
      case 1:
        return TimerType.breakTime;
      default:
        return TimerType.focus;
    }
  }

  @override
  void write(BinaryWriter writer, TimerType obj) {
    switch (obj) {
      case TimerType.focus:
        writer.writeByte(0);
      case TimerType.breakTime:
        writer.writeByte(1);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SoundTypeAdapter extends TypeAdapter<SoundType> {
  @override
  final typeId = 4;

  @override
  SoundType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SoundType.bell;
      case 1:
        return SoundType.digital;
      case 2:
        return SoundType.bird;
      case 3:
        return SoundType.none;
      case 4:
        return SoundType.custom;
      default:
        return SoundType.bell;
    }
  }

  @override
  void write(BinaryWriter writer, SoundType obj) {
    switch (obj) {
      case SoundType.bell:
        writer.writeByte(0);
      case SoundType.digital:
        writer.writeByte(1);
      case SoundType.bird:
        writer.writeByte(2);
      case SoundType.none:
        writer.writeByte(3);
      case SoundType.custom:
        writer.writeByte(4);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SoundTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
