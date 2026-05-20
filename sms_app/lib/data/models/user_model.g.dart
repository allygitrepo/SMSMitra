// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      fullName: fields[0] as String,
      email: fields[1] as String,
      phoneNumber: fields[2] as String,
      password: fields[3] as String,
      deviceCode: fields[4] as String?,
      createdAt: fields[5] as String?,
      profilePath: fields[6] as String?,
      id: fields[7] as int?,
      whatsappInstanceKey: fields[8] as String?,
      whatsappProfileImage: fields[9] as String?,
      whatsappPhone: fields[10] as String?,
      whatsappName: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.fullName)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.phoneNumber)
      ..writeByte(3)
      ..write(obj.password)
      ..writeByte(4)
      ..write(obj.deviceCode)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.profilePath)
      ..writeByte(7)
      ..write(obj.id)
      ..writeByte(8)
      ..write(obj.whatsappInstanceKey)
      ..writeByte(9)
      ..write(obj.whatsappProfileImage)
      ..writeByte(10)
      ..write(obj.whatsappPhone)
      ..writeByte(11)
      ..write(obj.whatsappName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
