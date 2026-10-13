import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/classes/room/gift/room_gift_repository.dart';
import 'package:project/classes/room/gift/viewmodel/room_gift_view_model.dart';
import 'package:project/classes/room/online/room_audience_view_model.dart';
import 'package:project/classes/room/room_repository.dart';
import 'package:project/classes/room/viewmodel/room_state.dart';
import 'package:project/classes/room/viewmodel/room_view_model.dart';
import 'package:project/manager/room_manager.dart';
import 'package:project/model/room_models.dart';
import 'package:project/model/room_socket_message.dart';
import 'package:project/model/room_user_info.dart';

import 'support/room_lifecycle_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RoomLifecycleFixture fixture;
  late RoomRepository repository;
  setUp(() {
    fixture = RoomLifecycleFixture();
    repository = RoomRepository(
      roomManager: fixture.manager,
      socketManager: fixture.socket,
      agoraManager: fixture.agora,
      authSession: fixture.auth,
      httpManager: fixture.http,
    );
  });
  tearDown(() => fixture.dispose());

  test('Nady audience model reuses userBase and parses room roles', () {
    final owner = RoomUserInfo.fromJson(_user(20, identity: 'ROOM_OWNER'));
    expect(owner.uid, 20);
    expect(owner.userBase.nick, 'User 20');
    expect(owner.roomIdentity, UserRoomIdentity.owner);
    expect(
      RoomUserInfo.fromJson(_user(30, identity: 'ROOM_MANAGER')).roomIdentity,
      UserRoomIdentity.manager,
    );
    expect(() => RoomUserInfo.fromJson({}), throwsFormatException);
  });

  test(
    'entry loads the canonical full audience, including off-mic users',
    () async {
      fixture.http.canonicalRoomId = 'canonical';
      fixture.http.audience = [_user(10), _user(20), _user(30), _user(30)];
      await fixture.enter('alias');
      expect(fixture.http.audienceRequests, [
        {'roomId': 'canonical'},
      ]);
      expect(fixture.manager.state.audience.map((user) => user.uid), [
        10,
        20,
        30,
      ]);
      expect(fixture.manager.state.onlineCount, 3);
      expect(fixture.manager.state.audienceLoaded, isTrue);
      expect(repository.giftAudience('canonical').onlineCount, 3);
      expect(repository.giftAudience('canonical').recipients, hasLength(1));
    },
  );

  test('an empty fetched audience replaces a stale detail count', () async {
    await fixture.enter();
    const state = RoomState(
      audienceLoaded: true,
      roomInfo: RoomInfo(roomId: 'first', audienceCount: 99, raw: {}),
    );
    expect(state.onlineCount, 0);
    expect(state.copyWith(audienceLoaded: false).onlineCount, 99);
    expect(fixture.manager.state.onlineCount, 0);
  });

  test('failed refresh retains cached users and can be retried', () async {
    fixture.http.audience = [_user(10), _user(20)];
    await fixture.enter();
    fixture.http.failAudience = true;
    await repository.refreshAudience();
    expect(fixture.manager.state.onlineCount, 2);
    expect(fixture.manager.state.loadingAudience, isFalse);
    expect(
      fixture.manager.state.audienceError,
      contains('Audience unavailable'),
    );
    fixture.http.failAudience = false;
    fixture.http.audience = [_user(10)];
    await repository.refreshAudience();
    expect(fixture.manager.state.onlineCount, 1);
    expect(fixture.manager.state.audienceError, isNull);
  });

  test(
    'top-three socket event triggers a full refresh, not a three-user count',
    () async {
      await fixture.enter();
      fixture.http.audience = List.generate(6, (index) => _user(index + 10));
      fixture.socket.controller.add(
        _event('first', {
          'roomAudience': [_user(10), _user(11), _user(12)],
          'audienceCount': 6,
        }),
      );
      await fixture.flush();
      expect(fixture.manager.state.onlineCount, 6);
      expect(fixture.manager.state.audience, hasLength(6));
      final count = fixture.http.audienceRequests.length;
      fixture.socket.controller.add(_event('other', {}));
      await fixture.flush();
      expect(fixture.http.audienceRequests, hasLength(count));
    },
  );

  test(
    'updates arriving during a pending refresh request the latest snapshot',
    () async {
      fixture.http.audience = [_user(10)];
      await fixture.enter();
      fixture.http.audienceGate = Completer<void>();
      final first = repository.refreshAudience();
      expect(repository.refreshAudience(), same(first));
      fixture.http.audience = [_user(10), _user(20)];
      fixture.socket.controller.add(_event('first', {}));
      fixture.socket.controller.add(_event('first', {}));
      fixture.http.audienceGate!.complete();
      await first;
      await fixture.flush();
      expect(fixture.manager.state.onlineCount, 2);
      expect(fixture.http.audienceRequests, hasLength(3));
    },
  );

  test(
    'Keep retains cached audience and late refresh cannot contaminate re-entry',
    () async {
      fixture.http.audience = [_user(10), _user(20)];
      await fixture.enter();
      final users = fixture.manager.state.audience;
      fixture.manager.minimizeRoom();
      fixture.manager.restoreRoom();
      expect(fixture.manager.state.audience, same(users));
      final oldGate = fixture.http.audienceGate = Completer<void>();
      final old = repository.refreshAudience();
      await repository.leaveRoom();
      fixture.http.audienceGate = null;
      fixture.http.audience = [_user(10)];
      await fixture.enter();
      oldGate.complete();
      await old;
      expect(fixture.manager.state.onlineCount, 1);
      expect(fixture.manager.state.loadingAudience, isFalse);
    },
  );

  test(
    'room, audience dialog and an open gift panel share live counts',
    () async {
      fixture.http.audience = [_user(10), _user(20)];
      await fixture.enter();
      final model = RoomViewModel(repository: repository, roomId: 'first');
      final audience = RoomAudienceViewModel(
        repository: repository,
        roomId: 'first',
      );
      addTearDown(model.dispose);
      addTearDown(audience.dispose);
      late RoomPageState roomState;
      model.addListener((value) => roomState = value);
      final container = ProviderContainer(
        overrides: [
          roomRepositoryProvider.overrideWithValue(repository),
          roomGiftRepositoryProvider.overrideWithValue(_GiftRepository()),
        ],
      );
      addTearDown(container.dispose);
      final provider = roomGiftViewModelProvider('first');
      final subscription = container.listen(provider, (_, __) {});
      addTearDown(subscription.close);
      await container
          .read(provider.notifier)
          .initialize(recipients: const [], onlineCount: 2, currentUid: 10);
      await fixture.flush();
      expect(container.read(provider).onlineCount, 2);
      fixture.http.audience = [_user(10), _user(20), _user(30)];
      await repository.refreshAudience();
      expect(roomState.onlineCount, 3);
      expect(container.read(provider).onlineCount, 3);
      expect(repository.giftAudience('first').onlineCount, 3);
      late RoomState audienceState;
      audience.addListener((value) => audienceState = value);
      expect(audienceState.onlineCount, 3);
      expect(audienceState.audience, same(fixture.manager.state.audience));
    },
  );

  test('disposed dialog ignores pending refresh completion', () async {
    await fixture.enter();
    fixture.http.audienceGate = Completer<void>();
    final model = RoomAudienceViewModel(
      repository: repository,
      roomId: 'first',
    );
    final pending = model.refresh();
    model.dispose();
    fixture.http.audienceGate!.complete();
    await pending;
    expect(fixture.manager.state.loadingAudience, isFalse);
  });
}

Map<String, dynamic> _user(int uid, {String identity = 'ROOM_AUDIENCE'}) => {
  'userBase': {
    'uid': uid,
    'userNo': uid + 100,
    'nick': 'User $uid',
    'gender': 1,
  },
  'roomIdentity': identity,
  'silenceEndTime': null,
};

RoomSocketMessage _event(String roomId, Object payload) => RoomSocketMessage(
  channel: 'room:$roomId',
  event: 'RoomAudienceUpdateEvent',
  payload: payload,
  raw: const {},
);

class _GiftRepository implements RoomGiftRepository {
  @override
  RoomGiftCatalog? get cachedCatalog =>
      const RoomGiftCatalog(balance: 1000, canSendSelf: false, tabs: []);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
