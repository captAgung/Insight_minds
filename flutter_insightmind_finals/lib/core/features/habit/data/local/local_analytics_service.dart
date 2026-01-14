import '../../domain/services/analytics_service.dart';
import 'habit_repository.dart';

class LocalAnalyticsService implements AnalyticsService {
  final HabitRepository habitRepository;
  LocalAnalyticsService(this.habitRepository);

  @override
  Future<double> getConsistencyRate({required String habitId, DateTimeRange? range}) async {
    final habits = await habitRepository.listAll();
    final habit = habits.firstWhere((h) => h.id == habitId, orElse: () => throw StateError('Habit not found'));
    if (habit.completedDates.isEmpty) return 0;
    final DateTime start = range?.start ?? habit.createdAt;
    final DateTime end = range?.end ?? DateTime.now();
    int days = end.difference(DateTime(start.year, start.month, start.day)).inDays + 1;
    if (days <= 0) return 0;
    final Set<String> uniqueDays = habit.completedDates
        .where((d) => !d.isBefore(DateTime(start.year, start.month, start.day)) && !d.isAfter(DateTime(end.year, end.month, end.day)))
        .map((d) => '${d.year}-${d.month}-${d.day}')
        .toSet();
    return uniqueDays.length / days;
  }

  @override
  Future<List<Duration>> getBestCompletionTimes({required String habitId, DateTimeRange? range}) async {
    // Without exact timestamps per completion, return empty for now.
    return <Duration>[];
  }

  @override
  Future<double> getHabitCorrelation(String habitIdA, String habitIdB, DateTimeRange range) async {
    // Minimal stub: correlation not implemented; return 0.
    return 0.0;
  }

  @override
  int calculateBestStreak(List<DateTime> completedDates) {
    if (completedDates.isEmpty) return 0;
    final dates = completedDates.map((d) => DateTime(d.year, d.month, d.day)).toList()
      ..sort((a, b) => a.compareTo(b));
    int best = 1;
    int current = 1;
    for (int i = 1; i < dates.length; i++) {
      if (dates[i].difference(dates[i - 1]).inDays == 1) {
        current++;
      } else if (dates[i] == dates[i - 1]) {
        // same day duplicate; ignore
      } else {
        if (current > best) best = current;
        current = 1;
      }
    }
    if (current > best) best = current;
    return best;
  }

  @override
  int calculateCurrentStreak(List<DateTime> completedDates) {
    if (completedDates.isEmpty) return 0;
    final today = DateTime.now();
    final dateOnly = DateTime(today.year, today.month, today.day);
    final sorted = completedDates.map((d) => DateTime(d.year, d.month, d.day)).toList()
      ..sort((a, b) => b.compareTo(a));
    int streak = 0;
    DateTime current = dateOnly;
    for (final d in sorted) {
      final dKey = DateTime(d.year, d.month, d.day);
      if (dKey == current) {
        streak++;
        current = current.subtract(const Duration(days: 1));
      } else if (dKey.isBefore(current)) {
        break;
      }
    }
    return streak;
  }
}


