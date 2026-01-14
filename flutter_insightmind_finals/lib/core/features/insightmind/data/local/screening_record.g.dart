// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screening_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScreeningRecordAdapter extends TypeAdapter<ScreeningRecord> {
  @override
  final int typeId = 1;

  @override
  ScreeningRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScreeningRecord(
      id: fields[0] as String,
      timestamp: fields[1] as DateTime,
      score: fields[2] as int,
      riskLevel: fields[3] as String,
      note: fields[4] as String?,
      name: fields[5] as String,
      age: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ScreeningRecord obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.score)
      ..writeByte(3)
      ..write(obj.riskLevel)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.name)
      ..writeByte(6)
      ..write(obj.age);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScreeningRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
