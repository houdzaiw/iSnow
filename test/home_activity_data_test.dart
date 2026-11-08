import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/classes/party/friends_activity/friends_activity_repository.dart';
import 'package:project/classes/party/friends_activity/friends_activity_view_model.dart';
import 'package:project/classes/party/friends_activity/friends_activity_widgets.dart';
import 'package:project/classes/party/home_feed_repository.dart';
import 'package:project/classes/party/model/home_friend_room.dart';
import 'package:project/classes/party/viewmodel/home_feed_controller.dart';
import 'package:project/classes/party/viewmodel/home_list_view_model.dart';
import 'package:project/manager/home_feed_session.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/model/server_response.dart';
import 'package:project/theme/app_theme.dart';

Object ok(Object? data) => {'code': 200, 'data': data};
Map<String, dynamic> friend(int id) => {
  'roomId': '$id',
  'uid': 81,
  'type': 1,
  'title': 'Room $id',
  'avatar': AppAssets.lanhuPartyAvatar,
  'userBaseInfo': {'uid': 81, 'nick': 'Friend'},
};

class _Session extends HomeFeedSession {
  void next() {
    generation++;
    notifyListeners();
  }
}

void main() {
  test(
    'repositories use exact Nady contracts and normalize the home country list',
    () async {
      final calls = <({String path, Map<String, dynamic> query})>[];
      Future<Object?> get(String path, Map<String, dynamic> query) async {
        calls.add((path: path, query: query));
        return ok(switch (path) {
          HttpApi.homeCountries => [
            {'isoCode': 'us', 'name': 'USA'},
            {'isoCode': ' US '},
            {'isoCode': 'NULL'},
            {'isoCode': '0'},
            {'isoCode': ''},
            {'isoCode': 'SA', 'name': 'Saudi Arabia'},
          ],
          HttpApi.friendPlayingList => [
            friend(42),
            {'uid': 8},
          ],
          HttpApi.homeRoomHistory => [friend(43)],
          _ => [],
        });
      }

      final home = HomeFeedRepository(get: get);
      final activity = FriendsActivityRepository(get: get);
      expect((await home.fetchHomeCountries()).map((c) => c.isoCode), [
        'US',
        'SA',
      ]);
      expect((await activity.fetchFriends()).single.uid, 81);
      expect((await activity.fetchHistory(2)).single.roomId, '43');
      await home.fetchRecommendRooms(countryCode: null);
      await home.fetchRecommendRooms(countryCode: ' sa ');
      expect(calls.map((c) => c.path), [
        HttpApi.homeCountries,
        HttpApi.friendPlayingList,
        HttpApi.homeRoomHistory,
        HttpApi.homeRecommendRoom,
        HttpApi.homeRecommendRoom,
      ]);
      expect(calls[1].query, isEmpty);
      expect(calls[2].query, {'type': 2, 'page': 2, 'pageSize': 20});
      expect(calls[3].query, {'page': 1});
      expect(calls[4].query, {'page': 1, 'country': 'SA'});
    },
  );

  test(
    'error msg takes priority without attempting to decode failure data',
    () async {
      final repo = FriendsActivityRepository(
        get: (_, __) async => {
          'code': 1003,
          'message': 'Fallback',
          'msg': 'Please retry later',
          'data': 'broken',
        },
      );
      await expectLater(
        repo.fetchFriends(),
        throwsA(
          isA<NadyApiException>().having(
            (e) => e.message,
            'message',
            'Please retry later',
          ),
        ),
      );
    },
  );

  test(
    'typed friend metadata and Nady badge priority never depend on list index',
    () {
      final json = {
        ...friend(42),
        'label': 1,
        'inMicNum': 2,
        'rocketRoomScheduleInfoListResp': {'showStatus': 2, 'level': 3},
        'userBaseInfo': {
          'uid': 81,
          'nick': 'Real friend',
          'userLevel': {'vipLevel': 4},
        },
      };
      expect(HomeFriendRoom.fromJson(json).badge, HomeFriendBadge.hall);
      json['label'] = 2;
      expect(HomeFriendRoom.fromJson(json).badge, HomeFriendBadge.mining);
      json['label'] = 0;
      final rocket = HomeFriendRoom.fromJson(json);
      expect(rocket.badge, HomeFriendBadge.rocket);
      expect(homeFriendBadgeAsset(rocket), AppAssets.roomRocketStages[0][2]);
      expect(rocket.user.userLevel.vipLevel, 4);
      json['rocketRoomScheduleInfoListResp'] = {'showStatus': 1};
      expect(HomeFriendRoom.fromJson(json).badge, HomeFriendBadge.voice);
      json['inMicNum'] = 0;
      expect(HomeFriendRoom.fromJson(json).badge, isNull);
      expect(homeFriendBadgeAsset(HomeFriendRoom.fromJson(friend(1))), isNull);
      expect(File(AppAssets.friendsActivityHall).existsSync(), isTrue);
    },
  );

  test(
    'refresh merges concurrent requests and leaves cached rows visible',
    () async {
      final gate = Completer<List<int>>();
      int calls = 0;
      final vm = HomeListViewModel<int>((_) {
        calls++;
        return gate.future;
      });
      final first = vm.refresh();
      final second = vm.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(calls, 1);
      gate.complete([1, 2]);
      await Future.wait([first, second]);
      expect(vm.state.items, [1, 2]);
      vm.dispose();
    },
  );

  test(
    'history paginates, deduplicates rooms and ends on a short page',
    () async {
      final calls = <int>[];
      final vm = HomeListViewModel<int>(
        (page) async {
          calls.add(page);
          return page == 1 ? List.generate(20, (i) => i) : [19, 20];
        },
        paginated: true,
        itemKey: (i) => '$i',
      );
      await vm.refresh();
      expect(vm.state.hasMore, isTrue);
      await Future.wait([vm.loadMore(), vm.loadMore()]);
      expect(calls, [1, 2]);
      expect(vm.state.items, List.generate(21, (i) => i));
      expect(vm.state.hasMore, isFalse);
      await vm.loadMore();
      expect(calls, [1, 2]);
      vm.dispose();
    },
  );

  test(
    'refresh replaces a pending history page and ignores its late response',
    () async {
      final page2 = Completer<List<int>>();
      int refreshes = 0;
      final vm = HomeListViewModel<int>(
        (p) async {
          if (p == 2) return page2.future;
          return refreshes++ == 0 ? List.generate(20, (i) => i) : [100];
        },
        paginated: true,
        itemKey: (i) => '$i',
      );
      await vm.refresh();
      final pending = vm.loadMore();
      await vm.refresh();
      page2.complete([999]);
      await pending;
      expect(vm.state.items, [100]);
      expect(vm.state.page, 1);
      vm.dispose();
    },
  );

  test(
    'failed refresh and failed page retain data and identify the correct retry',
    () async {
      bool fail = false;
      final vm = HomeListViewModel<int>(
        (p) async {
          if (fail) {
            throw const NadyApiException(message: 'History unavailable');
          }
          return List.generate(20, (i) => i);
        },
        paginated: true,
        itemKey: (i) => '$i',
      );
      await vm.refresh();
      fail = true;
      await vm.loadMore();
      expect(vm.state.errorPage, 2);
      expect(vm.state.items, hasLength(20));
      await vm.refresh();
      expect(vm.state.errorPage, 1);
      expect(vm.state.error, 'History unavailable');
      expect(vm.state.items, hasLength(20));
      vm.dispose();
    },
  );

  test(
    'home country failure does not block Hot, and countries own separate results',
    () async {
      final sa = Completer<Object?>();
      final repo = HomeFeedRepository(
        post: (_) async => ok([]),
        get: (p, q) async {
          if (p == HttpApi.homeCountries) {
            throw const NadyApiException(message: 'Countries unavailable');
          }
          if (q['country'] == 'SA') return sa.future;
          return ok([
            {'roomId': q['country'] ?? 'hot', 'title': 'A room'},
          ]);
        },
      );
      final c = ProviderContainer(
        overrides: [homeFeedRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      final pending = c.read(homeCountryRoomsProvider('SA').notifier).refresh();
      await c.read(homeCountryRoomsProvider(null).notifier).refresh();
      await c.read(homeCountryRoomsProvider('US').notifier).refresh();
      await c.read(homeFeedProvider.notifier).refreshCountries();
      expect(c.read(homeFeedProvider).countriesError, 'Countries unavailable');
      expect(c.read(homeCountryRoomsProvider(null)).items.single.roomId, 'hot');
      expect(c.read(homeCountryRoomsProvider('US')).items.single.roomId, 'US');
      sa.complete(
        ok([
          {'roomId': 'sa'},
        ]),
      );
      await pending;
      expect(c.read(homeCountryRoomsProvider('SA')).items.single.roomId, 'sa');
      expect(c.read(homeCountryRoomsProvider('US')).items.single.roomId, 'US');
    },
  );

  test(
    'countries keep selection on failure and reset only if it is removed',
    () async {
      bool fail = false, remove = false;
      final vm = HomeFeedViewModel(
        HomeFeedRepository(
          post: (_) async => ok([]),
          get: (_, __) async {
            if (fail) throw const NadyApiException(message: 'Try later');
            return ok([
              {'isoCode': 'US'},
              if (!remove) {'isoCode': 'SA'},
            ]);
          },
        ),
      );
      await vm.refreshCountries();
      vm.selectCountry('sa');
      expect(vm.state.selectedCountryCode, 'SA');
      fail = true;
      await vm.refreshCountries();
      expect(vm.state.selectedCountryCode, 'SA');
      fail = false;
      remove = true;
      await vm.refreshCountries();
      expect(vm.state.selectedCountryCode, isNull);
      vm.dispose();
    },
  );

  test(
    'account generation replaces all home lists and rejects old friend results',
    () async {
      final session = _Session();
      final old = Completer<Object?>();
      int calls = 0;
      final repo = FriendsActivityRepository(
        get: (_, __) async {
          if (calls++ == 0) return old.future;
          return ok([friend(2)]);
        },
      );
      final c = ProviderContainer(
        overrides: [
          homeFeedSessionProvider.overrideWith((ref) => session),
          friendsActivityRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(c.dispose);
      c.listen(friendsActivityProvider, (_, __) {});
      final pending = c.read(friendsActivityProvider.notifier).refresh();
      session.next();
      await c.read(friendsActivityProvider.notifier).refresh();
      old.complete(ok([friend(1)]));
      await pending;
      expect(c.read(friendsActivityProvider).items.single.roomId, '2');
    },
  );
}
