import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/score_repository.dart';
import '../../domain/entities/mental_result.dart';
import '../../domain/usecase/calculate_risk_level.dart';

/// Peran: Jembatan state (Riverpod) antara UI ⇄ Domain/Data.
///
/// Isi penting:
/// - answersProvider → menyimpan jawaban kuisioner sementara (list int).
/// - scoreRepositoryProvider → menyediakan instance repo.
/// - calculateRiskProvider → menyediakan instance use case.
/// - scoreProvider → hitung total skor dan answersProvider via repo.
/// - resultProvider → panggil use case dengan skor → MentalResult.
///
/// Siapa memanggil: Halaman UI (Home/Result) watch provider ini.
///
/// Tips:
/// - Gunakan ref.watch di UI untuk reactive rebuild.
/// - Gunakan ref.read(...notifier).state = ... untuk mutasi state

// 1. Provider untuk menyimpan jawaban (List<int>)
final answersProvider = StateProvider<List<int>>((ref) => []);

// 2. Provider untuk ScoreRepository
final scoreRepositoryProvider = Provider<ScoreRepository>((ref) {
  return ScoreRepository();
});

// 3. Provider untuk CalculateRiskLevel use case
final calculateRiskProvider = Provider<CalculateRiskLevel>((ref) {
  return CalculateRiskLevel();
});

// 4. Provider untuk menghitung total skor
final scoreProvider = Provider<int>((ref) {
  final answers = ref.watch(answersProvider);
  final repository = ref.watch(scoreRepositoryProvider);
  return repository.calculateScore(answers);
});

// 5. Provider untuk hasil akhir (MentalResult)
final resultProvider = Provider<MentalResult>((ref) {
  final score = ref.watch(scoreProvider);
  final calculateRisk = ref.watch(calculateRiskProvider);
  return calculateRisk.execute(score);
});