enum RiskLevel {
  low, // 0-40%
  moderate, // 40-70%
  high, // 70-100%
}

class RiskScore {
  final double depressionRisk; // 0-100%
  final double anxietyRisk; // 0-100%
  final double burnoutRisk; // 0-100%
  final double confidenceScore; // 0-100% - kualitas dan kuantitas data
  final DateTime calculatedAt;
  final Map<String, dynamic>? metadata; // Additional info (trend, factors, etc.)

  RiskScore({
    required this.depressionRisk,
    required this.anxietyRisk,
    required this.burnoutRisk,
    required this.confidenceScore,
    required this.calculatedAt,
    this.metadata,
  });

  RiskLevel get depressionLevel => _getRiskLevel(depressionRisk);
  RiskLevel get anxietyLevel => _getRiskLevel(anxietyRisk);
  RiskLevel get burnoutLevel => _getRiskLevel(burnoutRisk);

  RiskLevel get overallLevel {
    final maxRisk = [depressionRisk, anxietyRisk, burnoutRisk].reduce((a, b) => a > b ? a : b);
    return _getRiskLevel(maxRisk);
  }

  RiskLevel _getRiskLevel(double risk) {
    if (risk < 40) return RiskLevel.low;
    if (risk < 70) return RiskLevel.moderate;
    return RiskLevel.high;
  }

  Map<String, dynamic> toJson() => {
        'depressionRisk': depressionRisk,
        'anxietyRisk': anxietyRisk,
        'burnoutRisk': burnoutRisk,
        'confidenceScore': confidenceScore,
        'calculatedAt': calculatedAt.toIso8601String(),
        'metadata': metadata,
      };

  factory RiskScore.fromJson(Map<String, dynamic> json) => RiskScore(
        depressionRisk: (json['depressionRisk'] as num).toDouble(),
        anxietyRisk: (json['anxietyRisk'] as num).toDouble(),
        burnoutRisk: (json['burnoutRisk'] as num).toDouble(),
        confidenceScore: (json['confidenceScore'] as num).toDouble(),
        calculatedAt: DateTime.parse(json['calculatedAt']),
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}
