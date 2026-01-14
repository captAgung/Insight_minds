import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/risk_score.dart';

class RiskScoreRepository {
  static const String boxName = 'risk_scores';

  Future<Box<Map>> _openBox() async {
    if (Hive.isBoxOpen(boxName)) return Hive.box<Map>(boxName);
    return Hive.openBox<Map>(boxName);
  }

  Future<void> save(RiskScore score) async {
    final box = await _openBox();
    final id = const Uuid().v4();
    await box.put(id, score.toJson());
  }

  Future<List<RiskScore>> getAll() async {
    final box = await _openBox();
    final scores = <RiskScore>[];
    for (final entry in box.values) {
      try {
        scores.add(RiskScore.fromJson(entry as Map<String, dynamic>));
      } catch (e) {
        // Skip invalid entries
        continue;
      }
    }
    scores.sort((a, b) => b.calculatedAt.compareTo(a.calculatedAt));
    return scores;
  }

  Future<RiskScore?> getLatest() async {
    final all = await getAll();
    return all.isEmpty ? null : all.first;
  }

  Future<List<RiskScore>> getForDateRange(DateTime start, DateTime end) async {
    final all = await getAll();
    return all
        .where((s) =>
            s.calculatedAt.isAfter(start) && s.calculatedAt.isBefore(end))
        .toList()
      ..sort((a, b) => a.calculatedAt.compareTo(b.calculatedAt));
  }

  Future<List<RiskScore>> getLast30Days() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return getForDateRange(cutoff, DateTime.now());
  }

  Future<void> clearAll() async {
    final box = await _openBox();
    await box.clear();
  }
}
