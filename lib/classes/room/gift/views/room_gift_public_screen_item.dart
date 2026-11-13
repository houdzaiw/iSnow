import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../theme/app_theme.dart';
import '../../chat/room_public_message.dart';
import '../models/room_gift_event_models.dart';

class RoomGiftPublicScreenItem extends StatelessWidget {
  const RoomGiftPublicScreenItem({
    super.key,
    required this.message,
    this.onUserTap,
  });
  final RoomGiftPublicMessage message;
  final ValueChanged<int>? onUserTap;
  @override
  Widget build(BuildContext context) => RoomPublicMessageFrame(
    uid: message.sender.uid,
    name: message.sender.name,
    avatar: message.sender.avatar,
    appearance: message.sender.appearance,
    avatarKey: ValueKey('room-chat-avatar-gift-${message.key}'),
    onUserTap: onUserTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(message.sentText, style: RoomPublicChatTheme.body),
            ),
            SizedBox(width: RoomPublicChatTheme.badgeGap.w),
            SizedBox.square(
              dimension: RoomPublicChatTheme.gift.r,
              child: RoomPublicChatImage(source: message.gift.icon),
            ),
          ],
        ),
        if (message.winAmount > 0)
          Text(
            '${message.winText}${message.multiplier >= 1 ? ' (${message.multiplier} times)' : ''}',
            style: RoomPublicChatTheme.giftText,
          ),
      ],
    ),
  );
}
