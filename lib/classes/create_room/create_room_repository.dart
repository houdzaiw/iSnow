import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../manager/auth_session.dart';
import '../../manager/http_api.dart';
import '../../manager/http_dio_manager.dart';
import '../../manager/room_manager.dart';
import '../../model/server_response.dart';
import '../../model/user_profile.dart';
import '../oauth/provider/login_provider.dart';
import 'create_room_models.dart';

final createRoomRepositoryProvider = Provider<CreateRoomRepository>((ref) {
  return CreateRoomRepository(
    httpManager: HttpDioManager(),
    authSession: AuthSession.instance,
    roomManager: RoomManager.instance,
    uploadProvider: LoginProvider(),
  );
});

class CreateRoomRepository {
  const CreateRoomRepository({
    required HttpDioManager httpManager,
    required AuthSession authSession,
    required RoomManager roomManager,
    required LoginProvider uploadProvider,
  }) : _httpManager = httpManager,
       _authSession = authSession,
       _roomManager = roomManager,
       _uploadProvider = uploadProvider;

  final HttpDioManager _httpManager;
  final AuthSession _authSession;
  final RoomManager _roomManager;
  final LoginProvider _uploadProvider;

  Future<UserData?> cachedUser() {
    return _authSession.user();
  }

  Future<UserData?> fetchCurrentUser() async {
    final cached = await _authSession.user();
    if (cached != null) return cached;
    return fetchRemoteCurrentUser();
  }

  Future<UserData?> fetchRemoteCurrentUser() async {
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

  Future<String> uploadAvatar(String filePath) {
    return _uploadProvider.uploadAvatarFile(filePath, returnFullUrl: true);
  }

  Future<String> openRoom(CreateRoomDraft draft) async {
    final response = await _httpManager.post(
      HttpApi.roomOpen,
      data: draft.toJson(),
    );
    final server = NadyServerResponse<String>.fromJson(
      _asMap(response),
      (json) => json?.toString() ?? '',
    );
    if (!server.isSuccess) {
      throw server.toException();
    }

    final roomId = server.data?.trim();
    if (roomId == null || roomId.isEmpty) {
      throw const NadyApiException(message: 'Empty room id');
    }
    return roomId;
  }

  Future<void> enterRoom(String roomId) {
    return _roomManager.enterRoom(roomId: roomId);
  }

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return response.cast<String, dynamic>();
    throw const NadyApiException(message: 'Invalid server response');
  }
}
