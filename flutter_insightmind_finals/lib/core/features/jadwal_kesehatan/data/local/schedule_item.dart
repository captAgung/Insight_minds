import 'package:hive/hive.dart';
part 'schedule_item.g.dart';

@HiveType(typeId: 7)
class ScheduleItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date; // only date (no time zone), time can be optional

  @HiveField(2)
  String title;

  @HiveField(3)
  String? note;


  @HiveField(4)
  bool isDone;

  ScheduleItem({
    required this.id,
    required this.date,
    required this.title,
    this.note,
    this.isDone = false,
  });
}

class ScheduleItemAdapter extends TypeAdapter<ScheduleItem> {
  @override
  final int typeId = 7;

  @override
  ScheduleItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScheduleItem(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      title: fields[2] as String,
      note: fields[3] as String?,
      isDone: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ScheduleItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.note)
      ..writeByte(4)
      ..write(obj.isDone);
  }
}
