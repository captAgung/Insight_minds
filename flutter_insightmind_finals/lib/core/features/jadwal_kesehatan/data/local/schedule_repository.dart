import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'schedule_item.dart';

class ScheduleRepository {
  static const String boxName = 'schedule_items';

  Future<Box<ScheduleItem>> _openBox() async {
    if (Hive.isBoxOpen(boxName)) return Hive.box<ScheduleItem>(boxName);
    return Hive.openBox<ScheduleItem>(boxName);
  }

  Future<List<ScheduleItem>> listByDate(DateTime day) async {
    final box = await _openBox();
    final key = _dateOnly(day);
    return box.values.where((e) => _dateOnly(e.date) == key).toList()
      ..sort((a, b) => a.title.compareTo(b.title));
  }

  Future<void> add(
      {required DateTime date, required String title, String? note}) async {
    final box = await _openBox();
    final id = const Uuid().v4();
    final item = ScheduleItem(id: id, date: date, title: title, note: note);
    await box.put(id, item);
  }

  Future<void> toggle(String id) async {
    final box = await _openBox();
    final item = box.get(id);
    if (item == null) return;
    item.isDone = !item.isDone;
    await item.save();
  }

  Future<void> delete(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }

  Future<void> clearAll() async {
    final box = await _openBox();
    await box.clear();
  }

  Future<List<ScheduleItem>> listAll() async {
    final box = await _openBox();
    return box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get all dates that have schedules (for calendar marking)
  Future<Set<DateTime>> getAllDatesWithSchedules() async {
    final box = await _openBox();
    final dates = <DateTime>{};
    for (final item in box.values) {
      final dateOnly = DateTime(item.date.year, item.date.month, item.date.day);
      dates.add(dateOnly);
    }
    return dates;
  }

  String _dateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String();
}
