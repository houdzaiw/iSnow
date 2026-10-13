import 'base_user_model.dart';
import 'room_models.dart';

class RoomUserInfo {
  const RoomUserInfo({
    required this.userBase,
    required this.roomIdentity,
    required this.raw,
    this.silenceEndTime,
  });

  final BaseUserInfo userBase;
  final UserRoomIdentity roomIdentity;
  final int? silenceEndTime;
  final Map<String, dynamic> raw;

  int get uid => userBase.uid;

  factory RoomUserInfo.fromJson(Map<String, dynamic> json) {
    final user = json['userBase'];
    if (user is! Map) {
      throw const FormatException('Missing room audience userBase');
    }
    final identity = userRoomIdentityFromJson(json['roomIdentity']);
    return RoomUserInfo(
      userBase: BaseUserInfo.fromJson(user.cast<String, dynamic>()),
      roomIdentity: identity ?? UserRoomIdentity.audience,
      silenceEndTime: (json['silenceEndTime'] as num?)?.toInt(),
      raw: json,
    );
  }
}
