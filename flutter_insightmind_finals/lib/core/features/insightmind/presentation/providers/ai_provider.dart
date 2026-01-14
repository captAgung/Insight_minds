// WEEK7: Provider inferensi AI
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecase/predict_risk_ai.dart';
import '../../data/models/feature_vector.dart';

/// File ini mengelola state dan dependensi menggunakan Riverpod untuk AI inference.
///
/// aiPredictorProvider (Provider):
/// - Bertanggung jawab untuk membuat dan menyediakan instance tunggal dari kelas PredictRiskAI.
/// - Ini adalah contoh dari Dependency Injection (DI) di Riverpod.
/// - Memungkinkan kode UI atau provider lain mengakses logika prediksi tanpa perlu membuat instance baru.
///
/// aiResultProvider (Provider.family):
/// - Ini adalah provider yang unik karena menggunakan .family.
/// - Memungkinkannya menerima argumen (FeatureVector fv) saat dipanggil.
/// - Saat dipanggil dari UI dengan ref.watch(aiResultProvider(fv)), ia akan:
///   1. Mengambil (watch) instance PredictRiskAI (model).
///   2. Menjalankan fungsi .predict(fv) dengan Feature Vector yang diberikan.
///   3. Mengembalikan Map<String, dynamic> yang berisi hasil prediksi.

/// Provider untuk instance PredictRiskAI (Dependency Injection).
/// 
/// Menggunakan Provider untuk memastikan hanya ada satu instance PredictRiskAI
/// yang digunakan di seluruh aplikasi, mengikuti pola Singleton.
final aiPredictorProvider = Provider<PredictRiskAI>((ref) {
  return PredictRiskAI();
});

/// Provider family untuk hasil prediksi AI berdasarkan FeatureVector.
///
/// Menggunakan Provider.family untuk menerima FeatureVector sebagai parameter.
/// Ketika dipanggil dengan ref.watch(aiResultProvider(featureVector)), akan:
/// - Mengambil instance PredictRiskAI dari aiPredictorProvider
/// - Menjalankan prediksi dengan FeatureVector yang diberikan
/// - Mengembalikan Map berisi weightedScore, riskLevel, dan confidence
final aiResultProvider = Provider.family<Map<String, dynamic>, FeatureVector>((ref, fv) {
  final model = ref.watch(aiPredictorProvider);
  return model.predict(fv);
});

