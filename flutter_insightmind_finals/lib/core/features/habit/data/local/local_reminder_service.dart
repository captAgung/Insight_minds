import '../../domain/services/reminder_service.dart';

class LocalReminderService implements ReminderService {
  @override
  Future<void> cancelReminder(String habitId) async {
    // Stub: integrate with flutter_local_notifications or WorkManager
  }

  @override
  Future<void> scheduleLocationReminder({required String habitId, required String geofenceId}) async {
    // Stub: integrate with geofencing plugin
  }

  @override
  Future<void> scheduleReminder({required String habitId, required DateTime time, List<int> weekdays = const []}) async {
    // Stub: schedule repeating notifications by weekdays
  }

  @override
  Future<void> snoozeReminder(String habitId, Duration duration) async {
    // Stub: re-schedule next notification after duration
  }
}


