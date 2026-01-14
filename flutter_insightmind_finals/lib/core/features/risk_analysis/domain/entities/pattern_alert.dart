enum AlertType {
  moodDrop, // Mood turun >30% dalam 3 hari
  riskIncrease, // Risk score naik ke High
  dangerousPattern, // Pattern berbahaya terdeteksi
  consecutiveLowMood, // Mood rendah berturut-turut
  sleepDisruption, // Pola tidur terganggu
  socialWithdrawal, // Penurunan aktivitas sosial
}

enum AlertSeverity {
  low,
  medium,
  high,
  critical,
}

class PatternAlert {
  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final String title;
  final String message;
  final String? recommendation; // Actionable recommendation
  final DateTime detectedAt;
  final Map<String, dynamic>? metadata; // Additional data (trends, values, etc.)
  final bool isDismissed;
  final DateTime? dismissedAt;

  PatternAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    this.recommendation,
    required this.detectedAt,
    this.metadata,
    this.isDismissed = false,
    this.dismissedAt,
  });

  PatternAlert copyWith({
    String? id,
    AlertType? type,
    AlertSeverity? severity,
    String? title,
    String? message,
    String? recommendation,
    DateTime? detectedAt,
    Map<String, dynamic>? metadata,
    bool? isDismissed,
    DateTime? dismissedAt,
  }) {
    return PatternAlert(
      id: id ?? this.id,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      message: message ?? this.message,
      recommendation: recommendation ?? this.recommendation,
      detectedAt: detectedAt ?? this.detectedAt,
      metadata: metadata ?? this.metadata,
      isDismissed: isDismissed ?? this.isDismissed,
      dismissedAt: dismissedAt ?? this.dismissedAt,
    );
  }
}
