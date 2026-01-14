import 'package:hive/hive.dart';

part 'mood_entry.g.dart';

enum EmotionType {
  cemas,
  lelah,
  sedih,
  bahagia,
  marah,
  netral,
}

@HiveType(typeId: 9)
class MoodEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime timestamp;

  @HiveField(2)
  int mood; // 1 (very bad) .. 5 (very good) - DEPRECATED, gunakan moodRating
  // Backward compatibility: jika moodRating null, gunakan mood * 2 untuk konversi

  @HiveField(3)
  String? note;

  // New fields untuk enhanced mood tracking
  @HiveField(4)
  int? moodRating; // 1-10 (1 = sangat buruk, 10 = sangat baik)

  @HiveField(5)
  List<String>? emotions; // List of emotion types (e.g., ["cemas", "lelah"])

  // Behavioral data
  @HiveField(6)
  double? sleepHours; // Jam tidur (contoh: 7.5 = 7 jam 30 menit)

  @HiveField(7)
  int? physicalActivityMinutes; // Durasi aktivitas fisik dalam menit

  @HiveField(8)
  int? socialInteractionLevel; // 0-10 (0 = tidak ada, 10 = sangat aktif)

  @HiveField(9)
  int? productivityLevel; // 0-10 (0 = tidak produktif, 10 = sangat produktif)

  MoodEntry({
    required this.id,
    required this.timestamp,
    required this.mood,
    this.note,
    this.moodRating,
    this.emotions,
    this.sleepHours,
    this.physicalActivityMinutes,
    this.socialInteractionLevel,
    this.productivityLevel,
  });

  // Helper untuk mendapatkan mood rating yang valid (prioritaskan moodRating, fallback ke mood)
  int get effectiveMoodRating {
    if (moodRating != null) return moodRating!;
    // Convert old 1-5 scale to 1-10 scale: 1->2, 2->4, 3->6, 4->8, 5->10
    return (mood * 2).clamp(1, 10);
  }

  // Helper untuk mendapatkan emotions sebagai List<String>
  List<String> get effectiveEmotions {
    return emotions ?? [];
  }
}

class MoodEntryAdapter extends TypeAdapter<MoodEntry> {
  @override
  final int typeId = 9;

  @override
  MoodEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MoodEntry(
      id: fields[0] as String,
      timestamp: fields[1] as DateTime,
      mood: fields[2] as int,
      note: fields[3] as String?,
      moodRating: fields[4] as int?,
      emotions: (fields[5] as List?)?.cast<String>(),
      sleepHours: fields[6] as double?,
      physicalActivityMinutes: fields[7] as int?,
      socialInteractionLevel: fields[8] as int?,
      productivityLevel: fields[9] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, MoodEntry obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.mood)
      ..writeByte(3)
      ..write(obj.note)
      ..writeByte(4)
      ..write(obj.moodRating)
      ..writeByte(5)
      ..write(obj.emotions)
      ..writeByte(6)
      ..write(obj.sleepHours)
      ..writeByte(7)
      ..write(obj.physicalActivityMinutes)
      ..writeByte(8)
      ..write(obj.socialInteractionLevel)
      ..writeByte(9)
      ..write(obj.productivityLevel);
  }
}
