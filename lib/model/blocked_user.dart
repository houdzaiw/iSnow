import 'package:isar/isar.dart';

part 'blocked_user.g.dart';

@collection
class BlockedUser {
  Id id = Isar.autoIncrement;

  /// 被拉黑用户的 userId（唯一索引，可直接 getByBlockedUserId 查询）
  @Index(unique: true, replace: true)
  late int blockedUserId;

  /// 被拉黑用户的昵称（冗余存储，方便展示）
  String? nick;

  /// 被拉黑用户的头像
  String? avatar;

  /// 拉黑时间
  DateTime blockedAt = DateTime.now();
}

