// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppLogModelAdapter extends TypeAdapter<AppLogModel> {
  @override
  final int typeId = 5;

  @override
  AppLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppLogModel(
      message: fields[0] as String,
      level: fields[1] as String,
      timestamp: fields[2] as DateTime,
      details: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AppLogModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.message)
      ..writeByte(1)
      ..write(obj.level)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.details);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
