import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:project/classes/room/viewmodel/room_session_view_model.dart';
import 'package:project/classes/room/views/room_exit_dialog.dart';
import 'package:project/classes/room/views/room_mini_overlay.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/manager/app_socket_manager.dart';
import 'package:project/manager/room_agora_manager.dart';
import 'package:project/manager/room_manager.dart';
import 'package:project/model/room_models.dart';
import 'package:project/model/room_socket_message.dart';
import 'package:project/model/user_profile.dart';
import 'package:project/theme/app_theme.dart';

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

  testWidgets('follow owner waits for success, ignores repeat taps and hides', (
    tester,
  ) async {
    final repository = _RoomRepository()..followGate = Completer<void>();
    final harness = await _openRoom(tester, repository, miniOverlay: true);
    final followButton = find.byKey(const ValueKey('room-follow-owner'));
    expect(followButton, findsOneWidget);
    await tester.tap(followButton);
    await tester.pump();
    expect(followButton, findsOneWidget);
    expect(tester.widget<InkWell>(followButton).onTap, isNull);
    await tester.tap(followButton);
    expect(repository.followCalls, 1);
    repository.followGate!.complete();
    await tester.pumpAndSettle();
    expect(followButton, findsNothing);
    expect(
      harness.container.read(roomViewModelProvider('alias')).isRoomFollowed,
      isTrue,
    );

    await tester.tap(_exitButton);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('room-exit-keep')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('room-mini-restore')));
    await tester.pumpAndSettle();
    expect(find.byType(RoomPage), findsOneWidget);
    expect(followButton, findsNothing);
    expect(repository.followCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed follow retains button and permits a retry', (
    tester,
  ) async {
    final repository = _RoomRepository()
      ..followError = StateError('Follow failed');
    await _openRoom(tester, repository);
    final followButton = find.byKey(const ValueKey('room-follow-owner'));
    await tester.tap(followButton);
    await tester.pumpAndSettle();
    expect(followButton, findsOneWidget);
    expect(find.text('Bad state: Follow failed'), findsOneWidget);
    expect(tester.widget<InkWell>(followButton).onTap, isNotNull);
    repository.followError = null;
    await tester.tap(followButton);
    await tester.pumpAndSettle();
    expect(followButton, findsNothing);
    expect(repository.followCalls, 2);
    expect(tester.takeException(), isNull);
  });

  for (final ownRoom in [false, true]) {
    testWidgets('follow icon is absent for followed/own room: own=$ownRoom', (
      tester,
    ) async {
      final repository = _RoomRepository()
        ..initiallyFollowed = !ownRoom
        ..ownerUid = ownRoom ? 10 : 20;
      await _openRoom(tester, repository);
      expect(find.byKey(const ValueKey('room-follow-owner')), findsNothing);
      expect(repository.followCalls, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('long room title does not push follow icon off a narrow screen', (
    tester,
  ) async {
    final repository = _RoomRepository();
    await _openRoom(tester, repository, width: 320);
    repository.room = repository.room.copyWith(
      roomInfo: const RoomInfo(
        roomId: 'canonical',
        title: 'A very long room title that should not push follow off screen',
        raw: {},
      ),
    );
    repository.notifyListeners();
    await tester.pumpAndSettle();
    final followButton = find.byKey(const ValueKey('room-follow-owner'));
    final rect = tester.getRect(followButton);
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(320));
    await tester.tap(followButton);
    await tester.pumpAndSettle();
    expect(repository.followCalls, 1);
    expect(followButton, findsNothing);
    expect(tester.takeException(), isNull);
  });

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

      await _chooseExit(tester);
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
      await _chooseExit(tester);
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
    await _chooseExit(tester);
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
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(RoomExitDialog), findsOneWidget);
    expect(repository.leaveCalls, 0);
    expect(repository.minimizeCalls, 0);
    await tester.tap(find.byKey(const ValueKey('room-exit-keep')));
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

  testWidgets('dismissing Keep/Exit leaves the room and controller untouched', (
    tester,
  ) async {
    final repository = _RoomRepository();
    final harness = await _openRoom(tester, repository);
    final model = harness.container.read(
      roomViewModelProvider('alias').notifier,
    );
    await tester.tap(_exitButton);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(15, 35));
    await tester.pumpAndSettle();
    expect(find.byType(RoomExitDialog), findsNothing);
    expect(find.byType(RoomPage), findsOneWidget);
    expect(repository.roomState.isInRoom, isTrue);
    expect(repository.leaveCalls, 0);
    expect(repository.minimizeCalls, 0);
    expect(model.mounted, isTrue);
    await _chooseExit(tester);
    await tester.pumpAndSettle();
  });

  testWidgets('background pauses visual effects without exiting a kept room', (
    tester,
  ) async {
    final repository = _RoomRepository();
    await _openRoom(tester, repository, miniOverlay: true);
    await tester.tap(_exitButton);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('room-exit-keep')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(repository.roomState.isInRoom, isTrue);
    expect(repository.roomState.isMinimized, isTrue);
    expect(repository.messages.hasListener, isTrue);
    expect(repository.leaveCalls, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.byKey(const ValueKey('room-mini-entry')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('room-mini-exit')));
    await tester.pumpAndSettle();
    expect(repository.leaveCalls, 1);
  });

  for (final failed in [false, true]) {
    testWidgets(
      'pending chat/refresh ignore disposed controller with failed=$failed',
      (tester) async {
        final repository = _RoomRepository()
          ..sendGate = Completer<void>()
          ..refreshGate = Completer<void>();
        final harness = await _openRoom(tester, repository);
        final model = harness.container.read(
          roomViewModelProvider('alias').notifier,
        );
        final sending = model.sendMessage('Pending message');
        final refreshing = model.refresh();
        await tester.tap(_exitButton);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('room-exit-keep')));
        await tester.pumpAndSettle();
        expect(model.mounted, isFalse);
        if (failed) {
          repository.sendGate!.completeError(StateError('Late chat failure'));
          repository.refreshGate!.completeError(
            StateError('Late refresh failure'),
          );
        } else {
          repository.sendGate!.complete();
          repository.refreshGate!.complete();
        }
        await sending;
        await refreshing;
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(repository.roomState.isMinimized, isTrue);
        await repository.leaveRoom();
        await tester.pumpAndSettle();
      },
    );
  }

  testWidgets('pending exit can finish after another route removes the page', (
    tester,
  ) async {
    final repository = _RoomRepository()..leaveGate = Completer<void>();
    final harness = await _openRoom(tester, repository);
    final model = harness.container.read(
      roomViewModelProvider('alias').notifier,
    );
    await _chooseExit(tester);
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

  testWidgets('failed exit still tears down the page after local cleanup', (
    tester,
  ) async {
    final repository = _RoomRepository()
      ..leaveError = StateError('Exit failed');
    final harness = await _openRoom(tester, repository);
    final model = harness.container.read(
      roomViewModelProvider('alias').notifier,
    );
    await _chooseExit(tester);
    await tester.pumpAndSettle();
    expect(find.byType(RoomPage), findsNothing);
    expect(model.mounted, isFalse);
    expect(repository.leaveCalls, 1);
    expect(repository.roomState.isInRoom, isFalse);
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

  testWidgets('terminal exit dismisses the Keep dialog and room controller', (
    tester,
  ) async {
    final repository = _RoomRepository();
    final harness = await _openRoom(tester, repository);
    final model = harness.container.read(
      roomViewModelProvider('alias').notifier,
    );
    await tester.tap(_exitButton);
    await tester.pumpAndSettle();
    expect(find.byType(RoomExitDialog), findsOneWidget);
    await repository.leaveRoom();
    await tester.pumpAndSettle();
    expect(find.byType(RoomExitDialog), findsNothing);
    expect(find.byType(RoomPage), findsNothing);
    expect(model.mounted, isFalse);
    expect(repository.minimizeCalls, 0);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets('Keep mini-room restores without re-entering at $width px', (
      tester,
    ) async {
      final repository = _RoomRepository();
      final harness = await _openRoom(
        tester,
        repository,
        miniOverlay: true,
        width: width,
      );
      final model = harness.container.read(
        roomViewModelProvider('alias').notifier,
      );
      await tester.tap(_exitButton);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('room-exit-keep')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump();
      expect(model.mounted, isFalse);
      expect(repository.leaveCalls, 0);
      expect(repository.enterCalls, 1);
      final mini = find.byKey(const ValueKey('room-mini-entry'));
      expect(mini, findsOneWidget);
      final initial = tester.getRect(mini);
      expect(initial.right, lessThan(width));
      expect(initial.bottom, lessThan(730));
      await tester.drag(mini, const Offset(-500, -150));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final moved = tester.getRect(mini);
      expect(moved.left, greaterThan(0));
      expect(moved.left, lessThan(25));
      expect(moved.top, lessThan(initial.top));
      await tester.tap(find.byKey(const ValueKey('room-mini-restore')));
      await tester.pumpAndSettle();
      expect(find.byType(RoomPage), findsOneWidget);
      expect(find.byKey(const ValueKey('room-mini-entry')), findsNothing);
      expect(repository.enterCalls, 1);
      expect(repository.restoreCalls, 1);
      expect(repository.roomState.isMinimized, isFalse);
      expect(repository.roomState.currentRoomId, 'canonical');
      await _chooseExit(tester);
      await tester.pumpAndSettle();
      expect(repository.leaveCalls, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('mini-room exit cleans up and hidden auth routes never show it', (
    tester,
  ) async {
    final repository = _RoomRepository();
    final harness = await _openRoom(tester, repository, miniOverlay: true);
    await tester.tap(_exitButton);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('room-exit-keep')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    unawaited(harness.router.push('/login'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('room-mini-entry')), findsNothing);
    expect(repository.roomState.isInRoom, isTrue);
    harness.router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('room-mini-entry')), findsOneWidget);
    harness.router.go('/login');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('room-mini-entry')), findsNothing);
    expect(repository.roomState.isInRoom, isTrue);
    harness.router.go('/party');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const ValueKey('room-mini-exit')));
    await tester.pumpAndSettle();
    expect(repository.leaveCalls, 1);
    expect(repository.roomState.isInRoom, isFalse);
    expect(find.byKey(const ValueKey('room-mini-entry')), findsNothing);
    expect(repository.messages.hasListener, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mini-room is rooted across primary pages and wallet', (
    tester,
  ) async {
    final repository = _RoomRepository();
    final harness = await _openRoom(tester, repository, miniOverlay: true);
    final model = harness.container.read(
      roomViewModelProvider('alias').notifier,
    );
    await tester.tap(_exitButton);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('room-exit-keep')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    for (final path in ['/home', '/message', '/profile', '/wallet', '/party']) {
      harness.router.go(path);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.byKey(const ValueKey('room-mini-entry')),
        findsOneWidget,
        reason: path,
      );
      expect(repository.roomState.isInRoom, isTrue);
      expect(repository.leaveCalls, 0);
      expect(repository.enterCalls, 1);
      expect(model.mounted, isFalse);
    }
    await tester.tap(find.byKey(const ValueKey('room-mini-exit')));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'Keep/Exit dialog and mini-room render their configured image assets',
    (tester) async {
      final repository = _RoomRepository();
      await _openRoom(tester, repository, miniOverlay: true);
      await tester.tap(_exitButton);
      await tester.pumpAndSettle();
      for (final (action, asset) in [
        (RoomExitAction.keep, AppAssets.roomExitKeep),
        (RoomExitAction.exit, AppAssets.roomExitClose),
      ]) {
        final image = tester.widget<Image>(
          find.descendant(
            of: find.byKey(ValueKey('room-exit-${action.name}')),
            matching: find.byType(Image),
          ),
        );
        expect((image.image as AssetImage).assetName, asset);
      }
      await expectLater(
        find.byKey(const ValueKey('room-lifecycle-snapshot')),
        matchesGoldenFile('goldens/room_exit_choices.png'),
      );
      await tester.tap(find.byKey(const ValueKey('room-exit-keep')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await expectLater(
        find.byKey(const ValueKey('room-lifecycle-snapshot')),
        matchesGoldenFile('goldens/room_mini_kept.png'),
      );
      await tester.tap(find.byKey(const ValueKey('room-mini-exit')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'terminal exit cancels restore lock so the next room remains usable',
    (tester) async {
      final repository = _RoomRepository();
      final harness = await _openRoom(tester, repository, miniOverlay: true);
      await tester.tap(_exitButton);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('room-exit-keep')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final session = harness.container.read(
        roomSessionViewModelProvider.notifier,
      );
      expect(session.restoreRoom(), 'canonical');
      expect(
        harness.container.read(roomSessionViewModelProvider).isBusy,
        isTrue,
      );
      // Simulate termination before the restore navigation Future completes.
      await repository.leaveRoom();
      await tester.pumpAndSettle();
      expect(
        harness.container.read(roomSessionViewModelProvider).isBusy,
        isFalse,
      );
      await tester.tap(find.text('Open room'));
      await tester.pumpAndSettle();
      await tester.tap(_exitButton);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('room-exit-keep')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byKey(const ValueKey('room-mini-exit')));
      await tester.pumpAndSettle();
      expect(repository.leaveCalls, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('auth invalidation exits a minimized room', (tester) async {
    final repository = _RoomRepository();
    await _openRoom(tester, repository, miniOverlay: true);
    await tester.tap(_exitButton);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('room-exit-keep')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    repository.loggedIn = false;
    for (final listener in repository.authListeners.toList()) {
      listener();
    }
    await tester.pumpAndSettle();
    expect(repository.leaveCalls, 1);
    expect(find.byKey(const ValueKey('room-mini-entry')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final kept in [false, true]) {
    testWidgets('switching rooms keeps the new page open with kept=$kept', (
      tester,
    ) async {
      final repository = _RoomRepository();
      final harness = await _openRoom(tester, repository);
      final oldModel = harness.container.read(
        roomViewModelProvider('alias').notifier,
      );
      if (kept) {
        await tester.tap(_exitButton);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('room-exit-keep')));
        await tester.pumpAndSettle();
      }
      unawaited(harness.router.push('/room/second'));
      await tester.pumpAndSettle();
      expect(repository.roomState.currentRoomId, 'second');
      expect(repository.leaveCalls, 1);
      expect(oldModel.mounted, isFalse);
      expect(find.byType(RoomPage), findsOneWidget);
      expect(tester.widget<RoomPage>(find.byType(RoomPage)).roomId, 'second');
      await _chooseExit(tester);
      await tester.pumpAndSettle();
      expect(find.byType(RoomPage), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _chooseExit(WidgetTester tester) async {
  await tester.tap(_exitButton);
  await tester.pumpAndSettle();
  expect(find.byType(RoomExitDialog), findsOneWidget);
  await tester.tap(find.byKey(const ValueKey('room-exit-exit')));
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
  bool miniOverlay = false,
  double width = 375,
}) async {
  tester.view.physicalSize = Size(width, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    initialLocation: pushed ? '/party' : '/room/alias',
    routes: [
      for (final path in ['/home', '/message', '/profile', '/wallet'])
        GoRoute(
          path: path,
          builder: (_, __) => Scaffold(body: Text(path)),
        ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const Scaffold(body: Text('Login')),
      ),
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
          builder: (_, child) => RepaintBoundary(
            key: const ValueKey('room-lifecycle-snapshot'),
            child: miniOverlay
                ? RoomMiniOverlay(router: router, child: child!)
                : child!,
          ),
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
  int enterCalls = 0;
  int restoreCalls = 0;
  int followCalls = 0;
  bool initiallyFollowed = false;
  int? ownerUid;
  bool loggedIn = true;
  final authListeners = <VoidCallback>[];
  Completer<void>? leaveGate;
  Completer<void>? sendGate;
  Completer<void>? refreshGate;
  Completer<void>? followGate;
  Object? followError;
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
  Future<bool> isLoggedIn() async => loggedIn;
  @override
  void addAuthListener(VoidCallback listener) => authListeners.add(listener);
  @override
  void removeAuthListener(VoidCallback listener) =>
      authListeners.remove(listener);
  @override
  Future<int?> sendTextMessage({
    required String roomId,
    required String text,
  }) async {
    await sendGate?.future;
    return null;
  }

  @override
  Future<void> refreshRoomData() async {
    await refreshGate?.future;
  }

  @override
  Future<void> followRoom() async {
    followCalls++;
    room = room.copyWith(isFollowingRoom: true, errorMessage: null);
    notifyListeners();
    await followGate?.future;
    if (followError != null) {
      room = room.copyWith(isFollowingRoom: false);
      notifyListeners();
      throw followError!;
    }
    room = room.copyWith(isFollowed: true, isFollowingRoom: false);
    notifyListeners();
  }

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
    enterCalls++;
    if (room.isInRoom && roomId == 'second') await leaveRoom();
    room = RoomState(status: RoomStatus.entering, currentRoomId: roomId);
    notifyListeners();
    room = RoomState(
      status: RoomStatus.ready,
      currentRoomId: roomId == 'second' ? 'second' : 'canonical',
      isInRoom: true,
      isFollowed: initiallyFollowed,
      roomInfo: ownerUid == null
          ? null
          : RoomInfo(
              roomId: roomId,
              roomOwnerUid: ownerUid,
              isFollow: initiallyFollowed,
              raw: const {},
            ),
    );
    notifyListeners();
  }

  @override
  Future<void> leaveRoom() async {
    leaveCalls++;
    room = room.copyWith(status: RoomStatus.leaving, isMinimized: false);
    notifyListeners();
    await leaveGate?.future;
    if (leaveError != null) {
      // Simulate a failed server exit after local cleanup has completed.
      room = const RoomState();
      notifyListeners();
      throw leaveError!;
    }
    room = const RoomState();
    notifyListeners();
  }

  @override
  void minimizeRoom() {
    if (room.status != RoomStatus.ready) return;
    minimizeCalls++;
    room = room.copyWith(isMinimized: true);
    notifyListeners();
  }

  @override
  void restoreRoom() {
    if (room.status != RoomStatus.ready) return;
    restoreCalls++;
    room = room.copyWith(isMinimized: false);
    notifyListeners();
  }

  @override
  Future<void> exitMinimizedRoom() => leaveRoom();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _GiftRepository implements RoomGiftRepository {
  @override
  RoomGiftCatalog? get cachedCatalog => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
