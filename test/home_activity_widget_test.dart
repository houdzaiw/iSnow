import 'dart:async';
import 'dart:io';

import 'package:extended_tabs/extended_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/party/friends_activity/friends_activity_page.dart';
import 'package:project/classes/party/friends_activity/friends_activity_view_model.dart';
import 'package:project/classes/party/viewmodel/home_feed_controller.dart';
import 'package:project/classes/party/views/home_countries_sheet.dart';
import 'package:project/manager/room_manager.dart';

import 'support/home_activity_fakes.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('Roboto')..addFont(
          File(
            'test/fixtures/fonts/Roboto-Regular.ttf',
          ).readAsBytes().then(ByteData.sublistView),
        ))
        .load();
  });
  late HomeActivityHarness h;
  setUp(() => h = HomeActivityHarness());

  testWidgets(
    'empty friends retain All and real empty state, without fake avatars',
    (tester) async {
      h.activity.friends = [];
      await h.pump(tester);
      expect(find.text('No friends are playing right now'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('friends-activity-all')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('friends-activity-all')));
      await tester.pumpAndSettle();
      expect(find.byType(FriendsActivityPage), findsOneWidget);
      expect(h.activity.historyCalls, isEmpty);
      await tester.tap(find.text('Recent Footprints'));
      await tester.pumpAndSettle();
      expect(h.activity.historyCalls, [1]);
      expect(find.text('Previously visited room'), findsOneWidget);
    },
  );

  testWidgets('All reuses data and refreshes once, tabs load history lazily', (
    tester,
  ) async {
    await h.pump(tester);
    expect(h.activity.friendCalls, 1);
    await tester.tap(find.byKey(const ValueKey('friends-activity-all')));
    await tester.pumpAndSettle();
    expect(h.activity.friendCalls, 2);
    expect(h.activity.historyCalls, isEmpty);
    expect(find.text('Own room description'), findsOneWidget);
    await tester.drag(
      find.byType(ExtendedTabBarView).last,
      const Offset(-350, 0),
    );
    await tester.pumpAndSettle();
    expect(h.activity.historyCalls, [1]);
    await tester.tap(find.text('Friends are playing'));
    await tester.pumpAndSettle();
    expect(h.activity.friendCalls, 2);
    h.activity.friends = [homeTestFriend(99)];
    await h.container.read(friendsActivityProvider.notifier).refresh();
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(h.container.read(friendsActivityProvider).items.single.roomId, '99');
  });

  testWidgets('all countries, modal selection, swipe and Hot share one state', (
    tester,
  ) async {
    await h.pump(tester);
    expect(
      tester.widget<ExtendedTabBar>(find.byType(ExtendedTabBar)).tabs,
      hasLength(8),
    );
    await tester.tap(find.byKey(const ValueKey('home-more-countries')));
    await tester.pumpAndSettle();
    expect(find.byType(HomeCountriesSheet), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('country-more-TR')));
    await tester.pumpAndSettle();
    expect(h.container.read(homeFeedProvider).selectedCountryCode, 'TR');
    expect(
      tester
          .widget<ExtendedTabBar>(find.byType(ExtendedTabBar))
          .controller!
          .index,
      7,
    );
    expect(h.roomCalls, contains('TR'));
    await tester.drag(find.byType(ExtendedTabBarView), const Offset(350, 0));
    await tester.pumpAndSettle();
    expect(h.container.read(homeFeedProvider).selectedCountryCode, 'ID');
    await tester.tap(find.byKey(const ValueKey('home-more-countries')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('country-more-hot')));
    await tester.pumpAndSettle();
    expect(h.container.read(homeFeedProvider).selectedCountryCode, isNull);
    expect(
      tester
          .widget<ExtendedTabBar>(find.byType(ExtendedTabBar))
          .controller!
          .index,
      0,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'cancel keeps selection, country failure retries without blocking Hot',
    (tester) async {
      h.failCountries = true;
      await h.pump(tester);
      expect(h.roomCalls, contains(null));
      await tester.tap(find.byKey(const ValueKey('home-more-countries')));
      await tester.pumpAndSettle();
      expect(find.text('Countries unavailable'), findsOneWidget);
      h.failCountries = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('country-more-TR')), findsOneWidget);
      await tester.tapAt(const Offset(10, 20));
      await tester.pumpAndSettle();
      expect(h.container.read(homeFeedProvider).selectedCountryCode, isNull);
    },
  );

  testWidgets(
    'friend entry carries real room id and followUid, debouncing duplicate taps',
    (tester) async {
      h.entryGate = Completer<Map<String, dynamic>>();
      await h.pump(tester, direct: true);
      await tester.tap(find.text('Real room'));
      await tester.pump();
      await tester.tap(find.text('Real room'));
      await tester.pump();
      expect(h.entryCalls, 1);
      h.entryGate!.complete({});
      await tester.pumpAndSettle();
      expect(h.router.state.uri.path, '/room/42');
      expect(h.router.state.uri.queryParameters['followUid'], '81');
    },
  );

  for (final change in ['close', 'account']) {
    testWidgets('$change ignores pending room navigation', (tester) async {
      h.entryGate = Completer<Map<String, dynamic>>();
      await h.pump(tester);
      await tester.tap(find.byKey(const ValueKey('friends-activity-all')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Real room'));
      await tester.pump();
      if (change == 'close') {
        await tester.tap(find.bySemanticsLabel('Back'));
      } else {
        h.session.next();
      }
      await tester.pumpAndSettle();
      h.entryGate!.complete({});
      await tester.pumpAndSettle();
      expect(h.router.state.uri.path, '/');
      expect(find.text('Switch room'), findsNothing);
    });
  }

  testWidgets(
    'history errors retry in place and share pending result with current tab',
    (tester) async {
      h.activity.failHistory = true;
      await h.pump(tester, direct: true);
      await tester.tap(find.text('Recent Footprints'));
      await tester.pumpAndSettle();
      expect(find.text('History unavailable'), findsOneWidget);
      h.activity.failHistory = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Previously visited room'), findsOneWidget);
      expect(h.activity.historyCalls, [1, 1]);
    },
  );

  testWidgets(
    'same room restores without loading entry info or joining again',
    (tester) async {
      h.room.current = const RoomState(
        currentRoomId: '42',
        status: RoomStatus.ready,
        isInRoom: true,
        isMinimized: true,
      );
      await h.pump(tester, direct: true);
      await tester.tap(find.text('Real room'));
      await tester.pumpAndSettle();
      expect(h.entryCalls, 0);
      expect(h.room.current.isMinimized, isFalse);
      expect(h.router.state.uri.path, '/room/42');
      expect(h.room.leaves, 0);
    },
  );

  testWidgets(
    'account change removes an owned password dialog and the friend page',
    (tester) async {
      h.lock = true;
      await h.pump(tester);
      await tester.tap(find.byKey(const ValueKey('friends-activity-all')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Real room'));
      await tester.pumpAndSettle();
      expect(find.text('Room password'), findsOneWidget);
      h.session.next();
      await tester.pumpAndSettle();
      expect(find.text('Room password'), findsNothing);
      expect(h.router.state.uri.path, '/');
      expect(h.room.leaves, 0);
    },
  );

  testWidgets(
    'country sheet closes on account switch and resets the selection',
    (tester) async {
      await h.pump(tester);
      h.container.read(homeFeedProvider.notifier).selectCountry('TR');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('home-more-countries')));
      await tester.pumpAndSettle();
      h.session.next();
      await tester.pumpAndSettle();
      expect(find.byType(HomeCountriesSheet), findsNothing);
      expect(h.container.read(homeFeedProvider).selectedCountryCode, isNull);
    },
  );

  testWidgets(
    'reordering countries keeps the selected country and subsequent swipe in sync',
    (tester) async {
      await h.pump(tester);
      h.container.read(homeFeedProvider.notifier).selectCountry('US');
      await tester.pumpAndSettle();
      h.countries = [h.countries[1], h.countries[0], ...h.countries.skip(2)];
      await h.container.read(homeFeedProvider.notifier).refreshCountries();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ExtendedTabBar>(find.byType(ExtendedTabBar))
            .controller!
            .index,
        1,
      );
      await tester.drag(find.byType(ExtendedTabBarView), const Offset(-350, 0));
      await tester.pumpAndSettle();
      expect(h.container.read(homeFeedProvider).selectedCountryCode, 'SA');
    },
  );

  testWidgets('repeated All taps open only one friend page', (tester) async {
    await h.pump(tester);
    await tester.tap(find.byKey(const ValueKey('friends-activity-all')));
    await tester.tap(
      find.byKey(const ValueKey('friends-activity-all')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(h.router.state.uri.path, '/');
    expect(h.activity.friendCalls, 2);
  });

  for (final width in [320.0, 375.0, 430.0]) {
    for (final page in ['friends', 'history', 'countries']) {
      testWidgets('home activity v1 $page at $width', (tester) async {
        await h.pump(tester, width: width, direct: page != 'countries');
        if (page == 'countries') {
          await tester.tap(find.byKey(const ValueKey('home-more-countries')));
          await tester.pumpAndSettle();
        } else if (page == 'history') {
          await tester.tap(find.text('Recent Footprints'));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/home_activity_v1/${page}_${width.toInt()}.png',
          ),
        );
      });
    }
  }

  testWidgets(
    'short home view and long country errors keep retry and grid reachable',
    (tester) async {
      await h.pump(tester, width: 320, height: 568);
      h.failCountries = true;
      h.countriesError = List.filled(
        40,
        'Country service unavailable.',
      ).join(' ');
      await h.container.read(homeFeedProvider.notifier).refreshCountries();
      await tester.tap(find.byKey(const ValueKey('home-more-countries')));
      await tester.pumpAndSettle();
      expect(find.text('Retry').hitTestable(), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('country-more-TR')),
        80,
        scrollable: find.descendant(
          of: find.byType(HomeCountriesSheet),
          matching: find.byType(Scrollable),
        ),
      );
      expect(
        find.byKey(const ValueKey('country-more-TR')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
