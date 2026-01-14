import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'mood_entry.dart';

class MoodRepository {
  static const String boxName = 'mood_entries';

  Future<Box<MoodEntry>> _openBox() async {
    // Make sure adapter is registered (safe on hot-reload)
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(MoodEntryAdapter());
    }
    if (Hive.isBoxOpen(boxName)) return Hive.box<MoodEntry>(boxName);
    return Hive.openBox<MoodEntry>(boxName);
  }

  Future<void> add({
    required int mood,
    String? note,
    int? moodRating,
    List<String>? emotions,
    double? sleepHours,
    int? physicalActivityMinutes,
    int? socialInteractionLevel,
    int? productivityLevel,
  }) async {
    final box = await _openBox();
    final id = const Uuid().v4();
    final entry = MoodEntry(
      id: id,
      timestamp: DateTime.now(),
      mood: mood,
      note: note,
      moodRating: moodRating,
      emotions: emotions,
      sleepHours: sleepHours,
      physicalActivityMinutes: physicalActivityMinutes,
      socialInteractionLevel: socialInteractionLevel,
      productivityLevel: productivityLevel,
    );
    await box.put(id, entry);
  }

  Future<List<MoodEntry>> listAll() async {
    final box = await _openBox();
    return box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<List<MoodEntry>> listForLastDays(int days) async {
    final box = await _openBox();
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return box.values.where((e) => e.timestamp.isAfter(cutoff)).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<List<MoodEntry>> listForDateRange(DateTime start, DateTime end) async {
    final box = await _openBox();
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate =
        DateTime(end.year, end.month, end.day).add(const Duration(days: 1));
    return box.values
        .where((e) =>
            e.timestamp.isAfter(startDate) && e.timestamp.isBefore(endDate))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<List<MoodEntry>> listForLast30Days() async {
    return listForLastDays(30);
  }

  Future<List<MoodEntry>> listForLast7Days() async {
    return listForLastDays(7);
  }

  Future<void> delete(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }

  Future<void> clearAll() async {
    final box = await _openBox();
    await box.clear();
  }
}
