abstract class ReminderService {
  Future<void> scheduleReminder({required String habitId, required DateTime time, List<int> weekdays = const []});
  Future<void> cancelReminder(String habitId);
  Future<void> snoozeReminder(String habitId, Duration duration);
  Future<void> scheduleLocationReminder({required String habitId, required String geofenceId});
}


