import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/barrage/room_barrage_models.dart';
import 'package:project/classes/room/gift/event/room_gift_event_manager.dart';
import 'package:project/classes/room/barrage/room_barrage_repository.dart';
import 'package:project/classes/room/barrage/room_barrage_view_model.dart';
import 'package:project/classes/room/gift/models/room_gift_event_models.dart';
import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/model/room_socket_message.dart';
import 'package:project/classes/room/more/room_tools_models.dart';
import 'package:project/manager/room_manager.dart';
import 'package:project/model/server_response.dart';
import 'room_barrage_parser_test.dart'
    show barrageNow, barrageMessage, giftBanner;

Future<void> tick() => Future<void>.delayed(Duration.zero);
void main() {
  late BarrageTestRepository repo;
  late RoomBarrageViewModel vm;
  late List<RoomGiftEffectTask> effects;
  setUp(() {
    repo = BarrageTestRepository();
    effects = [];
    vm =
        RoomBarrageViewModel(
            repo,
            now: () => barrageNow,
            startTimer: false,
            onPresentedEffect: effects.add,
          )
          ..syncRoom()
          ..bindIdentity(10, country: 'US');
  });
  tearDown(() {
    vm.dispose();
    repo.events.close();
  });
  Future<RoomBarrageTask> gift({
    String room = '999',
    String id = 'gift',
  }) async {
    vm.receive(
      barrageMessage('RoomGiftSendBannerEvent', giftBanner(room: room), id: id),
    );
    await tick();
    return vm.snapshot.active!.task;
  }

  test(
    'one account queue deduplicates cross-channel copies and advances only matching completion',
    () async {
      vm.receive(barrageMessage('RoomGiftSendBannerEvent', giftBanner()));
      vm.receive(
        barrageMessage(
          'RoomGiftSendBannerEvent',
          giftBanner(),
          channel: 'room:123',
        ),
      );
      await tick();
      expect(repo.prepares, 1);
      final active = vm.snapshot.active!.task;
      vm.complete('other');
      expect(vm.snapshot.active!.task, same(active));
      vm.complete(active.key);
      expect(vm.snapshot.active, isNull);
      vm.receive(barrageMessage('RoomGiftSendBannerEvent', giftBanner()));
      await tick();
      expect(repo.prepares, 1);
    },
  );
  test(
    'prepare failure never preempts; successful waiters are shown without blocking',
    () async {
      repo.failure = true;
      vm.receive(barrageMessage('RoomGiftSendBannerEvent', giftBanner()));
      await tick();
      expect(vm.snapshot.active, isNull);
      expect(effects, isEmpty);
      repo.failure = false;
      await gift(id: 'new');
      expect(vm.snapshot.active, isNotNull);
    },
  );
  test(
    'prize is delivered only once after actual banner presentation, not download or waiting',
    () async {
      await gift(room: '123');
      vm.receive(
        barrageMessage(
          'RoomBigRocketPrizeEvent',
          {'roomId': '999', 'level': 2},
          id: 'rocket',
          channel: 'global',
        ),
      );
      await tick();
      expect(effects, isEmpty);
      final first = vm.snapshot.active!.task.key;
      vm.presented('RoomBigRocketPrizeEvent:rocket');
      expect(effects, isEmpty);
      vm.complete(first);
      final rocket = vm.snapshot.active!.task;
      vm.presented(rocket.key);
      vm.presented(rocket.key);
      expect(effects.length, 1);
      expect(effects.single.message.roomId, '999');
    },
  );
  test(
    'Keep/outside room can display account banners without playing room full-screen',
    () async {
      repo.current = repo.current.copyWith(isMinimized: true);
      vm.receive(
        barrageMessage('RoomBigRocketPrizeEvent', {
          'roomId': '123',
        }, channel: 'global'),
      );
      await tick();
      vm.presented(vm.snapshot.active!.task.key);
      expect(effects, isEmpty);
      expect(vm.snapshot.active, isNotNull);
    },
  );
  test(
    'pending preparation cannot revive after background, room switch, or account change',
    () async {
      repo.pending = Completer<RoomBarragePrepared>();
      vm.receive(barrageMessage('RoomGiftSendBannerEvent', giftBanner()));
      final task = repo.last!;
      vm.setVisible(false);
      vm.setVisible(true);
      repo.pending!.complete(RoomBarragePrepared(task));
      await tick();
      expect(vm.snapshot.active, isNull);
      repo.pending = Completer();
      vm.receive(
        barrageMessage(
          'RoomGiftSendBannerEvent',
          giftBanner(),
          id: 'account-old',
        ),
      );
      final old = repo.last!;
      vm.bindIdentity(99);
      repo.pending!.complete(RoomBarragePrepared(old));
      await tick();
      expect(vm.snapshot.active, isNull);
    },
  );
  test(
    'screen toggle hides banners and config-disabled game prize is not queued',
    () async {
      await gift();
      vm.updateSettings(const RoomEffectPreferences(screen: false));
      expect(vm.snapshot.active, isNull);
      vm.updateSettings(
        const RoomEffectPreferences(),
        functions: const RoomFunctionConfig([]),
      );
      vm.receive(
        barrageMessage('RoomLobbyBigWinPrizeEvent', {
          'userWinCoins': 88,
        }, channel: 'global:10'),
      );
      await tick();
      expect(vm.snapshot.active, isNull);
    },
  );
  test(
    'same-room ordinary/rocket no-op; target room uses existing confirmation adapter',
    () async {
      final navigator = BarrageTestNavigator();
      await vm.activate(await gift(room: '123'), navigator);
      expect(navigator.calls, isEmpty);
      vm.complete(vm.snapshot.active!.task.key);
      await vm.activate(await gift(room: '999', id: 'other'), navigator);
      expect(navigator.calls, ['enter:999']);
    },
  );
  test(
    'duplicate click is blocked; account change invalidates pending enter',
    () async {
      final navigator = BarrageTestNavigator()..pending = Completer<bool>();
      final task = await gift();
      final first = vm.activate(task, navigator);
      await tick();
      await vm.activate(task, navigator);
      expect(navigator.calls.length, 1);
      vm.bindIdentity(20);
      navigator.pending!.complete(true);
      await first;
      expect(navigator.valid!(), isFalse);
      expect(vm.snapshot.actionBusy, isFalse);
    },
  );
  test(
    'noble profile, local prize, safe web and server msg remain typed',
    () async {
      final navigator = BarrageTestNavigator();
      vm.receive(
        barrageMessage(
          'GlobalAristocracyOnlineEvent',
          {
            'userInfo': {'uid': 42},
            'enMsg': 'Noble',
          },
          id: 'noble',
          channel: 'global',
        ),
      );
      await tick();
      await vm.activate(vm.snapshot.active!.task, navigator);
      expect(navigator.calls, ['profile:42']);
      vm.complete(vm.snapshot.active!.task.key);
      vm.receive(
        barrageMessage(
          'RoomLobbyBigWinPrizeEvent',
          {'userWinCoins': 88},
          id: 'prize',
          channel: 'global:10',
        ),
      );
      await tick();
      await vm.activate(vm.snapshot.active!.task, navigator);
      expect(navigator.calls.last, 'prize:88');
      vm.complete(vm.snapshot.active!.task.key);
      vm.receive(
        barrageMessage(
          'RoomResourceFloatScreenEvent',
          {
            'copywriting': {'en': 'Reward'},
            'jumpLink': 'https://example.test/?a=1',
          },
          id: 'resource',
          channel: 'global',
        ),
      );
      await tick();
      navigator.error = const NadyApiException(message: 'Server msg');
      await vm.activate(vm.snapshot.active!.task, navigator);
      expect(vm.snapshot.issue, 'Server msg');
    },
  );
  test(
    'cross-room game waits for confirmed ready room; cancellation does not open game',
    () async {
      final navigator = BarrageTestNavigator();
      vm.receive(
        barrageMessage('RoomGameFloatScreenEvent', {
          'roomId': '999',
          'win': 8,
          'gameName': 'Game',
          'gameUrl': 'https://example.test/game',
        }, id: 'game'),
      );
      await tick();
      final task = vm.snapshot.active!.task;
      navigator.onEnter = () {
        repo.generation++;
        repo.current = const RoomState(
          status: RoomStatus.leaving,
          isInRoom: true,
          currentRoomId: '123',
        );
        vm.syncRoom();
        repo.current = const RoomState(status: RoomStatus.idle);
        vm.syncRoom();
        repo.current = const RoomState(
          status: RoomStatus.entering,
          currentRoomId: '999',
        );
        vm.syncRoom();
        repo.current = const RoomState(
          status: RoomStatus.ready,
          isInRoom: true,
          currentRoomId: '999',
        );
        vm.syncRoom();
      };
      await vm.activate(task, navigator);
      expect(navigator.calls, ['enter:999', 'game:999']);
      expect(navigator.valid!(), isTrue);
    },
  );

  test(
    'new login ends the previous account room before binding new account channels',
    () async {
      vm.start();
      await tick();
      expect(repo.boundAccounts, [10]);
      repo.identityValue = const RoomBarrageIdentity(
        20,
        'TR',
        RoomEffectPreferences(),
      );
      repo.authListeners.single();
      await tick();
      expect(repo.endedRooms, 1);
      expect(repo.boundAccounts, [10, 20]);
      expect(vm.snapshot.uid, 20);
      expect(repo.current.status, RoomStatus.idle);
      vm.dispose();
      expect(repo.roomListeners, isEmpty);
      expect(repo.authListeners, isEmpty);
      vm = RoomBarrageViewModel(repo, now: () => barrageNow, startTimer: false);
    },
  );
  test(
    'late identity reads cannot bind an account superseded by a new login',
    () async {
      final first = Completer<RoomBarrageIdentity>();
      repo.identityPending = first;
      vm.start();
      await tick();
      final latest = Completer<RoomBarrageIdentity>();
      repo.identityPending = latest;
      repo.authListeners.single();
      first.complete(
        const RoomBarrageIdentity(20, 'US', RoomEffectPreferences()),
      );
      latest.complete(
        const RoomBarrageIdentity(30, 'US', RoomEffectPreferences()),
      );
      await tick();
      expect(repo.boundAccounts, [30]);
      expect(vm.snapshot.uid, 30);
    },
  );
  test(
    'release failure clears only visual lane and prevents new native work',
    () async {
      final task = await gift();
      vm.blockPlayback(task.key, StateError('release failed'));
      expect(vm.snapshot.active, isNull);
      expect(vm.snapshot.issue, 'room.barrage.playbackUnavailable');
      vm.receive(
        barrageMessage(
          'RoomGiftSendBannerEvent',
          giftBanner(),
          id: 'new-after-error',
        ),
      );
      await tick();
      expect(repo.prepares, 1);
      expect(repo.endedRooms, 0);
      expect(effects, isEmpty);
    },
  );
  test(
    'expired or replaced own combo cannot show an old SUPER banner',
    () async {
      vm.dispose();
      RoomScreenGiftMsg? active = const RoomScreenGiftMsg(
        uid: 10,
        userInfo: RoomGiftUser(uid: 10),
        comboId: 'combo-one',
        roomId: '123',
        giftCount: 1,
        gift: RoomGift(
          id: 31,
          name: 'Lucky',
          icon: '',
          price: 1,
          isCombo: 1,
          tabId: 0,
          giftType: 3,
        ),
      );
      vm =
          RoomBarrageViewModel(
              repo,
              now: () => barrageNow,
              startTimer: false,
              onPresentedEffect: effects.add,
              activeJackpotGift: (_) => active,
            )
            ..syncRoom()
            ..bindIdentity(10);
      final first = await gift(room: '123');
      vm.receive(
        barrageMessage('LuckyGiftJackpotSuperMode', {
          'roomId': '123',
          'giftId': 31,
          'mode': 'SUPER',
          'amount': 500,
        }, id: 'super'),
      );
      await tick();
      active = null;
      vm.complete(first.key);
      expect(vm.snapshot.active, isNull);
      expect(effects, isEmpty);
    },
  );

  test(
    'old same-ID UI callbacks cannot affect a new account/visual epoch',
    () async {
      final oldTask = await gift(id: 'same-id');
      final oldEpoch = vm.snapshot.epoch;
      vm.bindIdentity(20);
      final fresh = await gift(id: 'same-id');
      vm.complete(oldTask.key, epoch: oldEpoch);
      vm.presented(oldTask.key, epoch: oldEpoch);
      vm.blockPlayback(
        oldTask.key,
        StateError('late old callback'),
        epoch: oldEpoch,
      );
      expect(vm.snapshot.active!.task, same(fresh));
      expect(vm.snapshot.issue, isNull);
      final navigator = BarrageTestNavigator();
      await vm.activate(oldTask, navigator);
      expect(navigator.calls, isEmpty);
    },
  );

  test(
    'old transport publications arriving after account rebind are discarded',
    () async {
      vm.dispose();
      var clock = barrageNow;
      vm = RoomBarrageViewModel(repo, now: () => clock, startTimer: false)
        ..syncRoom()
        ..bindIdentity(10);
      final old = barrageMessage(
        'RoomGiftSendBannerEvent',
        giftBanner(),
        id: 'old-transport',
      );
      clock = clock.add(const Duration(milliseconds: 10));
      vm.bindIdentity(20);
      vm.receive(old);
      await tick();
      expect(vm.snapshot.active, isNull);
    },
  );
  test(
    'room-side compatibility lanes cannot duplicate account banner or foreground effects',
    () async {
      final room = RoomGiftEventManager(
        roomId: '123',
        now: () => barrageNow,
        startTimer: false,
        barrageManaged: true,
      );
      final event = barrageMessage('RoomGiftSendBannerEvent', {
        ...giftBanner(),
        'upperEffect': 'https://cdn.example/foreground.pag',
      }, channel: 'room:123');
      room.receive(event);
      vm.receive(event);
      await tick();
      expect(room.snapshot.banners, isEmpty);
      expect(room.snapshot.effects, isEmpty);
      expect(
        vm.snapshot.active!.task.foreground,
        'https://cdn.example/foreground.pag',
      );
      room.dispose();
    },
  );

  test(
    'same-account new login also ends the previous room session before reauthentication',
    () async {
      vm.start();
      await tick();
      repo.authListeners.single();
      await tick();
      expect(repo.endedRooms, 1);
      expect(repo.boundAccounts, [10, 10]);
      expect(repo.current.status, RoomStatus.idle);
    },
  );
}

class BarrageTestRepository implements RoomBarrageRepository {
  RoomState current = const RoomState(
    status: RoomStatus.ready,
    isInRoom: true,
    currentRoomId: '123',
  );
  int generation = 1, prepares = 0;
  bool failure = false;
  RoomBarrageTask? last;
  Completer<RoomBarragePrepared>? pending;
  final events = StreamController<RoomSocketMessage>.broadcast();
  final roomListeners = <void Function()>[],
      authListeners = <void Function()>[];
  RoomBarrageIdentity identityValue = const RoomBarrageIdentity(
    10,
    'US',
    RoomEffectPreferences(),
  );
  Completer<RoomBarrageIdentity>? identityPending;
  final boundAccounts = <int?>[];
  int endedRooms = 0;
  @override
  Stream<RoomSocketMessage> get messages => events.stream;
  @override
  Future<RoomBarrageIdentity> identity() async =>
      identityPending?.future ?? identityValue;
  @override
  Future<void> bindAccount(int? uid, {bool reauthenticate = false}) async {
    boundAccounts.add(uid);
  }

  @override
  Future<void> endPreviousRoom() async {
    if (current.status != RoomStatus.idle) {
      endedRooms++;
      generation++;
      current = const RoomState();
      for (final cb in roomListeners.toList()) {
        cb();
      }
    }
  }

  @override
  RoomState get roomState => current;
  @override
  int get roomGeneration => generation;
  @override
  int giftValue(RoomBarrageTask task) => task.value;
  @override
  Future<RoomBarragePrepared> prepare(RoomBarrageTask task) async {
    prepares++;
    last = task;
    if (failure) throw const FormatException('Fixture unavailable');
    return pending?.future ?? Future.value(RoomBarragePrepared(task));
  }

  @override
  Future<bool> waitForRoom(String id, bool Function() valid) async =>
      valid() && current.currentRoomId == id && current.isInRoom;
  @override
  void addRoomListener(void Function() cb) => roomListeners.add(cb);
  @override
  void removeRoomListener(void Function() cb) => roomListeners.remove(cb);
  @override
  void addAuthListener(void Function() cb) => authListeners.add(cb);
  @override
  void removeAuthListener(void Function() cb) => authListeners.remove(cb);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class BarrageTestNavigator implements RoomBarrageNavigator {
  final calls = <String>[];
  int cancelled = 0;
  @override
  void cancelPending() {
    cancelled++;
  }

  bool Function()? valid;
  void Function()? onEnter;
  Completer<bool>? pending;
  Object? error;
  @override
  Future<bool> enterRoom(String id, bool Function() valid) async {
    this.valid = valid;
    calls.add('enter:$id');
    onEnter?.call();
    return pending?.future ?? true;
  }

  @override
  Future<void> profile(int uid, bool Function() valid) async {
    this.valid = valid;
    calls.add('profile:$uid');
  }

  @override
  Future<void> gift(String id, int gift, bool Function() valid) async {
    this.valid = valid;
    calls.add('gift:$id:$gift');
  }

  @override
  Future<void> game(String id, Uri url, bool Function() valid) async {
    this.valid = valid;
    calls.add('game:$id');
  }

  @override
  Future<void> prize(RoomBarragePrize prize, bool Function() valid) async {
    this.valid = valid;
    calls.add('prize:${prize.amount}');
  }

  @override
  Future<void> web(Uri url, bool Function() valid) async {
    if (error != null) throw error!;
    calls.add('web:$url');
  }
}
