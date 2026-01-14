import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/mood_providers.dart';
import 'mood_scan_page.dart';
import '../../data/local/mood_entry.dart';
import '../../../../../core/utils/haptic_feedback_helper.dart';

class MoodPage extends ConsumerStatefulWidget {
  const MoodPage({super.key});

  @override
  ConsumerState<MoodPage> createState() => _MoodPageState();
}

class _MoodPageState extends ConsumerState<MoodPage> {
  final _noteController = TextEditingController();
  int _selectedMood = 3; // backward compatible (1-5)
  double _moodRating = 5.0; // Enhanced (1-10)
  final Set<String> _selectedEmotions = {};
  double? _sleepHours;
  int? _physicalActivityMinutes;
  double _socialInteractionLevel = 5.0;
  double _productivityLevel = 5.0;
  bool _showAdvancedOptions = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _toggleEmotion(String emotion) {
    setState(() {
      if (_selectedEmotions.contains(emotion)) {
        _selectedEmotions.remove(emotion);
      } else {
        _selectedEmotions.add(emotion);
      }
    });
  }

  Future<void> _saveMood() async {
    if (ref.read(isSavingMoodProvider)) return;

    ref.read(isSavingMoodProvider.notifier).state = true;
    try {
      await ref.read(moodRepositoryProvider).add(
            mood: _selectedMood, // backward compatible
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
            moodRating: _moodRating.round(),
            emotions:
                _selectedEmotions.isEmpty ? null : _selectedEmotions.toList(),
            sleepHours: _sleepHours,
            physicalActivityMinutes: _physicalActivityMinutes,
            socialInteractionLevel: _socialInteractionLevel.round(),
            productivityLevel: _productivityLevel.round(),
          );

      // ignore: unused_result
      ref.refresh(moodWeekProvider);

      _noteController.clear();
      setState(() {
        _selectedMood = 3;
        _moodRating = 5.0;
        _selectedEmotions.clear();
        _sleepHours = null;
        _physicalActivityMinutes = null;
        _socialInteractionLevel = 5.0;
        _productivityLevel = 5.0;
        _showAdvancedOptions = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mood tersimpan.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      ref.read(isSavingMoodProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(isSavingMoodProvider);
    final week = ref.watch(moodWeekProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mood & Jurnal Emosi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bagaimana perasaan Anda hari ini?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quick Mood Selection (Backward Compatible)
                  const Text(
                    'Mood Cepat (1-5)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildQuickMoodButton(1, 'Buruk',
                          Icons.sentiment_very_dissatisfied, Colors.red),
                      const SizedBox(width: 8),
                      _buildQuickMoodButton(
                          3, 'Biasa', Icons.sentiment_neutral, Colors.amber),
                      const SizedBox(width: 8),
                      _buildQuickMoodButton(5, 'Baik',
                          Icons.sentiment_very_satisfied, Colors.green),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Enhanced Mood Rating (1-10)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Mood Rating (1-10):'),
                      Text(
                        _moodRating.round().toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getMoodColor(_moodRating),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _moodRating,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: _moodRating.round().toString(),
                    onChanged: (value) {
                      setState(() {
                        _moodRating = value;
                        // Auto-update quick mood for backward compatibility
                        if (value <= 2) {
                          _selectedMood = 1;
                        } else if (value <= 4) {
                          _selectedMood = 2;
                        } else if (value <= 6) {
                          _selectedMood = 3;
                        } else if (value <= 8) {
                          _selectedMood = 4;
                        } else {
                          _selectedMood = 5;
                        }
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Emotions Selection
                  const Text(
                    'Emosi yang dirasakan (bisa pilih lebih dari satu):',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: EmotionType.values.map((emotion) {
                      final emotionStr = emotion.name;
                      final isSelected = _selectedEmotions.contains(emotionStr);
                      return FilterChip(
                        label: Text(_getEmotionLabel(emotionStr)),
                        selected: isSelected,
                        onSelected: (_) => _toggleEmotion(emotionStr),
                        avatar: Icon(
                          _getEmotionIcon(emotionStr),
                          size: 18,
                          color: isSelected ? Colors.white : null,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Advanced Options Toggle
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showAdvancedOptions = !_showAdvancedOptions;
                      });
                    },
                    child: Row(
                      children: [
                        Icon(
                          _showAdvancedOptions
                              ? Icons.expand_less
                              : Icons.expand_more,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Data Tambahan (Opsional)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Advanced Options
                  if (_showAdvancedOptions) ...[
                    const SizedBox(height: 16),

                    // Sleep Hours
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Jam Tidur (contoh: 7.5)',
                        hintText: 'Opsional',
                        border: OutlineInputBorder(),
                        suffixText: 'jam',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _sleepHours =
                              value.isEmpty ? null : double.tryParse(value);
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    // Physical Activity
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Aktivitas Fisik',
                        hintText: 'Durasi dalam menit (contoh: 30)',
                        border: OutlineInputBorder(),
                        suffixText: 'menit',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _physicalActivityMinutes =
                              value.isEmpty ? null : int.tryParse(value);
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Social Interaction Level
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text('Interaksi Sosial (0-10):'),
                        ),
                        Text(
                          _socialInteractionLevel.round().toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _socialInteractionLevel,
                      min: 0,
                      max: 10,
                      divisions: 10,
                      label: _socialInteractionLevel.round().toString(),
                      onChanged: (value) {
                        setState(() {
                          _socialInteractionLevel = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Productivity Level
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text('Tingkat Produktivitas (0-10):'),
                        ),
                        Text(
                          _productivityLevel.round().toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _productivityLevel,
                      min: 0,
                      max: 10,
                      divisions: 10,
                      label: _productivityLevel.round().toString(),
                      onChanged: (value) {
                        setState(() {
                          _productivityLevel = value;
                        });
                      },
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Note
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Catatan (opsional)',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 2,
                    maxLines: 4,
                  ),

                  const SizedBox(height: 16),

                  // Save Button
                  FilledButton.icon(
                    onPressed: saving
                        ? null
                        : () {
                            HapticFeedbackHelper.medium();
                            _saveMood();
                          },
                    icon: saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(saving ? 'Menyimpan...' : 'Simpan Mood'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Face Scan Button
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MoodScanPage()),
                      );
                    },
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Scan Wajah (Eksperimental)'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // History
          const Text(
            'Riwayat 7 hari terakhir',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          week.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (items) {
              if (items.isEmpty) {
                return const Text('Belum ada catatan mood.');
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final it = items[i];
                  final moodRating = it.effectiveMoodRating;
                  final color = _getMoodColor(moodRating.toDouble());
                  final emotions = it.effectiveEmotions;

                  return Card(
                    child: ExpansionTile(
                      leading: Icon(
                        moodRating >= 7
                            ? Icons.sentiment_very_satisfied
                            : moodRating <= 4
                                ? Icons.sentiment_very_dissatisfied
                                : Icons.sentiment_neutral,
                        color: color,
                      ),
                      title: Text('Mood: $moodRating/10'),
                      subtitle: Text(
                        it.timestamp.toLocal().toString().split('.')[0],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (emotions.isNotEmpty) ...[
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: emotions
                                      .map((e) => Chip(
                                            label: Text(_getEmotionLabel(e)),
                                            avatar: Icon(
                                              _getEmotionIcon(e),
                                              size: 18,
                                            ),
                                          ))
                                      .toList(),
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (it.sleepHours != null)
                                Text('💤 Tidur: ${it.sleepHours} jam'),
                              if (it.physicalActivityMinutes != null)
                                Text(
                                    '🏃 Aktivitas: ${it.physicalActivityMinutes} menit'),
                              if (it.socialInteractionLevel != null)
                                Text(
                                    '👥 Sosial: ${it.socialInteractionLevel}/10'),
                              if (it.productivityLevel != null)
                                Text(
                                    '⚡ Produktivitas: ${it.productivityLevel}/10'),
                              if (it.note != null && it.note!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text('📝 ${it.note}'),
                              ],
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Hapus Mood Entry'),
                                        content: const Text(
                                          'Apakah Anda yakin ingin menghapus catatan mood ini?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Batal'),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            child: const Text('Hapus'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmed == true && mounted) {
                                      try {
                                        await ref
                                            .read(moodRepositoryProvider)
                                            .delete(it.id);
                                        final _ = ref.refresh(moodWeekProvider);
                                        if (mounted) {
                                          // ignore: use_build_context_synchronously
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content:
                                                  Text('Catatan mood berhasil dihapus'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          // ignore: use_build_context_synchronously
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text('Error: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Hapus Catatan'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMoodButton(
      int value, String label, IconData icon, Color color) {
    final isSelected = _selectedMood == value;
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () {
          setState(() {
            _selectedMood = value;
            // Auto-update mood rating for enhanced tracking
            _moodRating = value * 2.0; // 1->2, 3->6, 5->10
          });
        },
        icon: Icon(icon, color: isSelected ? Colors.white : color),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? color : null,
        ),
      ),
    );
  }

  Color _getMoodColor(double rating) {
    if (rating >= 8) return Colors.green;
    if (rating >= 6) return Colors.lightGreen;
    if (rating >= 4) return Colors.amber;
    if (rating >= 2) return Colors.orange;
    return Colors.red;
  }

  String _getEmotionLabel(String emotion) {
    switch (emotion) {
      case 'cemas':
        return 'Cemas';
      case 'lelah':
        return 'Lelah';
      case 'sedih':
        return 'Sedih';
      case 'bahagia':
        return 'Bahagia';
      case 'marah':
        return 'Marah';
      case 'netral':
        return 'Netral';
      default:
        return emotion;
    }
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
