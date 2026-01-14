import 'package:hive/hive.dart';
import '../../domain/entities/assessment_result.dart';
import '../../../insightmind/domain/entities/question.dart';

class AssessmentRepository {
  static const String boxName = 'assessment_results';

  Future<Box<Map>> _openBox() async {
    if (Hive.isBoxOpen(boxName)) return Hive.box<Map>(boxName);
    return Hive.openBox<Map>(boxName);
  }

  Future<void> save(AssessmentResult result) async {
    final box = await _openBox();
    await box.put(result.id, {
      'id': result.id,
      'timestamp': result.timestamp.toIso8601String(),
      'type': result.type.name,
      'answers': result.answers,
      'totalScore': result.totalScore,
      'userId': result.userId,
    });
  }

  Future<List<AssessmentResult>> getAll() async {
    final box = await _openBox();
    final results = <AssessmentResult>[];
    for (final entry in box.values) {
      try {
        results.add(_fromMap(Map<String, dynamic>.from(entry)));
      } catch (e) {
        // Skip invalid entries
        continue;
      }
    }
    results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return results;
  }

  Future<List<AssessmentResult>> getByType(AssessmentType type) async {
    final all = await getAll();
    return all.where((a) => a.type == type).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<AssessmentResult?> getLatest(AssessmentType type) async {
    final byType = await getByType(type);
    return byType.isEmpty ? null : byType.first;
  }

  Future<void> delete(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }

  Future<void> clearAll() async {
    final box = await _openBox();
    await box.clear();
  }

  AssessmentResult _fromMap(Map<String, dynamic> map) {
    return AssessmentResult(
      id: map['id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      type: AssessmentType.values.firstWhere(
        (e) => e.name == map['type'] as String,
        orElse: () => AssessmentType.phq9,
      ),
      answers: Map<String, int>.from(map['answers'] as Map),
      totalScore: map['totalScore'] as int,
      userId: map['userId'] as String?,
    );
  }
}
