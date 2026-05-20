// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sms_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SmsLogModelAdapter extends TypeAdapter<SmsLogModel> {
  @override
  final int typeId = 2;

  @override
  SmsLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SmsLogModel(
      id: fields[0] as String?,
      receiverNumber: fields[1] as String,
      message: fields[2] as String,
      status: fields[3] as String,
      simId: fields[4] as String?,
      createdAt: fields[5] as DateTime,
      errorMessage: fields[6] as String?,
      orgCode: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SmsLogModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.receiverNumber)
      ..writeByte(2)
      ..write(obj.message)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.simId)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.errorMessage)
      ..writeByte(7)
      ..write(obj.orgCode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmsLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
