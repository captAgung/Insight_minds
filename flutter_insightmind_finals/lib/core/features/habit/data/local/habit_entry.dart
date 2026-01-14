import 'package:hive/hive.dart';

part 'habit_entry.g.dart';

@HiveType(typeId: 10)
class HabitEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  List<DateTime> completedDates; // dates when habit was completed

  HabitEntry({
    required this.id,
    required this.title,
    required this.createdAt,
    this.completedDates = const [],
  });

  bool isCompletedOn(DateTime date) {
    final key = _dateOnly(date);
    return completedDates.any((d) => _dateOnly(d) == key);
  }

  int getCurrentStreak() {
    if (completedDates.isEmpty) return 0;
    final sorted = completedDates.toList()..sort((a, b) => b.compareTo(a));
    final today = _dateOnly(DateTime.now());
    int streak = 0;
    DateTime? current = today;
    for (final d in sorted) {
      final dKey = _dateOnly(d);
      if (dKey == current) {
        streak++;
        current = current?.subtract(const Duration(days: 1));
      } else if (dKey.isBefore(current!)) {
        break;
      }
    }
    return streak;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

class HabitEntryAdapter extends TypeAdapter<HabitEntry> {
  @override
  final int typeId = 10;

  @override
  HabitEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HabitEntry(
      id: fields[0] as String,
      title: fields[1] as String,
      createdAt: fields[2] as DateTime,
      completedDates: (fields[3] as List).cast<DateTime>(),
    );
  }

  @override
  void write(BinaryWriter writer, HabitEntry obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.completedDates);
  }
}
