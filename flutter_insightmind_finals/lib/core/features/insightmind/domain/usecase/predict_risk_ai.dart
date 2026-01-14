// WEEK7: PredictRiskAI rule-based AI sederhana
import '../../data/models/feature_vector.dart';

/// Core Logic AI Rule-Based untuk prediksi risiko mental health.
///
/// Dalam arsitektur Domain-Driven Design, ini disebut "Usecase" atau "Service"
/// karena mengkapsulasi business logic utama, khususnya prediksi.
///
/// Tujuan: Menerima FeatureVector sebagai input dan menghasilkan hasil prediksi
/// yang mencakup Weighted Score, Risk Level, dan Confidence.
class PredictRiskAI {
  /// Melakukan prediksi risiko berdasarkan FeatureVector.
  ///
  /// [f] - FeatureVector yang berisi data fitur yang telah diproses
  ///
  /// Returns Map dengan keys:
  /// - 'weightedScore': Skor tertimbang hasil perhitungan
  /// - 'riskLevel': Level risiko ('Tinggi', 'Sedang', atau 'Rendah')
  /// - 'confidence': Tingkat kepercayaan prediksi (0.3 - 0.95)
  Map<String, dynamic> predict(FeatureVector f) {
    // Weighted Score: Kombinasi screening score (60%), activity variance (20%), dan PPG variance (20%)
    double weightedScore = f.screeningScore * 0.6 +
        (f.activityVar * 10) * 0.2 +
        (f.ppgVar * 1000) * 0.2;

    // Risk Level berdasarkan weighted score
    String level;
    if (weightedScore > 25) {
      level = 'Tinggi';
    } else if (weightedScore > 12) {
      level = 'Sedang';
    } else {
      level = 'Rendah';
    }

    // Confidence score: Normalisasi weighted score ke range 0.3 - 0.95
    double confidence = (weightedScore / 30).clamp(0.3, 0.95);

    return {
      'weightedScore': weightedScore,
      'riskLevel': level,
      'confidence': confidence,
    };
  }
}

