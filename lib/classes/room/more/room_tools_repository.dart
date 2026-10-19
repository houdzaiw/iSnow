import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../manager/http_api.dart';
import '../../../manager/http_dio_manager.dart';
import '../../../model/server_response.dart';
import 'room_tools_models.dart';

final roomToolsRepositoryProvider = Provider((ref) => RoomToolsRepository());

class RoomToolsRepository {
  RoomToolsRepository({HttpDioManager? http}) : http = http ?? HttpDioManager();
  final HttpDioManager http;

  Future<Object?> get(String path, [ToolJson? query]) async =>
      _data(await http.get(path, queryParameters: query));
  Future<Object?> post(String path, ToolJson body) async =>
      _data(await http.post(path, data: body));
  Object? _data(Object? response) {
    final server = NadyServerResponse<Object?>.fromJson(
      toolMap(response),
      (value) => value,
    );
    if (!server.isSuccess) throw server.toException();
    return server.data;
  }

  Future<RoomFunctionConfig> functions(String roomId) async =>
      RoomFunctionConfig(
        toolList(await get(HttpApi.roomFunctions, {'roomId': roomId})),
      );
  Future<RoomEffectPreferences> effects(int uid) async {
    final prefs = await SharedPreferences.getInstance();
    return RoomEffectPreferences.fromJson(
      toolMap(prefs.getString('room_effects_$uid')),
    );
  }

  Future<void> saveEffects(int uid, RoomEffectPreferences effects) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(
      'room_effects_$uid',
      jsonEncode(effects.toJson()),
    )) {
      throw const NadyApiException(message: 'Unable to save preferences');
    }
  }

  Future<bool> speakerMuted(int uid, String roomId) async =>
      (await SharedPreferences.getInstance()).getBool(
        'room_speaker_${uid}_$roomId',
      ) ??
      false;
  Future<void> saveSpeaker(int uid, String roomId, bool muted) async {
    if (!await (await SharedPreferences.getInstance()).setBool(
      'room_speaker_${uid}_$roomId',
      muted,
    )) {
      throw const NadyApiException(message: 'Unable to save preferences');
    }
  }

  Future<bool> luckyConfirmed(int uid) async =>
      (await SharedPreferences.getInstance()).getBool(
        'room_lucky_confirmed_$uid',
      ) ??
      false;
  Future<void> confirmLucky(int uid) async {
    if (!await (await SharedPreferences.getInstance()).setBool(
      'room_lucky_confirmed_$uid',
      true,
    )) {
      throw const NadyApiException(message: 'Unable to save confirmation');
    }
  }
}
