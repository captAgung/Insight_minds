import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:hive/hive.dart';
import '../../../../../core/utils/haptic_feedback_helper.dart';
import '../../domain/services/notification_service.dart';
import '../../../risk_analysis/data/local/assessment_repository.dart';
import '../../../risk_analysis/data/local/risk_score_repository.dart';
import '../../../mood/data/local/mood_repository.dart';
import '../../../habit/data/local/habit_repository.dart';
import '../../../jadwal_kesehatan/data/local/schedule_repository.dart';
import '../providers/settings_providers.dart';

class ProfileSettingsPage extends ConsumerStatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  ConsumerState<ProfileSettingsPage> createState() =>
      _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends ConsumerState<ProfileSettingsPage> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final settings = ref.read(settingsProvider);
    _nameController.text = settings.userName ?? '';
    _ageController.text = settings.userAge?.toString() ?? '';
    _emergencyNameController.text = settings.emergencyContactName ?? '';
    _emergencyPhoneController.text = settings.emergencyContactPhone ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final settings = ref.read(settingsProvider);
    settings.userName = _nameController.text.trim();
    settings.userAge = int.tryParse(_ageController.text.trim());
    settings.emergencyContactName = _emergencyNameController.text.trim();
    settings.emergencyContactPhone = _emergencyPhoneController.text.trim();
    await settings.save();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil disimpan')),
      );
    }
  }

  Future<void> _exportData() async {
    try {
      final exportData = <String, dynamic>{};

      // Export Mood Entries
      final moodRepo = MoodRepository();
      final moodEntries = await moodRepo.listAll();
      exportData['mood_entries'] = moodEntries
          .map((e) => {
                'id': e.id,
                'timestamp': e.timestamp.toIso8601String(),
                'mood': e.mood,
                'moodRating': e.moodRating,
                'emotions': e.emotions,
                'sleepHours': e.sleepHours,
                'physicalActivityMinutes': e.physicalActivityMinutes,
                'socialInteractionLevel': e.socialInteractionLevel,
                'productivityLevel': e.productivityLevel,
                'note': e.note,
              })
          .toList();

      // Export Assessments
      final assessmentRepo = AssessmentRepository();
      final assessments = await assessmentRepo.getAll();
      exportData['assessments'] = assessments
          .map((a) => {
                'id': a.id,
                'timestamp': a.timestamp.toIso8601String(),
                'type': a.type.toString().split('.').last,
                'totalScore': a.totalScore,
                'answers': a.answers,
              })
          .toList();

      // Export Risk Scores
      final riskRepo = RiskScoreRepository();
      final riskScores = await riskRepo.getAll();
      exportData['risk_scores'] = riskScores.map((r) => r.toJson()).toList();

      // Export Habits
      final habitRepo = HabitRepository();
      final habits = await habitRepo.listAll();
      exportData['habits'] = habits
          .map((h) => {
                'id': h.id,
                'title': h.title,
                'createdAt': h.createdAt.toIso8601String(),
                'completedDates':
                    h.completedDates.map((c) => c.toIso8601String()).toList(),
              })
          .toList();

      // Export Schedules
      final scheduleRepo = ScheduleRepository();
      final schedules = await scheduleRepo.listAll();
      exportData['schedules'] = schedules
          .map((s) => {
                'id': s.id,
                'title': s.title,
                'date': s.date.toIso8601String(),
                'note': s.note,
                'isDone': s.isDone,
              })
          .toList();

      exportData['exported_at'] = DateTime.now().toIso8601String();
      exportData['app_version'] = '1.0.0';

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Save to file and share
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
          '${directory.path}/insightmind_export_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Data Export dari InsightMind',
        );
        messenger.showSnackBar(
          const SnackBar(content: Text('Data berhasil diekspor')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saat mengekspor data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua Data'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus semua data? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Clear all boxes
        await Hive.box('mood_entries').clear();
        await Hive.box('assessment_results').clear();
        await Hive.box('risk_scores').clear();
        await Hive.box('habits').clear();
        await Hive.box('schedules').clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Semua data berhasil dihapus')),
          );
          // Refresh providers
          // ignore: unused_result
          ref.refresh(settingsProvider);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Personal Info Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Pribadi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama',
                      hintText: 'Masukkan nama Anda',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ageController,
                    decoration: const InputDecoration(
                      labelText: 'Usia',
                      hintText: 'Masukkan usia',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _saveProfile,
                    icon: const Icon(Icons.save),
                    label: const Text('Simpan Profil'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Emergency Contacts Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kontak Darurat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kontak yang dapat dihubungi saat darurat',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emergencyNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Kontak',
                      hintText: 'Masukkan nama kontak darurat',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.emergency),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emergencyPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Telepon',
                      hintText: 'Masukkan nomor telepon',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _saveProfile,
                    icon: const Icon(Icons.save),
                    label: const Text('Simpan Kontak Darurat'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Notification Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pengaturan Notifikasi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Daily Check-in Reminder'),
                    subtitle: const Text('Ingatkan untuk check-in mood harian'),
                    value: settings.dailyReminderEnabled,
                    onChanged: (value) async {
                      HapticFeedbackHelper.selection();
                      settings.dailyReminderEnabled = value;
                      await settings.save();

                      final notificationService = NotificationService();
                      if (value) {
                        await notificationService.scheduleDailyReminder(
                          time: settings.reminderTime ?? '09:00',
                          id: 1,
                        );
                      } else {
                        await notificationService.cancelDailyReminder(1);
                      }

                      setState(() {});
                    },
                  ),
                  if (settings.dailyReminderEnabled)
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                      child: Row(
                        children: [
                          const Text('Waktu: '),
                          Expanded(
                            child: DropdownButton<String>(
                              value: settings.reminderTime ?? '09:00',
                              isExpanded: true,
                              items: [
                                '07:00',
                                '08:00',
                                '09:00',
                                '10:00',
                                '18:00',
                                '20:00',
                              ].map((time) {
                                return DropdownMenuItem(
                                  value: time,
                                  child: Text(time),
                                );
                              }).toList(),
                              onChanged: (value) async {
                                HapticFeedbackHelper.selection();
                                settings.reminderTime = value;
                                await settings.save();

                                final notificationService =
                                    NotificationService();
                                await notificationService
                                    .cancelDailyReminder(1);
                                if (settings.dailyReminderEnabled) {
                                  await notificationService
                                      .scheduleDailyReminder(
                                    time: value ?? '09:00',
                                    id: 1,
                                  );
                                }

                                setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Risk Alert Notifications'),
                    subtitle:
                        const Text('Notifikasi saat risiko tinggi terdeteksi'),
                    value: settings.riskAlertEnabled,
                    onChanged: (value) async {
                      HapticFeedbackHelper.selection();
                      settings.riskAlertEnabled = value;
                      await settings.save();
                      setState(() {});
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Gunakan tema gelap'),
                    value: settings.darkModeEnabled,
                    onChanged: (value) async {
                      HapticFeedbackHelper.selection();
                      settings.darkModeEnabled = value;
                      await settings.save();
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Data Management
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manajemen Data',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.download),
                    title: const Text('Ekspor Data'),
                    subtitle: const Text('Simpan semua data ke file JSON'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      HapticFeedbackHelper.medium();
                      _exportData();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading:
                        const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Hapus Semua Data',
                        style: TextStyle(color: Colors.red)),
                    subtitle: const Text('Hapus semua data yang tersimpan'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      HapticFeedbackHelper.heavy();
                      _clearAllData();
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // App Info
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tentang Aplikasi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    leading: Icon(Icons.info),
                    title: Text('Versi'),
                    subtitle: Text('1.0.0'),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.description),
                    title: Text('Disclaimer'),
                    subtitle: Text(
                      'Aplikasi ini bukan diagnosis medis profesional. '
                      'Hasil hanya sebagai indikasi awal. Untuk diagnosis yang akurat, '
                      'konsultasikan dengan profesional kesehatan mental.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.lock),
                    title: Text('Privasi'),
                    subtitle: Text(
                      'Semua data disimpan lokal di perangkat Anda. '
                      'Tidak ada data yang dikirim ke server eksternal.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
