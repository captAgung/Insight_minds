import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/risk_analysis_providers.dart';
import '../../../mood/presentation/providers/mood_providers.dart';
import '../../../mood/data/local/mood_entry.dart';
import '../../domain/entities/risk_score.dart';

class MoodCalendarPage extends ConsumerStatefulWidget {
  const MoodCalendarPage({super.key});

  @override
  ConsumerState<MoodCalendarPage> createState() => _MoodCalendarPageState();
}

class _MoodCalendarPageState extends ConsumerState<MoodCalendarPage> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = DateTime(now.year, now.month, now.day);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  Color _getMoodColor(int moodRating) {
    if (moodRating >= 8) return Colors.green;
    if (moodRating >= 6) return Colors.lightGreen;
    if (moodRating >= 4) return Colors.amber;
    if (moodRating >= 2) return Colors.orange;
    return Colors.red;
  }

  Color _getRiskColor(RiskLevel? level) {
    if (level == null) return Colors.grey;
    switch (level) {
      case RiskLevel.low:
        return Colors.green;
      case RiskLevel.moderate:
        return Colors.orange;
      case RiskLevel.high:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final moodAsync = ref.watch(moodWeekProvider);
    final riskScoresAsync = ref.watch(riskScoreListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood & Risk Calendar'),
      ),
      body: Column(
        children: [
          // Calendar
          moodAsync.when(
            loading: () => const Card(
              margin: EdgeInsets.all(16),
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, stack) => Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error loading calendar: $error'),
              ),
            ),
            data: (moodEntries) {
              return riskScoresAsync.when(
                loading: () => const Card(
                  margin: EdgeInsets.all(16),
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, stack) => Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error loading risk scores: $error'),
                  ),
                ),
                data: (riskScores) {
                  return Card(
                    margin: const EdgeInsets.all(16),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      calendarFormat: _calendarFormat,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      locale: 'id_ID',
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: true,
                        titleCentered: true,
                      ),
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Colors.indigo.shade100,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: Colors.indigo,
                          shape: BoxShape.circle,
                        ),
                        outsideDaysVisible: false,
                        markerDecoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                      ),
                      eventLoader: (day) {
                        final dateOnly = DateTime(day.year, day.month, day.day);
                        final hasMood = moodEntries.any((e) {
                          final entryDate = DateTime(
                            e.timestamp.year,
                            e.timestamp.month,
                            e.timestamp.day,
                          );
                          return isSameDay(entryDate, dateOnly);
                        });
                        final hasRisk = riskScores.any((s) {
                          final scoreDate = DateTime(
                            s.calculatedAt.year,
                            s.calculatedAt.month,
                            s.calculatedAt.day,
                          );
                          return isSameDay(scoreDate, dateOnly);
                        });
                        return hasMood || hasRisk ? [1, 2] : [];
                      },
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, events) {
                          if (events.isEmpty) return null;
                          final dateOnly = DateTime(date.year, date.month, date.day);
                          
                          // Get mood for this date
                          final moodEntry = moodEntries.firstWhere(
                            (e) {
                              final entryDate = DateTime(
                                e.timestamp.year,
                                e.timestamp.month,
                                e.timestamp.day,
                              );
                              return isSameDay(entryDate, dateOnly);
                            },
                            orElse: () => moodEntries.first,
                          );
                          
                          // Get risk score for this date
                          RiskScore? riskScore;
                          try {
                            riskScore = riskScores.firstWhere(
                              (s) {
                                final scoreDate = DateTime(
                                  s.calculatedAt.year,
                                  s.calculatedAt.month,
                                  s.calculatedAt.day,
                                );
                                return isSameDay(scoreDate, dateOnly);
                              },
                            );
                          } catch (e) {
                            riskScore = null;
                          }

                          final moodRating = moodEntry.effectiveMoodRating;
                          final moodColor = _getMoodColor(moodRating);
                          final riskColor = _getRiskColor(riskScore?.overallLevel);

                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: moodColor,
                                  shape: BoxShape.circle,
                                ),
                                margin: const EdgeInsets.only(right: 2),
                              ),
                              if (riskScore != null)
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: riskColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = DateTime(
                            selectedDay.year,
                            selectedDay.month,
                            selectedDay.day,
                          );
                          _focusedDay = focusedDay;
                        });
                      },
                      onFormatChanged: (format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        setState(() {
                          _focusedDay = focusedDay;
                        });
                      },
                    ),
                  );
                },
              );
            },
          ),

          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('Mood', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.purple,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('Risk Score', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Selected Day Details
          Expanded(
            child: _buildSelectedDayDetails(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayDetails() {
    final moodAsync = ref.watch(moodWeekProvider);
    final riskScoresAsync = ref.watch(riskScoreListProvider);

    return moodAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (moodEntries) {
        return riskScoresAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (riskScores) {
            final selectedDateOnly = DateTime(
              _selectedDay.year,
              _selectedDay.month,
              _selectedDay.day,
            );

            final dayMoodEntries = moodEntries.where((e) {
              final entryDate = DateTime(
                e.timestamp.year,
                e.timestamp.month,
                e.timestamp.day,
              );
              return isSameDay(entryDate, selectedDateOnly);
            }).toList();

            RiskScore? dayRiskScore;
            try {
              dayRiskScore = riskScores.firstWhere((s) {
                final scoreDate = DateTime(
                  s.calculatedAt.year,
                  s.calculatedAt.month,
                  s.calculatedAt.day,
                );
                return isSameDay(scoreDate, selectedDateOnly);
              });
            } catch (e) {
              dayRiskScore = null;
            }

            if (dayMoodEntries.isEmpty && dayRiskScore == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Tidak ada data untuk tanggal ini',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (dayMoodEntries.isNotEmpty) ...[
                  const Text(
                    'Mood Entries',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...dayMoodEntries.map((entry) => _buildMoodCard(entry)),
                  const SizedBox(height: 16),
                ],
                if (dayRiskScore != null) ...[
                  const Text(
                    'Risk Score',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildRiskScoreCard(dayRiskScore),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMoodCard(MoodEntry entry) {
    final moodRating = entry.effectiveMoodRating;
    final color = _getMoodColor(moodRating);
    final emotions = entry.effectiveEmotions;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mood: $moodRating/10',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            if (emotions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: emotions.map((e) => Chip(
                      label: Text(e),
                      avatar: Icon(
                        _getEmotionIcon(e),
                        size: 18,
                      ),
                    )).toList(),
              ),
            ],
            if (entry.sleepHours != null ||
                entry.physicalActivityMinutes != null ||
                entry.socialInteractionLevel != null ||
                entry.productivityLevel != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              if (entry.sleepHours != null)
                Text('💤 Tidur: ${entry.sleepHours} jam'),
              if (entry.physicalActivityMinutes != null)
                Text('🏃 Aktivitas: ${entry.physicalActivityMinutes} menit'),
              if (entry.socialInteractionLevel != null)
                Text('👥 Sosial: ${entry.socialInteractionLevel}/10'),
              if (entry.productivityLevel != null)
                Text('⚡ Produktivitas: ${entry.productivityLevel}/10'),
            ],
            if (entry.note != null && entry.note!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text('📝 ${entry.note}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRiskScoreCard(RiskScore score) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Risk Analysis',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _getRiskColor(score.overallLevel),
              ),
            ),
            const SizedBox(height: 16),
            _buildRiskProgressBar('Depresi', score.depressionRisk, Colors.blue),
            const SizedBox(height: 12),
            _buildRiskProgressBar('Kecemasan', score.anxietyRisk, Colors.orange),
            const SizedBox(height: 12),
            _buildRiskProgressBar('Burnout', score.burnoutRisk, Colors.red),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Confidence: ${score.confidenceScore.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${score.calculatedAt.hour.toString().padLeft(2, '0')}:${score.calculatedAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskProgressBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              '${value.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value / 100,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  IconData _getEmotionIcon(String emotion) {
    switch (emotion) {
      case 'cemas':
        return Icons.psychology;
      case 'lelah':
        return Icons.bedtime;
      case 'sedih':
        return Icons.sentiment_dissatisfied;
      case 'bahagia':
        return Icons.sentiment_very_satisfied;
      case 'marah':
        return Icons.mood_bad;
      case 'netral':
        return Icons.sentiment_neutral;
      default:
        return Icons.tag;
    }
  }
}
