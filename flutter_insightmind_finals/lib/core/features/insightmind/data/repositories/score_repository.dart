/// Repository = sederhana untuk kalkulasi skor mental (sum list jawaban).
///
/// Metode: calculateScore(List<int> answers) -> int.
///
/// Siapa memanggil: Provider di Presentation (scoreProvider).
///
/// Kapan diubah:
/// - Saat sumber data berkembang:
///   * Minggu 5 → qanit/extend dengan Hive/Isar (persistensi).
///   * Minggu 6 → integrasi sensor (menambah data fitur).
///   * Minggu 7 → tarik/push data.
///   * Minggu 9 → tarik/backup ke API.
///
/// Catatan arsitektur: Di tahap lanjut, biasanya ada kontrak di
/// Domain (abstract ScoreRepository) lalu implementasi di Data
/// (ScoreRepositoryImpl). Minggu 2 kita masih 1 file sederhana untuk fokus konsep.

class ScoreRepository {
  /// Menyediakan seluruh jawaban (sum list jawaban) dan return int
  int calculateScore(List<int> answers) {
    if (answers.isEmpty) return 0;
    return answers.reduce((a, b) => a + b);
  }
}