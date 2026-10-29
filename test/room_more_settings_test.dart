import 'dart:async';

import 'package:extended_tabs/extended_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project/classes/room/more/room_settings_content.dart';
import 'package:project/classes/room/more/room_settings_page.dart';
import 'package:project/classes/room/more/room_tools_controller.dart';
import 'package:project/classes/room/more/room_tools_models.dart';
import 'package:project/classes/room/more/room_tools_repository.dart';
import 'package:project/classes/room/room_repository.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/model/room_models.dart';
import 'package:project/model/server_response.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/theme/app_theme.dart';

import 'support/room_tools_fakes.dart';
import 'support/room_more_settings_fixture.dart';

void main() {
  final sheet = find.byKey(const ValueKey('room-more-tools-sheet'));
  final tabs = find.byKey(const ValueKey('room-more-tabs'));
  final pages = find.byKey(const ValueKey('room-more-tab-view'));
  Finder effect(String key) => find.byKey(ValueKey('room-effect-$key'));
  bool value(WidgetTester tester, String key) =>
      tester.widget<Switch>(effect(key)).value;

  Future<void> selectSetting(WidgetTester tester) async {
    await tester.tap(find.text('Setting'));
    await tester.pumpAndSettle();
    expect(tester.widget<ExtendedTabBar>(tabs).controller!.index, 1);
  }

  Future<void> toggle(WidgetTester tester, String key) async {
    await tester.ensureVisible(effect(key));
    await tester.tap(effect(key));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'tabs swipe, retain independent scroll, and do not reload tools',
    (tester) async {
      final f = await mountRoomMoreSettings(tester, height: 500, games: 20);
      await f.open(tester);
      expect(tester.widget<ExtendedTabBar>(tabs).controller!.index, 0);
      expect(
        tester.widget<ExtendedTabBarView>(pages).controller,
        same(tester.widget<ExtendedTabBar>(tabs).controller),
      );
      expect(tester.getSize(sheet).width, 375);
      final calls = f.api.calls.length;
      final basic = tester
          .widget<SingleChildScrollView>(
            find.byKey(const PageStorageKey('room-more-basic-scroll')),
          )
          .controller!;
      basic.jumpTo(120);
      await tester.pump();
      await selectSetting(tester);
      final settings = tester
          .widget<SingleChildScrollView>(
            find.byKey(const PageStorageKey('room-more-settings-scroll')),
          )
          .controller!;
      expect(settings.position.maxScrollExtent, greaterThan(0));
      settings.jumpTo(settings.position.maxScrollExtent);
      await tester.pump();
      final settingsOffset = settings.offset;
      await tester.drag(pages, const Offset(300, 0));
      await tester.pumpAndSettle();
      expect(tester.widget<ExtendedTabBar>(tabs).controller!.index, 0);
      expect(basic.offset, closeTo(120, .01));
      await tester.drag(pages, const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(tester.widget<ExtendedTabBar>(tabs).controller!.index, 1);
      expect(settings.offset, settingsOffset);
      expect(f.api.calls.length, calls);
      expect(f.api.loads, 1);
      expect(f.banners.loads, 2);
      expect(f.room.leaves, 0);
      expect(f.room.speaker, isFalse);
      f.close(tester);
      await tester.pumpAndSettle();
      await f.open(tester);
      expect(tester.widget<ExtendedTabBar>(tabs).controller!.index, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('effect shortcut stays in Setting without charm controls', (
    tester,
  ) async {
    final f = await mountRoomMoreSettings(tester);
    await f.open(tester);
    await tester.ensureVisible(find.text('Effect Settings'));
    await tester.tap(find.text('Effect Settings'));
    await tester.pumpAndSettle();
    expect(sheet, findsOneWidget);
    expect(tester.widget<ExtendedTabBar>(tabs).controller!.index, 1);
    expect(find.byType(RoomSettingsPage), findsNothing);
    expect(f.router.state.uri.path, '/room/123');
    final headingY = tester.getRect(find.text('Effects Setting')).top;
    expect(headingY, greaterThanOrEqualTo(tester.getRect(tabs).bottom));
    expect(headingY, lessThan(tester.getRect(sheet).bottom));
    expect(find.byType(Radio<int>), findsNothing);
    expect(find.text('Charm Setting'), findsNothing);
    expect(f.room.leaves, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'six effect controls aggregate, persist, and are shared by the old page',
    (tester) async {
      final f = await mountRoomMoreSettings(tester);
      await f.open(tester);
      await selectSetting(tester);
      expect(find.byType(Switch), findsNWidgets(6));
      await toggle(tester, 'gift_big_effect');
      expect(value(tester, 'gift_big_effect'), isFalse);
      expect(value(tester, 'all_effect'), isFalse);
      expect(value(tester, 'gift_effect'), isTrue);
      expect(find.text('Partially enabled'), findsOneWidget);
      expect(f.api.stored.bigGift, isFalse);
      await toggle(tester, 'all_effect');
      expect(f.api.stored.toJson().values, everyElement(true));
      await toggle(tester, 'all_effect');
      expect(f.api.stored.toJson().values, everyElement(false));
      f.close(tester);
      await tester.pumpAndSettle();
      f.router.push(
        '/room-tool',
        extra: const RoomSettingsPage(
          roomId: '123',
          section: RoomSettingSection.effects,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RoomEffectSettingsContent), findsOneWidget);
      expect(value(tester, 'all_effect'), isFalse);
      await toggle(tester, 'sound_effect');
      expect(f.api.stored.sound, isTrue);
      expect(f.room.speaker, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'loading and saving disable switches, including duplicate clicks',
    (tester) async {
      final api = RoomSettingsApiFake()
        ..loadGate = Completer<RoomEffectPreferences>();
      final f = await mountRoomMoreSettings(tester, api: api, settle: false);
      await f.open(tester, settle: false);
      await tester.tap(find.text('Setting'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(tester.widget<Switch>(effect('all_effect')).onChanged, isNull);
      api.loadGate!.complete(const RoomEffectPreferences());
      await tester.pumpAndSettle();
      api.saveGate = Completer<void>();
      await tester.tap(effect('all_effect'));
      await tester.pump();
      expect(value(tester, 'all_effect'), isTrue);
      expect(
        tester
            .widgetList<Switch>(find.byType(Switch))
            .every((s) => s.onChanged == null),
        isTrue,
      );
      expect(await f.controller.setEffect('car_effect', false), isFalse);
      expect(api.saves, 1);
      api.saveGate!.complete();
      await tester.pumpAndSettle();
      expect(value(tester, 'all_effect'), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed preference load can retry without rebuilding the room', (
    tester,
  ) async {
    final api = RoomSettingsApiFake()
      ..loadError = const NadyApiException(message: 'Preferences unavailable');
    final f = await mountRoomMoreSettings(tester, api: api);
    await f.open(tester);
    await selectSetting(tester);
    expect(find.text('Preferences unavailable'), findsWidgets);
    expect(tester.widget<Switch>(effect('all_effect')).onChanged, isNull);
    api.loadError = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(effect('all_effect')).onChanged, isNotNull);
    expect(api.loads, 2);
    expect(f.room.leaves, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('save errors preserve values and show msg; retry succeeds', (
    tester,
  ) async {
    final api = RoomSettingsApiFake()
      ..saveError = NadyServerResponse<Object?>.fromJson({
        'code': 1003,
        'message': 'Generic failure',
        'msg': 'Settings cannot be saved',
      }, (value) => value).toException();
    final f = await mountRoomMoreSettings(tester, api: api);
    await f.open(tester);
    await selectSetting(tester);
    await toggle(tester, 'all_effect');
    expect(value(tester, 'all_effect'), isTrue);
    expect(api.stored.all, isTrue);
    expect(find.text('Settings cannot be saved'), findsOneWidget);
    expect(find.text('Generic failure'), findsNothing);
    api.saveError = null;
    await toggle(tester, 'all_effect');
    expect(value(tester, 'all_effect'), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'currency uses existing API and is hidden after losing permission',
    (tester) async {
      final f = await mountRoomMoreSettings(tester);
      await f.openCharm(tester);
      f.api.failingPath = HttpApi.roomCharmSwitch;
      await tester.tap(find.byKey(const ValueKey('room-currency-2')));
      await tester.pumpAndSettle();
      expect(f.controller.snapshot.currency, 1);
      f.api.failingPath = null;
      await tester.tap(find.byKey(const ValueKey('room-currency-2')));
      await tester.pumpAndSettle();
      expect(
        f.api.calls.lastWhere((c) => c.path == HttpApi.roomCharmSwitch).body,
        {'roomId': '123', 'digitalCurrency': 2},
      );
      expect(f.controller.snapshot.currency, 2);
      f.room.setRole(UserRoomIdentity.audience);
      await tester.pumpAndSettle();
      expect(find.byType(Radio<int>), findsNothing);
      expect(find.byType(Switch), findsNothing);
      expect(await f.controller.setCurrency(1), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('closing during a failed save never uses a disposed view', (
    tester,
  ) async {
    final api = RoomSettingsApiFake()
      ..saveGate = Completer<void>()
      ..saveError = const NadyApiException(message: 'Late failure');
    final f = await mountRoomMoreSettings(tester, api: api);
    await f.open(tester);
    await selectSetting(tester);
    await tester.tap(effect('all_effect'));
    await tester.pump();
    f.close(tester);
    await tester.pumpAndSettle();
    api.saveGate!.complete();
    await tester.pumpAndSettle();
    expect(sheet, findsNothing);
    expect(f.room.leaves, 0);
    expect(f.controller.snapshot.effects.all, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'small screen, long descriptions, keyboard and safe area do not overflow',
    (tester) async {
      final f = await mountRoomMoreSettings(
        tester,
        width: 320,
        height: 568,
        inset: 200,
        bottom: 24,
      );
      await f.open(tester);
      await selectSetting(tester);
      expect(tester.getRect(sheet).bottom, lessThanOrEqualTo(368));
      await tester.ensureVisible(effect('screen_top_effect'));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(effect('screen_top_effect')).bottom,
        lessThanOrEqualTo(tester.getRect(sheet).bottom - 24),
      );
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'effect persistence is isolated by UID and restores existing keys',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = RoomToolsRepository();
      await repository.saveEffects(
        10,
        const RoomEffectPreferences(bigGift: false),
      );
      await repository.saveEffects(
        20,
        const RoomEffectPreferences(sound: false),
      );
      expect((await repository.effects(10)).bigGift, isFalse);
      expect((await repository.effects(10)).sound, isTrue);
      expect((await repository.effects(20)).bigGift, isTrue);
      expect((await repository.effects(20)).sound, isFalse);
      expect((await repository.effects(30)).all, isTrue);
    },
  );

  for (final exit in [false, true]) {
    test(
      'late effect save is ignored after ${exit ? 'exit' : 'account/session change'}',
      () async {
        final room = ToolsRoomFake();
        final api = RoomSettingsApiFake()..saveGate = Completer<void>();
        final vm = RoomToolsController(
          roomId: '123',
          repository: api,
          room: room,
        )..start();
        addTearDown(() {
          vm.dispose();
          room.dispose();
        });
        await flushTools();
        final pending = vm.setEffect('gift_effect', false);
        await flushTools();
        if (exit) {
          await room.leaveRoom();
        } else {
          room.generation++;
          room.changeAccount(20);
          room.emitState();
          await flushTools();
          expect(vm.uid, 20);
        }
        api.saveGate!.complete();
        expect(await pending, isFalse);
        expect(vm.snapshot.effects.gift, isTrue);
        expect(vm.snapshot.sessionActive, !exit);
      },
    );
  }

  testWidgets('shared settings wrap long text at large accessibility sizes', (
    tester,
  ) async {
    final room = ToolsRoomFake();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      room.dispose();
    });
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roomRepositoryProvider.overrideWithValue(room),
          roomToolsRepositoryProvider.overrideWithValue(RoomSettingsApiFake()),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: const [AppLocalizations.delegate],
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.5)),
              child: child!,
            ),
            home: const Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      RoomCharmCurrencyContent(roomId: '123'),
                      RoomEffectSettingsContent(roomId: '123'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await toggle(tester, 'screen_top_effect');
    expect(value(tester, 'screen_top_effect'), isFalse);
    expect(tester.takeException(), isNull);
  });
}
