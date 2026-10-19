import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../theme/app_theme.dart';
import 'room_entry_flow.dart';
import 'room_tools_models.dart';
import 'room_tools_widgets.dart';

class RoomInvitationCard extends ConsumerStatefulWidget {
  const RoomInvitationCard({super.key, required this.room});
  final ToolJson room;
  @override
  ConsumerState<RoomInvitationCard> createState() => _RoomInvitationCardState();
}

class _RoomInvitationCardState extends ConsumerState<RoomInvitationCard> {
  bool entering = false;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: entering
        ? null
        : () async {
            setState(() => entering = true);
            try {
              await enterSharedRoom(context, ref, '${widget.room['roomId']}');
            } finally {
              if (mounted) setState(() => entering = false);
            }
          },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ToolImage(
          '${widget.room['avatar'] ?? ''}',
          size: AppSpacing.roomExitChoiceSize,
        ),
        Text(
          '${widget.room['title'] ?? widget.room['roomId']}',
          style: AppTextStyles.bodyStrong,
        ),
        Text(
          '${widget.room['roomDesc'] ?? ''}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text(toolText(context, 'Join room', '进入房间'), style: AppTextStyles.hint),
      ],
    ),
  );
}
