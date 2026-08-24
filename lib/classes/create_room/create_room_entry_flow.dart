import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../localization/app_localizations.dart';
import '../../model/user_profile.dart';
import 'create_room_repository.dart';
import 'create_room_sheet.dart';

Future<void> enterOwnRoom(BuildContext context, WidgetRef ref) async {
  final repository = ref.read(createRoomRepositoryProvider);

  final cachedRoomId = _roomIdOf(await repository.cachedUser());
  if (!context.mounted) return;
  if (cachedRoomId != null) {
    await _enterAndOpenRoom(context, repository, cachedRoomId);
    return;
  }

  UserData? latestUser;
  try {
    latestUser = await repository.fetchRemoteCurrentUser();
  } catch (_) {
    if (context.mounted) {
      _showMessage(context, context.l10n.t('createRoom.fetchOwnRoomFailed'));
    }
    return;
  }

  if (!context.mounted) return;
  final remoteRoomId = _roomIdOf(latestUser);
  if (remoteRoomId != null) {
    await _enterAndOpenRoom(context, repository, remoteRoomId);
    return;
  }

  final createdRoomId = await showCreateRoomSheet(context);
  if (createdRoomId == null ||
      createdRoomId.trim().isEmpty ||
      !context.mounted) {
    return;
  }
  context.go('/room/${Uri.encodeComponent(createdRoomId.trim())}');
}

Future<void> _enterAndOpenRoom(
  BuildContext context,
  CreateRoomRepository repository,
  String roomId,
) async {
  try {
    await repository.enterRoom(roomId);
  } catch (_) {
    if (context.mounted) {
      _showMessage(context, context.l10n.t('createRoom.enterFailed'));
    }
    return;
  }

  if (!context.mounted) return;
  context.go('/room/${Uri.encodeComponent(roomId)}');
}

String? _roomIdOf(UserData? user) {
  final roomId = user?.roomId?.trim();
  return roomId == null || roomId.isEmpty ? null : roomId;
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
