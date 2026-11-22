import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/classes/room/more/room_tools_repository.dart';
import 'package:project/classes/room/recovery/room_recovery_host.dart';
import 'package:project/classes/room/recovery/room_recovery_view_model.dart';
import 'package:project/classes/room/room_repository.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/manager/app_socket_manager.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/manager/room_agora_manager.dart';
import 'package:project/manager/room_manager.dart';
import 'package:project/model/room_recovery_notice.dart';
import 'package:project/model/server_response.dart';
import 'package:project/theme/app_theme.dart';

import 'support/room_lifecycle_fakes.dart';
import 'support/room_tools_fakes.dart';

void terminal(RoomLifecycleFixture f, {int code = 3502}) => f.socket.setState(
  AppSocketState(
    status: AppSocketStatus.disconnected,
    isTerminal: true,
    disconnectCode: code,
  ),
);

RoomRepository repositoryFor(RoomLifecycleFixture f) => RoomRepository(
  roomManager: f.manager,
  socketManager: f.socket,
  agoraManager: f.agora,
  httpManager: f.http,
  authSession: f.auth,
);

void main() {
  test(
    'terminal cleanup retains canonical target, never automatically enters',
    () async {
      final f = RoomLifecycleFixture();
      addTearDown(f.dispose);
      f.http.canonicalRoomId = 'canonical';
      await f.enter('display-id');
      f.http.exitGate = Completer<void>();
      terminal(f);
      await f.flush();
      final notice = f.manager.recoveryNotice!;
      expect(notice.roomId, 'canonical');
      expect(notice.reason, RoomDisconnectReason.authenticationTimeout);
      expect(f.manager.state.status, RoomStatus.leaving);
      f.http.exitGate!.complete();
      await f.flush();
      expect(f.manager.state.status, RoomStatus.idle);
      expect(f.manager.recoveryNotice, same(notice));
      expect(f.manager.sessionGeneration, notice.generation);
      await f.flush();
      expect(f.actions.where((s) => s.startsWith('enter:')), [
        'enter:display-id',
      ]);
      expect(f.actions.where((s) => s.startsWith('exit:')).length, 1);
      expect(f.actions, containsAll(['agora-leave', 'socket-disconnect']));
    },
  );

  test('transient loss and deliberate exit do not offer recovery', () async {
    final f = RoomLifecycleFixture();
    addTearDown(f.dispose);
    await f.enter();
    f.socket.setState(const AppSocketState(status: AppSocketStatus.connecting));
    await f.flush();
    expect(f.manager.state.isInRoom, isTrue);
    expect(f.manager.recoveryNotice, isNull);
    await f.manager.leaveRoom();
    expect(f.manager.recoveryNotice, isNull);
  });

  test(
    'audio terminal has its own reason; new session clears old recovery',
    () async {
      final f = RoomLifecycleFixture();
      addTearDown(f.dispose);
      await f.enter();
      f.agora.setState(const RoomAgoraState(isTerminal: true));
      await f.flush();
      final old = f.manager.recoveryNotice!;
      expect(old.reason, RoomDisconnectReason.audioClosed);
      await f.enter('second');
      expect(f.manager.recoveryNotice, isNull);
      terminal(f, code: 3501);
      await f.flush();
      final next = f.manager.recoveryNotice!;
      f.manager.dismissRecovery(old);
      expect(f.manager.recoveryNotice, same(next));
      expect(next.reason, RoomDisconnectReason.socketClosed);
      f.manager.dismissRecovery(next);
      expect(f.manager.recoveryNotice, isNull);
    },
  );

  test(
    'view model waits for cleanup and merges repeated manual clicks',
    () async {
      final f = RoomLifecycleFixture();
      addTearDown(f.dispose);
      final vm = RoomRecoveryViewModel(repositoryFor(f));
      addTearDown(vm.dispose);
      await f.enter();
      f.http.exitGate = Completer<void>();
      terminal(f);
      await f.flush();
      expect(vm.state.notice, isNull);
      f.http.exitGate!.complete();
      await f.flush();
      final navigation = _Navigation()..gate = Completer<bool>();
      final pending = vm.retry(navigation);
      await vm.retry(navigation);
      expect(navigation.calls, 1);
      expect(vm.state.busy, isTrue);
      navigation.gate!.complete(false);
      await pending;
      expect(vm.state.busy, isFalse);
      expect(vm.state.notice, isNotNull);
      navigation.gate = null;
      navigation.result = true;
      await vm.retry(navigation);
      expect(vm.state.notice, isNull);
      expect(f.manager.recoveryNotice, isNull);
    },
  );

  test('account changes invalidate pending checks and owned prompts', () async {
    final f = RoomLifecycleFixture();
    addTearDown(f.dispose);
    final vm = RoomRecoveryViewModel(repositoryFor(f));
    addTearDown(vm.dispose);
    await f.enter();
    terminal(f);
    await f.flush();
    final navigation = _Navigation()..gate = Completer<bool>();
    final pending = vm.retry(navigation);
    navigation.onPrompt!();
    expect(vm.state.prompt, isTrue);
    await f.auth.clear();
    expect(navigation.valid!(), isFalse);
    expect(navigation.cancellations, 1);
    navigation.gate!.complete(true);
    await pending;
    expect(vm.state.notice, isNull);
    expect(f.manager.recoveryNotice, isNull);
  });

  test(
    'failed checks keep recovery and server error; disposal cancels work',
    () async {
      final f = RoomLifecycleFixture();
      addTearDown(f.dispose);
      final vm = RoomRecoveryViewModel(repositoryFor(f));
      await f.enter();
      terminal(f);
      await f.flush();
      final navigation = _Navigation()..error = StateError('failure');
      await vm.retry(navigation);
      expect(vm.state.issue, 'room.recovery.failed');
      expect(vm.state.notice, isNotNull);
      navigation.error = null;
      navigation.gate = Completer<bool>();
      final pending = vm.retry(navigation);
      vm.dispose();
      expect(navigation.valid!(), isFalse);
      expect(navigation.cancellations, 1);
      navigation.gate!.complete(true);
      await pending;
    },
  );

  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets(
      'manual re-entry uses normal info and password checks at $width',
      (tester) async {
        final f = RoomLifecycleFixture();
        final api = ToolsApiFake()
          ..responses[HttpApi.roomInfo] = {'roomLock': true};
        final h = await _mount(tester, f, api, width: width);
        expect(find.text('Room connection lost'), findsOneWidget);
        expect(
          find.textContaining('authentication did not finish'),
          findsOneWidget,
        );
        expect(api.count(HttpApi.roomInfo), 0);
        await tester.tap(find.byKey(const ValueKey('room-recovery-reenter')));
        await tester.pumpAndSettle();
        expect(find.text('Room password'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('room-recovery-notice')),
          findsNothing,
        );
        expect(f.actions.where((a) => a.startsWith('enter:')).length, 1);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('room-recovery-notice')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('room-recovery-reenter')));
        await tester.pumpAndSettle();
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.enterText(find.byType(TextField), '1234');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Enter'));
        await tester.pumpAndSettle();
        expect(h.router.state.uri.path, '/room/first');
        expect(h.router.state.uri.queryParameters['roomPassword'], '1234');
        expect(
          find.byKey(const ValueKey('room-recovery-notice')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'closed-room failure preserves notice; dismiss cancels a late request',
    (tester) async {
      final f = RoomLifecycleFixture();
      final api = ToolsApiFake()..failingPath = HttpApi.roomInfo;
      final h = await _mount(tester, f, api);
      await tester.tap(find.byKey(const ValueKey('room-recovery-reenter')));
      await tester.pumpAndSettle();
      expect(find.text('Unable to open room'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('room-recovery-notice')),
        findsOneWidget,
      );
      api.failingPath = null;
      api.heldPath = HttpApi.roomInfo;
      api.gate = Completer<Object?>();
      await tester.tap(find.byKey(const ValueKey('room-recovery-reenter')));
      await tester.pump();
      await tester.tap(find.text('Later'));
      api.gate!.complete({'roomLock': false});
      await tester.pumpAndSettle();
      expect(h.router.state.uri.path, '/party');
      expect(find.byKey(const ValueKey('room-recovery-notice')), findsNothing);
    },
  );

  testWidgets('server rejection keeps msg and never attempts room enter', (
    tester,
  ) async {
    final f = RoomLifecycleFixture();
    final api = ToolsApiFake()
      ..heldPath = HttpApi.roomInfo
      ..gate = Completer<Object?>();
    await _mount(tester, f, api);
    await tester.tap(find.byKey(const ValueKey('room-recovery-reenter')));
    await tester.pump();
    api.gate!.completeError(
      const NadyApiException(
        code: 1003,
        message: 'Room unavailable from server',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Room unavailable from server'), findsOneWidget);
    expect(find.byKey(const ValueKey('room-recovery-notice')), findsOneWidget);
    expect(f.actions.where((a) => a.startsWith('enter:')).length, 1);
    expect(api.count(HttpApi.roomInfo), 1);
  });

  testWidgets(
    'account change removes password prompt and blocks late navigation',
    (tester) async {
      final f = RoomLifecycleFixture();
      final api = ToolsApiFake()
        ..responses[HttpApi.roomInfo] = {'roomLock': true};
      final h = await _mount(tester, f, api);
      await tester.tap(find.byKey(const ValueKey('room-recovery-reenter')));
      await tester.pumpAndSettle();
      expect(find.text('Room password'), findsOneWidget);
      await f.auth.clear();
      await tester.pumpAndSettle();
      expect(find.text('Room password'), findsNothing);
      expect(find.byKey(const ValueKey('room-recovery-notice')), findsNothing);
      expect(h.router.state.uri.path, '/party');
      expect(tester.takeException(), isNull);
    },
  );
}

class _Navigation implements RoomRecoveryNavigator {
  int calls = 0, cancellations = 0;
  bool result = false;
  Object? error;
  Completer<bool>? gate;
  bool Function()? valid;
  VoidCallback? onPrompt;
  @override
  Future<bool> enterRoom(
    String id,
    bool Function() isCurrent,
    VoidCallback prompt,
  ) async {
    expect(id, 'first');
    calls++;
    valid = isCurrent;
    onPrompt = prompt;
    if (error != null) throw error!;
    return gate?.future ?? result;
  }

  @override
  void cancelPending() => cancellations++;
}

Future<({GoRouter router, ProviderContainer container})> _mount(
  WidgetTester tester,
  RoomLifecycleFixture f,
  ToolsApiFake api, {
  double width = 375,
}) async {
  tester.view.physicalSize = Size(width, 812);
  tester.view.devicePixelRatio = 1;
  await tester.runAsync(() async {
    await f.enter();
    terminal(f);
    await f.flush();
  });
  final container = ProviderContainer(
    overrides: [
      roomRepositoryProvider.overrideWithValue(repositoryFor(f)),
      roomToolsRepositoryProvider.overrideWithValue(api),
    ],
  );
  final router = GoRouter(
    initialLocation: '/party',
    routes: [
      GoRoute(
        path: '/party',
        builder: (_, __) => const Scaffold(body: Text('Party')),
      ),
      GoRoute(
        path: '/room/:id',
        builder: (_, __) => const Scaffold(body: Text('Normal entry route')),
      ),
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    router.dispose();
    await f.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.view.resetViewInsets();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light,
          localizationsDelegates: const [AppLocalizations.delegate],
          builder: (_, child) =>
              RoomRecoveryHost(router: router, child: child!),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (router: router, container: container);
}
