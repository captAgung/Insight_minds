import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../providers/risk_analysis_providers.dart';
import '../../../mood/presentation/providers/mood_providers.dart';
import '../../../insightmind/presentation/providers/history_providers.dart';
import '../../../habit/presentation/providers/habit_providers.dart';
import '../../../habit/presentation/providers/habit_mood_correlation_providers.dart';
import '../../../habit/domain/services/habit_mood_correlation_service.dart';
import '../../domain/entities/risk_score.dart';
import '../../../mood/data/local/mood_entry.dart';
import '../../../insightmind/presentation/pages/screening_page.dart';
import '../../../../utils/pdf_report_service.dart';
import '../../../settings/presentation/providers/settings_providers.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = '30 Hari';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _getDaysFromPeriod(String period) {
    switch (period) {
      case '7 Hari':
        return 7;
      case '30 Hari':
        return 30;
      case '90 Hari':
        return 90;
      default:
        return 30;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History & Analytics'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.show_chart), text: 'Mood Trend'),
            Tab(icon: Icon(Icons.analytics), text: 'Risk Scores'),
            Tab(icon: Icon(Icons.fitness_center), text: 'Behavioral'),
            Tab(icon: Icon(Icons.link), text: 'Habit-Mood'),
            Tab(icon: Icon(Icons.lightbulb), text: 'Insights'),
            Tab(icon: Icon(Icons.compare), text: 'Comparison'),
            Tab(icon: Icon(Icons.calendar_view_month), text: 'Heatmap'),
            Tab(icon: Icon(Icons.assessment), text: 'Advanced'),
            Tab(icon: Icon(Icons.auto_awesome), text: 'Charts'),
          ],
        ),
        actions: [
          // Logo aplikasi di AppBar agar tidak terlihat kosong
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              child: const Icon(
                Icons.psychology_alt,
                color: Colors.white,
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '7 Hari', child: Text('7 Hari')),
              const PopupMenuItem(value: '30 Hari', child: Text('30 Hari')),
              const PopupMenuItem(value: '90 Hari', child: Text('90 Hari')),
            ],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedPeriod),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMoodTrendTab(),
          _buildRiskScoresTab(),
          _buildBehavioralDataTab(),
          _buildHabitMoodCorrelationTab(),
          _buildInsightsTab(),
          _buildComparisonTab(),
          _buildHeatmapTab(),
          _buildAdvancedStatsTab(),
          _buildInteractiveChartsTab(),
        ],
      ),
    );
  }

  Widget _buildMoodTrendTab() {
    final days = _getDaysFromPeriod(_selectedPeriod);
    final moodAsync = ref.watch(moodWeekProvider);

    return moodAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (moodEntries) {
        final cutoff = DateTime.now().subtract(Duration(days: days));
        final filteredEntries = moodEntries
            .where((e) => e.timestamp.isAfter(cutoff))
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

        if (filteredEntries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.show_chart, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Belum ada data mood',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mulai track mood Anda untuk melihat trend',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mood Trend ($_selectedPeriod)',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 250,
                        child: LineChart(
                          _buildMoodLineChart(filteredEntries),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMoodStats(filteredEntries),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  LineChartData _buildMoodLineChart(List<MoodEntry> entries) {
    final spots = entries.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final moodRating = entry.value.effectiveMoodRating.toDouble();
      return FlSpot(index, moodRating);
    }).toList();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 2,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: entries.length > 7 ? entries.length / 7 : 1,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= entries.length) return const Text('');
              final entry = entries[value.toInt()];
              final date = entry.timestamp;
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '${date.day}/${date.month}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: 2,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.shade300),
      ),
      minY: 0,
      maxY: 10,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.blue,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.blue.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodStats(List<MoodEntry> entries) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final avgMood =
        entries.map((e) => e.effectiveMoodRating).reduce((a, b) => a + b) /
            entries.length;

    final minMood = entries
        .map((e) => e.effectiveMoodRating)
        .reduce((a, b) => a < b ? a : b);

    final maxMood = entries
        .map((e) => e.effectiveMoodRating)
        .reduce((a, b) => a > b ? a : b);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('Rata-rata', avgMood.toStringAsFixed(1), Colors.blue),
        _buildStatItem('Terendah', minMood.toString(), Colors.red),
        _buildStatItem('Tertinggi', maxMood.toString(), Colors.green),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRiskScoresTab() {
    final days = _getDaysFromPeriod(_selectedPeriod);
    final riskHistoryAsync = ref.watch(riskScoreHistory30DaysProvider);

    return riskHistoryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (riskScores) {
        final cutoff = DateTime.now().subtract(Duration(days: days));
        final filteredScores = riskScores
            .where((s) => s.calculatedAt.isAfter(cutoff))
            .toList()
          ..sort((a, b) => a.calculatedAt.compareTo(b.calculatedAt));

        if (filteredScores.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Belum ada data risk score',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Lengkapi assessment untuk melihat risk analysis',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Risk Score History ($_selectedPeriod)',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildLegendItem('Depresi', Colors.blue),
                          const SizedBox(width: 16),
                          _buildLegendItem('Kecemasan', Colors.orange),
                          const SizedBox(width: 16),
                          _buildLegendItem('Burnout', Colors.red),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300,
                        child: LineChart(
                          _buildRiskScoreLineChart(filteredScores),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
      ],
    );
  }

  LineChartData _buildRiskScoreLineChart(List<RiskScore> scores) {
    final depressionSpots = scores.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      return FlSpot(index, entry.value.depressionRisk);
    }).toList();

    final anxietySpots = scores.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      return FlSpot(index, entry.value.anxietyRisk);
    }).toList();

    final burnoutSpots = scores.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      return FlSpot(index, entry.value.burnoutRisk);
    }).toList();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 20,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: scores.length > 7 ? scores.length / 7 : 1,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= scores.length) return const Text('');
              final score = scores[value.toInt()];
              final date = score.calculatedAt;
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '${date.day}/${date.month}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: 20,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}%',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.shade300),
      ),
      minY: 0,
      maxY: 100,
      lineBarsData: [
        LineChartBarData(
          spots: depressionSpots,
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
        ),
        LineChartBarData(
          spots: anxietySpots,
          isCurved: true,
          color: Colors.orange,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
        ),
        LineChartBarData(
          spots: burnoutSpots,
          isCurved: true,
          color: Colors.red,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
        ),
      ],
    );
  }

  Widget _buildBehavioralDataTab() {
    final days = _getDaysFromPeriod(_selectedPeriod);
    final moodAsync = ref.watch(moodWeekProvider);

    return moodAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (moodEntries) {
        final cutoff = DateTime.now().subtract(Duration(days: days));
        final filteredEntries =
            moodEntries.where((e) => e.timestamp.isAfter(cutoff)).toList();

        final sleepEntries =
            filteredEntries.where((e) => e.sleepHours != null).toList();
        final activityEntries = filteredEntries
            .where((e) => e.physicalActivityMinutes != null)
            .toList();
        final socialEntries = filteredEntries
            .where((e) => e.socialInteractionLevel != null)
            .toList();
        final productivityEntries =
            filteredEntries.where((e) => e.productivityLevel != null).toList();

        if (sleepEntries.isEmpty &&
            activityEntries.isEmpty &&
            socialEntries.isEmpty &&
            productivityEntries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fitness_center, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Belum ada data behavioral',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Lengkapi data tambahan saat input mood',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sleepEntries.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rata-rata Jam Tidur',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: BarChart(
                            _buildSleepBarChart(sleepEntries),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              if (activityEntries.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aktivitas Fisik (Menit)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: BarChart(
                            _buildActivityBarChart(activityEntries),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              if (socialEntries.isNotEmpty || productivityEntries.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Interaksi Sosial & Produktivitas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildLegendItem('Sosial', Colors.purple),
                            const SizedBox(width: 16),
                            _buildLegendItem('Produktivitas', Colors.orange),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: BarChart(
                            _buildSocialProductivityBarChart(
                                socialEntries, productivityEntries),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  BarChartData _buildSleepBarChart(List<MoodEntry> entries) {
    final Map<int, List<double>> weeklyData = {};
    for (final entry in entries) {
      final week = entry.timestamp.difference(DateTime.now()).inDays ~/ 7;
      weeklyData.putIfAbsent(week, () => []).add(entry.sleepHours!);
    }

    final barGroups = weeklyData.entries.map((entry) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      return BarChartGroupData(
        x: entry.key.abs(),
        barRods: [
          BarChartRodData(
            toY: avg,
            color: Colors.blue,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return BarChartData(
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return Text(
                'Minggu ${value.toInt() + 1}',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}h',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: barGroups,
    );
  }

  BarChartData _buildActivityBarChart(List<MoodEntry> entries) {
    final Map<int, List<int>> weeklyData = {};
    for (final entry in entries) {
      final week = entry.timestamp.difference(DateTime.now()).inDays ~/ 7;
      weeklyData
          .putIfAbsent(week, () => [])
          .add(entry.physicalActivityMinutes!);
    }

    final barGroups = weeklyData.entries.map((entry) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      return BarChartGroupData(
        x: entry.key.abs(),
        barRods: [
          BarChartRodData(
            toY: avg,
            color: Colors.green,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return BarChartData(
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return Text(
                'Minggu ${value.toInt() + 1}',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}m',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: barGroups,
    );
  }

  BarChartData _buildSocialProductivityBarChart(
      List<MoodEntry> socialEntries, List<MoodEntry> productivityEntries) {
    final Map<int, List<double>> weeklySocial = {};
    final Map<int, List<double>> weeklyProductivity = {};

    for (final entry in socialEntries) {
      final week = entry.timestamp.difference(DateTime.now()).inDays ~/ 7;
      weeklySocial
          .putIfAbsent(week, () => [])
          .add(entry.socialInteractionLevel!.toDouble());
    }

    for (final entry in productivityEntries) {
      final week = entry.timestamp.difference(DateTime.now()).inDays ~/ 7;
      weeklyProductivity
          .putIfAbsent(week, () => [])
          .add(entry.productivityLevel!.toDouble());
    }

    final allWeeks = {...weeklySocial.keys, ...weeklyProductivity.keys}.toList()
      ..sort();

    final barGroups = allWeeks.map((week) {
      final socialAvg = weeklySocial[week] != null
          ? weeklySocial[week]!.reduce((a, b) => a + b) /
              weeklySocial[week]!.length
          : 0.0;
      final productivityAvg = weeklyProductivity[week] != null
          ? weeklyProductivity[week]!.reduce((a, b) => a + b) /
              weeklyProductivity[week]!.length
          : 0.0;

      return BarChartGroupData(
        x: week.abs(),
        barRods: [
          BarChartRodData(
            toY: socialAvg,
            color: Colors.purple,
            width: 15,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: productivityAvg,
            color: Colors.orange,
            width: 15,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return BarChartData(
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return Text(
                'Minggu ${value.toInt() + 1}',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: barGroups,
    );
  }

  // ========== NEW COMPLEX FEATURES ==========

  Widget _buildInsightsTab() {
    final moodAsync = ref.watch(moodWeekProvider);
    final riskAsync = ref.watch(calculatedRiskScoreProvider);
    final historyAsync = ref.watch(historyListProvider);

    return moodAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (moodEntries) {
        return riskAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (riskScore) {
            return historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (history) {
                final insights =
                    _generateInsights(moodEntries, riskScore, history);
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInsightCard(
                        '📊 Analisis Tren',
                        insights['trend'] ?? '',
                        Colors.blue,
                        Icons.trending_up,
                      ),
                      const SizedBox(height: 12),
                      _buildInsightCard(
                        '⚠️ Peringatan',
                        insights['warning'] ?? '',
                        Colors.orange,
                        Icons.warning,
                      ),
                      const SizedBox(height: 12),
                      _buildInsightCard(
                        '💡 Rekomendasi',
                        insights['recommendation'] ?? '',
                        Colors.green,
                        Icons.lightbulb,
                      ),
                      const SizedBox(height: 12),
                      _buildInsightCard(
                        '🎯 Prediksi',
                        insights['prediction'] ?? '',
                        Colors.purple,
                        Icons.auto_graph,
                      ),
                      const SizedBox(height: 12),
                      _buildCorrelationMatrix(moodEntries),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Map<String, String> _generateInsights(
    List<MoodEntry> moodEntries,
    RiskScore riskScore,
    List<dynamic> history,
  ) {
    final insights = <String, String>{};

    // Trend Analysis
    if (moodEntries.length >= 7) {
      final recent =
          moodEntries.take(7).map((e) => e.effectiveMoodRating).toList();
      final older = moodEntries
          .skip(7)
          .take(7)
          .map((e) => e.effectiveMoodRating)
          .toList();
      if (older.isNotEmpty) {
        final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
        final olderAvg = older.reduce((a, b) => a + b) / older.length;
        final change = recentAvg - olderAvg;
        if (change > 1) {
          insights['trend'] =
              'Mood Anda meningkat ${change.toStringAsFixed(1)} poin dalam 7 hari terakhir. Tren positif!';
        } else if (change < -1) {
          insights['trend'] =
              'Mood Anda menurun ${change.abs().toStringAsFixed(1)} poin. Perhatikan pola tidur dan aktivitas.';
        } else {
          insights['trend'] =
              'Mood Anda relatif stabil. Pertahankan kebiasaan baik!';
        }
      }
    } else {
      insights['trend'] =
          'Data belum cukup untuk analisis tren. Lanjutkan tracking mood setiap hari.';
    }

    // Warning
    if (riskScore.overallLevel == RiskLevel.high) {
      insights['warning'] =
          'Risiko kesehatan mental Anda saat ini TINGGI. Disarankan untuk segera berkonsultasi dengan profesional.';
    } else if (riskScore.overallLevel == RiskLevel.moderate) {
      insights['warning'] =
          'Risiko kesehatan mental Anda SEDANG. Perhatikan pola tidur, aktivitas fisik, dan interaksi sosial.';
    } else {
      insights['warning'] =
          'Risiko kesehatan mental Anda RENDAH. Tetap pertahankan pola hidup sehat!';
    }

    // Recommendations
    final avgSleep = moodEntries
        .where((e) => e.sleepHours != null)
        .map((e) => e.sleepHours!)
        .toList();
    if (avgSleep.isNotEmpty) {
      final sleepAvg = avgSleep.reduce((a, b) => a + b) / avgSleep.length;
      if (sleepAvg < 6) {
        insights['recommendation'] =
            'Rata-rata tidur Anda ${sleepAvg.toStringAsFixed(1)} jam - terlalu sedikit. Targetkan 7-9 jam per hari untuk kesehatan mental yang optimal.';
      } else if (sleepAvg > 10) {
        insights['recommendation'] =
            'Rata-rata tidur Anda ${sleepAvg.toStringAsFixed(1)} jam - terlalu banyak. Coba kurangi menjadi 7-9 jam per hari.';
      } else {
        insights['recommendation'] =
            'Pola tidur Anda baik (${sleepAvg.toStringAsFixed(1)} jam). Pertahankan!';
      }
    } else {
      insights['recommendation'] =
          'Lengkapi data tidur untuk mendapatkan rekomendasi yang lebih akurat.';
    }

    // Prediction
    if (moodEntries.length >= 14) {
      final lastWeek =
          moodEntries.take(7).map((e) => e.effectiveMoodRating).toList();
      final previousWeek = moodEntries
          .skip(7)
          .take(7)
          .map((e) => e.effectiveMoodRating)
          .toList();
      if (previousWeek.isNotEmpty) {
        final trend = (lastWeek.reduce((a, b) => a + b) / lastWeek.length) -
            (previousWeek.reduce((a, b) => a + b) / previousWeek.length);
        if (trend > 0.5) {
          insights['prediction'] =
              'Berdasarkan tren, mood Anda diprediksi akan terus membaik dalam minggu depan.';
        } else if (trend < -0.5) {
          insights['prediction'] =
              'Berdasarkan tren, perhatian ekstra diperlukan. Pertimbangkan untuk meningkatkan aktivitas fisik dan interaksi sosial.';
        } else {
          insights['prediction'] = 'Mood Anda diprediksi akan relatif stabil.';
        }
      }
    } else {
      insights['prediction'] =
          'Data belum cukup untuk prediksi. Lanjutkan tracking selama 2 minggu.';
    }

    return insights;
  }

  Widget _buildInsightCard(
      String title, String content, Color color, IconData icon) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrelationMatrix(List<MoodEntry> entries) {
    final correlations = _calculateCorrelations(entries);
    if (correlations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Korelasi Faktor',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...correlations.entries.map((entry) {
              final correlation = entry.value;
              Color color;
              if (correlation.abs() > 0.7) {
                color = correlation > 0 ? Colors.green : Colors.red;
              } else if (correlation.abs() > 0.4) {
                color = correlation > 0 ? Colors.lightGreen : Colors.orange;
              } else {
                color = Colors.grey;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child:
                          Text(entry.key, style: const TextStyle(fontSize: 14)),
                    ),
                    Container(
                      width: 100,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: correlation > 0
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        widthFactor: correlation.abs(),
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: Text(
                        '${(correlation * 100).toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 12, color: color),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Map<String, double> _calculateCorrelations(List<MoodEntry> entries) {
    final correlations = <String, double>{};
    final validEntries = entries
        .where((e) =>
            e.sleepHours != null &&
            e.physicalActivityMinutes != null &&
            e.socialInteractionLevel != null &&
            e.productivityLevel != null)
        .toList();

    if (validEntries.length < 5) return correlations;

    final moods =
        validEntries.map((e) => e.effectiveMoodRating.toDouble()).toList();
    final sleeps = validEntries.map((e) => e.sleepHours!).toList();
    final activities =
        validEntries.map((e) => e.physicalActivityMinutes!.toDouble()).toList();
    final socials =
        validEntries.map((e) => e.socialInteractionLevel!.toDouble()).toList();
    final productivities =
        validEntries.map((e) => e.productivityLevel!.toDouble()).toList();

    correlations['Mood vs Tidur'] = _pearsonCorrelation(moods, sleeps);
    correlations['Mood vs Aktivitas'] = _pearsonCorrelation(moods, activities);
    correlations['Mood vs Sosial'] = _pearsonCorrelation(moods, socials);
    correlations['Mood vs Produktivitas'] =
        _pearsonCorrelation(moods, productivities);

    return correlations;
  }

  double _pearsonCorrelation(List<double> x, List<double> y) {
    if (x.length != y.length || x.length < 2) return 0.0;

    final n = x.length.toDouble();
    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    final sumXY = x
        .asMap()
        .entries
        .map((e) => e.value * y[e.key])
        .reduce((a, b) => a + b);
    final sumX2 = x.map((e) => e * e).reduce((a, b) => a + b);
    final sumY2 = y.map((e) => e * e).reduce((a, b) => a + b);

    final numerator = (n * sumXY) - (sumX * sumY);
    final denominator = math
        .sqrt(((n * sumX2) - (sumX * sumX)) * ((n * sumY2) - (sumY * sumY)));

    if (denominator == 0) return 0.0;
    return (numerator / denominator).clamp(-1.0, 1.0);
  }

  Widget _buildComparisonTab() {
    final moodAsync = ref.watch(moodWeekProvider);

    return moodAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (moodEntries) {
        if (moodEntries.length < 14) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.compare, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Data belum cukup untuk perbandingan',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Perlu minimal 14 hari data untuk membandingkan periode',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          );
        }

        final thisWeek = moodEntries.take(7).toList();
        final lastWeek = moodEntries.skip(7).take(7).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Perbandingan Minggu',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildComparisonRow(
                          'Mood Rata-rata', thisWeek, lastWeek, 'mood'),
                      const SizedBox(height: 12),
                      _buildComparisonRow(
                          'Tidur Rata-rata', thisWeek, lastWeek, 'sleep'),
                      const SizedBox(height: 12),
                      _buildComparisonRow(
                          'Aktivitas Fisik', thisWeek, lastWeek, 'activity'),
                      const SizedBox(height: 12),
                      _buildComparisonRow(
                          'Interaksi Sosial', thisWeek, lastWeek, 'social'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComparisonRow(
    String label,
    List<MoodEntry> thisWeek,
    List<MoodEntry> lastWeek,
    String type,
  ) {
    double thisValue, lastValue;
    String unit;

    switch (type) {
      case 'mood':
        thisValue =
            thisWeek.map((e) => e.effectiveMoodRating).reduce((a, b) => a + b) /
                thisWeek.length;
        lastValue =
            lastWeek.map((e) => e.effectiveMoodRating).reduce((a, b) => a + b) /
                lastWeek.length;
        unit = '/10';
        break;
      case 'sleep':
        final thisSleep = thisWeek
            .where((e) => e.sleepHours != null)
            .map((e) => e.sleepHours!)
            .toList();
        final lastSleep = lastWeek
            .where((e) => e.sleepHours != null)
            .map((e) => e.sleepHours!)
            .toList();
        if (thisSleep.isEmpty || lastSleep.isEmpty) {
          return const SizedBox.shrink();
        }
        thisValue = thisSleep.reduce((a, b) => a + b) / thisSleep.length;
        lastValue = lastSleep.reduce((a, b) => a + b) / lastSleep.length;
        unit = ' jam';
        break;
      case 'activity':
        final thisAct = thisWeek
            .where((e) => e.physicalActivityMinutes != null)
            .map((e) => e.physicalActivityMinutes!)
            .toList();
        final lastAct = lastWeek
            .where((e) => e.physicalActivityMinutes != null)
            .map((e) => e.physicalActivityMinutes!)
            .toList();
        if (thisAct.isEmpty || lastAct.isEmpty) return const SizedBox.shrink();
        thisValue = thisAct.reduce((a, b) => a + b) / thisAct.length;
        lastValue = lastAct.reduce((a, b) => a + b) / lastAct.length;
        unit = ' menit';
        break;
      case 'social':
        final thisSoc = thisWeek
            .where((e) => e.socialInteractionLevel != null)
            .map((e) => e.socialInteractionLevel!)
            .toList();
        final lastSoc = lastWeek
            .where((e) => e.socialInteractionLevel != null)
            .map((e) => e.socialInteractionLevel!)
            .toList();
        if (thisSoc.isEmpty || lastSoc.isEmpty) return const SizedBox.shrink();
        thisValue = thisSoc.reduce((a, b) => a + b) / thisSoc.length;
        lastValue = lastSoc.reduce((a, b) => a + b) / lastSoc.length;
        unit = '/10';
        break;
      default:
        return const SizedBox.shrink();
    }

    final change = thisValue - lastValue;
    final changePercent = lastValue != 0 ? (change / lastValue * 100) : 0;
    Color changeColor = change > 0
        ? Colors.green
        : change < 0
            ? Colors.red
            : Colors.grey;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Minggu ini: ${thisValue.toStringAsFixed(1)}$unit',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    change > 0
                        ? Icons.arrow_upward
                        : change < 0
                            ? Icons.arrow_downward
                            : Icons.remove,
                    size: 16,
                    color: changeColor,
                  ),
                  Text(
                    '${changePercent.abs().toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 12, color: changeColor),
                  ),
                ],
              ),
              Text(
                'Minggu lalu: ${lastValue.toStringAsFixed(1)}$unit',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeatmapTab() {
    final moodAsync = ref.watch(moodWeekProvider);

    return moodAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (moodEntries) {
        if (moodEntries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_view_month,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Belum ada data mood',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mood Heatmap (30 Hari Terakhir)',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildHeatmapCalendar(moodEntries),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeatmapCalendar(List<MoodEntry> entries) {
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 30));
    final moodMap = <DateTime, int>{};

    for (final entry in entries) {
      final date = DateTime(
          entry.timestamp.year, entry.timestamp.month, entry.timestamp.day);
      if (date.isAfter(startDate.subtract(const Duration(days: 1)))) {
        moodMap[date] = entry.effectiveMoodRating;
      }
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: 30,
      itemBuilder: (context, index) {
        final date = startDate.add(Duration(days: index));
        final mood = moodMap[date];
        Color color;
        if (mood == null) {
          color = Colors.grey.shade200;
        } else if (mood >= 8) {
          color = Colors.green.shade400;
        } else if (mood >= 6) {
          color = Colors.lightGreen.shade300;
        } else if (mood >= 4) {
          color = Colors.yellow.shade300;
        } else if (mood >= 2) {
          color = Colors.orange.shade300;
        } else {
          color = Colors.red.shade300;
        }

        return Tooltip(
          message: mood != null
              ? '${DateFormat('dd MMM').format(date)}\nMood: $mood/10'
              : '${DateFormat('dd MMM').format(date)}\nTidak ada data',
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade300, width: 0.5),
            ),
            child: Center(
              child: Text(
                date.day.toString(),
                style: TextStyle(
                  fontSize: 10,
                  color: mood != null ? Colors.black87 : Colors.grey,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdvancedStatsTab() {
    final moodAsync = ref.watch(moodWeekProvider);
    final riskAsync = ref.watch(calculatedRiskScoreProvider);

    return moodAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (moodEntries) {
        return riskAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (riskScore) {
            final stats = _calculateAdvancedStats(moodEntries);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Statistik Lanjutan',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _buildStatRow('Rata-rata',
                              stats['mean']?.toStringAsFixed(2) ?? 'N/A'),
                          _buildStatRow('Median',
                              stats['median']?.toStringAsFixed(2) ?? 'N/A'),
                          _buildStatRow('Standar Deviasi',
                              stats['stdDev']?.toStringAsFixed(2) ?? 'N/A'),
                          _buildStatRow('Varians',
                              stats['variance']?.toStringAsFixed(2) ?? 'N/A'),
                          _buildStatRow('Range',
                              stats['range']?.toStringAsFixed(2) ?? 'N/A'),
                          _buildStatRow('Modus',
                              stats['mode']?.toStringAsFixed(0) ?? 'N/A'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Risk Score Details',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _buildStatRow('Depresi',
                              '${riskScore.depressionRisk.toStringAsFixed(1)}%'),
                          _buildStatRow('Kecemasan',
                              '${riskScore.anxietyRisk.toStringAsFixed(1)}%'),
                          _buildStatRow('Burnout',
                              '${riskScore.burnoutRisk.toStringAsFixed(1)}%'),
                          _buildStatRow('Confidence',
                              '${riskScore.confidenceScore.toStringAsFixed(1)}%'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Export Data',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.download),
                                onPressed: () => _exportData(
                                    context, moodEntries, riskScore),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Export data analitik sebagai PDF atau CSV',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Map<String, double> _calculateAdvancedStats(List<MoodEntry> entries) {
    if (entries.isEmpty) return {};

    final ratings =
        entries.map((e) => e.effectiveMoodRating.toDouble()).toList();
    ratings.sort();

    final mean = ratings.reduce((a, b) => a + b) / ratings.length;
    final median = ratings.length % 2 == 0
        ? (ratings[ratings.length ~/ 2 - 1] + ratings[ratings.length ~/ 2]) / 2
        : ratings[ratings.length ~/ 2];

    final variance =
        ratings.map((e) => math.pow(e - mean, 2)).reduce((a, b) => a + b) /
            ratings.length;
    final stdDev = math.sqrt(variance);

    final range = ratings.last - ratings.first;

    // Mode (most frequent value)
    final frequency = <int, int>{};
    for (final rating in ratings.map((e) => e.round())) {
      frequency[rating] = (frequency[rating] ?? 0) + 1;
    }
    final mode = frequency.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key
        .toDouble();

    return {
      'mean': mean,
      'median': median,
      'stdDev': stdDev,
      'variance': variance,
      'range': range,
      'mode': mode,
    };
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context, List<MoodEntry> moodEntries,
      RiskScore riskScore) async {
    // Show export options dialog dengan pilihan waktu
    final timeOption = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Kapan Anda ingin download PDF?'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context, 'now'),
            child: const Text('Sekarang'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, 'later'),
            child: const Text('Nanti'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Batal'),
          ),
        ],
      ),
    );

    if (timeOption == null) return;

    // Jika pilih "Nanti", hanya tampilkan pesan
    if (timeOption == 'later') {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda dapat download PDF nanti melalui menu ini'),
          ),
        );
      }
      return;
    }

    // Jika pilih "Sekarang", lanjutkan dengan pilihan format
    final formatOption = await showDialog<String>(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Pilih format export:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'PDF'),
            child: const Text('PDF'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'CSV'),
            child: const Text('CSV'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Batal'),
          ),
        ],
      ),
    );

    if (formatOption == null) return;

    try {
      if (formatOption == 'PDF') {
        // Get assessment history
        final assessmentListAsync = ref.read(assessmentListProvider.future);
        final assessments = await assessmentListAsync;

        // Get user settings
        final settings = ref.read(settingsProvider);
        final userName =
            settings.userName?.isNotEmpty == true ? settings.userName! : 'User';
        final userAge = settings.userAge ?? 25;

        // Tanya user apakah mau download/share sekarang atau hanya generate
        final shareNow = await showDialog<bool>(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Download PDF'),
            content: const Text(
                'Apakah Anda ingin download/share PDF sekarang atau hanya generate saja?'),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Download Sekarang'),
              ),
              OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Generate Saja'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Batal'),
              ),
            ],
          ),
        );

        if (shareNow == null) return;

        // Show loading indicator
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Membuat PDF...'),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // Generate comprehensive report
        if (shareNow == true) {
          // Jika user mau download/share sekarang
          await PdfReportService.generateAndShareComprehensiveReport(
            patientName: userName,
            patientAge: userAge,
            generatedAt: DateTime.now(),
            allAssessmentHistory: assessments,
          );
          // Tunggu sebentar untuk memastikan dialog share sudah selesai
          await Future.delayed(const Duration(milliseconds: 1000));
        } else {
          // Jika user hanya mau generate tanpa download
          // Generate PDF tanpa share (hanya prepare/save internal)
          await PdfReportService.generateComprehensiveReportWithoutShare(
            patientName: userName,
            patientAge: userAge,
            generatedAt: DateTime.now(),
            allAssessmentHistory: assessments,
          );
        }

        // Close loading dialog
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
        }

        // Navigate to ScreeningPage dengan menghapus semua route sebelumnya
        // Gunakan Future.delayed untuk memastikan semua dialog sudah tertutup
        await Future.delayed(const Duration(milliseconds: 300));

        if (context.mounted) {
          // Gunakan rootNavigator untuk memastikan semua route dihapus
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const ScreeningPage(),
            ),
            (route) => false, // Remove all previous routes
          );
        }
      } else if (formatOption == 'CSV') {
        // Generate CSV data
        final csvData = _generateCSV(moodEntries, riskScore);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'CSV data:\n${csvData.substring(0, csvData.length > 100 ? 100 : csvData.length)}...'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _generateCSV(List<MoodEntry> moodEntries, RiskScore riskScore) {
    final buffer = StringBuffer();
    buffer.writeln(
        'Date,Mood Rating,Sleep Hours,Activity Minutes,Social Level,Productivity Level');
    for (final entry in moodEntries) {
      buffer.writeln(
        '${DateFormat('yyyy-MM-dd').format(entry.timestamp)},'
        '${entry.effectiveMoodRating},'
        '${entry.sleepHours ?? ""},'
        '${entry.physicalActivityMinutes ?? ""},'
        '${entry.socialInteractionLevel ?? ""},'
        '${entry.productivityLevel ?? ""}',
      );
    }
    buffer.writeln('\nRisk Scores');
    buffer
        .writeln('Depression Risk,Anxiety Risk,Burnout Risk,Confidence Score');
    buffer.writeln(
      '${riskScore.depressionRisk},'
      '${riskScore.anxietyRisk},'
      '${riskScore.burnoutRisk},'
      '${riskScore.confidenceScore}',
    );
    return buffer.toString();
  }

  // ========== HABIT-MOOD CORRELATION TAB ==========

  Widget _buildHabitMoodCorrelationTab() {
    final correlationAsync = ref.watch(habitMoodCorrelationProvider);
    final habitsAsync = ref.watch(habitListProvider);
    final moodAsync = ref.watch(moodWeekProvider);

    return correlationAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (correlations) {
        return habitsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (habits) {
            return moodAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (moodEntries) {
                if (habits.isEmpty || moodEntries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.link, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada data untuk analisis',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tambahkan habits dan track mood untuk melihat korelasi',
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final validCorrelations = correlations
                    .where((c) => c.sampleSize >= 5 && c.confidence > 0.3)
                    .toList();

                if (validCorrelations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.link_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Data belum cukup untuk analisis korelasi',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Perlu minimal 5 data points dengan confidence > 30%',
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Card
                      Card(
                        color: Colors.purple.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.insights,
                                      color: Colors.purple.shade700),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Analisis Habit-Mood Correlation',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple.shade900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Ditemukan ${validCorrelations.length} habit dengan korelasi signifikan',
                                style: TextStyle(color: Colors.purple.shade700),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Correlation Chart
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Korelasi Habit vs Mood',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 300,
                                child: BarChart(
                                  _buildHabitCorrelationBarChart(
                                      validCorrelations),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Most Positive Habits
                      if (validCorrelations
                          .where((c) =>
                              c.impact == HabitImpact.positive ||
                              c.impact == HabitImpact.stronglyPositive)
                          .isNotEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.trending_up,
                                        color: Colors.green),
                                    SizedBox(width: 8),
                                    Text(
                                      'Habits yang Meningkatkan Mood',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ...validCorrelations
                                    .where((c) =>
                                        c.impact == HabitImpact.positive ||
                                        c.impact ==
                                            HabitImpact.stronglyPositive)
                                    .take(5)
                                    .map((correlation) =>
                                        _buildCorrelationCard(correlation)),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // All Correlations List
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Semua Korelasi',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...validCorrelations.map((correlation) =>
                                  _buildCorrelationCard(correlation)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  BarChartData _buildHabitCorrelationBarChart(
      List<CorrelationResult> correlations) {
    final barGroups = correlations.asMap().entries.map((entry) {
      final index = entry.key;
      final correlation = entry.value;
      Color color;
      if (correlation.impact == HabitImpact.stronglyPositive) {
        color = Colors.green.shade400;
      } else if (correlation.impact == HabitImpact.positive) {
        color = Colors.lightGreen.shade300;
      } else if (correlation.impact == HabitImpact.negative ||
          correlation.impact == HabitImpact.stronglyNegative) {
        color = Colors.red.shade300;
      } else {
        color = Colors.grey.shade300;
      }

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: (correlation.correlation * 100).clamp(-100, 100),
            color: color,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return BarChartData(
      gridData: const FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 20,
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= correlations.length) return const Text('');
              final title = correlations[value.toInt()].habitTitle;
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  title.length > 10 ? '${title.substring(0, 10)}...' : title,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}%',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      barGroups: barGroups,
      maxY: 100,
      minY: -100,
    );
  }

  Widget _buildCorrelationCard(CorrelationResult correlation) {
    Color impactColor;
    IconData impactIcon;
    switch (correlation.impact) {
      case HabitImpact.stronglyPositive:
        impactColor = Colors.green;
        impactIcon = Icons.trending_up;
        break;
      case HabitImpact.positive:
        impactColor = Colors.lightGreen;
        impactIcon = Icons.arrow_upward;
        break;
      case HabitImpact.negative:
        impactColor = Colors.orange;
        impactIcon = Icons.arrow_downward;
        break;
      case HabitImpact.stronglyNegative:
        impactColor = Colors.red;
        impactIcon = Icons.trending_down;
        break;
      case HabitImpact.neutral:
        impactColor = Colors.grey;
        impactIcon = Icons.remove;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: impactColor.withValues(alpha: 0.1),
      child: ExpansionTile(
        leading: Icon(impactIcon, color: impactColor),
        title: Text(
          correlation.habitTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          correlation.impactDescription,
          style: TextStyle(color: impactColor, fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow('Korelasi',
                    '${(correlation.correlation * 100).toStringAsFixed(1)}%'),
                _buildStatRow('Confidence',
                    '${(correlation.confidence * 100).toStringAsFixed(1)}%'),
                _buildStatRow('Sample Size', '${correlation.sampleSize} hari'),
                _buildStatRow(
                  'Mood saat Completed',
                  '${correlation.avgMoodWhenCompleted.toStringAsFixed(1)}/10',
                ),
                _buildStatRow(
                  'Mood saat Tidak Completed',
                  '${correlation.avgMoodWhenNotCompleted.toStringAsFixed(1)}/10',
                ),
                _buildStatRow(
                  'Completion Rate',
                  '${(correlation.completionRate * 100).toStringAsFixed(1)}%',
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Perbedaan: ${(correlation.avgMoodWhenCompleted - correlation.avgMoodWhenNotCompleted).toStringAsFixed(1)} poin',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== INTERACTIVE CHARTS TAB ==========

  Widget _buildInteractiveChartsTab() {
    final moodAsync = ref.watch(moodWeekProvider);
    final riskAsync = ref.watch(calculatedRiskScoreProvider);

    return moodAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (moodEntries) {
        return riskAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (riskScore) {
            if (moodEntries.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada data untuk visualisasi',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pie Chart - Mood Distribution
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Distribusi Mood (30 Hari)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 300,
                            child: PieChart(
                                _buildMoodDistributionPieChart(moodEntries)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Scatter Plot - Mood vs Sleep
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Korelasi Mood vs Tidur',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 300,
                            child: LineChart(
                              _buildMoodSleepScatterChart(moodEntries),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Radar Chart - Multi-dimensional Analysis
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Analisis Multi-Dimensi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 350,
                            child: _buildRadarChart(moodEntries, riskScore),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  PieChartData _buildMoodDistributionPieChart(List<MoodEntry> entries) {
    final moodDistribution = <int, int>{};
    for (final entry in entries) {
      final rating = entry.effectiveMoodRating;
      final category = rating >= 8
          ? 4 // Excellent
          : rating >= 6
              ? 3 // Good
              : rating >= 4
                  ? 2 // Fair
                  : rating >= 2
                      ? 1 // Poor
                      : 0; // Very Poor
      moodDistribution[category] = (moodDistribution[category] ?? 0) + 1;
    }

    final total = entries.length;
    final colors = [
      Colors.red.shade400,
      Colors.orange.shade400,
      Colors.yellow.shade400,
      Colors.lightGreen.shade400,
      Colors.green.shade400,
    ];

    return PieChartData(
      sections: moodDistribution.entries.map((entry) {
        final percentage = (entry.value / total * 100);
        final color = colors[entry.key];
        final section = PieChartSectionData(
          value: entry.value.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          color: color,
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
        return section;
      }).toList(),
      sectionsSpace: 2,
      centerSpaceRadius: 40,
    );
  }

  LineChartData _buildMoodSleepScatterChart(List<MoodEntry> entries) {
    final validEntries = entries.where((e) => e.sleepHours != null).toList();
    if (validEntries.isEmpty) {
      return LineChartData();
    }

    final spots = validEntries.map((entry) {
      return FlSpot(
          entry.sleepHours!.toDouble(), entry.effectiveMoodRating.toDouble());
    }).toList();

    return LineChartData(
      gridData: const FlGridData(
        show: true,
        drawVerticalLine: true,
        drawHorizontalLine: true,
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) => Text(
              '${value.toInt()}h',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) => Text(
              value.toInt().toString(),
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true),
      minX: 0,
      maxX: 12,
      minY: 0,
      maxY: 10,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: false,
          color: Colors.purple,
          barWidth: 2,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.purple,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(show: false),
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((LineBarSpot touchedSpot) {
              return LineTooltipItem(
                'Tidur: ${touchedSpot.x.toStringAsFixed(1)}h\nMood: ${touchedSpot.y.toStringAsFixed(1)}',
                const TextStyle(color: Colors.white),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildRadarChart(List<MoodEntry> entries, RiskScore riskScore) {
    // Calculate averages
    final avgMood = entries.isEmpty
        ? 5.0
        : entries.map((e) => e.effectiveMoodRating).reduce((a, b) => a + b) /
            entries.length;

    final avgSleep = entries
            .where((e) => e.sleepHours != null)
            .map((e) => e.sleepHours!)
            .toList()
            .isEmpty
        ? 7.0
        : entries
                .where((e) => e.sleepHours != null)
                .map((e) => e.sleepHours!)
                .reduce((a, b) => a + b) /
            entries.where((e) => e.sleepHours != null).length;

    final avgSocial = entries
            .where((e) => e.socialInteractionLevel != null)
            .map((e) => e.socialInteractionLevel!.toDouble())
            .toList()
            .isEmpty
        ? 5.0
        : entries
                .where((e) => e.socialInteractionLevel != null)
                .map((e) => e.socialInteractionLevel!.toDouble())
                .reduce((a, b) => a + b) /
            entries.where((e) => e.socialInteractionLevel != null).length;

    final avgActivity = entries
            .where((e) => e.physicalActivityMinutes != null)
            .map((e) => e.physicalActivityMinutes!.toDouble())
            .toList()
            .isEmpty
        ? 30.0
        : entries
                .where((e) => e.physicalActivityMinutes != null)
                .map((e) => e.physicalActivityMinutes!.toDouble())
                .reduce((a, b) => a + b) /
            entries.where((e) => e.physicalActivityMinutes != null).length;

    // Normalize to 0-10 scale
    final normalizedSleep = (avgSleep / 10 * 10).clamp(0.0, 10.0);
    final normalizedActivity = (avgActivity / 60 * 10).clamp(0.0, 10.0);
    final normalizedSocial = avgSocial;

    // Risk scores (invert untuk radar - higher is better)
    final normalizedDepression = (100 - riskScore.depressionRisk) / 10;
    final normalizedAnxiety = (100 - riskScore.anxietyRisk) / 10;

    final categories = [
      'Mood',
      'Tidur',
      'Aktivitas',
      'Sosial',
      'Depresi',
      'Kecemasan',
    ];
    final values = [
      avgMood,
      normalizedSleep,
      normalizedActivity,
      normalizedSocial,
      normalizedDepression,
      normalizedAnxiety,
    ];

    // Create a bar chart representation instead of radar chart
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 10,
        barGroups: values.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.toDouble(),
                color: Colors.blue.shade300,
                width: 20,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= categories.length) return const Text('');
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    categories[value.toInt()],
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
