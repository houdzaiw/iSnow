import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/classes/room/gift/room_gift_repository.dart';
import 'package:project/classes/room/room_page.dart';
import 'package:project/classes/room/room_repository.dart';
import 'package:project/classes/room/viewmodel/room_state.dart';
import 'package:project/classes/room/viewmodel/room_view_model.dart';
import 'package:project/configs/app_configs.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/manager/room_agora_manager.dart';
import 'package:project/manager/room_background_audio_manager.dart';
import 'package:project/manager/room_manager.dart';
import 'package:project/model/user_profile.dart';
import 'package:project/theme/app_assets.dart';

import 'support/room_lifecycle_fakes.dart';
import 'support/room_microphone_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Roboto')
      ..addFont(
        File(
          'test/fixtures/fonts/Roboto-Regular.ttf',
        ).readAsBytes().then(ByteData.sublistView),
      );
    await font.load();
  });

  test(
    'default entry initializes Agora; real manager listeners update the VM',
    () async {
      final fixture = _Fixture();
      final model = RoomViewModel(
        repository: fixture.repository,
        roomId: 'first',
      );
      late RoomPageState snapshot;
      model.addListener((state) => snapshot = state);
      addTearDown(() async {
        model.dispose();
        await fixture.dispose();
      });
      await model.enterRoom();
      await fixture.flush();
      await fixture.manager.upMic(0);
      expect(fixture.engine.appId, AppConfig.shared.appEnv.agoraAppId);
      expect(snapshot.isOnMic, isTrue);
      expect(snapshot.agoraState.publishing, isTrue);
      await model.toggleLocalMicrophone();
      expect(snapshot.agoraState.mutedMicrophone, isTrue);
      await model.toggleLocalMicrophone();
      expect(snapshot.agoraState.mutedMicrophone, isFalse);
      expect(fixture.engine.recordingMutes, [false, true, false]);
    },
  );

  test(
    'mute waits for initialization even though HTTP entry is ready',
    () async {
      final fixture = _Fixture();
      final gate = Completer<void>();
      fixture.engine.initializeGate = gate;
      final model = RoomViewModel(
        repository: fixture.repository,
        roomId: 'first',
      );
      late RoomPageState snapshot;
      model.addListener((state) => snapshot = state);
      addTearDown(() async {
        model.dispose();
        await fixture.dispose();
      });
      await model.enterRoom();
      await fixture.flush();
      expect(snapshot.isReady, isTrue);
      expect(snapshot.agoraState.joined, isFalse);
      final muting = model.toggleLocalMicrophone();
      await fixture.flush();
      expect(snapshot.togglingMicrophone, isTrue);
      expect(fixture.engine.recordingMutes, isEmpty);
      gate.complete();
      await muting;
      expect(snapshot.agoraState.mutedMicrophone, isTrue);
      expect(snapshot.togglingMicrophone, isFalse);
    },
  );

  test(
    'up mic waits for initialization before publishing its audio track',
    () async {
      final fixture = _Fixture();
      addTearDown(fixture.dispose);
      final gate = Completer<void>();
      fixture.engine.initializeGate = gate;
      await fixture.manager.enterRoom(roomId: 'first');
      final publishing = fixture.manager.upMic(0);
      await fixture.flush();
      expect(fixture.engine.mediaOptions, isEmpty);
      gate.complete();
      await publishing;
      expect(fixture.engine.mediaOptions.last.publishMicrophoneTrack, isTrue);
      expect(fixture.agora.state.publishing, isTrue);
    },
  );

  testWidgets('bottom mic icon toggles both ways and ignores in-flight taps', (
    tester,
  ) async {
    final fixture = _Fixture();
    await _openRoom(tester, fixture);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(RoomPage)),
    );
    final provider = roomViewModelProvider('first');
    expect(_micIcon(tester), AppAssets.lanhuRoomBottomMic);
    final gate = Completer<void>();
    fixture.engine.microphoneGate = gate;
    final recordingCalls = fixture.engine.recordingMutes.length;
    await tester.tap(_micButton);
    await tester.pump();
    expect(container.read(provider).togglingMicrophone, isTrue);
    expect(_micIcon(tester), AppAssets.lanhuRoomBottomMic);
    await tester.tap(_micButton);
    await tester.pump();
    expect(fixture.engine.recordingMutes.length, recordingCalls + 1);
    fixture.engine.microphoneGate = null;
    gate.complete();
    await tester.pumpAndSettle();
    expect(_micIcon(tester), AppAssets.lanhuRoomBottomMicMuted);
    expect(container.read(provider).togglingMicrophone, isFalse);
    await tester.tap(_micButton);
    await tester.pumpAndSettle();
    expect(_micIcon(tester), AppAssets.lanhuRoomBottomMic);
    expect(fixture.engine.recordingMutes.last, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SDK mute failure preserves the icon and allows retry', (
    tester,
  ) async {
    final fixture = _Fixture();
    await _openRoom(tester, fixture);
    fixture.engine.failMicrophone = true;
    await tester.tap(_micButton);
    await tester.pump();
    expect(_micIcon(tester), AppAssets.lanhuRoomBottomMic);
    expect(find.textContaining('recording mute failed'), findsOneWidget);
    fixture.engine.failMicrophone = false;
    await tester.tap(_micButton);
    await tester.pumpAndSettle();
    expect(_micIcon(tester), AppAssets.lanhuRoomBottomMicMuted);
    expect(tester.takeException(), isNull);
  });

  test('Keep/restoring a new VM retains mute; Exit resets it', () async {
    final fixture = _Fixture();
    final model = RoomViewModel(
      repository: fixture.repository,
      roomId: 'first',
    );
    await model.enterRoom();
    await fixture.flush();
    await model.toggleLocalMicrophone();
    fixture.manager.minimizeRoom();
    model.dispose();
    fixture.manager.restoreRoom();
    final restored = RoomViewModel(
      repository: fixture.repository,
      roomId: 'first',
    );
    late RoomPageState snapshot;
    restored.addListener((state) => snapshot = state);
    await fixture.flush();
    expect(snapshot.agoraState.mutedMicrophone, isTrue);
    await restored.toggleLocalMicrophone();
    expect(snapshot.agoraState.mutedMicrophone, isFalse);
    await restored.toggleLocalMicrophone();
    await fixture.manager.leaveRoom();
    expect(snapshot.agoraState.mutedMicrophone, isFalse);
    restored.dispose();
    await fixture.dispose();
  });
}

final _micButton = find.byKey(const ValueKey('room-microphone-toggle'));

String _micIcon(WidgetTester tester) {
  final image = tester.widget<Image>(
    find.descendant(of: _micButton, matching: find.byType(Image)),
  );
  return (image.image as AssetImage).assetName;
}

Future<void> _openRoom(WidgetTester tester, _Fixture fixture) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    final disposing = fixture.dispose();
    var disposed = false;
    unawaited(disposing.then((_) => disposed = true));
    // Teardown also drains futures created in the widget's fake async zone.
    for (var i = 0; i < 20 && !disposed; i++) {
      await tester.pump();
    }
    expect(disposed, isTrue, reason: 'room cleanup must settle');
    await disposing;
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        roomRepositoryProvider.overrideWithValue(fixture.repository),
        roomGiftRepositoryProvider.overrideWithValue(_GiftRepository()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => const MaterialApp(
          home: RoomPage(roomId: 'first'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en')],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final publishing = fixture.manager.upMic(0);
  await tester.pump();
  await publishing;
  await tester.pumpAndSettle();
}

class _Fixture {
  _Fixture() {
    http = _RoomHttp(actions, auth);
    agora = RoomAgoraManager.forTesting(
      engineFactory: () => engine,
      authSession: auth,
    );
    manager = RoomManager.forTesting(
      httpManager: http,
      socketManager: socket,
      agoraManager: agora,
      authSession: auth,
      backgroundAudioManager: RoomBackgroundAudioManager.forTesting(
        start: (_) async => true,
        stop: () async {},
        foreground: () => true,
      ),
    );
    repository = RoomRepository(
      roomManager: manager,
      socketManager: socket,
      agoraManager: agora,
      httpManager: http,
      authSession: auth,
    );
  }
  final actions = <String>[];
  final auth = _Auth();
  final socket = FakeRoomSocket([]);
  final engine = RoomMicrophoneEngine();
  late final _RoomHttp http;
  late final RoomAgoraManager agora;
  late final RoomManager manager;
  late final RoomRepository repository;

  Future<void> flush() => Future<void>.delayed(Duration.zero);
  Future<void> dispose() async {
    await manager.leaveRoom();
    manager.dispose();
    await agora.release();
    agora.dispose();
    await socket.controller.close();
    socket.dispose();
    auth.dispose();
  }
}

class _Auth extends FakeRoomAuth {
  @override
  Future<UserData?> user() async => null;
}

class _RoomHttp extends FakeRoomHttp {
  _RoomHttp(super.actions, super.auth);
  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (path == HttpApi.roomMicUp) {
      return {
        'code': 200,
        'data': {'position': 0, 'uid': 10},
      };
    }
    return super.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}

class _GiftRepository implements RoomGiftRepository {
  @override
  RoomGiftCatalog? get cachedCatalog => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
