import '../../../manager/http_api.dart';
import '../../../manager/room_location_manager.dart';
import '../../../model/room_user_info.dart';
import 'room_interaction_repository.dart';
import 'room_moderation.dart';

enum RoomManagementList {
  admins(HttpApi.roomAdminInfo, RoomModerationAction.removeAdmin),
  silenced(HttpApi.roomSilenceList, RoomModerationAction.unsilence),
  blocked(HttpApi.roomBlacklist, RoomModerationAction.unblock);

  const RoomManagementList(this.path, this.action);
  final String path;
  final RoomModerationAction action;
}

class RoomBackground {
  const RoomBackground({
    required this.id,
    required this.preview,
    required this.active,
    this.custom = false,
  });
  final int id;
  final String preview;
  final bool active;
  final bool custom;
}

extension RoomManagementRepository on RoomInteractionRepository {
  Future<List<RoomUserInfo>> members(String id, RoomManagementList kind) async {
    final data = await get(kind.path, {'roomId': id});
    return [
      if (data is List)
        for (final row in data.whereType<Map>())
          if (row['userBase'] is Map)
            RoomUserInfo.fromJson(roomInteractionMap(row)),
    ];
  }

  Future<void> updateRoom(
    String id, {
    required bool locked,
    String? title,
    String? description,
    String? avatar,
    String? password,
    bool? locationEnabled,
    RoomLocation? location,
  }) async {
    await post(HttpApi.roomUpdateInfo, {
      'roomId': id,
      'roomLock': locked,
      if (title != null) 'title': title,
      if (description != null) 'roomDesc': description,
      if (avatar != null) 'avatar': avatar,
      if (password != null) 'roomPasswd': password,
      if (locationEnabled != null) 'locationEnabled': locationEnabled,
      if (location != null) ...{
        'longitude': location.longitude,
        'latitude': location.latitude,
        'address': location.address,
      },
    });
  }

  Future<void> changeLayout(String roomId, int type) async {
    await post(HttpApi.roomMicAdjust, {'roomId': roomId, 'micType': type});
  }

  Future<List<RoomBackground>> backgrounds(int owner) async {
    final data = await get(HttpApi.roomBackgrounds, {
      'type': 6,
      'pageNum': 1,
      'targetUid': owner,
    });
    final vip = roomInteractionMap(
      await get(HttpApi.roomVipBackground, {'uid': owner}),
    );
    return [
      if (data is List)
        for (final row in data.whereType<Map>())
          if (int.tryParse('${row['goodsId']}') case final id? when id > 0)
            RoomBackground(
              id: id,
              preview: (row['icon'] ?? '').toString(),
              active: row['state'].toString() == '2',
            ),
      if (vip['backgroundUrl'] case final String url when url.trim().isNotEmpty)
        RoomBackground(
          id: 0,
          preview: url,
          active: vip['status'] == true,
          custom: true,
        ),
    ];
  }

  Future<void> useBackground(int owner, RoomBackground background) async {
    if (background.custom) {
      await post(HttpApi.roomUseVipBackground, {
        'uid': owner,
        'use': !background.active,
      });
    } else {
      await post(HttpApi.roomUseBackground, {
        'goodsType': 6,
        'goodsId': background.id,
        'useState': background.active ? 0 : 1,
        'targetUid': owner,
      });
    }
  }

  Future<void> uploadVipBackground(int owner, String url) async {
    await post(HttpApi.roomVipBackground, {'uid': owner, 'backgroundUrl': url});
  }
}
