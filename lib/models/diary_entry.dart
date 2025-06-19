import 'package:hive/hive.dart';

part 'diary_entry.g.dart';

@HiveType(typeId: 0)
class DiaryEntry extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  int minutes;

  @HiveField(3)
  String content;

  @HiveField(4)
  bool isFavorite;

  @HiveField(5)
  bool isEditing;

  DiaryEntry({
    required this.title,
    required this.date,
    required this.minutes,
    required this.content,
    this.isFavorite = false,
    this.isEditing = false,
  });

  void update({
    required String newTitle,
    required int newMinutes,
    required String newContent,
  }) {
    title = newTitle;
    minutes = newMinutes;
    content = newContent;
    isEditing = false;
    save();
  }

  void toggleEditing() {
    isEditing = !isEditing;
    save();
  }
}