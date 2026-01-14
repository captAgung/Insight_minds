// WEEK7: Feature Vector untuk AI InsightMind
// Windsurf: Refactor | Explain

/// Model Data yang berfungsi sebagai kontainer untuk semua input fitur yang telah diproses (Feature Engineering).
///
/// Tujuan: Mendefinisikan struktur data terpusat yang berisi angka-angka hasil pemrosesan sensor dan kuisioner.
/// Ini adalah input standar untuk model prediksi AI.
///
/// Isi: Berisi 5 properti double yang mewakili skor dan statistik fitur:
/// - screeningScore: Skor dari kuisioner
/// - activityMean: Rata-rata magnitude accelerometer
/// - activityVar: Variansi accelerometer (indikator stres)
/// - ppgMean: Rata-rata sinyal PPG-like
/// - ppgVar: Variansi PPG-like
class FeatureVector {
  final double screeningScore; // Skor dari kuisioner (Score from questionnaire)
  final double activityMean; // Rata-rata magnitude accelerometer (Average accelerometer magnitude)
  final double activityVar; // Variansi accelerometer (indikator stres) (Accelerometer variance (stress indicator))
  final double ppgMean; // Rata-rata sinyal PPG-like (Average PPG-like signal)
  final double ppgVar; // Variansi PPG-like (PPG-like variance)

  FeatureVector({
    required this.screeningScore,
    required this.activityMean,
    required this.activityVar,
    required this.ppgMean,
    required this.ppgVar,
  });
}

