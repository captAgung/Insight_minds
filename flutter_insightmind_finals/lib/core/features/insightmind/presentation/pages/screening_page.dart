import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/question.dart';
import '../providers/questionnaire_provider.dart';
import '../providers/score_provider.dart';
import 'result_page.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../risk_analysis/presentation/pages/assessment_form_page.dart';
import '../providers/history_providers.dart'; // Pastikan untuk history
import '../../domain/usecase/calculate_risk_level.dart';

final _submitLoadingProvider = StateProvider<bool>((ref) => false);
final _nameProvider = StateProvider<String>((ref) => '');
final _ageProvider = StateProvider<String>((ref) => '');

/// Halaman untuk menampilkan dan mengisi screening test
class ScreeningPage extends ConsumerWidget {
  const ScreeningPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questions = ref.watch(questionsProvider);
    final qState = ref.watch(questionnaireProvider);
    final progress =
        questions.isEmpty ? 0.0 : (qState.answers.length / questions.length);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Screening InsightMind'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _buildIdentityForm(context, ref),
            const SizedBox(height: 12),
            _buildProgressCard(
                context, questions.length, qState.answers.length, progress),
            const SizedBox(height: 12),
            ..._buildQuestionList(questions, qState, ref),
            const SizedBox(height: 12),
            _buildActionButtons(context, questions, qState, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityForm(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsProvider);
    final currentName = settings.userName ?? '';
    final currentAge = settings.userAge?.toString() ?? '';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Nama',
                hintText:
                    currentName.isNotEmpty ? 'Contoh: $currentName' : null,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              onChanged: (v) => ref.read(_nameProvider.notifier).state = v,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: 'Umur',
                hintText: currentAge.isNotEmpty ? 'Contoh: $currentAge' : null,
                prefixIcon: const Icon(Icons.calendar_today_outlined),
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) => ref.read(_ageProvider.notifier).state = v,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, int totalQuestions,
      int answeredQuestions, double progress) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.indigo),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Terisi: $answeredQuestions/$totalQuestions pertanyaan',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildQuestionList(
      List<Question> questions, QuestionnaireState qState, WidgetRef ref) {
    return [
      for (int i = 0; i < questions.length; i++) ...[
        _QuestionCard(
          key: ValueKey(questions[i].id),
          index: i,
          question: questions[i],
          selectedScore: qState.answers[questions[i].id],
          onSelected: (score) => ref
              .read(questionnaireProvider.notifier)
              .selectAnswer(questionId: questions[i].id, score: score),
        ),
        const SizedBox(height: 8),
      ]
    ];
  }

  Widget _buildActionButtons(BuildContext context, List<Question> questions,
      QuestionnaireState qState, WidgetRef ref) {
    final isLoading = ref.watch(_submitLoadingProvider);
    final isEnabled = qState.isComplete && !isLoading;
    return Column(
      children: [
        FilledButton.icon(
          icon: const Icon(Icons.check_circle_outline),
          label: isLoading
              ? const Text('Memproses...')
              : const Text('Selesai & Lanjut Assessment'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            backgroundColor: isEnabled ? Colors.indigo : Colors.grey,
          ),
          onPressed: isEnabled
              ? () => _handleSubmit(context, questions, qState, ref)
              : null,
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: isLoading ? null : () => _handleReset(context, ref),
          icon: const Icon(Icons.refresh),
          label: const Text('Reset Jawaban'),
        ),
      ],
    );
  }

  Future<void> _handleSubmit(
    BuildContext context,
    List<Question> questions,
    QuestionnaireState qState,
    WidgetRef ref,
  ) async {
    if (!qState.isComplete) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lengkapi semua pertanyaan sebelum melihat hasil.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final settings = ref.read(settingsProvider);
    final nameInput = ref.read(_nameProvider).trim();
    final ageInput = ref.read(_ageProvider).trim();
    final name =
        nameInput.isNotEmpty ? nameInput : (settings.userName ?? '').trim();
    final age = ageInput.isNotEmpty
        ? (int.tryParse(ageInput) ?? 0)
        : (settings.userAge ?? 0);
    if (name.isEmpty || age <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lengkapi Nama & Usia di menu Akun terlebih dahulu.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    ref.read(_submitLoadingProvider.notifier).state = true;
    List<int> ordered =
        questions.map((q) => qState.answers[q.id] ?? 0).toList();
    final score = ordered.fold<int>(0, (a, b) => a + b);
    final calculateRisk = CalculateRiskLevel();
    final result = calculateRisk.execute(score);
    try {
      // Simpan identitas ke Account jika user mengisi di sini
      if (nameInput.isNotEmpty || ageInput.isNotEmpty) {
        settings.userName = name;
        settings.userAge = age;
        await settings.save();
      }
      ref.read(answersProvider.notifier).state = ordered;
      await ref.read(historyRepositoryProvider).addRecord(
            score: result.score,
            riskLevel: result.riskLevel,
            name: name,
            age: age,
          );
      // Pastikan provider riwayat memuat ulang data terbaru
      final _ = ref.refresh(historyListProvider);
      if (context.mounted) {
        // Tampilkan hasil singkat lalu lanjut ke Assessment (PHQ-9 terlebih dahulu)
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ResultPage()),
        );
        // ignore: use_build_context_synchronously
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const AssessmentFormPage(
              assessmentType: AssessmentType.phq9,
            ),
          ),
        );
        // Reset setelah rangkaian navigasi
        ref.read(questionnaireProvider.notifier).reset();
        ref.read(answersProvider.notifier).state = [];
      }
    } catch (e) {
      if (context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResultPage(
              fallbackScore: score,
              fallbackRisk: result.riskLevel,
              errorMsg: 'Gagal simpan hasil ke riwayat. ($e)',
            ),
          ),
        );
        // Tetap reset setelah user melihat hasil fallback dan kembali
        ref.read(questionnaireProvider.notifier).reset();
        ref.read(answersProvider.notifier).state = [];
      }
    } finally {
      ref.read(_submitLoadingProvider.notifier).state = false;
    }
  }

  Future<void> _handleReset(BuildContext context, WidgetRef ref) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Jawaban'),
        content: const Text('Apakah Anda yakin ingin menghapus semua jawaban?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (shouldReset == true) {
      ref.read(questionnaireProvider.notifier).reset();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jawaban telah direset.')),
        );
      }
    }
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    super.key,
    required this.index,
    required this.question,
    required this.selectedScore,
    required this.onSelected,
  });

  final int index;
  final Question question;
  final int? selectedScore;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final isAnswered = selectedScore != null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isAnswered
            ? const BorderSide(color: Colors.indigo, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildQuestionHeader(context, isAnswered),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 8),
            _buildRadioOptions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionHeader(BuildContext context, bool isAnswered) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nomor pertanyaan dengan indicator
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isAnswered ? Colors.indigo : Colors.grey.shade400,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Text pertanyaan
        Expanded(
          child: Text(
            question.text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
          ),
        ),

        // Check icon jika sudah dijawab
        if (isAnswered)
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 24,
          ),
      ],
    );
  }

  Widget _buildRadioOptions(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < question.options.length; i++) ...[
          _buildRadioOption(context, question.options[i]),
          if (i < question.options.length - 1) const SizedBox(height: 4),
        ],
      ],
    );
  }

  Widget _buildRadioOption(BuildContext context, AnswerOption option) {
    final isSelected = selectedScore == option.score;

    return Card(
      elevation: isSelected ? 3 : 0.5,
      color: isSelected ? Colors.indigo.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isSelected
            ? const BorderSide(color: Colors.indigo, width: 1.5)
            : BorderSide(color: Colors.grey.shade300, width: 0.5),
      ),
      child: RadioListTile<int>(
        title: Text(
          option.label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.indigo.shade900 : Colors.black87,
          ),
        ),
        value: option.score,
        // ignore: deprecated_member_use
        groupValue: selectedScore,
        activeColor: Colors.indigo,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        dense: true,
        // ignore: deprecated_member_use
        onChanged: (value) {
          if (value != null) {
            onSelected(value);
          }
        },
      ),
    );
  }
}
