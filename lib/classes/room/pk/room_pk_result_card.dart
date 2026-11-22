import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../theme/app_theme.dart';
import '../activities/room_activity_widgets.dart';
import '../more/room_tools_widgets.dart';
import 'room_pk_models.dart';
import 'room_pk_view_model.dart';

class RoomPkResultCard extends ConsumerWidget {
  const RoomPkResultCard({
    super.key,
    required this.roomId,
    required this.data,
    required this.onUser,
  });
  final String roomId;
  final RoomPkData data;
  final ValueChanged<int> onUser;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(roomPkProvider(roomId).notifier);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: RoomActivityTheme.multiWidth.w,
          maxHeight:
              MediaQuery.sizeOf(context).height * RoomActivityTheme.sheetRatio,
        ),
        child: Material(
          color: AppColors.transparent,
          borderRadius: RoomActivityTheme.cardRadius,
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  data.doublePk
                      ? AppAssets.roomActivityDoublePkResultBg
                      : AppAssets.roomActivityPkMultiplayerMaxBg,
                ),
                fit: BoxFit.fill,
              ),
              borderRadius: RoomActivityTheme.cardRadius,
            ),
            child: Padding(
              padding: EdgeInsets.all(RoomActivityTheme.edge.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Image.asset(
                          AppAssets.roomActivityPkTitleIcon,
                          width: RoomActivityTheme.resultTitleWidth.w,
                          height: RoomActivityTheme.resultTitleHeight.h,
                          fit: BoxFit.contain,
                        ),
                      ),
                      RoomActivityClose(onTap: vm.closeResult),
                    ],
                  ),
                  Flexible(
                    child: data.doublePk
                        ? Padding(
                            padding: EdgeInsets.all(RoomActivityTheme.edge.r),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final user in [
                                  data.side(1) ?? data.users.first,
                                  data.side(2) ?? data.users.last,
                                ])
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: () => onUser(user.uid),
                                          child: ToolImage(
                                            user.avatar,
                                            size: RoomActivityTheme
                                                .resultAvatar
                                                .r,
                                          ),
                                        ),
                                        SizedBox(
                                          height: RoomActivityTheme.gap.h,
                                        ),
                                        Text(
                                          user.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: RoomActivityTheme.body,
                                        ),
                                        Text(
                                          '${user.score}${data.winner?.uid == user.uid ? ' WIN' : ''}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: RoomActivityTheme.body,
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              showRoomPkContributors(
                                                context,
                                                user,
                                                onUser,
                                              ),
                                          child: Text(
                                            toolText(
                                              context,
                                              'Contributors',
                                              '贡献用户',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : ListView(
                            shrinkWrap: true,
                            children: [
                              for (final (index, user) in data.users.indexed)
                                Column(
                                  children: [
                                    ListTile(
                                      leading: InkWell(
                                        onTap: () => onUser(user.uid),
                                        child: ToolImage(user.avatar),
                                      ),
                                      title: Text(
                                        user.name,
                                        style: RoomActivityTheme.body,
                                      ),
                                      subtitle: Text(
                                        '${user.score}${index == 0 && user.score > 0 ? ' WIN' : ''}',
                                        style: RoomActivityTheme.body,
                                      ),
                                    ),
                                    if (user.contributors.isNotEmpty)
                                      ExpansionTile(
                                        title: Text(
                                          toolText(
                                            context,
                                            'Contributors',
                                            '贡献用户',
                                          ),
                                          style: RoomActivityTheme.body,
                                        ),
                                        trailing: Image.asset(
                                          AppAssets.lanhuRoomGiftTargetArrow,
                                          width: RoomActivityTheme.icon.r,
                                        ),
                                        children: [
                                          for (final contributor
                                              in user.contributors)
                                            ListTile(
                                              onTap: () =>
                                                  onUser(contributor.uid),
                                              leading: ToolImage(
                                                contributor.avatar,
                                              ),
                                              title: Text(
                                                contributor.name,
                                                style: RoomActivityTheme.body,
                                              ),
                                            ),
                                        ],
                                      ),
                                  ],
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showRoomPkContributors(
  BuildContext context,
  RoomPkUser user,
  ValueChanged<int> onUser,
) => showDialog<void>(
  context: context,
  useRootNavigator: true,
  builder: (dialogContext) => AlertDialog(
    title: Text(toolText(dialogContext, 'Contributors', '贡献用户')),
    content: SizedBox(
      width: RoomActivityTheme.multiWidth.w,
      child: ListView(
        shrinkWrap: true,
        children: [
          if (user.contributors.isEmpty)
            Text(toolText(dialogContext, 'No contributors yet', '暂无贡献用户')),
          for (final person in user.contributors)
            ListTile(
              leading: ToolImage(person.avatar),
              title: Text(
                person.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.of(dialogContext).pop();
                onUser(person.uid);
              },
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(dialogContext).pop(),
        child: Text(toolText(dialogContext, 'Close', '关闭')),
      ),
    ],
  ),
);
