// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_point.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocationPointAdapter extends TypeAdapter<LocationPoint> {
  @override
  final int typeId = 0;

  @override
  LocationPoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocationPoint()
      ..latitude = fields[0] as String
      ..longitude = fields[1] as String
      ..speed = fields[2] as String;
  }

  @override
  void write(BinaryWriter writer, LocationPoint obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.latitude)
      ..writeByte(1)
      ..write(obj.longitude)
      ..writeByte(2)
      ..write(obj.speed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationPointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
