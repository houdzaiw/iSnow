import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/auth_session.dart';
import '../../../manager/http_api.dart';
import '../../../manager/http_dio_manager.dart';
import '../home_feed_repository.dart';
import '../home_response.dart';
import '../model/home_friend_room.dart';
import '../model/home_history_room.dart';

final friendsActivityRepositoryProvider = Provider(
  (ref) => FriendsActivityRepository(),
);

class FriendsActivityRepository {
  FriendsActivityRepository({HomeGet? get})
    : _get = get ?? ((p, q) => HttpDioManager().get(p, queryParameters: q));
  final HomeGet _get;

  Future<List<HomeFriendRoom>> fetchFriends() async =>
      homeResponseRows(await _get(HttpApi.friendPlayingList, const {}))
          .map(HomeFriendRoom.fromJson)
          .where((item) => item.roomId?.isNotEmpty == true)
          .toList();

  Future<List<HomeHistoryRoom>> fetchHistory(int page) async =>
      homeResponseRows(
            await _get(HttpApi.homeRoomHistory, {
              'type': 2,
              'page': page,
              'pageSize': 20,
            }),
          )
          .map(HomeHistoryRoom.fromJson)
          .where((item) => item.roomId.isNotEmpty)
          .toList();

  Future<String?> ownRoomId() async =>
      (await AuthSession.instance.user())?.roomId;
}
