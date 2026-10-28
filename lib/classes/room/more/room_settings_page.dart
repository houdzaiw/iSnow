import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../theme/app_theme.dart';
import '../room_repository.dart';
import 'room_tools_controller.dart';
import 'room_tools_models.dart';
import 'room_tools_widgets.dart';
import 'room_tool_navigation.dart';
import 'room_settings_content.dart';

enum RoomSettingSection { effects, charmCounter, charmCurrency }

class RoomSettingsPage extends ConsumerWidget {
  const RoomSettingsPage({
    super.key,
    required this.roomId,
    required this.section,
  });
  final String roomId;
  final RoomSettingSection section;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roomToolsControllerProvider(roomId));
    final vm = ref.read(roomToolsControllerProvider(roomId).notifier);
    final title = switch (section) {
      RoomSettingSection.effects => toolText(
        context,
        'Effect settings',
        '特效设置',
      ),
      RoomSettingSection.charmCounter => toolText(
        context,
        'Charm counter',
        '魅力值计数',
      ),
      RoomSettingSection.charmCurrency => toolText(
        context,
        'Charm settings',
        '魅力值设置',
      ),
    };
    return RoomToolPage(
      roomId: roomId,
      title: title,
      child: Column(
        children: [
          if (section == RoomSettingSection.effects)
            RoomEffectSettingsContent(roomId: roomId),
          if (section == RoomSettingSection.charmCounter) ...[
            SwitchListTile(
              title: Text(title),
              value: state.charmEnabled,
              onChanged: vm.canManage && !state.busy.contains('charm')
                  ? vm.setCharmEnabled
                  : null,
            ),
            for (final mic
                in ref.watch(roomRepositoryProvider).roomState.micList)
              if ((mic.uid ?? 0) > 0)
                ListTile(
                  leading: ToolImage('${mic.userInfo?['avatar'] ?? ''}'),
                  title: Text('${mic.userInfo?['nick'] ?? mic.uid}'),
                  onTap: () => pushRoomTool(
                    context,
                    RoomCharmRankPage(roomId: roomId, targetUid: mic.uid!),
                  ),
                ),
          ],
          if (section == RoomSettingSection.charmCurrency)
            RoomCharmCurrencyContent(roomId: roomId),
        ],
      ),
    );
  }
}

final roomCharmRankProvider = FutureProvider.autoDispose
    .family<ToolJson, (String, int)>((ref, key) {
      ref.watch(
        roomToolsControllerProvider(key.$1).select((state) => state.currency),
      );
      return ref
          .read(roomToolsControllerProvider(key.$1).notifier)
          .charmRank(key.$2);
    });

class RoomCharmRankPage extends ConsumerWidget {
  const RoomCharmRankPage({
    super.key,
    required this.roomId,
    required this.targetUid,
  });
  final String roomId;
  final int targetUid;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rank = ref.watch(roomCharmRankProvider((roomId, targetUid)));
    return RoomToolPage(
      roomId: roomId,
      title: toolText(context, 'Charm contributors', '魅力贡献榜'),
      child: rank.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => TextButton(
          onPressed: () =>
              ref.invalidate(roomCharmRankProvider((roomId, targetUid))),
          child: Text('$error'),
        ),
        data: (data) => Column(
          children: [
            Text('${data['charmValue'] ?? 0}', style: AppTextStyles.navTitle),
            TextButton(
              onPressed: () =>
                  openRoomToolGift(context, ref, roomId, targetUid: targetUid),
              child: Text(toolText(context, 'Gift', '送礼')),
            ),
            if (data['myContributor'] != null && data['myContributor'] is! Map)
              ListTile(
                title: Text(toolText(context, 'My contribution', '我的贡献')),
                trailing: Text('${data['myContributor']}'),
              ),
            if (data['ratio'] != null)
              ListTile(
                title: Text(toolText(context, 'Contribution ratio', '贡献比例')),
                trailing: Text('${data['ratio']}'),
              ),
            if (Uri.tryParse('${data['rule'] ?? ''}') case final ruleUri?)
              if ({'http', 'https'}.contains(ruleUri.scheme) &&
                  ruleUri.host.isNotEmpty)
                TextButton(
                  onPressed: () => context.push(
                    Uri(
                      path: '/web-view',
                      queryParameters: {
                        'title': toolText(context, 'Charm rules', '魅力规则'),
                        'uri': ruleUri
                            .replace(
                              queryParameters: {
                                ...ruleUri.queryParameters,
                                'language': Localizations.localeOf(
                                  context,
                                ).languageCode,
                              },
                            )
                            .toString(),
                      },
                    ).toString(),
                  ),
                  child: Text(toolText(context, 'Rules', '规则')),
                ),
            for (final person in [
              if (toolMap(data['myContributor']).isNotEmpty)
                toolMap(data['myContributor']),
              ...toolList(data['contributors']),
            ])
              ListTile(
                leading: ToolImage('${person['avatar'] ?? ''}'),
                title: Text('${person['nickName'] ?? person['uid'] ?? ''}'),
                subtitle: Text('${person['charmValue'] ?? 0}'),
                onTap: toolInt(person['uid']) <= 0
                    ? null
                    : () => context.push('/profile-homepage/${person['uid']}'),
              ),
          ],
        ),
      ),
    );
  }
}
