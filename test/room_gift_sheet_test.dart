import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/classes/room/gift/room_gift_repository.dart';
import 'package:project/classes/room/gift/views/room_gift_sheet.dart';
import 'package:project/localization/app_localizations.dart';

void main() {
  testWidgets('gift button opens a usable Nady-style gift panel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roomGiftRepositoryProvider.overrideWithValue(_SheetGiftRepository()),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('zh')],
            home: const _GiftSheetHarness(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open gift panel'));
    await tester.pumpAndSettle();

    expect(find.text('All Mic'), findsOneWidget);
    expect(find.text('Popular'), findsOneWidget);
    expect(find.text('Rose'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _GiftSheetHarness extends StatelessWidget {
  const _GiftSheetHarness();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => showRoomGiftSheet(
            context: context,
            roomId: 'room-1',
            onlineCount: 2,
            currentUid: 10,
            recipients: const [
              RoomGiftRecipient(uid: 10, nickname: 'Self', seatPosition: 0),
              RoomGiftRecipient(uid: 20, nickname: 'Friend', seatPosition: 1),
            ],
          ),
          child: const Text('Open gift panel'),
        ),
      ),
    );
  }
}

class _SheetGiftRepository implements RoomGiftRepository {
  @override
  Future<RoomGiftCatalog> fetchCatalog() async {
    return const RoomGiftCatalog(
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
      ],
    );
  }

  @override
  Future<int> fetchBalance() async => 1000;

  @override
  Future<RoomGiftSendResult> sendGift(SendRoomGiftRequest request) async {
    return const RoomGiftSendResult();
  }
}
