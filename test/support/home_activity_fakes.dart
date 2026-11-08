import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/classes/party/friends_activity/friends_activity_page.dart';
import 'package:project/classes/party/friends_activity/friends_activity_repository.dart';
import 'package:project/classes/party/home_feed_repository.dart';
import 'package:project/classes/party/model/home_friend_room.dart';
import 'package:project/classes/party/model/home_history_room.dart';
import 'package:project/classes/party/party_page.dart';
import 'package:project/classes/room/more/room_entry_flow.dart';
import 'package:project/classes/room/room_repository.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/manager/home_feed_session.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/manager/room_manager.dart';
import 'package:project/model/server_response.dart';
import 'package:project/theme/app_theme.dart';

import 'precache_room_assets.dart';
import 'room_tools_fakes.dart';

class HomeTestSession extends HomeFeedSession {
  void next() {
    generation++;
    notifyListeners();
  }
}

HomeFriendRoom homeTestFriend(int id, {int type = 1}) =>
    HomeFriendRoom.fromJson({
      'roomId': '$id',
      'uid': 81,
      'type': type,
      'title': id == 42
          ? 'Real room'
          : 'A very long room title to check the single line layout',
      'avatar': AppAssets.lanhuPartyAvatar,
      'roomDesc': 'Own room description',
      'inMicNum': 2,
      'label': 1,
      'userBaseInfo': {'uid': 81, 'nick': 'Friend'},
    });

class HomeActivityFake extends FriendsActivityRepository {
  List<HomeFriendRoom> friends = [
    homeTestFriend(42),
    homeTestFriend(43, type: 2),
  ];
  List<HomeHistoryRoom> history = [
    const HomeHistoryRoom(
      roomId: '44',
      uid: 91,
      title: 'Previously visited room',
      cover: AppAssets.lanhuPartyAvatar,
      inMicNum: 1,
    ),
  ];
  int friendCalls = 0;
  final historyCalls = <int>[];
  bool failFriends = false, failHistory = false;
  Completer<List<HomeFriendRoom>>? friendsGate;
  @override
  Future<List<HomeFriendRoom>> fetchFriends() async {
    friendCalls++;
    if (failFriends) {
      throw const NadyApiException(message: 'Friends unavailable');
    }
    return friendsGate?.future ?? friends;
  }

  @override
  Future<List<HomeHistoryRoom>> fetchHistory(int page) async {
    historyCalls.add(page);
    if (failHistory) {
      throw const NadyApiException(message: 'History unavailable');
    }
    return page == 1 ? history : [];
  }

  @override
  Future<String?> ownRoomId() async => '42';
}

class HomeActivityHarness {
  HomeActivityHarness() {
    room.current = const RoomState();
  }
  final activity = HomeActivityFake();
  final room = ToolsRoomFake();
  final session = HomeTestSession();
  final roomCalls = <String?>[];
  bool failCountries = false, lock = false;
  String countriesError = 'Countries unavailable';
  Completer<Object?>? countriesGate;
  Completer<Map<String, dynamic>>? entryGate;
  int entryCalls = 0;
  late GoRouter router;
  late ProviderContainer container;
  List<Map<String, Object>> countries = [
    for (final code in ['SA', 'US', 'CN', 'IN', 'BR', 'ID', 'TR'])
      {
        'isoCode': code,
        'name': code == 'US' ? 'United States with a very long name' : code,
        'arName': code,
        'dialCode': '+1',
      },
  ];
  Future<void> pump(
    WidgetTester tester, {
    bool direct = false,
    double width = 375,
    double height = 812,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    container = ProviderContainer(
      overrides: [
        homeFeedSessionProvider.overrideWith((ref) => session),
        friendsActivityRepositoryProvider.overrideWithValue(activity),
        homeFeedRepositoryProvider.overrideWithValue(
          HomeFeedRepository(
            post: (_) async => {'code': 200, 'data': []},
            get: (path, q) async {
              if (path == HttpApi.homeCountries) {
                if (failCountries) {
                  throw NadyApiException(message: countriesError);
                }
                return countriesGate?.future ??
                    {'code': 200, 'data': countries};
              }
              roomCalls.add(q['country'] as String?);
              return {'code': 200, 'data': <Object>[]};
            },
          ),
        ),
        roomRepositoryProvider.overrideWithValue(room),
        roomEntryInfoProvider.overrideWith((ref, id) async {
          entryCalls++;
          return entryGate?.future ?? {'roomLock': lock};
        }),
      ],
    );
    router = GoRouter(
      initialLocation: direct ? '/friends' : '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: HomeFeedView()),
        ),
        GoRoute(
          path: '/friends',
          name: 'friends-activity',
          builder: (_, __) => const FriendsActivityPage(),
        ),
        GoRoute(
          path: '/room/:id',
          builder: (_, s) =>
              Scaffold(body: Text('Entered ${s.pathParameters['id']}')),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, __) => MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            locale: const Locale('en'),
            routerConfig: router,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en')],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await precacheRoomAssets(
      tester,
      tester.element(find.byType(Scaffold).first),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      container.dispose();
      room.dispose();
    });
  }
}
