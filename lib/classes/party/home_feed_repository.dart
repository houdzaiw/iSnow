part of 'party_page.dart';

final _homeFeedRepositoryProvider = Provider<_HomeFeedRepository>((ref) {
  return _HomeFeedRepository(HttpDioManager());
});

class _HomeFeedRepository {
  const _HomeFeedRepository(this._httpManager);

  final HttpDioManager _httpManager;

  Future<List<_HomeBannerItem>> fetchBanners() async {
    final response = await _httpManager.post(
      HttpApi.homeResourceBanner,
      data: const <String, dynamic>{},
    );
    return _requireList(
      response,
    ).whereType<Map>().map((item) => _HomeBannerItem.fromJson(item)).toList();
  }

  Future<List<_HomeFriendItem>> fetchFriendsPlaying() async {
    final response = await _httpManager.get(HttpApi.friendPlayingList);
    return _requireList(
      response,
    ).whereType<Map>().map((item) => _HomeFriendItem.fromJson(item)).toList();
  }

  Future<List<CountryInfo>> fetchHotCountries() async {
    final response = await _httpManager.get(HttpApi.hotCountry);
    return _requireList(response)
        .whereType<Map>()
        .map((item) => CountryInfo.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<List<_HomeRoomItem>> fetchRecommendRooms({
    required String? countryCode,
  }) async {
    final normalizedCountryCode = _normalizeHomeCountryCode(countryCode);
    final queryParameters = <String, dynamic>{
      'page': 1,
      if (normalizedCountryCode != null) 'country': normalizedCountryCode,
    };
    final response = await _httpManager.get(
      HttpApi.homeRecommendRoom,
      queryParameters: queryParameters,
    );
    return _requireList(
      response,
    ).whereType<Map>().map((item) => _HomeRoomItem.fromJson(item)).toList();
  }

  List<dynamic> _requireList(dynamic response) {
    final server = NadyServerResponse<dynamic>.fromJson(
      _asMap(response),
      (json) => json,
    );
    if (!server.isSuccess) {
      throw server.toException();
    }
    final data = server.data;
    if (data is Map && data['data'] != null) {
      return _extractList(data['data']);
    }
    return _extractList(data);
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['list'] is List) return data['list'] as List;
    if (data is Map && data['data'] != null) return _extractList(data['data']);
    return const [];
  }

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return response.cast<String, dynamic>();
    throw const NadyApiException(message: 'Invalid server response');
  }
}
