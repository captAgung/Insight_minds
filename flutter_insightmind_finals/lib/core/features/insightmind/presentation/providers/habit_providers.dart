import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../habit/data/local/habit_repository.dart';
import '../../../habit/data/local/habit_entry.dart';

final habitRepositoryProvider = Provider<HabitRepository>((ref) => HabitRepository());

final habitListProvider = FutureProvider<List<HabitEntry>>((ref) async {
  final repo = ref.watch(habitRepositoryProvider);
  return repo.listAll();
});

final isSavingHabitProvider = StateProvider<bool>((ref) => false);

