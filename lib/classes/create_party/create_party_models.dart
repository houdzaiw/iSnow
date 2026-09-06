import '../../model/user_profile.dart';
import '../../model/room_models.dart';

class CreatePartyTag {
  const CreatePartyTag({
    required this.id,
    required this.arName,
    required this.enName,
    this.trName,
    this.idName,
    this.tagPic,
    this.seqNo = 0,
  });

  final int id;
  final String arName;
  final String enName;
  final String? trName;
  final String? idName;
  final String? tagPic;
  final int seqNo;

  String nameForLocale(String languageCode) {
    final preferred = switch (languageCode) {
      'tr' => trName,
      'id' => idName,
      _ => enName,
    };
    return _firstText(preferred, enName, arName, idName, trName, '$id');
  }

  factory CreatePartyTag.fromJson(Map<dynamic, dynamic> json) {
    return CreatePartyTag(
      id: _int(json['id']),
      arName: _string(json['arName']) ?? '',
      enName: _string(json['enName']) ?? '',
      trName: _string(json['trName']),
      idName: _string(json['idName']),
      tagPic: _string(json['tagPic']),
      seqNo: _int(json['seqNo']),
    );
  }
}

class CreatePartyHost {
  const CreatePartyHost({
    required this.name,
    required this.idText,
    this.avatar,
    this.countryCode,
  });

  final String name;
  final String idText;
  final String? avatar;
  final String? countryCode;

  factory CreatePartyHost.fromUser(UserData? user) {
    final userNo = user?.userNo;
    return CreatePartyHost(
      name: _firstText(user?.nick, 'anywhere'),
      idText: userNo == null || userNo <= 0 ? '100100' : '$userNo',
      avatar: _string(user?.avatar),
      countryCode: _string(user?.countryCode)?.toUpperCase(),
    );
  }

  factory CreatePartyHost.fromRoomInfo(
    RoomInfo? roomInfo, {
    UserData? fallbackUser,
  }) {
    final title = _string(roomInfo?.title);
    final roomNo = _string(roomInfo?.roomNo);
    final roomId = _string(roomInfo?.roomId);
    final avatar = _string(roomInfo?.avatar);
    if (title == null && roomNo == null && roomId == null && avatar == null) {
      return CreatePartyHost.fromUser(fallbackUser);
    }

    return CreatePartyHost(
      name: _firstText(title, fallbackUser?.nick, 'anywhere'),
      idText: _firstText(roomNo, roomId, fallbackUser?.userNo?.toString()),
      avatar: avatar ?? _string(fallbackUser?.avatar),
      countryCode: _string(fallbackUser?.countryCode)?.toUpperCase(),
    );
  }
}

class CreatePartyDraft {
  const CreatePartyDraft({
    required this.picUrl,
    required this.topic,
    required this.description,
    required this.duration,
    required this.beginTime,
    required this.tagIdList,
  });

  final String picUrl;
  final String topic;
  final String description;
  final int duration;
  final DateTime beginTime;
  final List<String> tagIdList;

  Map<String, dynamic> toJson() {
    return {
      'picUrl': picUrl,
      'topic': topic,
      'description': description,
      'duration': duration,
      'beginTime': beginTime.toUtc().millisecondsSinceEpoch,
      'tagIdList': tagIdList,
    };
  }
}

String _firstText(
  String? first, [
  String? second,
  String? third,
  String? fourth,
  String? fifth,
  String fallback = '',
]) {
  for (final item in [first, second, third, fourth, fifth]) {
    final text = _string(item);
    if (text != null) return text;
  }
  return fallback;
}

String? _string(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
