part of 'rank_page.dart';

final _rankRepositoryProvider = Provider<_RankRepository>((ref) {
  return _RankRepository(HttpDioManager());
});

class _RankRepository {
  const _RankRepository(this._httpManager);

  final HttpDioManager _httpManager;

  Future<_RankBoard> fetchRank({
    required _RankCategory category,
    required _RankPeriod period,
    int size = 20,
  }) {
    if (category == _RankCategory.room) {
      return _fetchRoomRank(period: period, size: size);
    }
    return _fetchUserRank(category: category, period: period, size: size);
  }

  Future<_RankBoard> _fetchUserRank({
    required _RankCategory category,
    required _RankPeriod period,
    required int size,
  }) async {
    final response = await _httpManager.get(
      HttpApi.rankCommonly,
      queryParameters: {
        'rankType': category.rankType,
        'frequencyType': period.frequencyType,
        'isInRoom': false,
        'size': size,
      },
    );
    final data = _requireData(response);
    final entries = _rankList(
      data['rankVOs'],
    ).map(_RankEntry.fromUserJson).toList(growable: false);
    final meMap = _rankMapOrNull(data['me']);
    return _RankBoard(
      entries: entries,
      me: meMap == null ? null : _RankEntry.fromUserJson(meMap),
      countdown: _rankInt(data['countdown']),
    );
  }

  Future<_RankBoard> _fetchRoomRank({
    required _RankPeriod period,
    required int size,
  }) async {
    final response = await _httpManager.get(
      HttpApi.rankRoomCommonly,
      queryParameters: {'frequencyType': period.frequencyType, 'size': size},
    );
    final data = _requireData(response);
    final entries = _rankList(
      data['rankVOs'],
    ).map(_RankEntry.fromRoomJson).toList(growable: false);
    final meMap = _rankMapOrNull(data['me']);
    return _RankBoard(
      entries: entries,
      me: meMap == null ? null : _RankEntry.fromRoomJson(meMap),
      countdown: _rankInt(data['countdown']),
    );
  }

  Map<String, dynamic> _requireData(dynamic response) {
    final server = NadyServerResponse<dynamic>.fromJson(
      _rankMap(response),
      (json) => json,
    );
    if (!server.isSuccess) {
      throw server.toException();
    }
    return _rankMap(server.data);
  }

  List<Map<dynamic, dynamic>> _rankList(dynamic value) {
    if (value is! List) return const <Map<dynamic, dynamic>>[];
    return value.whereType<Map<dynamic, dynamic>>().toList(growable: false);
  }
}
