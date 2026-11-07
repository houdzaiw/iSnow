import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/http_api.dart';
import '../../../manager/http_dio_manager.dart';
import '../../../model/room_user_info.dart';
import '../../../model/server_response.dart';

final roomInteractionRepositoryProvider = Provider(
  (ref) => RoomInteractionRepository(),
);

class RoomInteractionRepository {
  RoomInteractionRepository({HttpDioManager? http})
    : _http = http ?? HttpDioManager();

  final HttpDioManager _http;

  Future<RoomUserInfo> user(String roomId, int uid) async {
    final data = await get(HttpApi.roomUserInfo, {
      'roomId': roomId,
      'targetUid': uid,
    });
    final user = RoomUserInfo.fromJson(roomInteractionMap(data));
    if (user.uid != uid) {
      throw const NadyApiException(message: 'Room user is unavailable');
    }
    return user;
  }

  Future<void> setFollowing(int uid, bool following) async {
    await post(HttpApi.userFollow, {
      'targetUid': uid,
      'isFollowing': following,
    });
  }

  Future<List<RoomLinkedParty>> parties(
    String roomId, {
    required bool history,
    required int page,
  }) async {
    final data = await post(HttpApi.roomPartyList, {
      'roomId': roomId,
      'history': history,
      'pageNum': page,
    });
    return [
      if (data is List)
        for (final row in data.whereType<Map>())
          if (RoomLinkedParty.fromJson(roomInteractionMap(row)) case final party
              when party.id > 0)
            party,
    ];
  }

  Future<RoomLinkedParty> partyDetail(int id) async {
    final result = RoomLinkedParty.fromJson(
      roomInteractionMap(await get(HttpApi.roomPartyDetail, {'partyId': id})),
    );
    if (result.id != id) {
      throw const NadyApiException(message: 'Party is unavailable');
    }
    return result;
  }

  Future<void> partyReminder(int id, bool enabled) async {
    await post(HttpApi.roomPartySubscribe, {
      'partyId': id,
      'type': enabled ? 1 : 2,
    });
  }

  Future<void> cancelParty(int id) async {
    await post(HttpApi.roomPartyCancel, {'partyId': id});
  }

  Future<Object?> get(String path, Map<String, dynamic> query) async =>
      _data(await _http.get(path, queryParameters: query));

  Future<Object?> post(String path, Map<String, dynamic> body) async =>
      _data(await _http.post(path, data: body));

  Object? _data(Object? response) {
    final result = NadyServerResponse<Object?>.fromJson(
      roomInteractionMap(response),
      (value) => value,
    );
    if (!result.isSuccess) throw result.toException();
    return result.data;
  }
}

Map<String, dynamic> roomInteractionMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

class RoomLinkedParty {
  const RoomLinkedParty({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.cover,
    required this.startsAt,
    required this.ownerUid,
    required this.subscribed,
    required this.raw,
    this.creatorName = '',
    this.creatorAvatar,
    this.subscribeNum = 0,
  });

  factory RoomLinkedParty.fromJson(Map<String, dynamic> json) {
    final text = '${json['beginTime']}';
    final time = int.tryParse(text);
    final host = roomInteractionMap(json['createUserInfo']);
    return RoomLinkedParty(
      id: int.tryParse('${json['partyId'] ?? json['id']}') ?? 0,
      title: (json['topic'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      status: json['cancle'] == true
          ? 4
          : int.tryParse('${json['status']}') ?? 0,
      cover: json['picUrl']?.toString(),
      startsAt: time != null && time > 0
          ? DateTime.fromMillisecondsSinceEpoch(
              time < 100000000000 ? time * 1000 : time,
            )
          : DateTime.tryParse(text),
      ownerUid: int.tryParse('${host['uid'] ?? json['uid']}') ?? 0,
      creatorName: (host['nick'] ?? '').toString(),
      creatorAvatar: host['avatar']?.toString(),
      subscribeNum: int.tryParse('${json['subscribeNum']}') ?? 0,
      subscribed: json['isSubscribe'] == true,
      raw: Map.unmodifiable(json),
    );
  }

  final int id, status, ownerUid;
  final String creatorName;
  final String? creatorAvatar;
  final int subscribeNum;
  final String title, description;
  final String? cover;
  final DateTime? startsAt;
  final bool subscribed;
  final Map<String, dynamic> raw;

  Map<String, dynamic> invitation() {
    Object? clean(Object? value) => switch (value) {
      Map() => <String, dynamic>{
        for (final entry in value.entries)
          if (entry.key is String &&
              !RegExp(
                r'passwd|password|token|phone|loginip|latitude|longitude',
                caseSensitive: false,
              ).hasMatch(entry.key as String))
            entry.key as String: clean(entry.value),
      },
      List() => value.map(clean).toList(),
      _ => value,
    };
    return roomInteractionMap(clean(raw));
  }
}
