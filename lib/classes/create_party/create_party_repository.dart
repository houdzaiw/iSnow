import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../manager/auth_session.dart';
import '../../manager/http_api.dart';
import '../../manager/http_dio_manager.dart';
import '../../model/room_models.dart';
import '../../model/server_response.dart';
import '../../model/user_profile.dart';
import '../oauth/provider/login_provider.dart';
import 'create_party_models.dart';

final createPartyRepositoryProvider = Provider<CreatePartyRepository>((ref) {
  return CreatePartyRepository(
    httpManager: HttpDioManager(),
    authSession: AuthSession.instance,
    uploadProvider: LoginProvider(),
  );
});

class CreatePartyRepository {
  const CreatePartyRepository({
    required HttpDioManager httpManager,
    required AuthSession authSession,
    required LoginProvider uploadProvider,
  }) : _httpManager = httpManager,
       _authSession = authSession,
       _uploadProvider = uploadProvider;

  final HttpDioManager _httpManager;
  final AuthSession _authSession;
  final LoginProvider _uploadProvider;

  Future<UserData?> fetchCurrentUser() async {
    final cached = await _authSession.user();
    if (cached != null && _string(cached.roomId) != null) return cached;

    final response = await _httpManager.get(HttpApi.myUserInfo);
    final server = NadyServerResponse<MeModel>.fromJson(
      _asMap(response),
      (json) => MeModel.fromJson((json as Map).cast<String, dynamic>()),
    );
    if (!server.isSuccess) {
      throw server.toException();
    }
    final user = server.data?.userBaseInfo;
    if (user != null) {
      await _authSession.saveUser(user);
    }
    return user;
  }

  Future<void> preCheck() async {
    final response = await _httpManager.post(HttpApi.partyPreCheck, data: {});
    final server = NadyServerResponse<dynamic>.fromJson(
      _asMap(response),
      (json) => json,
    );
    if (!server.isSuccess) {
      throw server.toException();
    }
  }

  Future<CreatePartyStrategyPushTimesCount>
  fetchCreatePartyStrategyTimesCount() async {
    try {
      final response = await _httpManager.post(
        HttpApi.strategyPushConfig,
        data: {},
      );
      final server =
          NadyServerResponse<List<CreatePartyStrategyPushConfig>>.fromJson(
            _asMap(response),
            (json) => _extractList(json)
                .whereType<Map>()
                .map(CreatePartyStrategyPushConfig.fromJson)
                .toList(growable: false),
          );
      if (!server.isSuccess) {
        return CreatePartyStrategyPushTimesCount.fallback;
      }

      final eventType = CreatePartyStrategyPushEvent.hostSideGameHall.value;
      for (final config
          in server.data ?? const <CreatePartyStrategyPushConfig>[]) {
        if (config.eventType == eventType) {
          return config.firstUsableTimesCount ??
              CreatePartyStrategyPushTimesCount.fallback;
        }
      }
    } catch (_) {
      return CreatePartyStrategyPushTimesCount.fallback;
    }
    return CreatePartyStrategyPushTimesCount.fallback;
  }

  Future<void> fetchStrategyPush({
    required String roomId,
    CreatePartyStrategyPushTimesCount? timesCount,
  }) async {
    final normalizedRoomId = _string(roomId);
    if (normalizedRoomId == null) {
      throw const NadyApiException(message: 'Current room is unavailable');
    }

    final request = CreatePartyStrategyPushRequest(
      eventType: CreatePartyStrategyPushEvent.hostSideGameHall.value,
      timesCount: timesCount ?? CreatePartyStrategyPushTimesCount.fallback,
      roomId: normalizedRoomId,
    );
    final response = await _httpManager.post(
      HttpApi.strategyPush,
      data: request.toJson(),
    );
    final server = NadyServerResponse<dynamic>.fromJson(
      _asMap(response),
      (json) => json,
    );
    if (!server.isSuccess) {
      throw server.toException();
    }
  }

  Future<RoomInfo?> fetchCurrentRoomInfo(UserData? user) async {
    final roomId = _string(user?.roomId);
    if (roomId == null) return null;

    final response = await _httpManager.get(
      HttpApi.roomInfo,
      queryParameters: {'roomId': roomId},
    );
    final server = NadyServerResponse<RoomInfo>.fromJson(
      _asMap(response),
      (json) => RoomInfo.fromJson((json as Map).cast<String, dynamic>()),
    );
    if (!server.isSuccess) {
      throw server.toException();
    }
    return server.data;
  }

  Future<List<CreatePartyTag>> fetchTags() async {
    final response = await _httpManager.get(HttpApi.partyTagList);
    final server = NadyServerResponse<List<CreatePartyTag>>.fromJson(
      _asMap(response),
      (json) => _extractList(json)
          .whereType<Map>()
          .map(CreatePartyTag.fromJson)
          .where((tag) => tag.id > 0)
          .toList(growable: false),
    );
    if (!server.isSuccess) {
      throw server.toException();
    }
    final tags = server.data ?? const <CreatePartyTag>[];
    return [...tags]..sort((a, b) => a.seqNo.compareTo(b.seqNo));
  }

  Future<String> uploadCover(String filePath) {
    return _uploadProvider.uploadAvatarFile(filePath);
  }

  Future<void> createParty(CreatePartyDraft draft) async {
    final response = await _httpManager.post(
      HttpApi.partyCreate,
      data: draft.toJson(),
    );
    final server = NadyServerResponse<dynamic>.fromJson(
      _asMap(response),
      (json) => json,
    );
    if (!server.isSuccess) {
      throw server.toException();
    }
  }

  Future<void> refreshPartyLists() async {
    await Future.wait([
      _fetchPartyList(type: 0, pageNum: 1),
      _fetchPartyList(type: 1, pageNum: 1),
      _fetchPartyList(type: 2, pageNum: 1),
    ]);
  }

  Future<void> _fetchPartyList({
    required int type,
    required int pageNum,
  }) async {
    final response = await _httpManager.get(
      HttpApi.partyList,
      queryParameters: {'type': type, 'pageNum': pageNum},
    );
    final server = NadyServerResponse<List<dynamic>>.fromJson(
      _asMap(response),
      (json) => _extractList(json),
    );
    if (!server.isSuccess) {
      throw server.toException();
    }
  }

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return response.cast<String, dynamic>();
    throw const NadyApiException(message: 'Invalid server response');
  }

  List<dynamic> _extractList(Object? data) {
    if (data is List) return data;
    if (data is Map && data['list'] is List) return data['list'] as List;
    if (data is Map && data['data'] != null) return _extractList(data['data']);
    return const [];
  }

  String? _string(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
