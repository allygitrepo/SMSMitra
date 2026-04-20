// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue_request_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QueueRequestModelAdapter extends TypeAdapter<QueueRequestModel> {
  @override
  final int typeId = 3;

  @override
  QueueRequestModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QueueRequestModel(
      path: fields[0] as String,
      method: fields[1] as String,
      data: (fields[2] as Map).cast<dynamic, dynamic>(),
      createdAt: fields[3] as DateTime,
      retryCount: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, QueueRequestModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.path)
      ..writeByte(1)
      ..write(obj.method)
      ..writeByte(2)
      ..write(obj.data)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.retryCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueueRequestModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
