import 'package:hive/hive.dart';

part 'screening_record.g.dart';

@HiveType(typeId: 0)
class ScreeningRecord extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late DateTime date;

  @HiveField(2)
  late List<int> answers;

  // Tambahkan constructor/manual adapter jika perlu
}
