import 'dart:io';

import 'package:extended_tabs/extended_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/classes/room/gift/room_gift_repository.dart';
import 'package:project/classes/room/gift/views/room_gift_sheet.dart';
import 'package:project/classes/room/gift/viewmodel/room_gift_view_model.dart';
import 'package:project/classes/room/gift/viewmodel/room_gift_send_controller.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/model/room_models.dart';
import 'package:project/model/server_response.dart';
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

  testWidgets('gift panel swipes between synchronized extended tabs', (
    tester,
  ) async {
    await _openPanel(tester);

    expect(find.text('All On Mic'), findsOneWidget);
    expect(find.text('Popular'), findsOneWidget);
    expect(find.text('Rose'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);

    await tester.drag(
      find.byType(ExtendedTabBarView).last,
      const Offset(-320, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Crown'), findsOneWidget);
    final luxuryTab = tester.widget<Text>(find.text('Luxury'));
    expect(luxuryTab.style, AppTextStyles.roomGiftTabSelected);
    expect(tester.takeException(), isNull);
  });

  testWidgets('gift pages link to categories and the fixed backpack', (
    tester,
  ) async {
    final catalog = RoomGiftCatalog(
      balance: 1000,
      canSendSelf: true,
      tabs: [
        RoomGiftTab(
          id: 8,
          name: 'Popular',
          gifts: List.generate(
            9,
            (index) => RoomGift(
              id: index + 1,
              name: 'Gift ${index + 1}',
              icon: '',
              price: 1,
              isCombo: 1,
              tabId: 8,
            ),
          ),
        ),
        _catalog.tabs[1],
        const RoomGiftTab(
          id: RoomGiftTab.backpackId,
          name: 'Backpack',
          gifts: [],
        ),
      ],
    );
    await _openPanel(
      tester,
      repository: _SheetGiftRepository(catalog: catalog),
    );
    await tester.drag(
      find.byType(ExtendedTabBarView).last,
      const Offset(-320, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Gift 9').hitTestable(), findsOneWidget);
    expect(
      tester
          .widget<ColoredBox>(find.byKey(const ValueKey('room-gift-page-1')))
          .color,
      AppColors.roomGiftPageSelected,
    );
    await tester.tap(find.text('Gift 9'));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(RoomGiftSheet)),
    );
    expect(
      container.read(roomGiftViewModelProvider('room-1')).selectedGift?.id,
      9,
    );

    await tester.drag(
      find.byType(ExtendedTabBarView).last,
      const Offset(-320, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Crown').hitTestable(), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('room-gift-backpack')));
    await tester.pumpAndSettle();
    expect(find.text('There is nothing here'), findsOneWidget);
    await tester.tap(find.text('Popular'));
    await tester.pumpAndSettle();
    expect(find.text('Gift 1').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('quick quantity and recipient selection use the send workflow', (
    tester,
  ) async {
    final repository = _SheetGiftRepository();
    RoomGiftSheetResult? result;
    await _openPanel(
      tester,
      repository: repository,
      onResult: (value) => result = value,
    );
    await tester.tap(find.byKey(const ValueKey('room-gift-recipient-10')));
    await tester.tap(find.byKey(const ValueKey('room-gift-count-18')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(repository.lastRequest?.giftCount, 18);
    expect(repository.lastRequest?.targetUids, [20]);
    expect(repository.lastRequest?.giftId, 31);
    expect(result, RoomGiftSheetResult.sent);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recharge artwork uses the existing wallet navigation result', (
    tester,
  ) async {
    RoomGiftSheetResult? result;
    await _openPanel(tester, onResult: (value) => result = value);
    await tester.tap(find.bySemanticsLabel('Recharge'));
    await tester.pumpAndSettle();
    expect(result, RoomGiftSheetResult.openWallet);
  });

  testWidgets('Send uses onlineNum from the live room for all-room gifting', (
    tester,
  ) async {
    final repository = _SheetGiftRepository();
    final roomInfo = RoomInfo.fromJson({
      'roomInfoDTO': {'roomId': 'room-1', 'onlineNum': 5},
    });
    RoomGiftSheetResult? result;
    await _openPanel(
      tester,
      repository: repository,
      onlineCount: 5,
      recipients: const [],
      audience: RoomGiftAudience(
        isInRoom: true,
        onlineCount: roomInfo.audienceCount ?? 0,
        recipients: const [],
      ),
      onResult: (value) => result = value,
    );

    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(repository.lastRequest?.sendType, RoomGiftSendType.onRoom);
    expect(repository.lastRequest?.targetUids, isNull);
    expect(repository.lastRequest?.giftId, 31);
    expect(result, RoomGiftSheetResult.sent);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid live recipients show an error inside the gift panel', (
    tester,
  ) async {
    final repository = _SheetGiftRepository();
    await _openPanel(
      tester,
      repository: repository,
      audience: const RoomGiftAudience(
        isInRoom: true,
        onlineCount: 2,
        recipients: [],
      ),
    );

    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(repository.lastRequest, isNull);
    expect(find.byType(RoomGiftSheet), findsOneWidget);
    expect(
      find.text('Please choose a recipient').hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Send errors are visible and leave the panel available to retry',
    (tester) async {
      final repository = _SheetGiftRepository(
        sendError: const NadyApiException(
          message: 'Gift unavailable',
          code: 1002,
        ),
      );
      RoomGiftSheetResult? result;
      await _openPanel(
        tester,
        repository: repository,
        onResult: (value) => result = value,
      );

      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(repository.lastRequest, isNotNull);
      expect(result, isNull);
      expect(find.text('Gift unavailable').hitTestable(), findsOneWidget);
      expect(find.text('Send').hitTestable(), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(RoomGiftSheet)),
      );
      expect(container.read(roomGiftViewModelProvider('room-1')).balance, 1000);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('quantity menu retains custom counts in the compact footer', (
    tester,
  ) async {
    await _openPanel(tester);
    await tester.tap(find.byType(PopupMenuButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '27');
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('room-gift-count-27')), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(RoomGiftSheet)),
    );
    expect(container.read(roomGiftViewModelProvider('room-1')).giftCount, 27);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 568),
    const Size(375, 812),
    const Size(430, 932),
  ]) {
    testWidgets(
      'gift panel fits ${size.width.toInt()}px with safe area and long text',
      (tester) async {
        final catalog = RoomGiftCatalog(
          balance: 999999999999999999,
          canSendSelf: true,
          tabs: [
            RoomGiftTab(
              id: 8,
              name: 'Customized gifts with a long category name',
              gifts: List.generate(
                8,
                (index) => RoomGift(
                  id: index + 1,
                  name: 'Gift name that is much longer than the tile',
                  icon: '',
                  cornerMark: index == 0 ? 'NEW' : '',
                  price: 19999,
                  isCombo: 1,
                  tabId: 8,
                ),
              ),
            ),
            const RoomGiftTab(
              id: RoomGiftTab.backpackId,
              name: 'Backpack',
              gifts: [],
            ),
          ],
        );
        await _openPanel(
          tester,
          size: size,
          bottomPadding: 34,
          repository: _SheetGiftRepository(catalog: catalog),
        );
        expect(tester.takeException(), isNull);
        final sendRect = tester.getRect(find.text('Send'));
        expect(sendRect.right, lessThan(size.width));
        expect(sendRect.bottom, lessThan(size.height - 34));
        expect(
          find.byKey(const ValueKey('room-gift-backpack')).hitTestable(),
          findsOneWidget,
        );
        if (size.width != 430) {
          await expectLater(
            find.byKey(const ValueKey('gift-test-screen')),
            matchesGoldenFile(
              'goldens/room_gift_panel_${size.width.toInt()}.png',
            ),
          );
        }
      },
    );
  }
}

Future<void> _openPanel(
  WidgetTester tester, {
  Size size = const Size(375, 812),
  double bottomPadding = 0,
  _SheetGiftRepository? repository,
  ValueChanged<RoomGiftSheetResult?>? onResult,
  RoomGiftAudience? audience,
  int onlineCount = 2,
  List<RoomGiftRecipient>? recipients,
}) async {
  final giftRepository = repository ?? _SheetGiftRepository();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(bottom: bottomPadding);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        roomGiftRepositoryProvider.overrideWithValue(giftRepository),
        if (audience != null)
          roomGiftSendControllerProvider('room-1').overrideWith(
            (ref) =>
                RoomGiftSendController(giftRepository, 'room-1')
                  ..audience = audience,
          ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) => MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('zh')],
          builder: (_, child) => RepaintBoundary(
            key: const ValueKey('gift-test-screen'),
            child: child!,
          ),
          home: _GiftSheetHarness(
            onResult: onResult,
            onlineCount: onlineCount,
            recipients: recipients,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('Open gift panel'));
  await tester.pumpAndSettle();
}

class _GiftSheetHarness extends StatelessWidget {
  const _GiftSheetHarness({
    this.onResult,
    this.onlineCount = 2,
    this.recipients,
  });

  final ValueChanged<RoomGiftSheetResult?>? onResult;
  final int onlineCount;
  final List<RoomGiftRecipient>? recipients;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.roomMoreSheet,
      body: Center(
        child: TextButton(
          onPressed: () async {
            final result = await showRoomGiftSheet(
              context: context,
              roomId: 'room-1',
              onlineCount: onlineCount,
              currentUid: 10,
              recipients:
                  recipients ??
                  const [
                    RoomGiftRecipient(
                      uid: 10,
                      nickname: 'Self',
                      seatPosition: 0,
                    ),
                    RoomGiftRecipient(
                      uid: 20,
                      nickname: 'Friend',
                      seatPosition: 1,
                    ),
                  ],
            );
            onResult?.call(result);
          },
          child: const Text('Open gift panel'),
        ),
      ),
    );
  }
}

class _SheetGiftRepository extends RoomGiftRepository {
  _SheetGiftRepository({this.catalog = _catalog, this.sendError});

  final RoomGiftCatalog catalog;
  final Object? sendError;
  SendRoomGiftRequest? lastRequest;

  @override
  RoomGiftCatalog? get cachedCatalog => null;

  @override
  Future<RoomGiftCatalog> fetchCatalog() async {
    return catalog;
  }

  @override
  Future<int> fetchBalance() async => catalog.balance;

  @override
  Future<RoomGiftSendResult> sendGift(SendRoomGiftRequest request) async {
    lastRequest = request;
    if (sendError != null) throw sendError!;
    return const RoomGiftSendResult();
  }
}

const _catalog = RoomGiftCatalog(
  balance: 1000,
  canSendSelf: true,
  tabs: [
    RoomGiftTab(
      id: 8,
      name: 'Popular',
      gifts: [
        RoomGift(
          id: 31,
          name: 'Rose',
          icon: '',
          price: 20,
          isCombo: 1,
          tabId: 8,
        ),
      ],
    ),
    RoomGiftTab(
      id: 9,
      name: 'Luxury',
      gifts: [
        RoomGift(
          id: 32,
          name: 'Crown',
          icon: '',
          price: 200,
          isCombo: 1,
          tabId: 9,
        ),
      ],
    ),
  ],
);
