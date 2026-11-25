import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/api_error_message.dart';
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
  String roomId, {
  int followUid = 0,
  int requestedLobby = 0,
  bool Function()? isCurrent,
}) async {
  await enterSharedRoomChecked(
    context,
    ref,
    roomId,
    followUid: followUid,
    requestedLobby: requestedLobby,
    isCurrent: isCurrent,
  );
}

Future<bool> enterSharedRoomChecked(
  BuildContext context,
  WidgetRef ref,
  String roomId, {
  int followUid = 0,
  int requestedLobby = 0,
  bool Function()? isCurrent,
  ValueChanged<Route<dynamic>>? onOwnedRoute,
}) async {
  bool valid() => isCurrent?.call() != false;
  if (!context.mounted || !valid() || roomId.trim().isEmpty) return false;
  final repository = ref.read(roomRepositoryProvider);
  final existing = repository.roomState;
  final generation = repository.roomGeneration;
  if (existing.isInRoom && existing.currentRoomId == roomId) {
    repository.restoreRoom();
    context.go(
      Uri(
        path: '/room/${Uri.encodeComponent(roomId)}',
        queryParameters: {
          if ([1, 2].contains(requestedLobby))
            'requestedLobby': '$requestedLobby',
        },
      ).toString(),
    );
    return true;
  }
  final capturedThemes = InheritedTheme.capture(
    from: context,
    to: Navigator.of(context, rootNavigator: true).context,
  );
  ToolJson info;
  try {
    info = await ref.read(roomEntryInfoProvider(roomId).future);
  } catch (error) {
    if (context.mounted && valid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userFacingErrorMessage(
              error,
              fallback: toolText(context, 'Unable to open room', '无法打开房间'),
            ),
          ),
        ),
      );
    }
    return false;
  }
  if (!context.mounted || !valid() || generation != repository.roomGeneration) {
    return false;
  }
  if (existing.isInRoom &&
      !await confirmRoomTool(
        context,
        toolText(context, 'Switch room', '切换房间'),
        toolText(
          context,
          'Leave the current room and enter this room?',
          '退出当前房间并进入此房间？',
        ),
        onRoute: onOwnedRoute,
      )) {
    return false;
  }
  if (!context.mounted || !valid() || generation != repository.roomGeneration) {
    return false;
  }
  String password = '';
  if (toolBool(info['roomLock'])) {
    final controller = TextEditingController();
    final passwordRoute = DialogRoute<String>(
      context: context,
      themes: capturedThemes,
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
    onOwnedRoute?.call(passwordRoute);
    final supplied = await Navigator.of(
      context,
      rootNavigator: true,
    ).push(passwordRoute);
    // Dialog exit animation may still reference the text controller.
    Future<void>.delayed(kThemeAnimationDuration, controller.dispose);
    if (supplied == null || supplied.isEmpty) return false;
    password = supplied;
  }
  if (!context.mounted || !valid() || generation != repository.roomGeneration) {
    return false;
  }
  context.push(
    Uri(
      path: '/room/$roomId',
      queryParameters: {
        if (password.isNotEmpty) 'roomPassword': password,
        if (followUid > 0) 'followUid': '$followUid',
        if ([1, 2].contains(requestedLobby))
          'requestedLobby': '$requestedLobby',
      },
    ).toString(),
  );
  return true;
}

ToolJson? decodeRoomInvitation(String? raw) {
  final envelope = toolMap(raw);
  if (envelope['type'] != 'shareRoom') return null;
  final room = toolMap(envelope['payload']);
  if ('${room['roomId'] ?? ''}'.isEmpty) return null;
  return {...room, 'roomPasswd': ''};
}
