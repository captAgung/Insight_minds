import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/schedule_repository.dart';
import '../../data/local/schedule_item.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository();
});

final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final scheduleListProvider = FutureProvider<List<ScheduleItem>>((ref) async {
  final repo = ref.watch(scheduleRepositoryProvider);
  final day = ref.watch(selectedDateProvider);
  return repo.listByDate(day);
});

/// Provider untuk mendapatkan semua tanggal yang punya schedule (untuk marking di kalender)
final datesWithSchedulesProvider = FutureProvider<Set<DateTime>>((ref) async {
  final repo = ref.watch(scheduleRepositoryProvider);
  return repo.getAllDatesWithSchedules();
});
