import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/habit_mood_correlation_service.dart';
import '../../../mood/presentation/providers/mood_providers.dart';
import '../providers/habit_providers.dart';

final habitMoodCorrelationServiceProvider = Provider<HabitMoodCorrelationService>(
  (ref) => HabitMoodCorrelationService(),
);

final habitMoodCorrelationProvider = FutureProvider<List<CorrelationResult>>((ref) async {
  final habits = await ref.watch(habitListProvider.future);
  final moodEntries = await ref.watch(moodWeekProvider.future);
  final service = ref.watch(habitMoodCorrelationServiceProvider);

  return service.analyzeAllHabits(
    habits: habits,
    moodEntries: moodEntries,
    daysToAnalyze: 30,
  );
});

final mostPositiveHabitsProvider = FutureProvider<List<CorrelationResult>>((ref) async {
  final habits = await ref.watch(habitListProvider.future);
  final moodEntries = await ref.watch(moodWeekProvider.future);
  final service = ref.watch(habitMoodCorrelationServiceProvider);

  return service.getMostPositiveHabits(
    habits: habits,
    moodEntries: moodEntries,
    daysToAnalyze: 30,
  );
});

