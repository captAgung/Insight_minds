// WEEK7: AI Result Page untuk menampilkan hasil prediksi AI
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ai_provider.dart';
import '../../data/models/feature_vector.dart';

/// User Interface component yang bertanggung jawab untuk menampilkan hasil prediksi AI
/// dengan design modern.
///
/// Menggunakan ConsumerWidget dan Riverpod untuk membaca hasil prediksi.
/// UI memanggil aiResultProvider dan mengirim fv (Feature Vector, diperoleh dari
/// halaman sebelumnya atau simulasi) sebagai argumen. Tindakan ini memicu proses prediksi.
class AIResultPage extends ConsumerWidget {
  final FeatureVector featureVector;

  const AIResultPage({
    super.key,
    required this.featureVector,
  });

  /// Mendapatkan warna berdasarkan risk level
  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'tinggi':
        return Colors.red;
      case 'sedang':
        return Colors.orange;
      case 'rendah':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Mendapatkan icon berdasarkan risk level
  IconData _getRiskIcon(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'tinggi':
        return Icons.warning;
      case 'sedang':
        return Icons.info;
      case 'rendah':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mengakses hasil prediksi menggunakan aiResultProvider dengan FeatureVector
    final result = ref.watch(aiResultProvider(featureVector));

    final riskLevel = result['riskLevel'] as String;
    final weightedScore = result['weightedScore'] as double;
    final confidence = result['confidence'] as double;

    final riskColor = _getRiskColor(riskLevel);
    final riskIcon = _getRiskIcon(riskLevel);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil Prediksi AI'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Luxury Card dengan shape dan elevation tinggi untuk menampilkan hasil utama
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 8,
              shadowColor: riskColor.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    // Icon Risk Level
                    Icon(
                      riskIcon,
                      size: 80,
                      color: riskColor,
                    ),
                    const SizedBox(height: 24),
                    // Risk Level dengan warna kondisional
                    Text(
                      'Tingkat Risiko',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      riskLevel,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: riskColor,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 32),
                    // AI Score (weighted) dengan 2 desimal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'AI Score (weighted):',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          weightedScore.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Confidence sebagai persentase dengan 1 desimal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Confidence:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${(confidence * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Informasi Feature Vector yang digunakan
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detail Feature Vector',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureRow('Screening Score', featureVector.screeningScore.toStringAsFixed(2)),
                    _buildFeatureRow('Activity Mean', featureVector.activityMean.toStringAsFixed(2)),
                    _buildFeatureRow('Activity Variance', featureVector.activityVar.toStringAsFixed(2)),
                    _buildFeatureRow('PPG Mean', featureVector.ppgMean.toStringAsFixed(2)),
                    _buildFeatureRow('PPG Variance', featureVector.ppgVar.toStringAsFixed(2)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Tombol kembali
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

