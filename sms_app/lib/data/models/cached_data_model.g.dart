// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_data_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedDataModelAdapter extends TypeAdapter<CachedDataModel> {
  @override
  final int typeId = 4;

  @override
  CachedDataModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedDataModel(
      data: fields[0] as dynamic,
      timestamp: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CachedDataModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.data)
      ..writeByte(1)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedDataModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
