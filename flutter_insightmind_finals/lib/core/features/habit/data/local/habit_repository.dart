import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'habit_entry.dart';

class HabitRepository {
  static const String boxName = 'habit_entries';

  Future<Box<HabitEntry>> _openBox() async {
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(HabitEntryAdapter());
    }
    if (Hive.isBoxOpen(boxName)) return Hive.box<HabitEntry>(boxName);
    return Hive.openBox<HabitEntry>(boxName);
  }

  Future<void> add({required String title}) async {
    final box = await _openBox();
    final id = const Uuid().v4();
    final entry = HabitEntry(
      id: id,
      title: title,
      createdAt: DateTime.now(),
    );
    await box.put(id, entry);
  }

  Future<String> createHabit({required String title, String? description}) async {
    final box = await _openBox();
    final id = const Uuid().v4();
    final entry = HabitEntry(
      id: id,
      title: title,
      createdAt: DateTime.now(),
    );
    await box.put(id, entry);
    return id;
  }

  Future<void> updateHabit({required String habitId, String? title}) async {
    final box = await _openBox();
    final habit = box.get(habitId);
    if (habit == null) return;
    if (title != null) habit.title = title;
    await habit.save();
  }

  Future<List<HabitEntry>> listAll() async {
    final box = await _openBox();
    return box.values.toList()
      ..sort((a, b) => a.title.compareTo(b.title));
  }

  Future<void> toggleCompletion(String habitId, DateTime date) async {
    final box = await _openBox();
    final habit = box.get(habitId);
    if (habit == null) return;
    final dateKey = DateTime(date.year, date.month, date.day);
    final existing = habit.completedDates.firstWhere(
      (d) => DateTime(d.year, d.month, d.day) == dateKey,
      orElse: () => DateTime.fromMillisecondsSinceEpoch(0),
    );
    if (existing.year == 0) {
      habit.completedDates.add(date);
    } else {
      habit.completedDates.remove(existing);
    }
    await habit.save();
  }

  Future<void> logCompletion({required String habitId, required DateTime date, int amount = 1}) async {
    final box = await _openBox();
    final habit = box.get(habitId);
    if (habit == null) return;
    final dateOnly = DateTime(date.year, date.month, date.day);
    final already = habit.completedDates.any((d) => d.year == dateOnly.year && d.month == dateOnly.month && d.day == dateOnly.day);
    if (!already) {
      habit.completedDates.add(dateOnly);
      await habit.save();
    }
  }

  Future<void> unlogCompletion({required String habitId, required DateTime date}) async {
    final box = await _openBox();
    final habit = box.get(habitId);
    if (habit == null) return;
    final dateOnly = DateTime(date.year, date.month, date.day);
    habit.completedDates.removeWhere((d) => d.year == dateOnly.year && d.month == dateOnly.month && d.day == dateOnly.day);
    await habit.save();
  }

  Future<void> delete(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }

  Future<void> clearAll() async {
    final box = await _openBox();
    await box.clear();
  }

  Future<List<HabitEntry>> filterHabits({List<String>? tags, bool? onlyToday, bool? overdue}) async {
    // Tags not supported in current model; ignore for now.
    final habits = await listAll();
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    Iterable<HabitEntry> res = habits;
    if (onlyToday == true) {
      res = res.where((h) => h.isCompletedOn(todayOnly));
    }
    if (overdue == true) {
      res = res.where((h) => !h.isCompletedOn(todayOnly));
    }
    return res.toList();
  }

  Future<String> exportDataToJson() async {
    final box = await _openBox();
    final items = box.values.map((e) => {
      'id': e.id,
      'title': e.title,
      'createdAt': e.createdAt.toIso8601String(),
      'completedDates': e.completedDates.map((d) => d.toIso8601String()).toList(),
    }).toList();
    return jsonEncode({'habits': items});
  }

  Future<void> importDataFromJson(String json) async {
    // Intentionally left minimal to avoid JSON parser dependency here.
    // Implement with your chosen JSON source in application layer.
  }
}

