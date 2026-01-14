import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/mood_repository.dart';
import '../../data/local/mood_entry.dart';

final moodRepositoryProvider = Provider<MoodRepository>((ref) => MoodRepository());

final moodListProvider = FutureProvider<List<MoodEntry>>((ref) async {
  final repo = ref.watch(moodRepositoryProvider);
  return repo.listAll();
});

final moodWeekProvider = FutureProvider<List<MoodEntry>>((ref) async {
  final repo = ref.watch(moodRepositoryProvider);
  return repo.listForLastDays(7);
});

final isSavingMoodProvider = StateProvider<bool>((ref) => false);
