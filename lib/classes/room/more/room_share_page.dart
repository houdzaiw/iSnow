import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../theme/app_theme.dart';
import 'room_share_view_model.dart';
import 'room_tools_models.dart';
import 'room_tools_widgets.dart';

class RoomSharePage extends HookConsumerWidget {
  const RoomSharePage({super.key, required this.roomId});
  final String roomId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (
      roomId: roomId,
      language: Localizations.localeOf(context).languageCode,
    );
    final state = ref.watch(roomShareViewModelProvider(key));
    final vm = ref.read(roomShareViewModelProvider(key).notifier);
    final tab = useState(1);
    final material = useState(0);
    final contacts = tab.value == 1 ? state.recent : state.friends;
    return RoomToolPage(
      roomId: roomId,
      title: toolText(context, 'Share room', '分享房间'),
      child: Column(
        children: [
          ToolChoices<int>(
            values: [if (state.materials.isNotEmpty) 0, 1, 2],
            selected: tab.value,
            label: (value) => [
              toolText(context, 'Share', '分享'),
              toolText(context, 'Recent chats', '最近会话'),
              toolText(context, 'Friends', '好友'),
            ][value],
            onSelected: (value) => tab.value = value,
          ),
          if (state.loading) const LinearProgressIndicator(),
          if (state.error != null)
            TextButton(onPressed: vm.load, child: Text(state.error!)),
          if (tab.value == 0 && state.materials.isNotEmpty) ...[
            RadioGroup<int>(
              groupValue: material.value,
              onChanged: (value) {
                if (!state.busy && value != null) material.value = value;
              },
              child: Column(
                children: [
                  for (final (index, item) in state.materials.indexed)
                    RadioListTile<int>(
                      value: index,
                      enabled: !state.busy,
                      title: Text('${item['copyText'] ?? ''}'),
                      secondary: ToolImage('${item['imageUrl'] ?? ''}'),
                    ),
                ],
              ),
            ),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final channel in [
                  'Copy',
                  'WhatsApp',
                  'Facebook',
                  'Snapchat',
                  'Telegram',
                  'Messenger',
                  'X',
                  'Instagram',
                  'Contacts',
                  'Other',
                ])
                  TextButton(
                    onPressed: state.busy
                        ? null
                        : () async {
                            final box =
                                context.findRenderObject() as RenderBox?;
                            final origin = box == null
                                ? null
                                : box.localToGlobal(Offset.zero) & box.size;
                            final result = await vm.share(
                              state.materials[material.value.clamp(
                                0,
                                state.materials.length - 1,
                              )],
                              channel,
                              origin: origin,
                            );
                            if (context.mounted && result == 'copied') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    toolText(context, 'Link copied', '链接已复制'),
                                  ),
                                ),
                              );
                            }
                          },
                    child: Text(channel),
                  ),
              ],
            ),
          ] else ...[
            TextField(
              onChanged: vm.search,
              decoration: InputDecoration(
                labelText: toolText(context, 'Search name or ID', '搜索昵称或 ID'),
              ),
            ),
            if (!state.loading && contacts.isEmpty)
              ToolHeading(toolText(context, 'No contacts found', '暂无联系人')),
            for (final contact in contacts)
              ListTile(
                leading: ToolImage('${contact['avatar'] ?? ''}'),
                title: Text('${contact['nick'] ?? contact['uid']}'),
                onTap: state.busy
                    ? null
                    : () async {
                        if (!await confirmRoomTool(
                          context,
                          toolText(context, 'Invite to room', '邀请进入房间'),
                          '${contact['nick'] ?? contact['uid']}\n${vm.roomCard()['title'] ?? roomId}',
                        )) {
                          return;
                        }
                        if (await vm.invite(toolInt(contact['uid'])) &&
                            context.mounted) {
                          final router = GoRouter.of(context);
                          Navigator.of(context).pop();
                          router.push(
                            Uri(
                              path: '/chat-view',
                              queryParameters: {
                                'targetUID': '${contact['uid']}',
                                'title': '${contact['nick'] ?? ''}',
                              },
                            ).toString(),
                          );
                        }
                      },
              ),
            if (tab.value == 2 && state.hasMore)
              TextButton(
                onPressed: () => vm.loadFriends(),
                child: Text(toolText(context, 'Load more', '加载更多')),
              ),
          ],
        ],
      ),
    );
  }
}
