import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart'; // WEEK6: init Hive
import 'core/features/onboarding/presentation/pages/splash_screen.dart';
import 'core/features/insightmind/data/local/screening_record.dart'; // gunakan model dari core/
import 'core/features/jadwal_kesehatan/data/local/schedule_item.dart';
import 'core/features/mood/data/local/mood_entry.dart';
import 'core/features/habit/data/local/habit_entry.dart';
import 'core/features/settings/data/local/settings_model.dart';
import 'package:intl/date_symbol_data_local.dart'; // Tambahkan import ini
import 'package:timezone/data/latest_all.dart' as tz;
import 'core/features/settings/domain/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone (synchronous, fast)
  tz.initializeTimeZones();

  // WEEK6: Inisialisasi Hive untuk Flutter (buat direktori penyimpanan)
  await Hive.initFlutter();

  // Registrasi adapter (synchronous, fast)
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(ScreeningRecordAdapter());
  }
  if (!Hive.isAdapterRegistered(7)) {
    Hive.registerAdapter(ScheduleItemAdapter());
  }
  if (!Hive.isAdapterRegistered(9)) {
    Hive.registerAdapter(MoodEntryAdapter());
  }
  if (!Hive.isAdapterRegistered(10)) {
    Hive.registerAdapter(HabitEntryAdapter());
  }
  if (!Hive.isAdapterRegistered(11)) {
    Hive.registerAdapter(SettingsModelAdapter());
  }

  // Jalankan operasi async secara paralel untuk mempercepat loading
  await Future.wait([
    // Buka box secara paralel (lebih cepat)
    Hive.openBox<ScreeningRecord>('screening_record'),
    Hive.openBox<SettingsModel>('settings'),
    // Initialize date formatting (bisa berjalan paralel)
    initializeDateFormatting('id', null),
  ]);

  // Render UI secepat mungkin
  runApp(const ProviderScope(child: SplashScreen()));

  // Inisialisasi notifikasi secara non-blocking setelah UI tampil
  // Menghindari hang di sebagian perangkat saat meminta izin notifikasi
  // ignore: unawaited_futures
  NotificationService().initialize();
}
