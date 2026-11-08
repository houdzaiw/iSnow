import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../manager/http_api.dart';
import '../../manager/http_dio_manager.dart';
import '../../model/country_info.dart';
import 'home_response.dart';
import 'model/home_feed_model.dart';
import 'model/home_json.dart';

typedef HomeGet =
    Future<Object?> Function(String path, Map<String, dynamic> query);
typedef HomePost = Future<Object?> Function(String path);
final homeFeedRepositoryProvider = Provider((ref) => HomeFeedRepository());

class HomeFeedRepository {
  HomeFeedRepository({HomeGet? get, HomePost? post})
    : _get = get ?? ((p, q) => HttpDioManager().get(p, queryParameters: q)),
      _post =
          post ??
          ((p) => HttpDioManager().post(p, data: const <String, dynamic>{}));
  final HomeGet _get;
  final HomePost _post;

  Future<List<HomeBannerItem>> fetchBanners() async => homeResponseRows(
    await _post(HttpApi.homeResourceBanner),
  ).map(HomeBannerItem.fromJson).toList();

  Future<List<CountryInfo>> fetchHomeCountries() async {
    final rows = homeResponseRows(await _get(HttpApi.homeCountries, const {}));
    final seen = <String>{};
    return [
      for (final row in rows)
        if (normalizeHomeCountryCode(homeString(row['isoCode']))
            case final code?)
          if (RegExp(r'^[A-Z]{2}$').hasMatch(code) && seen.add(code))
            CountryInfo.fromJson({...row, 'isoCode': code}),
    ];
  }

  Future<List<HomeRoomItem>> fetchRecommendRooms({
    required String? countryCode,
  }) async => homeResponseRows(
    await _get(HttpApi.homeRecommendRoom, {
      'page': 1,
      if (normalizeHomeCountryCode(countryCode) case final code?)
        'country': code,
    }),
  ).map(HomeRoomItem.fromJson).toList();
}
