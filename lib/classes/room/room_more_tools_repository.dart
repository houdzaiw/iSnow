import '../../manager/http_api.dart';
import '../../manager/http_dio_manager.dart';
import '../../model/server_response.dart';
import 'models/room_more_tools_models.dart';

class RoomMoreToolsRepository {
  RoomMoreToolsRepository({HttpDioManager? httpManager})
    : _httpManager = httpManager ?? HttpDioManager();

  final HttpDioManager _httpManager;

  Future<List<RoomToolBanner>> fetchBanners({
    required RoomMoreBannerPosition position,
    required String roomId,
  }) async {
    final response = await _httpManager.post(
      HttpApi.homeResourceBanner,
      data: {
        'position': position.value,
        if (roomId.trim().isNotEmpty) 'roomId': roomId.trim(),
      },
    );

    final server = NadyServerResponse<List<RoomToolBanner>>.fromJson(
      _asMap(response),
      _bannerListFromJson,
    );
    if (!server.isSuccess) throw server.toException();
    return server.data ?? const [];
  }

  Future<void> setLobbyOpen({
    required String roomId,
    required RoomLobbyToolType lobbyType,
    required bool open,
  }) async {
    final response = await _httpManager.post(
      HttpApi.lobbyOpen,
      data: {
        'status': open ? 1 : 0,
        'roomId': roomId.trim(),
        'lobbyType': lobbyType.value,
      },
    );

    final server = NadyServerResponse<Object?>.fromJson(
      _asMap(response),
      (json) => json,
    );
    if (!server.isSuccess) throw server.toException();
  }

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return response.cast<String, dynamic>();
    throw const NadyApiException(message: 'Invalid server response');
  }

  List<RoomToolBanner> _bannerListFromJson(Object? json) {
    return _bannerItems(json)
        .map(_asDynamicMap)
        .whereType<Map<String, dynamic>>()
        .map(RoomToolBanner.fromJson)
        .toList();
  }

  Iterable<dynamic> _bannerItems(Object? json) {
    if (json is List) return json;
    if (json is Map) {
      for (final key in const [
        'list',
        'records',
        'rows',
        'items',
        'data',
        'bannerList',
      ]) {
        final value = json[key];
        if (value is List) return value;
        if (value is Map) {
          final nested = _bannerItems(value).toList();
          if (nested.isNotEmpty) return nested;
        }
      }
    }
    return const [];
  }

  Map<String, dynamic>? _asDynamicMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return null;
  }
}
