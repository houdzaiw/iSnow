import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:project/classes/room/gift/event/room_gift_event_provider.dart';
import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/classes/room/gift/room_gift_repository.dart';
import 'package:project/classes/room/gift/viewmodel/room_gift_send_controller.dart';
import 'package:project/classes/room/room_page.dart';
import 'package:project/classes/room/room_repository.dart';
import 'package:project/classes/room/viewmodel/room_view_model.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/manager/app_socket_manager.dart';
import 'package:project/manager/room_agora_manager.dart';
import 'package:project/manager/room_manager.dart';
import 'package:project/model/room_socket_message.dart';
import 'package:project/model/user_profile.dart';
import 'package:project/theme/app_theme.dart';

void main() {
  for (final pushed in [false, true]) {
    testWidgets('exit disposes room controllers with pushed=$pushed', (
      tester,
    ) async {
      final repository = _RoomRepository();
      final harness = await _openRoom(tester, repository, pushed: pushed);
      final model = harness.container.read(
        roomViewModelProvider('alias').notifier,
      );
      final gifts = harness.container.read(
        roomGiftEventManagerProvider('canonical').notifier,
      );
      final sender = harness.container.read(
        roomGiftSendControllerProvider('canonical').notifier,
      );
      expect(model.mounted, isTrue);
      expect(repository.messages.hasListener, isTrue);

      await tester.tap(_exitButton);
      await tester.pumpAndSettle();
      await tester.pump();

      expect(find.byType(RoomPage), findsNothing);
      expect(find.text('Party'), findsOneWidget);
      expect(repository.leaveCalls, 1);
      expect(repository.minimizeCalls, 0);
      expect(model.mounted, isFalse);
      expect(gifts.isAlive, isFalse);
      expect(sender.mounted, isFalse);
      expect(repository.hasActiveListeners, isFalse);
      expect(repository.messages.hasListener, isFalse);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Open room'));
      await tester.pumpAndSettle();
      final next = harness.container.read(
        roomViewModelProvider('alias').notifier,
      );
      expect(next, isNot(same(model)));
      await tester.tap(_exitButton);
      await tester.pumpAndSettle();
      expect(next.mounted, isFalse);
      expect(repository.leaveCalls, 2);
      expect(repository.hasActiveListeners, isFalse);
      expect(repository.messages.hasListener, isFalse);
    });
  }

  testWidgets('exit in flight ignores repeat taps and prevents back minimize', (
    tester,
  ) async {
    final repository = _RoomRepository()..leaveGate = Completer<void>();
    final harness = await _openRoom(tester, repository);
    await tester.tap(_exitButton);
    await tester.pump();
    await tester.tap(_exitButton);
    await tester.pump();
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    await navigator.maybePop();
    await tester.pump();
    expect(find.byType(RoomPage), findsOneWidget);
    expect(repository.leaveCalls, 1);
    expect(repository.minimizeCalls, 0);
    repository.leaveGate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(RoomPage), findsNothing);
    expect(repository.messages.hasListener, isFalse);
    expect(harness.router.canPop(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('back minimizes but releases only the page controller', (
    tester,
  ) async {
    final repository = _RoomRepository();
    final harness = await _openRoom(tester, repository);
    final model = harness.container.read(
      roomViewModelProvider('alias').notifier,
    );
    final gifts = harness.container.read(
      roomGiftEventManagerProvider('canonical').notifier,
    );
    harness.router.pop();
    await tester.pumpAndSettle();
    expect(model.mounted, isFalse);
    expect(gifts.isAlive, isTrue);
    expect(repository.roomState.isMinimized, isTrue);
    expect(repository.roomState.isInRoom, isTrue);
    expect(repository.minimizeCalls, 1);
    expect(repository.leaveCalls, 0);
    expect(repository.messages.hasListener, isTrue);
    await repository.leaveRoom();
    await tester.pump();
    await tester.pump();
    expect(gifts.isAlive, isFalse);
    expect(repository.hasActiveListeners, isFalse);
    expect(repository.messages.hasListener, isFalse);
  });

  testWidgets('pending exit can finish after another route removes the page', (
    tester,
  ) async {
    final repository = _RoomRepository()..leaveGate = Completer<void>();
    final harness = await _openRoom(tester, repository);
    final model = harness.container.read(
      roomViewModelProvider('alias').notifier,
    );
    await tester.tap(_exitButton);
    await tester.pump();
    harness.router.go('/party');
    await tester.pumpAndSettle();
    expect(model.mounted, isFalse);
    repository.leaveGate!.complete();
    await tester.pump();
    await tester.pump();
    expect(repository.hasActiveListeners, isFalse);
    expect(repository.messages.hasListener, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed exit stays in the page and can retry', (tester) async {
    final repository = _RoomRepository()
      ..leaveError = StateError('Exit failed');
    final harness = await _openRoom(tester, repository);
    final model = harness.container.read(
      roomViewModelProvider('alias').notifier,
    );
    await tester.tap(_exitButton);
    await tester.pumpAndSettle();
    expect(find.byType(RoomPage), findsOneWidget);
    expect(model.mounted, isTrue);
    expect(repository.leaveCalls, 1);
    expect(find.text('Bad state: Exit failed'), findsOneWidget);
    repository.leaveError = null;
    await tester.tap(_exitButton);
    await tester.pumpAndSettle();
    expect(model.mounted, isFalse);
    expect(find.byType(RoomPage), findsNothing);
    expect(repository.leaveCalls, 2);
    expect(repository.messages.hasListener, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an idle gift runtime does not retain an unused controller', (
    tester,
  ) async {
    final repository = _RoomRepository();
    final container = ProviderContainer(
      overrides: [
        roomRepositoryProvider.overrideWithValue(repository),
        roomGiftRepositoryProvider.overrideWithValue(_GiftRepository()),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await repository.messages.close();
      repository.dispose();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const SizedBox()),
    );
    final subscription = container.listen(
      roomGiftEventManagerProvider('alias'),
      (_, __) {},
    );
    final gifts = container.read(
      roomGiftEventManagerProvider('alias').notifier,
    );
    final sender = container.read(
      roomGiftSendControllerProvider('alias').notifier,
    );
    await tester.pump();
    subscription.close();
    await tester.pump();
    await tester.pump();
    expect(gifts.isAlive, isFalse);
    expect(sender.mounted, isFalse);
    expect(repository.hasActiveListeners, isFalse);
    expect(repository.messages.hasListener, isFalse);
  });
}

Finder get _exitButton => find.byWidgetPredicate(
  (widget) =>
      widget is Image &&
      widget.image is AssetImage &&
      (widget.image as AssetImage).assetName == AppAssets.lanhuRoomPower,
);

Future<({ProviderContainer container, GoRouter router})> _openRoom(
  WidgetTester tester,
  _RoomRepository repository, {
  bool pushed = true,
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    initialLocation: pushed ? '/party' : '/room/alias',
    routes: [
      GoRoute(
        path: '/party',
        builder: (context, _) => Scaffold(
          body: Column(
            children: [
              const Text('Party'),
              TextButton(
                onPressed: () => context.push('/room/alias'),
                child: const Text('Open room'),
              ),
            ],
          ),
        ),
      ),
      GoRoute(
        path: '/room/:roomId',
        builder: (_, state) =>
            RoomPage(roomId: state.pathParameters['roomId']!),
      ),
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    await repository.messages.close();
    repository.dispose();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        roomRepositoryProvider.overrideWithValue(repository),
        roomGiftRepositoryProvider.overrideWithValue(_GiftRepository()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => MaterialApp.router(
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
  if (pushed) {
    await tester.tap(find.text('Open room'));
    await tester.pumpAndSettle();
  }
  final container = ProviderScope.containerOf(
    tester.element(find.byType(RoomPage)),
  );
  return (container: container, router: router);
}

class _RoomRepository extends ChangeNotifier implements RoomRepository {
  bool get hasActiveListeners => hasListeners;
  RoomState room = const RoomState();
  final messages = StreamController<RoomSocketMessage>.broadcast(sync: true);
  int leaveCalls = 0;
  int minimizeCalls = 0;
  Completer<void>? leaveGate;
  Object? leaveError;

  @override
  RoomState get roomState => room;
  @override
  AppSocketState get socketState => const AppSocketState();
  @override
  RoomAgoraState get agoraState => const RoomAgoraState();
  @override
  Stream<RoomSocketMessage> get socketMessages => messages.stream;
  @override
  Future<int?> currentUid() async => 10;
  @override
  Future<UserData?> currentUser() async => null;
  @override
  RoomGiftAudience giftAudience(String roomId) => RoomGiftAudience(
    isInRoom: room.isInRoom && room.currentRoomId == roomId,
    onlineCount: 1,
    recipients: const [],
  );
  @override
  Future<void> enterRoom({
    required String roomId,
    String roomPassword = '',
    int followUid = 0,
  }) async {
    room = RoomState(status: RoomStatus.entering, currentRoomId: roomId);
    notifyListeners();
    room = const RoomState(
      status: RoomStatus.ready,
      currentRoomId: 'canonical',
      isInRoom: true,
    );
    notifyListeners();
  }

  @override
  Future<void> leaveRoom() async {
    leaveCalls++;
    room = room.copyWith(status: RoomStatus.leaving);
    notifyListeners();
    await leaveGate?.future;
    if (leaveError != null) {
      room = room.copyWith(status: RoomStatus.ready);
      notifyListeners();
      throw leaveError!;
    }
    room = const RoomState();
    notifyListeners();
  }

  @override
  void minimizeRoom() {
    minimizeCalls++;
    room = room.copyWith(isMinimized: true);
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _GiftRepository implements RoomGiftRepository {
  @override
  RoomGiftCatalog? get cachedCatalog => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
