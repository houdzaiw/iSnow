import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../theme/app_theme.dart';
import '../interaction/room_mention.dart';

class RoomPublicMessageText extends HookWidget {
  const RoomPublicMessageText({
    super.key,
    required this.text,
    required this.onUserTap,
    this.system = false,
    this.gift = false,
  });
  final String text;
  final ValueChanged<int> onUserTap;
  final bool system, gift;

  @override
  Widget build(BuildContext context) {
    final parts = useMemoized(() => decodeRoomMentions(text), [text]);
    final currentTap = useRef(onUserTap)..value = onUserTap;
    final recognizers = useMemoized(
      () => [
        for (final part in parts)
          part.uid == null
              ? null
              : (TapGestureRecognizer()
                  ..onTap = () => currentTap.value(part.uid!)),
      ],
      [parts],
    );
    useEffect(
      () => () {
        for (final recognizer in recognizers) {
          recognizer?.dispose();
        }
      },
      [recognizers],
    );
    return Text.rich(
      TextSpan(
        children: [
          for (var index = 0; index < parts.length; index++)
            TextSpan(
              text: parts[index].text,
              style: parts[index].uid == null
                  ? null
                  : RoomPublicChatTheme.mention,
              recognizer: recognizers[index],
            ),
        ],
      ),
      style: system
          ? RoomPublicChatTheme.notice
          : gift
          ? RoomPublicChatTheme.giftText
          : RoomPublicChatTheme.body,
    );
  }
}
