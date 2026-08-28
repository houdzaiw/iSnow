class EnterRoomResp {
  const EnterRoomResp({
    required this.roomId,
    required this.raw,
    this.identity,
    this.agoraToken,
    this.longLinkToken,
    this.status,
    this.lobbyType,
  });

  final String roomId;
  final int? identity;
  final String? agoraToken;
  final String? longLinkToken;
  final int? status;
  final int? lobbyType;
  final Map<String, dynamic> raw;

  factory EnterRoomResp.fromJson(Map<String, dynamic> json) {
    return EnterRoomResp(
      roomId: json['roomId']?.toString() ?? json['roomID']?.toString() ?? '',
      identity: _asInt(json['identity']),
      agoraToken: json['agoraToken']?.toString(),
      longLinkToken: json['longLinkToken']?.toString(),
      status: _asInt(json['status']),
      lobbyType: _asInt(json['lobbyType']),
      raw: json,
    );
  }
}

class RoomInfo {
  const RoomInfo({
    required this.roomId,
    required this.raw,
    this.title,
    this.avatar,
    this.roomDesc,
    this.roomLock,
    this.audienceCount,
  });

  final String roomId;
  final String? title;
  final String? avatar;
  final String? roomDesc;
  final bool? roomLock;
  final int? audienceCount;
  final Map<String, dynamic> raw;

  factory RoomInfo.fromJson(Map<String, dynamic> json) {
    final data = _nestedRoomInfo(json);
    return RoomInfo(
      roomId: data['roomId']?.toString() ?? data['roomID']?.toString() ?? '',
      title: data['title']?.toString(),
      avatar: data['avatar']?.toString(),
      roomDesc: data['roomDesc']?.toString(),
      roomLock: _asBool(data['roomLock']),
      audienceCount: _asInt(data['audienceCount'] ?? data['roomAudience']),
      raw: json,
    );
  }

  static Map<String, dynamic> _nestedRoomInfo(Map<String, dynamic> json) {
    final roomInfoDto = json['roomInfoDTO'];
    if (roomInfoDto is Map) {
      return roomInfoDto.cast<String, dynamic>();
    }
    final roomInfo = json['roomInfo'];
    if (roomInfo is Map) {
      return roomInfo.cast<String, dynamic>();
    }
    return json;
  }
}

class RoomMicModel {
  const RoomMicModel({
    required this.position,
    required this.raw,
    this.uid,
    this.isLocked,
    this.isMuted,
    this.userInfo,
  });

  final int position;
  final int? uid;
  final bool? isLocked;
  final bool? isMuted;
  final Map<String, dynamic>? userInfo;
  final Map<String, dynamic> raw;

  factory RoomMicModel.fromJson(Map<String, dynamic> json) {
    final roomUserBaseDto = _asMap(json['roomUserBaseDto']);
    final roomUserBase = _asMap(roomUserBaseDto?['userBase']);
    final userInfo =
        _asMap(json['userBaseInfo'] ?? json['userInfo']) ?? roomUserBase;
    return RoomMicModel(
      position:
          _asInt(json['position'] ?? json['pos'] ?? json['micIndex']) ?? -1,
      uid: _asInt(
        json['uid'] ??
            json['userId'] ??
            json['userID'] ??
            roomUserBaseDto?['uid'] ??
            roomUserBase?['uid'],
      ),
      isLocked: _asBool(json['isLock'] ?? json['isLocked'] ?? json['lock']),
      isMuted: _asBool(json['isMute'] ?? json['isMuted'] ?? json['mute']),
      userInfo: userInfo,
      raw: json,
    );
  }
}

class RoomMicOperateResp {
  const RoomMicOperateResp({required this.raw, this.position, this.uid});

  final int? position;
  final int? uid;
  final Map<String, dynamic> raw;

  factory RoomMicOperateResp.fromJson(Map<String, dynamic> json) {
    return RoomMicOperateResp(
      position: _asInt(json['position'] ?? json['pos'] ?? json['micIndex']),
      uid: _asInt(json['uid'] ?? json['userId'] ?? json['userID']),
      raw: json,
    );
  }
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

bool? _asBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().toLowerCase();
  if (text == 'true') return true;
  if (text == 'false') return false;
  return null;
}

Map<String, dynamic>? _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return null;
}
