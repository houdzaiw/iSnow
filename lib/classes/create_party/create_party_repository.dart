import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../manager/auth_session.dart';
import '../../manager/http_api.dart';
import '../../manager/http_dio_manager.dart';
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
    if (cached != null) return cached;

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
}
