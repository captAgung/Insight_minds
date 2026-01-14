import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/history_providers.dart';
import 'package:intl/intl.dart';
import '../../../risk_analysis/presentation/pages/assessment_form_page.dart';
import '../../domain/entities/question.dart';

class ResultPage extends ConsumerWidget {
  final int? fallbackScore;
  final String? fallbackRisk;
  final String? errorMsg;
  const ResultPage(
      {super.key, this.fallbackScore, this.fallbackRisk, this.errorMsg});

  String _riskDescription(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'rendah':
        return 'Risiko rendah. Terus pertahankan kesehatan mental Anda.';
      case 'sedang':
        return 'Risiko sedang. Cobalah kelola stres, dan pertimbangkan untuk konsultasi jika perlu.';
      case 'tinggi':
        return 'Risiko tinggi. Disarankan mencari bantuan profesional atau berdiskusi dengan konselor.';
      default:
        return 'Tidak ada interpretasi.';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Screening')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _fallbackOrError(context, errorMsg ?? 'Terjadi kesalahan: $e'),
        data: (items) {
          if (items.isEmpty && fallbackScore != null && fallbackRisk != null) {
            return _fallbackResult(context: context);
          }
          if (items.isEmpty) {
            return const Center(child: Text('Belum ada hasil screening...'));
          }
          final last = items.first;
          final color = last.riskLevel.toLowerCase() == 'tinggi'
              ? Colors.red
              : last.riskLevel.toLowerCase() == 'sedang'
                  ? Colors.orange
                  : Colors.green;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events, color: color, size: 64),
                    const SizedBox(height: 12),
                    Text(
                      'Nilai Akhir: ${last.score}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: color),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kategori: ${last.riskLevel}',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Waktu: ${DateFormat('EEEE, d MMM yyyy HH:mm', 'id').format(
                              DateTime.tryParse(last.timestamp.toString()) ??
                                  DateTime.now())}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _riskDescription(last.riskLevel),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AssessmentFormPage(
                              assessmentType: AssessmentType.phq9,
                            ),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text('Lanjutkan Assessment'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _fallbackOrError(BuildContext context, String msg) {
    if (fallbackScore != null && fallbackRisk != null) {
      return _fallbackResult(context: context, msg: msg);
    }
    return Center(child: Text(msg, style: const TextStyle(color: Colors.red)));
  }

  Widget _fallbackResult({BuildContext? context, String? msg}) {
    final color = (fallbackRisk ?? '').toLowerCase() == 'tinggi'
        ? Colors.red
        : (fallbackRisk ?? '').toLowerCase() == 'sedang'
            ? Colors.orange
            : Colors.green;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events, color: color, size: 64),
              const SizedBox(height: 12),
              Text('Nilai Akhir: $fallbackScore',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 22, color: color)),
              const SizedBox(height: 8),
              Text('Kategori: $fallbackRisk',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 18)),
              if (msg != null) ...[
                const SizedBox(height: 10),
                Text(msg, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 12),
              Text(
                fallbackRisk != null ? _riskDescription(fallbackRisk!) : '',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
              if (context != null) ...[
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AssessmentFormPage(
                          assessmentType: AssessmentType.phq9,
                        ),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Lanjutkan Assessment'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
