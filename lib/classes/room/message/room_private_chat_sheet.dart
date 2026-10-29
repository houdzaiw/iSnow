import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_conversation.dart';

import '../../../model/im_models.dart';
import '../../../theme/app_theme.dart';
import '../../message/chat_content.dart';
import 'room_message_frame.dart';
import 'room_message_view_model.dart';

Future<void> showRoomPrivateChatSheet(
  BuildContext context,
  String roomId,
  int generation,
  V2TimConversation conversation,
) async {
  ModalRoute<dynamic>? route;
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    barrierColor: AppColors.transparent,
    builder: (sheetContext) {
      route = ModalRoute.of(sheetContext);
      return RoomPrivateChatSheet(
        roomId: roomId,
        generation: generation,
        conversation: conversation,
      );
    },
  );
  await route?.completed;
}

class RoomPrivateChatSheet extends ConsumerWidget {
  const RoomPrivateChatSheet({
    super.key,
    required this.roomId,
    required this.generation,
    required this.conversation,
  });
  final String roomId;
  final int generation;
  final V2TimConversation conversation;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = conversation.userID!;
    final provider = roomPrivateChatProvider((
      roomId: roomId,
      generation: generation,
      uid: uid,
    ));
    final vm = ref.read(provider.notifier);
    listenRoomMessageLifetime(context, ref, roomId, onClose: vm.close);
    return PopScope<void>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) vm.close();
      },
      child: RoomMessageFrame(
        key: const ValueKey('room-private-chat-sheet'),
        title: imConversationTitle(conversation),
        chat: true,
        onBack: () {
          FocusManager.instance.primaryFocus?.unfocus();
          Navigator.of(context).pop();
        },
        child: ChatContent(targetUID: uid, dark: true, provider: provider),
      ),
    );
  }
}

void listenRoomMessageLifetime(
  BuildContext context,
  WidgetRef ref,
  String id, {
  VoidCallback? onClose,
}) {
  final route = ModalRoute.of(context);
  ref.listen(roomMessageViewModelProvider(id).select((s) => s.active), (
    _,
    active,
  ) {
    if (active) return;
    onClose?.call();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted && route?.isActive == true) {
        Navigator.of(context).removeRoute(route!);
      }
    });
  });
}
