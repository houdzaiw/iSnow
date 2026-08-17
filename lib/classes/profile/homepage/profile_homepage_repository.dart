import '../../../manager/http_api.dart';
import '../../../manager/http_dio_manager.dart';
import 'profile_homepage_models.dart';

class ProfileHomepageRepository {
  ProfileHomepageRepository({HttpDioManager? httpManager})
    : _httpManager = httpManager ?? HttpDioManager();

  final HttpDioManager _httpManager;

  Future<ProfileHomepageInfo> fetch({required int targetUid}) async {
    final response = await _httpManager.get(
      HttpApi.userHomepage,
      queryParameters: {'targetUid': targetUid},
    );
    final body = _map(response);
    final code = _int(body['code']);
    if (code != null && code != 200) {
      throw Exception(body['message']?.toString() ?? 'Request failed');
    }

    final data = _map(body['data']);
    if (data.isEmpty) {
      throw Exception('Empty profile homepage data');
    }
    return ProfileHomepageInfo.fromJson(data);
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
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return const {};
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
