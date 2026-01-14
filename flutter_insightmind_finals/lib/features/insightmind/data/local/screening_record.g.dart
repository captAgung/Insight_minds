part of 'screening_record.dart';
class ScreeningRecordAdapter extends TypeAdapter<ScreeningRecord> {
  @override
  final int typeId = 0;

  @override
  ScreeningRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScreeningRecord()
      ..id = fields[0] as String
      ..date = fields[1] as DateTime
      ..answers = (fields[2] as List).cast<int>();
  }

  @override
  void write(BinaryWriter writer, ScreeningRecord obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.answers);
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
