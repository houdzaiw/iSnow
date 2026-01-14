import 'package:isar/isar.dart';

part 'diary_entry.g.dart';

@collection
class DiaryEntry {
  Id id = Isar.autoIncrement;

  late DateTime date;
  late String emoji;
  String? content;

  DateTime createdAt = DateTime.now();
}
