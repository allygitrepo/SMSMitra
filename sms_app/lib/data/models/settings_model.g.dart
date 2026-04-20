// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsModelAdapter extends TypeAdapter<SettingsModel> {
  @override
  final int typeId = 1;

  @override
  SettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsModel(
      activeSimId: fields[0] as String?,
      dailySmsLimit: fields[1] as int,
      themeMode: fields[2] as String,
      isLoggedIn: fields[3] == null ? false : fields[3] as bool,
      limitPeriod: fields[4] == null ? 'day' : fields[4] as String,
      simPriority: fields[5] == null ? [] : (fields[5] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, SettingsModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.activeSimId)
      ..writeByte(1)
      ..write(obj.dailySmsLimit)
      ..writeByte(2)
      ..write(obj.themeMode)
      ..writeByte(3)
      ..write(obj.isLoggedIn)
      ..writeByte(4)
      ..write(obj.limitPeriod)
      ..writeByte(5)
      ..write(obj.simPriority);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
