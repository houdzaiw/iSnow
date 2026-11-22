import '../more/room_tools_repository.dart';
import '../../../manager/http_api.dart';
import '../more/room_tools_models.dart';
import 'room_pk_models.dart';

class RoomPkRepository {
  RoomPkRepository(this.tools);
  final RoomToolsRepository tools;
  Future<void> begin(String roomId, int duration, List<ToolJson> users) async {
    await tools.post(HttpApi.roomPkBegin, {
      'roomId': roomId,
      'duration': duration,
      'pkUserList': users,
    });
  }

  Future<void> end(String roomId) async {
    await tools.post(HttpApi.roomPkOver, {'roomId': roomId});
  }

  Future<RoomPkData> fetch(String roomId, {String? pkId}) async {
    final raw = toolMap(
      await tools.get(HttpApi.roomPkInfo, {
        'roomId': roomId,
        if (pkId != null) 'pkId': pkId,
      }),
    );
    // Nady restores current PK from pkInfo even if the snapshot has no eventType.
    if (pkId == null &&
        toolInt(raw['eventType']) == 0 &&
        toolList(toolMap(raw['pkInfo'])['pkMap']).length >= 2) {
      return RoomPkData.fromJson({...raw, 'eventType': 1});
    }
    return RoomPkData.fromJson(raw);
  }
}
