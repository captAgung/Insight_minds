import '../entities/mental_result.dart';

/// Use Case = logika bisnis murni. Mengubah input (skor)
/// menjadi keputusan (level risiko).
///
/// Metode: execute(int score) -> MentalResult.
///
/// Siapa memanggil: Provider di Presentation (resultProvider) dan akhirnya UI.
///
/// Kapan diubah:
/// - Saat aturan bisnis/threshold berubah.
/// - Saat algoritma makin kompleks (misal pembobotan pertanyaan).
///
/// Tips uji: Unit test-lah file ini (input -> output) tanpa ketergantungan UI/DB.

class CalculateRiskLevel {
  MentalResult execute(int score) {
    String risk;

    // Aturan bisnis/threshold
    if (score < 20) {
      risk = 'Rendah';
    } else if (score <= 40) {
      risk = 'Sedang';
    } else {
      risk = 'Tinggi';
    }

    return MentalResult(score: score, riskLevel: risk);
  }
}