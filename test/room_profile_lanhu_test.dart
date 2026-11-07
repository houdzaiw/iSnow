import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/classes/room/interaction/room_detail_sheet.dart';
import 'package:project/classes/room/interaction/room_detail_view_model.dart';
import 'package:project/classes/room/interaction/room_interaction_repository.dart';
import 'package:project/classes/room/interaction/room_interaction_frame.dart';
import 'package:project/classes/room/interaction/room_interaction_view_model.dart';
import 'package:project/classes/room/interaction/room_member_card_content.dart';
import 'package:project/classes/room/interaction/room_moderation.dart';
import 'package:project/classes/room/interaction/room_party_history.dart';
import 'package:project/classes/room/interaction/room_user_card.dart';
import 'package:project/classes/room/room_repository.dart';
import 'package:project/classes/room/viewmodel/room_state.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/manager/room_manager.dart';
import 'package:project/model/room_models.dart';
import 'package:project/model/room_user_info.dart';
import 'package:project/model/server_response.dart';
import 'package:project/theme/app_theme.dart';

import 'support/precache_room_assets.dart';
import 'support/room_tools_fakes.dart';

final _roomNotifier = ChangeNotifierProvider<_Room>(
  (ref) => throw UnimplementedError(),
);
final _page = Provider<RoomPageState>((ref) {
  final room = ref.watch(_roomNotifier);
  return RoomPageState.initial('123').copyWith(
    status: RoomStatus.ready,
    isInRoom: true,
    currentUid: 10,
    roomTitle: 'A room for a happy day',
    roomAvatar: AppAssets.lanhuRoomAvatarSample,
    roomNo: '10002',
    roomDesc: 'Welcome to my room, lets chat together!',
    roomInfo: room.roomState.roomInfo,
    enterResponse: room.roomState.enterResponse,
  );
});

Map<String, dynamic> _user(int uid) => {
  'userBase': <String, dynamic>{
    'uid': uid,
    'userNo': 10002222,
    'nick': 'Jenny',
    'avatar': AppAssets.lanhuRoomAvatarSample,
    'gender': 2,
    'countryCode': 'SA',
    'userLevel': {
      'wealthLevel': 80,
      'wealthLevelIcon': AppAssets.lanhuProfileHomepageWealth,
      'charmLevel': 10,
      'charmLevelIcon': AppAssets.lanhuProfileHomepageCharm,
    },
  },
  'roomIdentity': 'AUDIENCE',
};

Map<String, dynamic> _party(int id) => {
  'partyId': id,
  'topic': 'A happy day',
  'status': 3,
  'picUrl': AppAssets.lanhuPartyCover,
  'subscribeNum': 100,
  'createUserInfo': {
    'uid': 20,
    'nick': 'Username',
    'avatar': AppAssets.lanhuRoomAvatarSample,
  },
};

class _Api extends RoomInteractionRepository {
  final posts = <({String path, Map<String, dynamic> body})>[];
  final pages = <int>[];
  bool failAdmins = false, failSave = false, locked = false;
  int adminCount = 2;
  Completer<void>? userGate;
  @override
  Future<Object?> get(String path, Map<String, dynamic> query) async {
    if (path == HttpApi.roomUserInfo) {
      await userGate?.future;
      return _user(query['targetUid'] as int);
    }
    if (path == HttpApi.roomAdminInfo) {
      if (failAdmins) {
        throw const NadyApiException(message: 'Admin list unavailable');
      }
      return List.generate(adminCount, (index) => _user(21 + index));
    }
    return [];
  }

  @override
  Future<Object?> post(String path, Map<String, dynamic> body) async {
    if (path == HttpApi.roomPartyList) {
      final page = body['pageNum'] as int;
      pages.add(page);
      return page == 1
          ? [_party(1)]
          : page == 2
          ? [_party(1), _party(2)]
          : [];
    }
    posts.add((path: path, body: body));
    if (failSave) throw const NadyApiException(message: 'Lock change denied');
    if (path == HttpApi.roomUpdateInfo) locked = body['roomLock'] as bool;
    return null;
  }
}

class _Room extends ToolsRoomFake {
  _Room(this.api) {
    _update();
  }
  final _Api api;
  bool disposed = false;
  @override
  void dispose() {
    if (disposed) return;
    disposed = true;
    super.dispose();
  }

  void _update() {
    current = current.copyWith(
      roomInfo: RoomInfo.fromJson({
        'roomId': '123',
        'roomUid': 10,
        'roomLock': api.locked,
        'countryCode': 'SA',
        'managerMaxNum': 8,
      }),
    );
  }

  @override
  Future<void> refreshRoomData() async {
    _update();
    emitState();
  }
}

void main() {
  setUpAll(() async {
    final font = FontLoader('Roboto')
      ..addFont(
        File(
          'test/fixtures/fonts/Roboto-Regular.ttf',
        ).readAsBytes().then(ByteData.sublistView),
      );
    await font.load();
  });
  late _Api api;
  late _Room room;
  late RoomInteractionKey key;
  setUp(() {
    api = _Api();
    room = _Room(api);
    key = (roomId: '123', generation: 1, viewToken: Object());
  });
  tearDown(() => room.dispose());

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    double width = 375,
    double height = 812,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roomRepositoryProvider.overrideWithValue(room),
          roomInteractionRepositoryProvider.overrideWithValue(api),
          _roomNotifier.overrideWith((ref) => room),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, __) => MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('en'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en')],
            home: Scaffold(
              backgroundColor: AppColors.roomMessageSurface,
              body: RepaintBoundary(
                key: const ValueKey('room-profile-golden'),
                child: Align(alignment: Alignment.bottomCenter, child: child),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await precacheRoomAssets(
      tester,
      tester.element(find.byType(Scaffold).first),
    );
    addTearDown(() async => tester.pumpWidget(const SizedBox()));
  }

  test(
    'optional decorations, quotas and Party data are backward compatible',
    () {
      final old = RoomUserInfo.fromJson({
        'userBase': {'uid': 20, 'nick': 'Peer'},
      });
      expect(old.appearance.badges, isEmpty);
      expect(old.appearance.levels, isEmpty);
      final decorated = _user(20);
      (decorated['userBase'] as Map<String, dynamic>).addAll({
        'avatarWidget': {
          'icon': 'https://example.com/frame.png',
          'animationUrl': 'https://example.com/frame.svga',
        },
        'userLevel': {
          'wealthLevel': 80,
          'wealthLevelIcon': 'https://example.com/wealth.png',
        },
        'userWearMedalVOS': [
          {'icon': 'b', 'sortingOrder': 2},
          {'icon': 'a', 'sortingOrder': 1},
        ],
        'userIdentityAuthenticationList': [
          {'idCardUrl': 'https://example.com/plaque.png'},
        ],
      });
      final appearance = RoomUserInfo.fromJson(decorated).appearance;
      expect(appearance.frameUrl, endsWith('.svga'));
      expect(appearance.badges, ['a', 'b']);
      expect(appearance.levels.single.level, 80);
      expect(appearance.levels.single.icon, 'https://example.com/wealth.png');
      expect(appearance.identityBadges, hasLength(1));
      expect(RoomInfo.fromJson({'roomId': '123'}).managerMaxNum, 20);
      expect(
        RoomInfo.fromJson({
          'roomInfoDTO': {'roomId': '123', 'managerMaxNum': 7},
        }).managerMaxNum,
        7,
      );
      final party = RoomLinkedParty.fromJson(_party(1));
      expect(party.creatorName, 'Username');
      expect(party.subscribeNum, 100);
      expect(party.status, 3);
    },
  );

  for (final width in [320.0, 375.0, 430.0]) {
    for (final kind in ['profile', 'member', 'history']) {
      testWidgets('$kind Lanhu layout at $width', (tester) async {
        final view = switch (kind) {
          'profile' => RoomDetailSheet(
            session: key,
            roomState: _page,
            onShare: () {},
          ),
          'member' => RoomUserCard(
            target: (session: key, uid: 20),
            currentUid: 10,
          ),
          _ => RoomPartyHistorySheet(session: key),
        };
        await pump(tester, view, width: width);
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey('room-profile-golden')),
          matchesGoldenFile(
            'goldens/room_profile_lanhu_v1/${kind}_${width.toInt()}.png',
          ),
        );
      });
    }
  }

  testWidgets(
    'lock cancellation and save failure preserve the original value',
    (tester) async {
      await pump(
        tester,
        RoomDetailSheet(session: key, roomState: _page, onShare: () {}),
      );
      expect(find.text('2/8'), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(api.posts, isEmpty);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '1234');
      api.failSave = true;
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Lock change denied'), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      expect(api.posts.single.body['roomPasswd'], '1234');
    },
  );

  testWidgets('successful lock and unlock update service state', (
    tester,
  ) async {
    await pump(
      tester,
      RoomDetailSheet(session: key, roomState: _page, onShare: () {}),
    );
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '1234');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(api.posts.map((e) => e.body['roomLock']), [true, false]);
  });

  testWidgets('admin failure never displays a false zero count', (
    tester,
  ) async {
    api.failAdmins = true;
    await pump(
      tester,
      RoomDetailSheet(session: key, roomState: _page, onShare: () {}),
    );
    expect(find.text('—/8'), findsOneWidget);
    expect(find.text('0/8'), findsNothing);
  });

  testWidgets('own member card hides interaction and management actions', (
    tester,
  ) async {
    await pump(
      tester,
      RoomUserCard(target: (session: key, uid: 10), currentUid: 10),
    );
    expect(find.text('Check Profile'), findsOneWidget);
    expect(find.text('Follow'), findsNothing);
    expect(find.text('Send Gift'), findsNothing);
    expect(find.byType(PopupMenuButton<RoomModerationAction>), findsNothing);
  });

  testWidgets('member management menu closes with the room session', (
    tester,
  ) async {
    await pump(
      tester,
      RoomUserCard(target: (session: key, uid: 20), currentUid: 10),
    );
    expect(find.text('Set as Admin'), findsNothing);
    await tester.tap(find.byType(PopupMenuButton<RoomModerationAction>));
    await tester.pumpAndSettle();
    expect(find.text('Set as Admin'), findsOneWidget);
    room.changeAccount(30);
    await tester.pumpAndSettle();
    expect(find.text('Set as Admin'), findsNothing);
    expect(api.posts, isEmpty);
  });

  testWidgets('ended Party share has its own hit target', (tester) async {
    var details = 0, shares = 0;
    await pump(
      tester,
      RoomLinkedPartyCard(
        item: RoomLinkedParty.fromJson(_party(1)),
        onTap: () => details++,
        onShare: () => shares++,
      ),
    );
    expect(find.text('Ended'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Share Party'));
    await tester.pump();
    expect(shares, 1);
    expect(details, 0);
    expect(api.posts, isEmpty);
  });

  testWidgets('long member name and missing decorations fit a short screen', (
    tester,
  ) async {
    final data = _user(20);
    (data['userBase'] as Map)['nick'] = 'Long name ' * 30;
    await pump(
      tester,
      RoomMemberCardContent(
        user: RoomUserInfo.fromJson(data),
        own: false,
        following: false,
        saving: false,
        loading: false,
        onProfile: () {},
        onCopy: () {},
        onFollow: () {},
        onMessage: () {},
        onMention: () {},
        onGift: () {},
        onRetry: () {},
      ),
      width: 320,
      height: 500,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Send Gift'), findsOneWidget);
  });
  testWidgets('returning from the admin list refreshes its summary', (
    tester,
  ) async {
    await pump(
      tester,
      RoomDetailSheet(session: key, roomState: _page, onShare: () {}),
    );
    expect(find.text('2/8'), findsOneWidget);
    await tester.tap(find.text('Room Admin'));
    await tester.pumpAndSettle();
    api.adminCount = 3;
    Navigator.of(tester.element(find.byType(RoomInteractionFrame))).pop();
    await tester.pumpAndSettle();
    expect(find.text('3/8'), findsOneWidget);
  });

  testWidgets('profile tabs support tapping and swiping', (tester) async {
    await pump(
      tester,
      RoomDetailSheet(session: key, roomState: _page, onShare: () {}),
    );
    await tester.tap(find.text('Party'));
    await tester.pumpAndSettle();
    expect(find.text('Party History'), findsOneWidget);
    await tester.drag(find.byType(RoomLinkedPartiesView), const Offset(320, 0));
    await tester.pumpAndSettle();
    expect(find.text('Room Lock'), findsOneWidget);
  });

  for (final role in [UserRoomIdentity.audience, UserRoomIdentity.manager]) {
    testWidgets('$role sees only permitted profile controls', (tester) async {
      room.setRole(role);
      room.current = room.current.copyWith(
        roomInfo: const RoomInfo(
          roomId: '123',
          roomOwnerUid: 30,
          roomLock: false,
          raw: {},
        ),
      );
      await pump(
        tester,
        RoomDetailSheet(session: key, roomState: _page, onShare: () {}),
      );
      expect(
        find.text('Room Lock'),
        role == UserRoomIdentity.manager ? findsOneWidget : findsNothing,
      );
    });
    testWidgets('$role sees only permitted member controls', (tester) async {
      room.setRole(role);
      room.current = room.current.copyWith(
        roomInfo: const RoomInfo(
          roomId: '123',
          roomOwnerUid: 30,
          roomLock: false,
          raw: {},
        ),
      );
      await pump(
        tester,
        RoomUserCard(target: (session: key, uid: 20), currentUid: 10),
      );
      expect(
        find.byType(PopupMenuButton<RoomModerationAction>),
        role == UserRoomIdentity.manager ? findsOneWidget : findsNothing,
      );
    });
  }

  for (final action in [
    RoomUserCardAction.message,
    RoomUserCardAction.gift,
    RoomUserCardAction.mention,
  ]) {
    testWidgets(
      'member $action returns the existing room action without submitting',
      (tester) async {
        RoomUserCardSelection? selected;
        await pump(
          tester,
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                selected =
                    await showRoomInteractionSheet<RoomUserCardSelection>(
                      context,
                      (_) => RoomUserCard(
                        target: (session: key, uid: 20),
                        currentUid: 10,
                      ),
                      backgroundColor: AppColors.transparent,
                    );
              },
              child: const Text('Open member'),
            ),
          ),
        );
        await tester.tap(find.text('Open member'));
        await tester.pumpAndSettle();
        final target = switch (action) {
          RoomUserCardAction.gift => find.text('Send Gift'),
          RoomUserCardAction.message => find.text('Chat'),
          _ => find.bySemanticsLabel('@'),
        };
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(selected?.action, action);
        expect(selected?.nickname, 'Jenny');
        expect(api.posts, isEmpty);
      },
    );
  }

  test(
    'history pagination deduplicates and refresh restarts the first page',
    () async {
      final container = ProviderContainer(
        overrides: [
          roomRepositoryProvider.overrideWithValue(room),
          roomInteractionRepositoryProvider.overrideWithValue(api),
        ],
      );
      addTearDown(container.dispose);
      final provider = roomLinkedPartiesProvider((session: key, history: true));
      final subscription = container.listen(provider, (_, __) {});
      addTearDown(subscription.close);
      await Future<void>.delayed(Duration.zero);
      final vm = container.read(provider.notifier);
      await vm.load();
      expect(container.read(provider).items.map((item) => item.id), [1, 2]);
      await vm.load();
      expect(container.read(provider).more, isFalse);
      await vm.load(refresh: true);
      expect(container.read(provider).items.map((item) => item.id), [1]);
      expect(api.pages, [1, 2, 3, 1]);
    },
  );
  testWidgets('member copy uses the display ID', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pump(
      tester,
      RoomUserCard(target: (session: key, uid: 20), currentUid: 10),
    );
    await tester.tap(find.text('ID:10002222'));
    await tester.pumpAndSettle();
    expect(copied, '10002222');
    expect(api.posts, isEmpty);
  });
}
