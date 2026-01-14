import '../../../insightmind/domain/entities/question.dart';

class AssessmentResult {
  final String id;
  final DateTime timestamp;
  final AssessmentType type;
  final Map<String, int> answers; // questionId -> score (0-3)
  final int totalScore;
  final String? userId; // Optional: untuk multi-user support

  AssessmentResult({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.answers,
    required this.totalScore,
    this.userId,
  });

  // Helper untuk mendapatkan score untuk question tertentu
  int getScoreForQuestion(String questionId) {
    return answers[questionId] ?? 0;
  }

  // Helper untuk mendapatkan max score untuk assessment type
  int get maxScore {
    switch (type) {
      case AssessmentType.phq9:
        return 27; // 9 questions * 3 max score
      case AssessmentType.gad7:
        return 21; // 7 questions * 3 max score
      case AssessmentType.burnout:
        return 15; // 5 questions * 3 max score
    }
  }

  // Helper untuk mendapatkan normalized score (0-100%)
  double get normalizedScore => (totalScore / maxScore) * 100;
}
