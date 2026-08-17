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

    final data = _map(body['data'] ?? body);
    if (data.isEmpty) {
      throw Exception('Empty profile homepage data');
    }
    final info = ProfileHomepageInfo.fromJson(data);
    final giftWall = await fetchGiftWall(targetUid: targetUid);
    final honors = await fetchAchievedMedals(targetUid: targetUid);
    return info.copyWith(giftWall: giftWall, honors: honors);
  }

  Future<ProfileHomepageGiftWall> fetchGiftWall({
    required int targetUid,
    int pageNum = 1,
  }) async {
    final response = await _httpManager.get(
      HttpApi.giftWallList,
      queryParameters: {'targetUid': targetUid, 'pageNum': pageNum},
    );
    final body = _map(response);
    final code = _int(body['code']);
    if (code != null && code != 200) {
      throw Exception(body['message']?.toString() ?? 'Request failed');
    }

    return ProfileHomepageGiftWall.fromJson(_map(body['data']));
  }

  Future<List<ProfileHomepageHonorItem>> fetchAchievedMedals({
    required int targetUid,
  }) async {
    final response = await _httpManager.get(
      HttpApi.medalAchieved,
      queryParameters: {'targetUid': targetUid},
    );
    final body = _map(response);
    final code = _int(body['code']);
    if (code != null && code != 200) {
      throw Exception(body['message']?.toString() ?? 'Request failed');
    }

    final data = body['data'];
    if (data is! List) return const [];
    final medals = data
        .map((item) => ProfileHomepageHonorItem.fromJson(_map(item)))
        .where((item) => item.icon.isNotEmpty || item.id.isNotEmpty)
        .toList(growable: false);
    return medals..sort((a, b) => a.sortingOrder.compareTo(b.sortingOrder));
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
