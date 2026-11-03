import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../model/system_message_card_data.dart';
import '../../room/more/room_entry_flow.dart';
import '../../wallet/wallet_page.dart';
import '../../web/web_view_page.dart';
import 'system_message_image.dart';

final systemMessageNavigatorProvider = Provider<SystemMessageNavigator>(
  (ref) => const SystemMessageNavigator(),
);

/// UI routing adapter; tests replace destinations without opening payments,
/// native web views, or actually switching rooms.
class SystemMessageNavigator {
  const SystemMessageNavigator();

  Widget destination(SystemMessageAction action) =>
      switch (action.destination) {
        SystemMessageDestination.image => SystemMessageImagePreview(
          uri: action.uri!,
        ),
        SystemMessageDestination.web => WebViewPage(
          title: action.title,
          uri: action.uri.toString(),
        ),
        SystemMessageDestination.wallet => const WalletPage(),
        SystemMessageDestination.room => throw StateError(
          'Room links require the existing entry guard',
        ),
      };

  Future<void> enterRoom(
    BuildContext context,
    WidgetRef ref,
    String roomId,
    bool Function() current,
  ) => enterSharedRoom(context, ref, roomId, isCurrent: current);
}
