import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'room_lobby_page.dart';
import 'room_tools_controller.dart';
import 'room_tools_widgets.dart';

/// A task may request a lobby, but changing the server mode still needs a choice.
Future<void> openRequestedRoomLobby(
  BuildContext context,
  WidgetRef ref,
  String roomId,
  int type,
) async {
  final owner = ref.read(roomToolsControllerProvider(roomId).notifier);
  if (!owner.active || ![1, 2].contains(type)) return;
  if (owner.snapshot.lobbyType != type) {
    if (!owner.canManage || !owner.snapshot.config.moreModes.contains(type)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            toolText(context, 'Room mode is unavailable', '该房间模式暂不可用'),
          ),
        ),
      );
      return;
    }
    final label = type == 1 ? 'Win' : 'Treasure';
    if (!await confirmRoomTool(
      context,
      toolText(context, 'Room Mode', '房间模式'),
      toolText(context, 'Switch to $label mode?', '是否切换为$label模式？'),
    )) {
      return;
    }
    if (!context.mounted || !owner.active || !await owner.selectMode(type)) {
      return;
    }
  }
  if (context.mounted && owner.active) {
    await openRoomLobby(context, ref, roomId);
  }
}

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
