import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/room_repository.dart';
import 'package:project/classes/room/viewmodel/room_state.dart';
import 'package:project/classes/room/viewmodel/room_view_model.dart';
import 'package:project/manager/room_manager.dart';
import 'package:project/model/room_models.dart';
import 'package:project/model/server_response.dart';

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

  test('room details decode nested and flat follow state', () {
    expect(
      RoomInfo.fromJson({
        'roomInfoDTO': {'roomId': 123, 'isFollow': true, 'roomUid': 20},
      }).isFollow,
      isTrue,
    );
    expect(
      RoomInfo.fromJson({
        'roomInfo': {'roomId': 123, 'isFollow': false},
      }).isFollow,
      isFalse,
    );
    expect(RoomInfo.fromJson({'roomId': 123, 'isFollow': 1}).isFollow, isTrue);
    expect(RoomInfo.fromJson({'roomId': 123}).isFollow, isNull);
  });

  test('follow visibility excludes owners but not room managers', () {
    const state = RoomPageState(
      roomId: 'first',
      currentRoomId: 'first',
      status: RoomStatus.ready,
      isInRoom: true,
      currentUid: 10,
    );
    expect(state.showFollowRoomButton, isTrue);
    expect(state.copyWith(isRoomFollowed: true).showFollowRoomButton, isFalse);
    expect(state.copyWith(currentUid: null).showFollowRoomButton, isFalse);
    expect(state.copyWith(isInRoom: false).showFollowRoomButton, isFalse);
    expect(
      state
          .copyWith(
            roomInfo: const RoomInfo(
              roomId: 'first',
              raw: {},
              roomOwnerUid: 10,
            ),
          )
          .showFollowRoomButton,
      isFalse,
    );
    for (final identity in [UserRoomIdentity.owner, UserRoomIdentity.manager]) {
      expect(
        state
            .copyWith(
              enterResponse: EnterRoomResp(
                roomId: 'first',
                raw: const {},
                identity: identity,
              ),
            )
            .showFollowRoomButton,
        identity == UserRoomIdentity.manager,
      );
    }
  });

  test(
    'follow sends canonical room ID and accepts success without data',
    () async {
      fixture.http.canonicalRoomId = 'canonical';
      fixture.http.roomIsFollowed = false;
      final model = RoomViewModel(repository: repository, roomId: 'alias');
      addTearDown(model.dispose);
      late RoomPageState state;
      model.addListener((value) => state = value);
      await model.enterRoom();
      await fixture.flush();
      expect(state.showFollowRoomButton, isTrue);
      final infoCalls = fixture.http.infoCalls;

      await model.followRoom();
      await fixture.flush();

      expect(fixture.http.followRequests, [
        {'roomId': 'canonical'},
      ]);
      expect(state.isRoomFollowed, isTrue);
      expect(state.followingRoom, isFalse);
      expect(state.showFollowRoomButton, isFalse);
      expect(state.errorMessage, isNull);
      expect(fixture.http.infoCalls, infoCalls + 1);
      // The server can return its pre-follow detail snapshot during refresh.
      expect(fixture.manager.state.roomInfo?.isFollow, isFalse);
      expect(fixture.manager.state.isFollowed, isTrue);
      await model.followRoom();
      expect(fixture.http.followRequests, hasLength(1));
    },
  );

  test('already followed room hides the button without another POST', () async {
    fixture.http.roomIsFollowed = true;
    await fixture.enter();
    final model = RoomViewModel(repository: repository, roomId: 'first');
    addTearDown(model.dispose);
    late RoomPageState state;
    model.addListener((value) => state = value);
    await fixture.flush();
    expect(state.isRoomFollowed, isTrue);
    expect(state.showFollowRoomButton, isFalse);
    await model.followRoom();
    await repository.followRoom();
    expect(fixture.http.followRequests, isEmpty);
  });

  test(
    'duplicate follow shares a pending task and does not hide early',
    () async {
      await fixture.enter();
      fixture.http.followGate = Completer<void>();
      final first = repository.followRoom();
      final second = repository.followRoom();
      expect(second, same(first));
      expect(fixture.manager.state.isFollowingRoom, isTrue);
      expect(fixture.manager.state.isFollowed, isFalse);
      expect(fixture.http.followRequests, hasLength(1));
      fixture.http.followGate!.complete();
      await first;
      expect(fixture.manager.state.isFollowingRoom, isFalse);
      expect(fixture.manager.state.isFollowed, isTrue);
    },
  );

  test(
    'failed follow preserves button, records API error, and allows retry',
    () async {
      await fixture.enter();
      fixture.http.followResponse = const {
        'code': 1003,
        'message': 'Server error',
        'traceId': 'follow-error',
      };
      final model = RoomViewModel(repository: repository, roomId: 'first');
      addTearDown(model.dispose);
      late RoomPageState state;
      model.addListener((value) => state = value);
      await fixture.flush();
      await model.followRoom();
      expect(state.isRoomFollowed, isFalse);
      expect(state.followingRoom, isFalse);
      expect(state.showFollowRoomButton, isTrue);
      expect(state.errorMessage, contains('Server error'));
      expect(state.errorMessage, contains('follow-error'));

      fixture.http.followResponse = const {'code': 200};
      await model.followRoom();
      expect(state.showFollowRoomButton, isFalse);
      expect(state.errorMessage, isNull);
      expect(fixture.http.followRequests, hasLength(2));
    },
  );

  test(
    'follow persists when Keep disposes and recreates the page model',
    () async {
      await fixture.enter();
      await repository.followRoom();
      final first = RoomViewModel(repository: repository, roomId: 'first');
      await fixture.flush();
      expect(first.minimizeRoom(), isTrue);
      first.dispose();
      final restored = RoomViewModel(repository: repository, roomId: 'first');
      addTearDown(restored.dispose);
      late RoomPageState state;
      restored.addListener((value) => state = value);
      restored.restoreRoom();
      await fixture.flush();
      expect(state.isRoomFollowed, isTrue);
      expect(state.isMinimized, isFalse);
      expect(state.showFollowRoomButton, isFalse);
      await restored.followRoom();
      expect(fixture.http.followRequests, hasLength(1));
    },
  );

  test('network failure clears pending state and allows a retry', () async {
    await fixture.enter();
    fixture.http.followGate = Completer<void>();
    final model = RoomViewModel(repository: repository, roomId: 'first');
    addTearDown(model.dispose);
    late RoomPageState state;
    model.addListener((value) => state = value);
    await fixture.flush();
    final pending = model.followRoom();
    fixture.http.followGate!.completeError(StateError('Network unavailable'));
    await pending;
    expect(state.followingRoom, isFalse);
    expect(state.isRoomFollowed, isFalse);
    expect(state.showFollowRoomButton, isTrue);
    expect(state.errorMessage, contains('Network unavailable'));
    fixture.http.followGate = null;
    await model.followRoom();
    expect(state.isRoomFollowed, isTrue);
    expect(fixture.http.followRequests, hasLength(2));
  });

  test('pending follow survives Keep and updates the restored model', () async {
    await fixture.enter();
    fixture.http.followGate = Completer<void>();
    final first = RoomViewModel(repository: repository, roomId: 'first');
    await fixture.flush();
    final pending = first.followRoom();
    expect(first.minimizeRoom(), isTrue);
    first.dispose();
    final restored = RoomViewModel(repository: repository, roomId: 'first');
    addTearDown(restored.dispose);
    late RoomPageState state;
    restored.addListener((value) => state = value);
    await fixture.flush();
    expect(state.followingRoom, isTrue);
    expect(state.showFollowRoomButton, isTrue);
    await restored.followRoom();
    expect(fixture.http.followRequests, hasLength(1));
    fixture.http.followGate!.complete();
    await pending;
    expect(state.isRoomFollowed, isTrue);
    expect(state.followingRoom, isFalse);
  });

  test(
    'late follow after Exit cannot mark a new same-ID session followed',
    () async {
      await fixture.enter();
      final oldGate = fixture.http.followGate = Completer<void>();
      final old = repository.followRoom();
      await repository.leaveRoom();
      await fixture.enter();
      final newGate = fixture.http.followGate = Completer<void>();
      final next = repository.followRoom();
      oldGate.complete();
      await old;
      expect(fixture.manager.state.isFollowed, isFalse);
      expect(fixture.manager.state.isFollowingRoom, isTrue);
      expect(repository.followRoom(), same(next));
      newGate.complete();
      await next;
      expect(fixture.manager.state.isFollowed, isTrue);
      expect(fixture.http.followRequests, hasLength(2));
    },
  );

  test(
    'late failed follow after page disposal cannot update the new room',
    () async {
      await fixture.enter();
      fixture.http.followGate = Completer<void>();
      fixture.http.followResponse = const {
        'code': 1003,
        'message': 'Server error',
      };
      final model = RoomViewModel(repository: repository, roomId: 'first');
      await fixture.flush();
      final pending = model.followRoom();
      model.dispose();
      await repository.leaveRoom();
      await fixture.enter('second');
      fixture.http.followGate!.complete();
      await pending;
      expect(fixture.manager.state.currentRoomId, 'second');
      expect(fixture.manager.state.isFollowed, isFalse);
      expect(fixture.manager.state.isFollowingRoom, isFalse);
      expect(fixture.manager.state.errorMessage, isNull);
    },
  );

  test('following outside an active session is rejected without a POST', () {
    expect(() => repository.followRoom(), throwsA(isA<NadyApiException>()));
    expect(fixture.http.followRequests, isEmpty);
  });

  test(
    'Exit during follow notification skips the follow-up detail request',
    () async {
      await fixture.enter();
      final infoCalls = fixture.http.infoCalls;
      Future<void>? leaving;
      void onChange() {
        if (fixture.manager.state.status == RoomStatus.ready &&
            fixture.manager.state.isFollowed) {
          leaving = fixture.manager.leaveRoom();
        }
      }

      fixture.manager.addListener(onChange);
      await repository.followRoom();
      await leaving;
      fixture.manager.removeListener(onChange);
      expect(fixture.manager.state.status, RoomStatus.idle);
      expect(fixture.http.infoCalls, infoCalls);
    },
  );

  test(
    'late failure cannot update a reused model in a new same-ID session',
    () async {
      await fixture.enter();
      fixture.http.followGate = Completer<void>();
      fixture.http.followResponse = const {
        'code': 1003,
        'message': 'Old failure',
      };
      final model = RoomViewModel(repository: repository, roomId: 'first');
      addTearDown(model.dispose);
      late RoomPageState state;
      model.addListener((value) => state = value);
      await fixture.flush();
      final pending = model.followRoom();
      await model.leaveRoom();
      await model.enterRoom();
      await fixture.flush();
      fixture.http.followGate!.complete();
      await pending;
      expect(state.isReady, isTrue);
      expect(state.followingRoom, isFalse);
      expect(state.isRoomFollowed, isFalse);
      expect(state.errorMessage, isNull);
    },
  );
}
