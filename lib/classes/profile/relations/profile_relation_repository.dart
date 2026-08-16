import '../../../manager/auth_session.dart';
import '../../../manager/http_api.dart';
import '../../../manager/http_dio_manager.dart';
import 'profile_relation_models.dart';
import 'profile_relation_type.dart';

class ProfileRelationRepository {
  ProfileRelationRepository({
    HttpDioManager? httpManager,
    AuthSession? authSession,
  }) : _httpManager = httpManager ?? HttpDioManager(),
       _authSession = authSession ?? AuthSession.instance;

  static const int pageSize = 20;

  final HttpDioManager _httpManager;
  final AuthSession _authSession;

  Future<ProfileRelationPageResult> fetch({
    required ProfileRelationType type,
    required int pageNum,
  }) async {
    final path = switch (type) {
      ProfileRelationType.followers => HttpApi.userFollowers,
      ProfileRelationType.following => HttpApi.userFollowing,
      ProfileRelationType.visitors => HttpApi.userVisitors,
    };
    final data = <String, dynamic>{'pageNum': pageNum, 'pageSize': pageSize};
    if (type != ProfileRelationType.visitors) {
      final uid = await _authSession.uid();
      if (uid != null) data['targetUid'] = uid;
    }

    final response = await _httpManager.post(path, data: data);
    final payload = _serverData(response);
    final rawItems = _extractItems(payload);
    final items = rawItems
        .map((item) => ProfileRelationUser.fromJson(item, type: type))
        .where((item) => item.uid != 0 || item.nick.isNotEmpty)
        .toList(growable: false);

    return ProfileRelationPageResult(
      items: items,
      pageNum: pageNum,
      hasMore: items.length >= pageSize,
    );
  }

  Future<void> setFollowing({
    required int targetUid,
    required bool isFollowing,
  }) async {
    await _httpManager.post(
      HttpApi.userFollow,
      data: {'targetUid': targetUid, 'isFollowing': isFollowing},
    );
  }

  Object? _serverData(Object? response) {
    final body = _asMap(response);
    final code = _int(body['code']);
    if (code != null && code != 200) {
      throw Exception(body['message']?.toString() ?? 'Request failed');
    }
    return body['data'];
  }

  List<Map<String, dynamic>> _extractItems(Object? payload) {
    if (payload is List) return payload.map(_asMap).toList(growable: false);
    final data = _asMap(payload);
    for (final key in const ['list', 'data', 'records', 'items']) {
      final value = data[key];
      if (value is List) return value.map(_asMap).toList(growable: false);
    }
    return const [];
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return const {};
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
