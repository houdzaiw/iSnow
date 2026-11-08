import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'room_lobby_page.dart';
import 'room_tools_controller.dart';
import 'room_tools_widgets.dart';

/// Shared local presentation for More, the pendant and award cards.
Future<void> openRoomLobby(
  BuildContext context,
  WidgetRef ref,
  String roomId,
) async {
  if (!context.mounted) return;
  final owner = ref.read(roomToolsControllerProvider(roomId).notifier);
  final token = owner.beginLobbyPanel();
  if (token == null) return;
  try {
    await pushRoomTool<void>(
      context,
      RoomLobbyPage(roomId: roomId, presentationToken: token),
    );
  } finally {
    owner.endLobbyPanel(token);
  }
}
