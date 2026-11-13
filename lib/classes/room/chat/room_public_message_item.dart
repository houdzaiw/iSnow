import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../theme/app_theme.dart';
import '../gift/views/room_gift_public_screen_item.dart';
import '../interaction/room_animated_artwork.dart';
import '../viewmodel/room_state.dart';
import 'room_public_message.dart';
import 'room_public_message_text.dart';

/// Renders typed message content. Navigation and room actions stay with callers.
class RoomPublicMessageItem extends StatelessWidget {
  const RoomPublicMessageItem({
    super.key,
    required this.message,
    required this.onUserTap,
    required this.onImageTap,
    required this.onPartyTap,
  });
  final RoomChatEntry message;
  final ValueChanged<int> onUserTap;
  final ValueChanged<String> onImageTap;
  final ValueChanged<int> onPartyTap;

  @override
  Widget build(BuildContext context) {
    if (message.gift case final gift?) {
      return RoomGiftPublicScreenItem(message: gift, onUserTap: onUserTap);
    }
    final system = message.kind == RoomChatEntryKind.system;
    final text = RoomPublicMessageText(
      text: message.text,
      onUserTap: onUserTap,
      system: system,
      gift: message.isGift,
    );
    if (system) return RoomPublicSystemMessage(child: text);
    Widget body = text;
    if (message.partyId case final partyId?) {
      body = InkWell(
        onTap: () => onPartyTap(partyId),
        child: Text(message.text, style: RoomPublicChatTheme.body),
      );
    } else if (message.mediaUrl case final url?) {
      final image = message.kind == RoomChatEntryKind.image;
      body = InkWell(
        onTap: image ? () => onImageTap(url) : null,
        child: SizedBox.square(
          dimension:
              (image
                      ? RoomPublicChatTheme.media
                      : RoomPublicChatTheme.expression)
                  .r,
          child: image
              ? RoomPublicChatImage(source: url)
              : RoomAnimatedArtwork(
                  key: ValueKey(message.id),
                  url: url,
                  preview: message.mediaPreviewUrl,
                ),
        ),
      );
    }
    return RoomPublicMessageFrame(
      uid: message.senderUid,
      name: message.senderName,
      avatar: message.senderAvatar,
      appearance: message.senderAppearance,
      avatarKey: ValueKey('room-chat-avatar-${message.id}'),
      onUserTap: onUserTap,
      child: body,
    );
  }
}
