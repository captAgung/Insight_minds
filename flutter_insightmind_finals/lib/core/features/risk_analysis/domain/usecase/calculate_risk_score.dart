import '../entities/risk_score.dart';
import '../entities/assessment_result.dart';
import '../../../mood/data/local/mood_entry.dart';
import '../../../insightmind/domain/entities/question.dart';

/// Use case untuk menghitung risk score berdasarkan assessment dan behavioral data
class CalculateRiskScore {
  /// Hitung risk score berdasarkan assessment results dan mood entries
  RiskScore execute({
    required List<AssessmentResult> assessments,
    required List<MoodEntry> moodEntries, // Last 30 days ideally
  }) {
    // Dapatkan latest assessment untuk setiap type
    final phq9Assessment = assessments
        .where((a) => a.type == AssessmentType.phq9)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final gad7Assessment = assessments
        .where((a) => a.type == AssessmentType.gad7)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final burnoutAssessment = assessments
        .where((a) => a.type == AssessmentType.burnout)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Hitung depression risk (PHQ-9 40%, mood trend 25%, sleep 20%, social activity 15%)
    final depressionRisk = _calculateDepressionRisk(
      phq9Assessment.isNotEmpty ? phq9Assessment.first : null,
      moodEntries,
    );

    // Hitung anxiety risk (GAD-7 40%, physical symptoms 30%, mood volatility 30%)
    final anxietyRisk = _calculateAnxietyRisk(
      gad7Assessment.isNotEmpty ? gad7Assessment.first : null,
      moodEntries,
    );

    // Hitung burnout risk (Work stress questions 50%, energy levels 30%, cynicism indicators 20%)
    final burnoutRisk = _calculateBurnoutRisk(
      burnoutAssessment.isNotEmpty ? burnoutAssessment.first : null,
      moodEntries,
    );

    // Hitung confidence score berdasarkan data completeness dan consistency
    final confidenceScore = _calculateConfidenceScore(
      assessments,
      moodEntries,
    );

    // Collect metadata (trends, key factors)
    final metadata = <String, dynamic>{
      'moodTrend': _calculateMoodTrend(moodEntries),
      'sleepAverage': _calculateAverageSleep(moodEntries),
      'socialActivityAverage': _calculateAverageSocialActivity(moodEntries),
      'productivityAverage': _calculateAverageProductivity(moodEntries),
      'dataCompleteness': _calculateDataCompleteness(moodEntries),
    };

    return RiskScore(
      depressionRisk: depressionRisk,
      anxietyRisk: anxietyRisk,
      burnoutRisk: burnoutRisk,
      confidenceScore: confidenceScore,
      calculatedAt: DateTime.now(),
      metadata: metadata,
    );
  }

  double _calculateDepressionRisk(
    AssessmentResult? phq9Assessment,
    List<MoodEntry> moodEntries,
  ) {
    double assessmentScore = 0.0;
    if (phq9Assessment != null) {
      // PHQ-9 score (0-27) -> convert to 0-100%
      assessmentScore = (phq9Assessment.totalScore / 27) * 100;
    }

    // Mood trend (25%)
    final moodTrend = _calculateMoodTrend(moodEntries);
    final moodScore = (1 - (moodTrend / 10)) * 100; // Lower mood = higher risk

    // Sleep average (20%)
    final sleepAvg = _calculateAverageSleep(moodEntries);
    double sleepScore = 0.0;
    if (sleepAvg != null) {
      // Optimal sleep: 7-9 hours = low risk, <6 or >10 = high risk
      if (sleepAvg >= 7 && sleepAvg <= 9) {
        sleepScore = 0;
      } else if (sleepAvg < 6 || sleepAvg > 10) {
        sleepScore = 100;
      } else {
        sleepScore = ((7 - sleepAvg).abs() * 20).clamp(0, 100);
      }
    }

    // Social activity (15%)
    final socialAvg = _calculateAverageSocialActivity(moodEntries);
    final socialScore = socialAvg != null ? (1 - (socialAvg / 10)) * 100 : 50;

    // Weighted combination
    double totalRisk = 0.0;
    double totalWeight = 0.0;

    if (phq9Assessment != null) {
      totalRisk += assessmentScore * 0.40;
      totalWeight += 0.40;
    }

    if (moodEntries.isNotEmpty) {
      totalRisk += moodScore * 0.25;
      totalWeight += 0.25;
    }

    if (sleepAvg != null) {
      totalRisk += sleepScore * 0.20;
      totalWeight += 0.20;
    }

    if (socialAvg != null) {
      totalRisk += socialScore * 0.15;
      totalWeight += 0.15;
    }

    // Normalize jika ada missing data
    if (totalWeight > 0) {
      totalRisk = totalRisk / totalWeight;
    }

    return totalRisk.clamp(0, 100);
  }

  double _calculateAnxietyRisk(
    AssessmentResult? gad7Assessment,
    List<MoodEntry> moodEntries,
  ) {
    double assessmentScore = 0.0;
    if (gad7Assessment != null) {
      // GAD-7 score (0-21) -> convert to 0-100%
      assessmentScore = (gad7Assessment.totalScore / 21) * 100;
    }

    // Physical symptoms dari emotions (30%)
    double physicalSymptomsScore = 0.0;
    int anxietyEmotionCount = 0;
    int totalEntries = 0;
    for (final entry in moodEntries) {
      if (entry.emotions != null && entry.emotions!.isNotEmpty) {
        totalEntries++;
        if (entry.emotions!.contains('cemas') || entry.emotions!.contains('marah')) {
          anxietyEmotionCount++;
        }
      }
    }
    if (totalEntries > 0) {
      physicalSymptomsScore = (anxietyEmotionCount / totalEntries) * 100;
    }

    // Mood volatility (30%)
    final moodVolatility = _calculateMoodVolatility(moodEntries);
    final volatilityScore = moodVolatility * 10; // Convert to 0-100 scale

    // Weighted combination
    double totalRisk = 0.0;
    double totalWeight = 0.0;

    if (gad7Assessment != null) {
      totalRisk += assessmentScore * 0.40;
      totalWeight += 0.40;
    }

    if (totalEntries > 0) {
      totalRisk += physicalSymptomsScore * 0.30;
      totalWeight += 0.30;
    }

    if (moodEntries.length > 1) {
      totalRisk += volatilityScore * 0.30;
      totalWeight += 0.30;
    }

    if (totalWeight > 0) {
      totalRisk = totalRisk / totalWeight;
    }

    return totalRisk.clamp(0, 100);
  }

  double _calculateBurnoutRisk(
    AssessmentResult? burnoutAssessment,
    List<MoodEntry> moodEntries,
  ) {
    double assessmentScore = 0.0;
    if (burnoutAssessment != null) {
      // Burnout score (0-15) -> convert to 0-100%
      assessmentScore = (burnoutAssessment.totalScore / 15) * 100;
    }

    // Energy levels (30%) - dari mood dan physical activity
    double energyScore = 0.0;
    final moodAvg = _calculateMoodTrend(moodEntries);
    final activityAvg = _calculateAveragePhysicalActivity(moodEntries);
    if (moodAvg > 0 && activityAvg != null) {
      // Lower mood + lower activity = higher burnout risk
      final moodComponent = (1 - (moodAvg / 10)) * 0.5;
      final activityComponent = (1 - (activityAvg / 100)) * 0.5; // Assume max 100 min/day
      energyScore = (moodComponent + activityComponent) * 100;
    }

    // Cynicism indicators (20%) - dari emotions seperti "lelah", "sedih"
    double cynicismScore = 0.0;
    int burnoutEmotionCount = 0;
    int totalEntries = 0;
    for (final entry in moodEntries) {
      if (entry.emotions != null && entry.emotions!.isNotEmpty) {
        totalEntries++;
        if (entry.emotions!.contains('lelah') || entry.emotions!.contains('sedih')) {
          burnoutEmotionCount++;
        }
      }
    }
    if (totalEntries > 0) {
      cynicismScore = (burnoutEmotionCount / totalEntries) * 100;
    }

    // Weighted combination
    double totalRisk = 0.0;
    double totalWeight = 0.0;

    if (burnoutAssessment != null) {
      totalRisk += assessmentScore * 0.50;
      totalWeight += 0.50;
    }

    if (moodAvg > 0 && activityAvg != null) {
      totalRisk += energyScore * 0.30;
      totalWeight += 0.30;
    }

    if (totalEntries > 0) {
      totalRisk += cynicismScore * 0.20;
      totalWeight += 0.20;
    }

    if (totalWeight > 0) {
      totalRisk = totalRisk / totalWeight;
    }

    return totalRisk.clamp(0, 100);
  }

  double _calculateConfidenceScore(
    List<AssessmentResult> assessments,
    List<MoodEntry> moodEntries,
  ) {
    double score = 0.0;

    // Assessment completeness (40%)
    final hasPHQ9 = assessments.any((a) => a.type == AssessmentType.phq9);
    final hasGAD7 = assessments.any((a) => a.type == AssessmentType.gad7);
    final hasBurnout = assessments.any((a) => a.type == AssessmentType.burnout);
    final assessmentCompleteness = (hasPHQ9 ? 1 : 0) +
        (hasGAD7 ? 1 : 0) +
        (hasBurnout ? 1 : 0);
    score += (assessmentCompleteness / 3) * 40;

    // Mood entries quantity (30%)
    final moodQuantityScore = (moodEntries.length / 30 * 100).clamp(0, 100);
    score += moodQuantityScore * 0.30;

    // Data consistency (30%)
    final dataCompleteness = _calculateDataCompleteness(moodEntries);
    score += dataCompleteness * 0.30;

    return score.clamp(0, 100);
  }

  // Helper methods
  double _calculateMoodTrend(List<MoodEntry> entries) {
    if (entries.isEmpty) return 5.0; // Neutral
    final ratings = entries.map((e) => e.effectiveMoodRating.toDouble()).toList();
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  double _calculateMoodVolatility(List<MoodEntry> entries) {
    if (entries.length < 2) return 0.0;
    final ratings = entries.map((e) => e.effectiveMoodRating.toDouble()).toList();
    double sumSquaredDiff = 0.0;
    final mean = ratings.reduce((a, b) => a + b) / ratings.length;
    for (final rating in ratings) {
      sumSquaredDiff += (rating - mean) * (rating - mean);
    }
    return (sumSquaredDiff / ratings.length).clamp(0, 10);
  }

  double? _calculateAverageSleep(List<MoodEntry> entries) {
    final sleepEntries = entries.where((e) => e.sleepHours != null).toList();
    if (sleepEntries.isEmpty) return null;
    final totalSleep = sleepEntries
        .map((e) => e.sleepHours!)
        .reduce((a, b) => a + b);
    return totalSleep / sleepEntries.length;
  }

  double? _calculateAverageSocialActivity(List<MoodEntry> entries) {
    final socialEntries = entries
        .where((e) => e.socialInteractionLevel != null)
        .toList();
    if (socialEntries.isEmpty) return null;
    final totalSocial = socialEntries
        .map((e) => e.socialInteractionLevel!.toDouble())
        .reduce((a, b) => a + b);
    return totalSocial / socialEntries.length;
  }

  double? _calculateAveragePhysicalActivity(List<MoodEntry> entries) {
    final activityEntries = entries
        .where((e) => e.physicalActivityMinutes != null)
        .toList();
    if (activityEntries.isEmpty) return null;
    final totalActivity = activityEntries
        .map((e) => e.physicalActivityMinutes!.toDouble())
        .reduce((a, b) => a + b);
    return totalActivity / activityEntries.length;
  }

  double? _calculateAverageProductivity(List<MoodEntry> entries) {
    final productivityEntries = entries
        .where((e) => e.productivityLevel != null)
        .toList();
    if (productivityEntries.isEmpty) return null;
    final totalProductivity = productivityEntries
        .map((e) => e.productivityLevel!.toDouble())
        .reduce((a, b) => a + b);
    return totalProductivity / productivityEntries.length;
  }

  double _calculateDataCompleteness(List<MoodEntry> entries) {
    if (entries.isEmpty) return 0.0;
    int completeEntries = 0;
    for (final entry in entries) {
      int fieldsCount = 0;
      int fieldsPresent = 0;
      if (entry.moodRating != null) {
        fieldsCount++;
        fieldsPresent++;
      }
      if (entry.emotions != null && entry.emotions!.isNotEmpty) {
        fieldsCount++;
        fieldsPresent++;
      }
      if (entry.sleepHours != null) {
        fieldsCount++;
        fieldsPresent++;
      }
      if (entry.physicalActivityMinutes != null) {
        fieldsCount++;
        fieldsPresent++;
      }
      if (entry.socialInteractionLevel != null) {
        fieldsCount++;
        fieldsPresent++;
      }
      if (entry.productivityLevel != null) {
        fieldsCount++;
        fieldsPresent++;
      }
      if (fieldsCount > 0) {
        completeEntries += (fieldsPresent / fieldsCount * 100).round();
      }
    }
    return (completeEntries / entries.length).clamp(0, 100);
  }
}
