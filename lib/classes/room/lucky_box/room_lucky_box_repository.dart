import '../../../manager/http_api.dart';
import '../../../model/server_response.dart';
import '../more/room_tools_models.dart';
import '../more/room_tools_repository.dart';
import 'room_lucky_box_models.dart';

class RoomLuckyBoxRepository {
  RoomLuckyBoxRepository(this.tools);
  final RoomToolsRepository tools;
  Future<RoomLuckyBoxConfig> config(String roomId) async =>
      RoomLuckyBoxConfig.fromJson(
        toolMap(await tools.get(HttpApi.roomLuckyConfig, {'roomId': roomId})),
      );
  Future<RoomLuckyBag> send(
    String roomId, {
    required int type,
    required int gold,
    required int people,
    required int countdown,
  }) async {
    final json = toolMap(
      await tools.post(HttpApi.roomLuckyPush, {
        'roomId': roomId,
        'type': type,
        'gold': gold,
        'numberOfRecipients': people,
        'countdown': countdown,
      }),
    );
    if ('${json['id'] ?? ''}'.trim().isEmpty) {
      throw const NadyApiException(
        message:
            'No Lucky Box receipt received. Refresh the list and balance before trying again.',
      );
    }
    return RoomLuckyBag.parse(json, DateTime.now());
  }

  Future<RoomLuckyBoxResult> grab(Object id) async {
    final json = toolMap(
      await tools.post(HttpApi.roomLuckyGrab, {'luckyBagId': id}),
    );
    if (int.tryParse('${json['count']}') == null) {
      throw const NadyApiException(
        message: 'No valid Lucky Box result received',
      );
    }
    return RoomLuckyBoxResult.fromJson(json);
  }
}
