import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/classes/create_room/create_room_repository.dart';
import 'package:project/classes/room/interaction/room_edit_info_sheet.dart';
import 'package:project/classes/room/interaction/room_interaction_repository.dart';
import 'package:project/classes/room/interaction/room_interaction_view_model.dart';
import 'package:project/classes/room/interaction/room_management_sheet.dart';
import 'package:project/classes/room/interaction/room_management_view_model.dart';
import 'package:project/classes/room/room_repository.dart';
import 'package:project/classes/room/viewmodel/room_state.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/manager/room_manager.dart';
import 'package:project/model/room_models.dart';
import 'package:project/model/server_response.dart';
import 'package:project/theme/app_theme.dart';

import 'precache_room_assets.dart';
import 'room_tools_fakes.dart';

final editRoomNotifier = ChangeNotifierProvider<EditRoomFake>(
  (ref) => throw UnimplementedError(),
);
final editPage = Provider<RoomPageState>((ref) {
  final room = ref.watch(editRoomNotifier);
  return RoomPageState.initial('123').copyWith(
    status: RoomStatus.ready,
    isInRoom: true,
    currentUid: room.uid,
    roomTitle: room.title,
    roomDesc: room.description,
    roomAvatar: AppAssets.lanhuRoomAvatarSample,
    roomInfo: room.roomState.roomInfo,
    enterResponse: room.roomState.enterResponse,
  );
});

class EditApiFake extends RoomInteractionRepository {
  final posts = <Map<String, dynamic>>[];
  bool fail = false;
  Completer<void>? gate;
  @override
  Future<Object?> post(String path, Map<String, dynamic> body) async {
    expect(path, HttpApi.roomUpdateInfo);
    posts.add(body);
    await gate?.future;
    if (fail) throw const NadyApiException(message: 'Room save denied');
    return null;
  }
}

class EditUploadFake implements CreateRoomRepository {
  final paths = <String>[];
  bool fail = false;
  Completer<void>? gate;
  @override
  Future<String> uploadAvatar(String path) async {
    paths.add(path);
    await gate?.future;
    if (fail) throw const NadyApiException(message: 'Cover upload denied');
    return 'https://example.com/uploaded.png';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class EditRoomFake extends ToolsRoomFake {
  EditRoomFake() {
    current = current.copyWith(
      roomInfo: RoomInfo.fromJson({
        'roomId': '123',
        'roomUid': 10,
        'roomLock': false,
      }),
    );
  }
  String title = 'Happy!';
  String description = 'Welcome to my room';
  int refreshes = 0;
  bool disposed = false;
  @override
  Future<void> refreshRoomData() async => refreshes++;
  @override
  void dispose() {
    if (disposed) return;
    disposed = true;
    super.dispose();
  }
}

class EditHarness {
  final api = EditApiFake();
  final upload = EditUploadFake();
  final room = EditRoomFake();
  final RoomInteractionKey session = (
    roomId: '123',
    generation: 1,
    viewToken: Object(),
  );
  String? picked;
  int pickerCalls = 0;
  final name = find.byKey(const ValueKey('room-edit-name'));
  final description = find.byKey(const ValueKey('room-edit-description'));
  final confirm = find.byKey(const ValueKey('room-edit-confirm'));

  Future<void> pump(
    WidgetTester tester, {
    double width = 375,
    double height = 812,
    bool direct = false,
    double bottom = 0,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = FakeViewPadding(bottom: bottom);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/image_picker'),
      (call) async {
        expect(call.method, 'pickImage');
        pickerCalls++;
        return picked;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/image_picker'),
        null,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roomRepositoryProvider.overrideWithValue(room),
          roomInteractionRepositoryProvider.overrideWithValue(api),
          createRoomRepositoryProvider.overrideWithValue(upload),
          editRoomNotifier.overrideWith((ref) => room),
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
              resizeToAvoidBottomInset: false,
              backgroundColor: AppColors.roomMessageSurface,
              body: RepaintBoundary(
                key: const ValueKey('edit-golden'),
                child: direct
                    ? Align(
                        alignment: Alignment.bottomCenter,
                        child: RoomEditInfoSheet(
                          session: session,
                          roomState: editPage,
                        ),
                      )
                    : Builder(
                        builder: (context) => Center(
                          child: TextButton(
                            onPressed: () => showRoomManagementSheet(
                              context,
                              session,
                              editPage,
                              RoomManagementSection.edit,
                            ),
                            child: const Text('Open editor'),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (!direct) {
      await tester.tap(find.text('Open editor'));
    }
    await tester.pumpAndSettle();
    await precacheRoomAssets(
      tester,
      tester.element(find.byType(Scaffold).first),
    );
    addTearDown(() async => tester.pumpWidget(const SizedBox()));
  }

  Future<void> selectCover(WidgetTester tester) async {
    picked = File(AppAssets.lanhuRoomAvatarSample).absolute.path;
    await tester.runAsync(() async {
      await precacheImage(
        FileImage(File(picked!)),
        tester.element(find.byType(RoomEditInfoSheet)),
      );
    });
    await tester.tap(find.bySemanticsLabel('Change cover'));
    await tester.pumpAndSettle();
    expect(pickerCalls, 1);
  }

  String text(WidgetTester tester, Finder field) =>
      tester.widget<TextField>(field).controller!.text;

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    room.dispose();
  }
}
