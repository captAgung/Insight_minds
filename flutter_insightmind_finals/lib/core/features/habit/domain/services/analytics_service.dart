abstract class AnalyticsService {
  Future<double> getConsistencyRate({required String habitId, DateTimeRange? range});
  Future<List<Duration>> getBestCompletionTimes({required String habitId, DateTimeRange? range});
  Future<double> getHabitCorrelation(String habitIdA, String habitIdB, DateTimeRange range);
  int calculateCurrentStreak(List<DateTime> completedDates);
  int calculateBestStreak(List<DateTime> completedDates);
}

class DateTimeRange {
  final DateTime start;
  final DateTime end;
  const DateTimeRange({required this.start, required this.end});
}


