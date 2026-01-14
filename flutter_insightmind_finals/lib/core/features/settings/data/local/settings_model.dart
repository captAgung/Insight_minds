import 'package:hive/hive.dart';

// part 'settings_model.g.dart'; // Not using code generation, using manual adapter

@HiveType(typeId: 11)
class SettingsModel extends HiveObject {
  @HiveField(0)
  String? userName;

  @HiveField(1)
  int? userAge;

  @HiveField(2)
  String? emergencyContactName;

  @HiveField(3)
  String? emergencyContactPhone;

  @HiveField(4)
  bool dailyReminderEnabled;

  @HiveField(5)
  String? reminderTime;

  @HiveField(6)
  bool riskAlertEnabled;

  @HiveField(7)
  bool darkModeEnabled;

  @HiveField(8)
  bool? hasCompletedOnboarding;

  SettingsModel({
    this.userName,
    this.userAge,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.dailyReminderEnabled = true,
    this.reminderTime = '09:00',
    this.riskAlertEnabled = true,
    this.darkModeEnabled = false,
    this.hasCompletedOnboarding = false,
  });

  @override
  Future<void> save() async {
    await Hive.box<SettingsModel>('settings').put('user_settings', this);
  }

  static SettingsModel load() {
    final box = Hive.box<SettingsModel>('settings');
    return box.get('user_settings') ?? SettingsModel();
  }
}

class SettingsModelAdapter extends TypeAdapter<SettingsModel> {
  @override
  final int typeId = 11;

  @override
  SettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsModel(
      userName: fields[0] as String?,
      userAge: fields[1] as int?,
      emergencyContactName: fields[2] as String?,
      emergencyContactPhone: fields[3] as String?,
      dailyReminderEnabled: fields[4] as bool? ?? true,
      reminderTime: fields[5] as String?,
      riskAlertEnabled: fields[6] as bool? ?? true,
      darkModeEnabled: fields[7] as bool? ?? false,
      hasCompletedOnboarding: fields[8] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.userName)
      ..writeByte(1)
      ..write(obj.userAge)
      ..writeByte(2)
      ..write(obj.emergencyContactName)
      ..writeByte(3)
      ..write(obj.emergencyContactPhone)
      ..writeByte(4)
      ..write(obj.dailyReminderEnabled)
      ..writeByte(5)
      ..write(obj.reminderTime)
      ..writeByte(6)
      ..write(obj.riskAlertEnabled)
      ..writeByte(7)
      ..write(obj.darkModeEnabled)
      ..writeByte(8)
      ..write(obj.hasCompletedOnboarding);
  }
}
