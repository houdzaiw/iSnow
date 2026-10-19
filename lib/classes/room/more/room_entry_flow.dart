import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/http_api.dart';
import '../room_repository.dart';
import 'room_tools_models.dart';
import 'room_tools_repository.dart';
import 'room_tools_widgets.dart';

final roomEntryInfoProvider = FutureProvider.autoDispose
    .family<ToolJson, String>((ref, id) async {
      final raw = toolMap(
        await ref.read(roomToolsRepositoryProvider).get(HttpApi.roomInfo, {
          'roomId': id,
        }),
      );
      final nested = toolMap(raw['roomInfoDTO'] ?? raw['roomInfo']);
      return nested.isEmpty ? raw : nested;
    });

Future<void> enterSharedRoom(
  BuildContext context,
  WidgetRef ref,
  String roomId,
) async {
  if (roomId.trim().isEmpty) return;
  final repository = ref.read(roomRepositoryProvider);
  final existing = repository.roomState;
  final generation = repository.roomGeneration;
  if (existing.isInRoom && existing.currentRoomId == roomId) {
    repository.restoreRoom();
    context.go('/room/${Uri.encodeComponent(roomId)}');
    return;
  }
  ToolJson info;
  try {
    info = await ref.read(roomEntryInfoProvider(roomId).future);
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
    return;
  }
  if (!context.mounted || generation != repository.roomGeneration) return;
  if (existing.isInRoom &&
      !await confirmRoomTool(
        context,
        toolText(context, 'Switch room', '切换房间'),
        toolText(
          context,
          'Leave the current room and enter this room?',
          '退出当前房间并进入此房间？',
        ),
      )) {
    return;
  }
  if (!context.mounted || generation != repository.roomGeneration) return;
  String password = '';
  if (toolBool(info['roomLock'])) {
    final controller = TextEditingController();
    final supplied = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(toolText(context, 'Room password', '房间密码')),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(toolText(context, 'Cancel', '取消')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(toolText(context, 'Enter', '进入')),
          ),
        ],
      ),
    );
    // Dialog exit animation may still reference the text controller.
    Future<void>.delayed(kThemeAnimationDuration, controller.dispose);
    if (supplied == null || supplied.isEmpty) return;
    password = supplied;
  }
  if (!context.mounted || generation != repository.roomGeneration) return;
  context.push(
    Uri(
      path: '/room/$roomId',
      queryParameters: {if (password.isNotEmpty) 'roomPassword': password},
    ).toString(),
  );
}

ToolJson? decodeRoomInvitation(String? raw) {
  final envelope = toolMap(raw);
  if (envelope['type'] != 'shareRoom') return null;
  final room = toolMap(envelope['payload']);
  if ('${room['roomId'] ?? ''}'.isEmpty) return null;
  return {...room, 'roomPasswd': ''};
}
