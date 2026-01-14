import '../entities/pattern_alert.dart';
import '../entities/risk_score.dart';
import '../../../mood/data/local/mood_entry.dart';
import 'package:uuid/uuid.dart';

/// Use case untuk mendeteksi pola berbahaya dalam data
class DetectPatterns {
  /// Detect patterns dalam mood entries dan risk scores, return list of alerts
  List<PatternAlert> execute({
    required List<MoodEntry> moodEntries, // Last 30 days ideally
    required RiskScore? currentRiskScore,
    required RiskScore? previousRiskScore, // From 7 days ago
  }) {
    final alerts = <PatternAlert>[];

    // Sort entries by timestamp (oldest first)
    final sortedEntries = List<MoodEntry>.from(moodEntries)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // 1. Check for mood drop >30% dalam 3 hari
    final moodDropAlert = _detectMoodDrop(sortedEntries);
    if (moodDropAlert != null) alerts.add(moodDropAlert);

    // 2. Check for risk increase to High
    final riskIncreaseAlert = _detectRiskIncrease(currentRiskScore, previousRiskScore);
    if (riskIncreaseAlert != null) alerts.add(riskIncreaseAlert);

    // 3. Check for dangerous patterns (consecutive low mood, sleep disruption, etc.)
    final dangerousPatternAlerts = _detectDangerousPatterns(sortedEntries);
    alerts.addAll(dangerousPatternAlerts);

    // 4. Check for social withdrawal
    final socialWithdrawalAlert = _detectSocialWithdrawal(sortedEntries);
    if (socialWithdrawalAlert != null) alerts.add(socialWithdrawalAlert);

    // Sort alerts by severity (critical first)
    alerts.sort((a, b) {
      final severityOrder = {
        AlertSeverity.critical: 0,
        AlertSeverity.high: 1,
        AlertSeverity.medium: 2,
        AlertSeverity.low: 3,
      };
      return (severityOrder[a.severity] ?? 3)
          .compareTo(severityOrder[b.severity] ?? 3);
    });

    return alerts;
  }

  PatternAlert? _detectMoodDrop(List<MoodEntry> entries) {
    if (entries.length < 4) return null; // Need at least 4 days

    // Get last 3 days vs previous 3 days
    final recent3Days = entries.length >= 3
        ? entries.sublist(entries.length - 3)
        : entries;
    final previous3Days = entries.length >= 6
        ? entries.sublist(entries.length - 6, entries.length - 3)
        : [];

    if (previous3Days.isEmpty) return null;

    final recentAvg = recent3Days
        .map((e) => e.effectiveMoodRating)
        .reduce((a, b) => a + b) /
        recent3Days.length;
    final previousAvg = previous3Days
        .map((e) => e.effectiveMoodRating)
        .reduce((a, b) => a + b) /
        previous3Days.length;

    final dropPercentage = ((previousAvg - recentAvg) / previousAvg) * 100;

    if (dropPercentage > 30) {
      return PatternAlert(
        id: const Uuid().v4(),
        type: AlertType.moodDrop,
        severity: dropPercentage > 50
            ? AlertSeverity.critical
            : dropPercentage > 40
                ? AlertSeverity.high
                : AlertSeverity.medium,
        title: 'Penurunan Mood Signifikan',
        message:
            'Mood Anda turun ${dropPercentage.toStringAsFixed(0)}% dalam 3 hari terakhir. '
            'Dari ${previousAvg.toStringAsFixed(1)} menjadi ${recentAvg.toStringAsFixed(1)}.',
        recommendation:
            'Pertimbangkan untuk berbicara dengan teman dekat atau profesional kesehatan mental. '
            'Jaga rutinitas harian dan coba aktivitas yang biasanya Anda nikmati.',
        detectedAt: DateTime.now(),
        metadata: {
          'previousAverage': previousAvg,
          'recentAverage': recentAvg,
          'dropPercentage': dropPercentage,
        },
      );
    }

    return null;
  }

  PatternAlert? _detectRiskIncrease(
    RiskScore? current,
    RiskScore? previous,
  ) {
    if (current == null) return null;

    // Check if current risk is High
    if (current.overallLevel == RiskLevel.high) {
      final maxRisk = [
        current.depressionRisk,
        current.anxietyRisk,
        current.burnoutRisk
      ].reduce((a, b) => a > b ? a : b);

      String riskType = 'Risiko Kesehatan Mental';
      if (maxRisk == current.depressionRisk) {
        riskType = 'Depresi';
      } else if (maxRisk == current.anxietyRisk) {
        riskType = 'Kecemasan';
      } else if (maxRisk == current.burnoutRisk) {
        riskType = 'Burnout';
      }

      // Check if it increased from previous
      bool isNewHigh = previous == null || previous.overallLevel != RiskLevel.high;
      if (isNewHigh || maxRisk > 70) {
        return PatternAlert(
          id: const Uuid().v4(),
          type: AlertType.riskIncrease,
          severity: AlertSeverity.critical,
          title: 'Tingkat Risiko Tinggi Terdeteksi',
          message:
              'Sistem mendeteksi tingkat risiko tinggi untuk $riskType (${maxRisk.toStringAsFixed(0)}%). '
              'Penting untuk mencari bantuan profesional.',
          recommendation:
              'Kami sangat menyarankan untuk berkonsultasi dengan profesional kesehatan mental. '
              'Jika Anda mengalami pikiran untuk menyakiti diri sendiri, segera hubungi layanan darurat.',
          detectedAt: DateTime.now(),
          metadata: {
            'riskType': riskType,
            'riskScore': maxRisk,
            'depressionRisk': current.depressionRisk,
            'anxietyRisk': current.anxietyRisk,
            'burnoutRisk': current.burnoutRisk,
          },
        );
      }
    }

    return null;
  }

  List<PatternAlert> _detectDangerousPatterns(List<MoodEntry> entries) {
    final alerts = <PatternAlert>[];

    // Check for consecutive low mood (5+ days with mood < 4)
    if (entries.length >= 5) {
      int consecutiveLowMood = 0;
      for (int i = entries.length - 1; i >= 0; i--) {
        if (entries[i].effectiveMoodRating < 4) {
          consecutiveLowMood++;
        } else {
          break;
        }
      }

      if (consecutiveLowMood >= 5) {
        alerts.add(PatternAlert(
          id: const Uuid().v4(),
          type: AlertType.consecutiveLowMood,
          severity: consecutiveLowMood >= 7
              ? AlertSeverity.critical
              : AlertSeverity.high,
          title: 'Mood Rendah Berkelanjutan',
          message:
              'Mood Anda rendah selama $consecutiveLowMood hari berturut-turut. '
              'Ini bisa menjadi tanda depresi.',
          recommendation:
              'Pertimbangkan untuk melakukan assessment PHQ-9 atau berkonsultasi dengan profesional kesehatan mental.',
          detectedAt: DateTime.now(),
          metadata: {'consecutiveDays': consecutiveLowMood},
        ));
      }
    }

    // Check for sleep disruption
    final sleepAlerts = _detectSleepDisruption(entries);
    alerts.addAll(sleepAlerts);

    return alerts;
  }

  List<PatternAlert> _detectSleepDisruption(List<MoodEntry> entries) {
    final alerts = <PatternAlert>[];
    final sleepEntries = entries
        .where((e) => e.sleepHours != null && e.sleepHours! > 0)
        .toList();

    if (sleepEntries.length < 5) return alerts;

    // Check for consecutive nights with <6 hours or >10 hours
    int consecutiveBadSleep = 0;
    for (int i = sleepEntries.length - 1; i >= 0; i--) {
      final sleep = sleepEntries[i].sleepHours!;
      if (sleep < 6 || sleep > 10) {
        consecutiveBadSleep++;
      } else {
        break;
      }
    }

    if (consecutiveBadSleep >= 5) {
      alerts.add(PatternAlert(
        id: const Uuid().v4(),
        type: AlertType.sleepDisruption,
        severity: consecutiveBadSleep >= 7
            ? AlertSeverity.high
            : AlertSeverity.medium,
        title: 'Gangguan Pola Tidur',
        message:
            'Pola tidur Anda terganggu selama $consecutiveBadSleep hari berturut-turut. '
            'Gangguan tidur dapat mempengaruhi kesehatan mental.',
        recommendation:
            'Coba jaga rutinitas tidur yang konsisten. Hindari layar sebelum tidur dan '
            'ciptakan lingkungan tidur yang nyaman.',
        detectedAt: DateTime.now(),
        metadata: {'consecutiveDays': consecutiveBadSleep},
      ));
    }

    return alerts;
  }

  PatternAlert? _detectSocialWithdrawal(List<MoodEntry> entries) {
    final socialEntries = entries
        .where((e) => e.socialInteractionLevel != null)
        .toList();

    if (socialEntries.length < 5) return null;

    // Compare last 3 days vs previous 3 days
    final recent3Days = socialEntries.length >= 3
        ? socialEntries.sublist(socialEntries.length - 3)
        : socialEntries;
    final previous3Days = socialEntries.length >= 6
        ? socialEntries.sublist(socialEntries.length - 6, socialEntries.length - 3)
        : [];

    if (previous3Days.isEmpty) return null;

    final recentAvg = recent3Days
        .map((e) => e.socialInteractionLevel!)
        .reduce((a, b) => a + b) /
        recent3Days.length;
    final previousAvg = previous3Days
        .map((e) => e.socialInteractionLevel!)
        .reduce((a, b) => a + b) /
        previous3Days.length;

    final dropPercentage = ((previousAvg - recentAvg) / previousAvg) * 100;

    if (dropPercentage > 40 && recentAvg < 3) {
      return PatternAlert(
        id: const Uuid().v4(),
        type: AlertType.socialWithdrawal,
        severity: recentAvg < 2
            ? AlertSeverity.high
            : AlertSeverity.medium,
        title: 'Penurunan Interaksi Sosial',
        message:
            'Interaksi sosial Anda menurun ${dropPercentage.toStringAsFixed(0)}% '
            'dalam 3 hari terakhir. Isolasi sosial dapat memperburuk kesehatan mental.',
        recommendation:
            'Coba hubungi teman atau keluarga. Bahkan percakapan singkat dapat membantu. '
            'Pertimbangkan untuk bergabung dengan aktivitas sosial atau komunitas online.',
        detectedAt: DateTime.now(),
        metadata: {
          'previousAverage': previousAvg,
          'recentAverage': recentAvg,
          'dropPercentage': dropPercentage,
        },
      );
    }

    return null;
  }
}
