class MentalResult {
  final int score;
  final String riskLevel;

  const MentalResult({
    required this.score,
    required this.riskLevel,
  });

  @override
  String toString() => 'MentalResult(score: $score, riskLevel: $riskLevel)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MentalResult &&
        other.score == score &&
        other.riskLevel == riskLevel;
  }

  @override
  int get hashCode => score.hashCode ^ riskLevel.hashCode;
}