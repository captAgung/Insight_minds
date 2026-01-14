import '../../../mood/data/local/mood_entry.dart';
import '../../data/local/habit_entry.dart';
import 'dart:math' as math;

/// Service untuk menganalisis korelasi antara habits dan mood
class HabitMoodCorrelationService {
  /// Analisis korelasi antara habit completion dan mood rating
  CorrelationResult analyzeHabitMoodCorrelation({
    required HabitEntry habit,
    required List<MoodEntry> moodEntries,
    int daysToAnalyze = 30,
  }) {
    if (moodEntries.isEmpty || habit.completedDates.isEmpty) {
      return CorrelationResult(
        habitId: habit.id,
        habitTitle: habit.title,
        correlation: 0.0,
        sampleSize: 0,
        impact: HabitImpact.neutral,
        confidence: 0.0,
      );
    }

    final cutoff = DateTime.now().subtract(Duration(days: daysToAnalyze));
    final recentMoods = moodEntries
        .where((e) => e.timestamp.isAfter(cutoff))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final recentHabitCompletions = habit.completedDates
        .where((d) => d.isAfter(cutoff))
        .toList()
      ..sort();

    if (recentMoods.isEmpty || recentHabitCompletions.isEmpty) {
      return CorrelationResult(
        habitId: habit.id,
        habitTitle: habit.title,
        correlation: 0.0,
        sampleSize: 0,
        impact: HabitImpact.neutral,
        confidence: 0.0,
      );
    }

    // Buat data points untuk correlation
    final dataPoints = <_DataPoint>[];

    // Untuk setiap hari, cek apakah habit completed dan mood rating
    for (final mood in recentMoods) {
      final moodDate = DateTime(
        mood.timestamp.year,
        mood.timestamp.month,
        mood.timestamp.day,
      );

      final habitCompleted = recentHabitCompletions.any((d) {
        final habitDate = DateTime(d.year, d.month, d.day);
        return habitDate == moodDate ||
            habitDate == moodDate.subtract(const Duration(days: 1));
      });

      dataPoints.add(_DataPoint(
        date: moodDate,
        habitCompleted: habitCompleted,
        moodRating: mood.effectiveMoodRating.toDouble(),
      ));
    }

    if (dataPoints.length < 5) {
      return CorrelationResult(
        habitId: habit.id,
        habitTitle: habit.title,
        correlation: 0.0,
        sampleSize: dataPoints.length,
        impact: HabitImpact.neutral,
        confidence: 0.0,
      );
    }

    // Hitung correlation menggunakan Pearson correlation
    final habitValues = dataPoints.map((p) => p.habitCompleted ? 1.0 : 0.0).toList();
    final moodValues = dataPoints.map((p) => p.moodRating).toList();

    final correlation = _pearsonCorrelation(habitValues, moodValues);

    // Analisis impact
    final completedDays = dataPoints.where((p) => p.habitCompleted).toList();
    final notCompletedDays = dataPoints.where((p) => !p.habitCompleted).toList();

    double avgMoodWhenCompleted = 0.0;
    double avgMoodWhenNotCompleted = 0.0;

    if (completedDays.isNotEmpty) {
      avgMoodWhenCompleted =
          completedDays.map((p) => p.moodRating).reduce((a, b) => a + b) /
              completedDays.length;
    }

    if (notCompletedDays.isNotEmpty) {
      avgMoodWhenNotCompleted =
          notCompletedDays.map((p) => p.moodRating).reduce((a, b) => a + b) /
              notCompletedDays.length;
    }

    final moodDifference = avgMoodWhenCompleted - avgMoodWhenNotCompleted;

    HabitImpact impact;
    if (moodDifference > 1.0 && correlation > 0.3) {
      impact = HabitImpact.stronglyPositive;
    } else if (moodDifference > 0.5 && correlation > 0.2) {
      impact = HabitImpact.positive;
    } else if (moodDifference < -1.0 && correlation < -0.3) {
      impact = HabitImpact.stronglyNegative;
    } else if (moodDifference < -0.5 && correlation < -0.2) {
      impact = HabitImpact.negative;
    } else {
      impact = HabitImpact.neutral;
    }

    // Confidence score berdasarkan sample size dan consistency
    final confidence = _calculateConfidence(
      dataPoints.length,
      completedDays.length,
      correlation.abs(),
    );

    return CorrelationResult(
      habitId: habit.id,
      habitTitle: habit.title,
      correlation: correlation,
      sampleSize: dataPoints.length,
      impact: impact,
      confidence: confidence,
      avgMoodWhenCompleted: avgMoodWhenCompleted,
      avgMoodWhenNotCompleted: avgMoodWhenNotCompleted,
      completionRate: completedDays.length / dataPoints.length,
    );
  }

  /// Analisis semua habits terhadap mood
  List<CorrelationResult> analyzeAllHabits({
    required List<HabitEntry> habits,
    required List<MoodEntry> moodEntries,
    int daysToAnalyze = 30,
  }) {
    return habits
        .map((habit) => analyzeHabitMoodCorrelation(
              habit: habit,
              moodEntries: moodEntries,
              daysToAnalyze: daysToAnalyze,
            ))
        .toList()
      ..sort((a, b) => b.correlation.abs().compareTo(a.correlation.abs()));
  }

  /// Identifikasi habits yang paling berpengaruh positif
  List<CorrelationResult> getMostPositiveHabits({
    required List<HabitEntry> habits,
    required List<MoodEntry> moodEntries,
    int daysToAnalyze = 30,
  }) {
    final results = analyzeAllHabits(
      habits: habits,
      moodEntries: moodEntries,
      daysToAnalyze: daysToAnalyze,
    );

    return results
        .where((r) =>
            r.impact == HabitImpact.positive ||
            r.impact == HabitImpact.stronglyPositive)
        .toList()
      ..sort((a, b) => b.correlation.compareTo(a.correlation));
  }

  /// Analisis korelasi temporal (habit hari ini vs mood besok)
  TemporalCorrelationResult analyzeTemporalCorrelation({
    required HabitEntry habit,
    required List<MoodEntry> moodEntries,
    int daysToAnalyze = 30,
  }) {
    final cutoff = DateTime.now().subtract(Duration(days: daysToAnalyze));
    final recentMoods = moodEntries
        .where((e) => e.timestamp.isAfter(cutoff))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final recentHabitCompletions = habit.completedDates
        .where((d) => d.isAfter(cutoff))
        .toList()
      ..sort();

    if (recentMoods.length < 2 || recentHabitCompletions.isEmpty) {
      return TemporalCorrelationResult(
        habitId: habit.id,
        habitTitle: habit.title,
        sameDayCorrelation: 0.0,
        nextDayCorrelation: 0.0,
        twoDayCorrelation: 0.0,
      );
    }

    // Same day correlation
    double sameDayCorrelation = 0.0;
    // Next day correlation
    double nextDayCorrelation = 0.0;
    // Two days later correlation
    double twoDayCorrelation = 0.0;

    final sameDayData = <_DataPoint>[];
    final nextDayData = <_DataPoint>[];
    final twoDayData = <_DataPoint>[];

    for (final mood in recentMoods) {
      final moodDate = DateTime(
        mood.timestamp.year,
        mood.timestamp.month,
        mood.timestamp.day,
      );

      // Check same day
      final sameDayCompleted = recentHabitCompletions.any((d) {
        final habitDate = DateTime(d.year, d.month, d.day);
        return habitDate == moodDate;
      });

      // Check previous day
      final prevDayCompleted = recentHabitCompletions.any((d) {
        final habitDate = DateTime(d.year, d.month, d.day);
        return habitDate == moodDate.subtract(const Duration(days: 1));
      });

      // Check two days ago
      final twoDaysAgoCompleted = recentHabitCompletions.any((d) {
        final habitDate = DateTime(d.year, d.month, d.day);
        return habitDate == moodDate.subtract(const Duration(days: 2));
      });

      sameDayData.add(_DataPoint(
        date: moodDate,
        habitCompleted: sameDayCompleted,
        moodRating: mood.effectiveMoodRating.toDouble(),
      ));

      if (prevDayCompleted) {
        nextDayData.add(_DataPoint(
          date: moodDate,
          habitCompleted: true,
          moodRating: mood.effectiveMoodRating.toDouble(),
        ));
      }

      if (twoDaysAgoCompleted) {
        twoDayData.add(_DataPoint(
          date: moodDate,
          habitCompleted: true,
          moodRating: mood.effectiveMoodRating.toDouble(),
        ));
      }
    }

    if (sameDayData.length >= 5) {
      final habitVals = sameDayData.map((p) => p.habitCompleted ? 1.0 : 0.0).toList();
      final moodVals = sameDayData.map((p) => p.moodRating).toList();
      sameDayCorrelation = _pearsonCorrelation(habitVals, moodVals);
    }

    if (nextDayData.length >= 5) {
      final avgMoodNextDay = nextDayData.map((p) => p.moodRating).reduce((a, b) => a + b) /
          nextDayData.length;
      // Compare dengan average mood overall
      final avgMoodOverall = recentMoods
              .map((e) => e.effectiveMoodRating.toDouble())
              .reduce((a, b) => a + b) /
          recentMoods.length;
      nextDayCorrelation = (avgMoodNextDay - avgMoodOverall) / 10.0;
    }

    if (twoDayData.length >= 5) {
      final avgMoodTwoDays = twoDayData.map((p) => p.moodRating).reduce((a, b) => a + b) /
          twoDayData.length;
      final avgMoodOverall = recentMoods
              .map((e) => e.effectiveMoodRating.toDouble())
              .reduce((a, b) => a + b) /
          recentMoods.length;
      twoDayCorrelation = (avgMoodTwoDays - avgMoodOverall) / 10.0;
    }

    return TemporalCorrelationResult(
      habitId: habit.id,
      habitTitle: habit.title,
      sameDayCorrelation: sameDayCorrelation,
      nextDayCorrelation: nextDayCorrelation,
      twoDayCorrelation: twoDayCorrelation,
    );
  }

  double _pearsonCorrelation(List<double> x, List<double> y) {
    if (x.length != y.length || x.length < 2) return 0.0;

    final n = x.length.toDouble();
    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    final sumXY = x.asMap().entries.map((e) => e.value * y[e.key]).reduce((a, b) => a + b);
    final sumX2 = x.map((e) => e * e).reduce((a, b) => a + b);
    final sumY2 = y.map((e) => e * e).reduce((a, b) => a + b);

    final numerator = (n * sumXY) - (sumX * sumY);
    final denominator = math.sqrt(((n * sumX2) - (sumX * sumX)) * ((n * sumY2) - (sumY * sumY)));

    if (denominator == 0) return 0.0;
    return (numerator / denominator).clamp(-1.0, 1.0);
  }

  double _calculateConfidence(int sampleSize, int completedDays, double correlation) {
    // Confidence berdasarkan sample size dan consistency
    double sizeScore = (sampleSize / 30.0).clamp(0.0, 1.0);
    double consistencyScore = completedDays / sampleSize.clamp(1, double.infinity);
    double correlationScore = correlation.abs();

    return ((sizeScore * 0.4) + (consistencyScore * 0.3) + (correlationScore * 0.3))
        .clamp(0.0, 1.0);
  }
}

class _DataPoint {
  final DateTime date;
  final bool habitCompleted;
  final double moodRating;

  _DataPoint({
    required this.date,
    required this.habitCompleted,
    required this.moodRating,
  });
}

enum HabitImpact {
  stronglyPositive,
  positive,
  neutral,
  negative,
  stronglyNegative,
}

class CorrelationResult {
  final String habitId;
  final String habitTitle;
  final double correlation; // -1 to 1
  final int sampleSize;
  final HabitImpact impact;
  final double confidence; // 0 to 1
  final double avgMoodWhenCompleted;
  final double avgMoodWhenNotCompleted;
  final double completionRate; // 0 to 1

  CorrelationResult({
    required this.habitId,
    required this.habitTitle,
    required this.correlation,
    required this.sampleSize,
    required this.impact,
    required this.confidence,
    this.avgMoodWhenCompleted = 0.0,
    this.avgMoodWhenNotCompleted = 0.0,
    this.completionRate = 0.0,
  });

  String get impactDescription {
    switch (impact) {
      case HabitImpact.stronglyPositive:
        return 'Sangat Meningkatkan Mood';
      case HabitImpact.positive:
        return 'Meningkatkan Mood';
      case HabitImpact.neutral:
        return 'Tidak Berpengaruh Signifikan';
      case HabitImpact.negative:
        return 'Menurunkan Mood';
      case HabitImpact.stronglyNegative:
        return 'Sangat Menurunkan Mood';
    }
  }
}

class TemporalCorrelationResult {
  final String habitId;
  final String habitTitle;
  final double sameDayCorrelation;
  final double nextDayCorrelation;
  final double twoDayCorrelation;

  TemporalCorrelationResult({
    required this.habitId,
    required this.habitTitle,
    required this.sameDayCorrelation,
    required this.nextDayCorrelation,
    required this.twoDayCorrelation,
  });
}

