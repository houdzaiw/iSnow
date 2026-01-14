import 'package:isar/isar.dart';

part 'diary_entry.g.dart';

@collection
class DiaryEntry {
  Id id = Isar.autoIncrement;

  late DateTime date;
  late String emoji;
  String? content;

  // 新增字段
  int? moodIndex; // 心情图标索引
  String? description; // 文字描述
  List<String>? images; // 图片路径数组
  String? type; // 类型：'edit' 或 'voice'

  DateTime createdAt = DateTime.now();
}
