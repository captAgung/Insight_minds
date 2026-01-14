import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/history_repository.dart';
import '../../data/local/screening_record.dart';

/// WEEK6: Provider untuk mengakses repository riwayat
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository();
});     

/// WEEK6: Provider Future untuk meload semua riwayat (dipakai di HistoryPage)
final historyListProvider = FutureProvider<List<ScreeningRecord>>((ref) async {
  final repo = ref.watch(historyRepositoryProvider);
  return repo.getAll();
});