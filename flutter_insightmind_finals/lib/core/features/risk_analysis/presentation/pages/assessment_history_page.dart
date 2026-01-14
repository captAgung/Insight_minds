import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/risk_analysis_providers.dart';
import '../../domain/entities/assessment_result.dart';
import '../../../insightmind/domain/entities/question.dart';

class AssessmentHistoryPage extends ConsumerWidget {
  const AssessmentHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessmentsAsync = ref.watch(assessmentListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessment History'),
      ),
      body: assessmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.refresh(assessmentListProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        data: (assessments) {
          if (assessments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada assessment',
                    style: TextStyle(color: Colors.grey[600], fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lengkapi assessment untuk melihat history',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            );
          }

          // Group by type
          final phq9Assessments = assessments
              .where((a) => a.type == AssessmentType.phq9)
              .toList();
          final gad7Assessments = assessments
              .where((a) => a.type == AssessmentType.gad7)
              .toList();
          final burnoutAssessments = assessments
              .where((a) => a.type == AssessmentType.burnout)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (phq9Assessments.isNotEmpty) ...[
                _buildSectionHeader('PHQ-9 (Depresi)', Colors.blue),
                const SizedBox(height: 8),
                ...phq9Assessments.map((a) => _buildAssessmentCard(context, ref, a)),
                const SizedBox(height: 16),
              ],
              if (gad7Assessments.isNotEmpty) ...[
                _buildSectionHeader('GAD-7 (Kecemasan)', Colors.orange),
                const SizedBox(height: 8),
                ...gad7Assessments.map((a) => _buildAssessmentCard(context, ref, a)),
                const SizedBox(height: 16),
              ],
              if (burnoutAssessments.isNotEmpty) ...[
                _buildSectionHeader('Burnout Assessment', Colors.red),
                const SizedBox(height: 8),
                ...burnoutAssessments.map((a) => _buildAssessmentCard(context, ref, a)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          color: color,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAssessmentCard(BuildContext context, WidgetRef ref, AssessmentResult assessment) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final normalizedScore = assessment.normalizedScore;
    final riskLevel = _getRiskLevel(normalizedScore);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(
          _getAssessmentIcon(assessment.type),
          color: _getRiskColor(riskLevel),
        ),
        title: Text(
          _getAssessmentTitle(assessment.type),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(dateFormat.format(assessment.timestamp)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Score',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${assessment.totalScore} / ${assessment.maxScore}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Risk Level',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getRiskColor(riskLevel).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getRiskColor(riskLevel),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _getRiskLabel(riskLevel),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _getRiskColor(riskLevel),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: normalizedScore / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getRiskColor(riskLevel),
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                Text(
                  '${normalizedScore.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Detail Jawaban:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                ...assessment.answers.entries.map((entry) {
                  final question = _getQuestionText(assessment.type, entry.key);
                  final score = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _getScoreColor(score).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getScoreColor(score),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              score.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getScoreColor(score),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            question,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Hapus Assessment'),
                          content: const Text(
                            'Apakah Anda yakin ingin menghapus assessment ini?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Batal'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Hapus'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true && context.mounted) {
                        try {
                          await ref
                              .read(assessmentRepositoryProvider)
                              .delete(assessment.id);
                          final _ = ref.refresh(assessmentListProvider);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Assessment berhasil dihapus'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Hapus Assessment'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getAssessmentTitle(AssessmentType type) {
    switch (type) {
      case AssessmentType.phq9:
        return 'PHQ-9 Assessment';
      case AssessmentType.gad7:
        return 'GAD-7 Assessment';
      case AssessmentType.burnout:
        return 'Burnout Assessment';
    }
  }

  IconData _getAssessmentIcon(AssessmentType type) {
    switch (type) {
      case AssessmentType.phq9:
        return Icons.health_and_safety;
      case AssessmentType.gad7:
        return Icons.psychology;
      case AssessmentType.burnout:
        return Icons.work_off;
    }
  }

  String _getQuestionText(AssessmentType type, String questionId) {
    // Get questions based on type
    List<Question> questions;
    switch (type) {
      case AssessmentType.phq9:
        questions = phq9Questions;
        break;
      case AssessmentType.gad7:
        questions = gad7Questions;
        break;
      case AssessmentType.burnout:
        questions = burnoutQuestions;
        break;
    }

    try {
      return questions.firstWhere((q) => q.id == questionId).text;
    } catch (e) {
      return questionId;
    }
  }

  String _getRiskLevel(double normalizedScore) {
    if (normalizedScore < 40) return 'low';
    if (normalizedScore < 70) return 'moderate';
    return 'high';
  }

  String _getRiskLabel(String level) {
    switch (level) {
      case 'low':
        return 'Rendah';
      case 'moderate':
        return 'Sedang';
      case 'high':
        return 'Tinggi';
      default:
        return 'Unknown';
    }
  }

  Color _getRiskColor(String level) {
    switch (level) {
      case 'low':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getScoreColor(int score) {
    if (score == 0) return Colors.green;
    if (score == 1) return Colors.yellow.shade700;
    if (score == 2) return Colors.orange;
    return Colors.red;
  }
}
