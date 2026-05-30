import 'package:hive/hive.dart';

part 'pet_diary.g.dart';

@HiveType(typeId: 6)
class PetDiaryModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  int completedTaskCount;

  @HiveField(3)
  int focusMinutes;

  @HiveField(4)
  int focusSessionCount;

  @HiveField(5)
  int lateNightTaskCount;

  @HiveField(6)
  String diaryText;

  @HiveField(7)
  DateTime generatedAt;

  PetDiaryModel({
    required this.id,
    required this.date,
    required this.completedTaskCount,
    required this.focusMinutes,
    required this.focusSessionCount,
    required this.lateNightTaskCount,
    required this.diaryText,
    required this.generatedAt,
  });
}
