import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../providers/risk_analysis_providers.dart';
import '../../domain/entities/assessment_result.dart';
import '../../../insightmind/domain/entities/question.dart';
import '../../../../../core/utils/haptic_feedback_helper.dart';
import '../../../../../core/utils/pdf_report_service.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../insightmind/presentation/providers/history_providers.dart';

class AssessmentFormPage extends ConsumerStatefulWidget {
  final AssessmentType assessmentType;

  const AssessmentFormPage({
    super.key,
    required this.assessmentType,
  });

  @override
  ConsumerState<AssessmentFormPage> createState() => _AssessmentFormPageState();
}

class _AssessmentFormPageState extends ConsumerState<AssessmentFormPage> {
  final Map<String, int> _answers = {};
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSubmitting = false;

  List<Question> get _questions {
    switch (widget.assessmentType) {
      case AssessmentType.phq9:
        return phq9Questions;
      case AssessmentType.gad7:
        return gad7Questions;
      case AssessmentType.burnout:
        return burnoutQuestions;
    }
  }

  String get _assessmentTitle {
    switch (widget.assessmentType) {
      case AssessmentType.phq9:
        return 'PHQ-9 (Depresi)';
      case AssessmentType.gad7:
        return 'GAD-7 (Kecemasan)';
      case AssessmentType.burnout:
        return 'Burnout Assessment';
    }
  }

  String get _assessmentDescription {
    switch (widget.assessmentType) {
      case AssessmentType.phq9:
        return 'Patient Health Questionnaire-9 adalah kuesioner untuk menilai tingkat depresi. Jawablah setiap pertanyaan berdasarkan pengalaman Anda dalam 2 minggu terakhir.';
      case AssessmentType.gad7:
        return 'Generalized Anxiety Disorder-7 adalah kuesioner untuk menilai tingkat kecemasan. Jawablah setiap pertanyaan berdasarkan pengalaman Anda dalam 2 minggu terakhir.';
      case AssessmentType.burnout:
        return 'Burnout Assessment adalah kuesioner untuk menilai tingkat kelelahan dan burnout terkait pekerjaan/tugas. Jawablah setiap pertanyaan berdasarkan pengalaman Anda.';
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questions = _questions;
    final totalQuestions = questions.length;
    final progress = (_currentPage + 1) / totalQuestions;

    return Scaffold(
      appBar: AppBar(
        title: Text(_assessmentTitle),
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pertanyaan ${_currentPage + 1} dari $totalQuestions',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),

          // Questions
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalQuestions,
              itemBuilder: (context, index) {
                return _buildQuestionPage(questions[index], index);
              },
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
            ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  OutlinedButton.icon(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Sebelumnya'),
                  )
                else
                  const SizedBox.shrink(),
                if (_currentPage < totalQuestions - 1)
                  FilledButton.icon(
                    onPressed: _answers.containsKey(questions[_currentPage].id)
                        ? () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Selanjutnya'),
                  )
                else
                  FilledButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => _submitAssessment(context, questions),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(_isSubmitting ? 'Menyimpan...' : 'Selesai'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPage(Question question, int index) {
    final selectedScore = _answers[question.id];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description (only on first page)
          if (index == 0) ...[
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _assessmentDescription,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Question text
          Text(
            question.text,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Answer options
          ...question.options.map((option) {
            final isSelected = selectedScore == option.score;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  HapticFeedbackHelper.selection();
                  setState(() {
                    _answers[question.id] = option.score;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected ? Colors.blue.shade50 : Colors.white,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isSelected ? Colors.blue : Colors.grey.shade400,
                            width: 2,
                          ),
                          color: isSelected ? Colors.blue : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          option.label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.blue.shade900
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _submitAssessment(
    BuildContext context,
    List<Question> questions,
  ) async {
    // Validate all questions are answered
    for (final question in questions) {
      if (!_answers.containsKey(question.id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mohon jawab semua pertanyaan'),
            backgroundColor: Colors.red,
          ),
        );
        // Scroll to first unanswered question
        final unansweredIndex =
            questions.indexWhere((q) => !_answers.containsKey(q.id));
        _pageController.jumpToPage(unansweredIndex);
        setState(() {
          _currentPage = unansweredIndex;
        });
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      // Calculate total score
      final totalScore = _answers.values.reduce((a, b) => a + b);

      // Create AssessmentResult
      final result = AssessmentResult(
        id: const Uuid().v4(),
        timestamp: DateTime.now(),
        type: widget.assessmentType,
        answers: Map<String, int>.from(_answers),
        totalScore: totalScore,
      );

      // Save to repository
      final repo = ref.read(assessmentRepositoryProvider);
      await repo.save(result);

      // Refresh providers
      // ignore: unused_result
      ref.refresh(assessmentListProvider);
      // ignore: unused_result
      ref.refresh(calculatedRiskScoreProvider);

      if (!mounted) return;

      // Show success
      messenger.showSnackBar(
        SnackBar(
          content: Text('Assessment berhasil disimpan! Skor: $totalScore'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Tentukan alur berikutnya: PHQ9 -> GAD7 -> Burnout -> PDF komprehensif
      AssessmentType? nextType;
      switch (widget.assessmentType) {
        case AssessmentType.phq9:
          nextType = AssessmentType.gad7;
          break;
        case AssessmentType.gad7:
          nextType = AssessmentType.burnout;
          break;
        case AssessmentType.burnout:
          nextType = null;
          break;
      }

      if (nextType != null) {
        // Lanjut ke assessment berikutnya
        await navigator.push(
          MaterialPageRoute(
            builder: (_) => AssessmentFormPage(assessmentType: nextType!),
          ),
        );
        if (!mounted) return;
        navigator.pop();
        return;
      }

      // Semua assessment selesai -> buat PDF komprehensif
      final settings = ref.read(settingsProvider);
      final history = await ref.read(historyListProvider.future);
      final latestScreening = history.isNotEmpty ? history.first : null;
      final assessmentRepo = ref.read(assessmentRepositoryProvider);
      final allAssessments = await assessmentRepo.getAll();

      await PdfReportService.generateAndShareComprehensiveReport(
        patientName: settings.userName ?? '-',
        patientAge: settings.userAge ?? 0,
        generatedAt: DateTime.now(),
        screeningScore: latestScreening?.score,
        screeningRiskLevel: latestScreening?.riskLevel,
        allAssessmentHistory: allAssessments,
        emergencyContactName: settings.emergencyContactName,
        emergencyContactPhone: settings.emergencyContactPhone,
      );

      // Kembali setelah berbagi PDF
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
