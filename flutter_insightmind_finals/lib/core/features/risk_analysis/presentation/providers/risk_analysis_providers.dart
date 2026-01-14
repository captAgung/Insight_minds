import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/assessment_repository.dart';
import '../../data/local/risk_score_repository.dart';
import '../../domain/entities/assessment_result.dart';
import '../../domain/entities/risk_score.dart';
import '../../domain/entities/pattern_alert.dart';
import '../../domain/usecase/calculate_risk_score.dart';
import '../../domain/usecase/detect_patterns.dart';
import '../../../mood/presentation/providers/mood_providers.dart';
import '../../../insightmind/domain/entities/question.dart';

// Repositories
final assessmentRepositoryProvider =
    Provider<AssessmentRepository>((ref) => AssessmentRepository());

final riskScoreRepositoryProvider =
    Provider<RiskScoreRepository>((ref) => RiskScoreRepository());

// Use cases
final calculateRiskScoreProvider =
    Provider<CalculateRiskScore>((ref) => CalculateRiskScore());

final detectPatternsProvider =
    Provider<DetectPatterns>((ref) => DetectPatterns());

// Assessment Results
final assessmentListProvider =
    FutureProvider<List<AssessmentResult>>((ref) async {
  final repo = ref.watch(assessmentRepositoryProvider);
  return repo.getAll();
});

final phq9AssessmentProvider =
    FutureProvider<AssessmentResult?>((ref) async {
  final repo = ref.watch(assessmentRepositoryProvider);
  return repo.getLatest(AssessmentType.phq9);
});

final gad7AssessmentProvider =
    FutureProvider<AssessmentResult?>((ref) async {
  final repo = ref.watch(assessmentRepositoryProvider);
  return repo.getLatest(AssessmentType.gad7);
});

final burnoutAssessmentProvider =
    FutureProvider<AssessmentResult?>((ref) async {
  final repo = ref.watch(assessmentRepositoryProvider);
  return repo.getLatest(AssessmentType.burnout);
});

// Risk Scores
final riskScoreListProvider =
    FutureProvider<List<RiskScore>>((ref) async {
  final repo = ref.watch(riskScoreRepositoryProvider);
  return repo.getAll();
});

final currentRiskScoreProvider =
    FutureProvider<RiskScore?>((ref) async {
  final repo = ref.watch(riskScoreRepositoryProvider);
  return repo.getLatest();
});

final riskScoreHistory30DaysProvider =
    FutureProvider<List<RiskScore>>((ref) async {
  final repo = ref.watch(riskScoreRepositoryProvider);
  return repo.getLast30Days();
});

// Calculated Risk Score (real-time calculation)
final calculatedRiskScoreProvider =
    FutureProvider<RiskScore>((ref) async {
  final assessments = await ref.watch(assessmentListProvider.future);
  final moodRepo = ref.watch(moodRepositoryProvider);
  final moodEntries = await moodRepo.listForLast30Days();
  final calculator = ref.watch(calculateRiskScoreProvider);

  return calculator.execute(
    assessments: assessments,
    moodEntries: moodEntries,
  );
});

// Pattern Alerts
final patternAlertsProvider = FutureProvider<List<PatternAlert>>((ref) async {
  final moodRepo = ref.watch(moodRepositoryProvider);
  final moodEntries = await moodRepo.listForLast30Days();
  final currentRisk = await ref.watch(currentRiskScoreProvider.future);
  
  // Get risk score from 7 days ago for comparison
  final allScores = await ref.watch(riskScoreListProvider.future);
  final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
  RiskScore? previousRisk;
  try {
    previousRisk = allScores.firstWhere(
      (s) => s.calculatedAt.isBefore(sevenDaysAgo),
    );
  } catch (e) {
    // No score found before 7 days ago, use oldest if available
    if (allScores.isNotEmpty) {
      previousRisk = allScores.last;
    }
  }

  final detector = ref.watch(detectPatternsProvider);
  return detector.execute(
    moodEntries: moodEntries,
    currentRiskScore: currentRisk,
    previousRiskScore: previousRisk,
  );
});

// Active alerts (not dismissed)
final activeAlertsProvider = FutureProvider<List<PatternAlert>>((ref) async {
  final allAlerts = await ref.watch(patternAlertsProvider.future);
  return allAlerts.where((a) => !a.isDismissed).toList();
});

// Critical alerts
final criticalAlertsProvider = FutureProvider<List<PatternAlert>>((ref) async {
  final activeAlerts = await ref.watch(activeAlertsProvider.future);
  return activeAlerts
      .where((a) => a.severity == AlertSeverity.critical)
      .toList();
});

// State providers
final isCalculatingRiskProvider = StateProvider<bool>((ref) => false);
final isSavingAssessmentProvider = StateProvider<bool>((ref) => false);
