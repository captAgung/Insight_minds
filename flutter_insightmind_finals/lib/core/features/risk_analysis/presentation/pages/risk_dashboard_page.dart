import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/risk_analysis_providers.dart';
import '../../domain/entities/risk_score.dart';
import '../../domain/entities/pattern_alert.dart';
import 'assessment_form_page.dart';
import '../../../insightmind/domain/entities/question.dart';

class RiskDashboardPage extends ConsumerWidget {
  const RiskDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riskScoreAsync = ref.watch(calculatedRiskScoreProvider);
    final alertsAsync = ref.watch(activeAlertsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Risk Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              // ignore: unused_result
              ref.refresh(calculatedRiskScoreProvider);
              // ignore: unused_result
              ref.refresh(activeAlertsProvider);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Disclaimer
          _buildDisclaimer(context),
          const SizedBox(height: 16),

          // Overall Risk Card
          riskScoreAsync.when(
            data: (riskScore) => _buildOverallRiskCard(context, riskScore),
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, stack) => Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(height: 8),
                    Text('Error: $error', textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Risk Breakdown
          riskScoreAsync.when(
            data: (riskScore) => _buildRiskBreakdown(context, riskScore),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),

          // Alerts Section
          alertsAsync.when(
            data: (alerts) {
              if (alerts.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Peringatan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...alerts.map((alert) => _buildAlertCard(context, alert)),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),

          // Quick Actions
          _buildQuickActions(context, ref),
        ],
      ),
    );
  }

  Widget _buildDisclaimer(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ini bukan diagnosis medis profesional. Konsultasikan dengan profesional kesehatan mental untuk diagnosis yang akurat.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallRiskCard(BuildContext context, RiskScore riskScore) {
    final overallLevel = riskScore.overallLevel;
    Color cardColor;
    IconData iconData;
    String levelText;

    switch (overallLevel) {
      case RiskLevel.low:
        cardColor = Colors.green.shade50;
        iconData = Icons.check_circle;
        levelText = 'Rendah';
        break;
      case RiskLevel.moderate:
        cardColor = Colors.orange.shade50;
        iconData = Icons.warning;
        levelText = 'Sedang';
        break;
      case RiskLevel.high:
        cardColor = Colors.red.shade50;
        iconData = Icons.error;
        levelText = 'Tinggi';
        break;
    }

    final maxRisk = [
      riskScore.depressionRisk,
      riskScore.anxietyRisk,
      riskScore.burnoutRisk,
    ].reduce((a, b) => a > b ? a : b);

    return Card(
      color: cardColor,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(iconData,
                    color: cardColor.computeLuminance() > 0.5
                        ? Colors.black87
                        : Colors.white,
                    size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tingkat Risiko Keseluruhan',
                        style: TextStyle(
                          fontSize: 14,
                          color: cardColor.computeLuminance() > 0.5
                              ? Colors.black54
                              : Colors.white70,
                        ),
                      ),
                      Text(
                        levelText,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: cardColor.computeLuminance() > 0.5
                              ? Colors.black87
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${maxRisk.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: cardColor.computeLuminance() > 0.5
                        ? Colors.black87
                        : Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Confidence Score
            Row(
              children: [
                Icon(Icons.insights,
                    size: 16,
                    color: cardColor.computeLuminance() > 0.5
                        ? Colors.black54
                        : Colors.white70),
                const SizedBox(width: 4),
                Text(
                  'Tingkat Keyakinan: ${riskScore.confidenceScore.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: cardColor.computeLuminance() > 0.5
                        ? Colors.black54
                        : Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskBreakdown(BuildContext context, RiskScore riskScore) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detail Risiko',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildRiskBar(
              context,
              'Depresi',
              riskScore.depressionRisk,
              riskScore.depressionLevel,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildRiskBar(
              context,
              'Kecemasan',
              riskScore.anxietyRisk,
              riskScore.anxietyLevel,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildRiskBar(
              context,
              'Burnout',
              riskScore.burnoutRisk,
              riskScore.burnoutLevel,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskBar(
    BuildContext context,
    String label,
    double risk,
    RiskLevel level,
    Color color,
  ) {
    String levelText;
    switch (level) {
      case RiskLevel.low:
        levelText = 'Rendah';
        break;
      case RiskLevel.moderate:
        levelText = 'Sedang';
        break;
      case RiskLevel.high:
        levelText = 'Tinggi';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${risk.toStringAsFixed(0)}% - $levelText',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: risk / 100,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildAlertCard(BuildContext context, PatternAlert alert) {
    MaterialColor alertColor;
    IconData alertIcon;

    switch (alert.severity) {
      case AlertSeverity.critical:
        alertColor = Colors.red;
        alertIcon = Icons.error;
        break;
      case AlertSeverity.high:
        alertColor = Colors.orange;
        alertIcon = Icons.warning;
        break;
      case AlertSeverity.medium:
        alertColor = Colors.amber;
        alertIcon = Icons.info;
        break;
      case AlertSeverity.low:
        alertColor = Colors.blue;
        alertIcon = Icons.info_outline;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: alertColor.shade50,
      child: ExpansionTile(
        leading: Icon(alertIcon, color: alertColor.shade700),
        title: Text(
          alert.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: alertColor.shade900,
          ),
        ),
        subtitle: Text(alert.message),
        children: [
          if (alert.recommendation != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rekomendasi:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: alertColor.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(alert.recommendation!),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assessment',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lengkapi assessment untuk mendapatkan analisis risiko yang lebih akurat',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            _buildAssessmentButton(
              context,
              'PHQ-9 (Depresi)',
              '9 pertanyaan',
              Icons.health_and_safety,
              Colors.blue,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AssessmentFormPage(
                      assessmentType: AssessmentType.phq9,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildAssessmentButton(
              context,
              'GAD-7 (Kecemasan)',
              '7 pertanyaan',
              Icons.psychology,
              Colors.orange,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AssessmentFormPage(
                      assessmentType: AssessmentType.gad7,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildAssessmentButton(
              context,
              'Burnout Assessment',
              '5 pertanyaan',
              Icons.work_off,
              Colors.red,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AssessmentFormPage(
                      assessmentType: AssessmentType.burnout,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.centerLeft,
        side: BorderSide(color: color),
      ),
    );
  }
}
