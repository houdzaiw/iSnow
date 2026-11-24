import 'package:flutter/material.dart';

import '../activities/room_activity_widgets.dart';
import '../interaction/room_expression_sheet.dart';
import '../more/room_tools_widgets.dart';

/// Image rules may be served as attachments and cannot be navigated by WebView.
Future<void> showRoomLuckyBoxImageRules(
  BuildContext context,
  String roomId,
  String url,
) => showRoomActivitySheet(context, roomId, RoomLuckyBoxImageRules(url: url));

class RoomLuckyBoxImageRules extends StatelessWidget {
  const RoomLuckyBoxImageRules({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) => RoomActivityPanel(
    title: toolText(context, 'Lucky Box Rules', '幸运盒规则'),
    light: true,
    child: InteractiveViewer(
      child: Center(
        child: RoomPublicImage(url: url, fit: BoxFit.contain),
      ),
    ),
  );
}
