import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../theme/app_theme.dart';
import '../more/room_tools_widgets.dart';
import '../online/room_audience_avatar.dart';
import '../viewmodel/room_state.dart';
import 'room_edit_info_sheet.dart';
import 'room_interaction_frame.dart';
import 'room_interaction_view_model.dart';
import 'room_management_view_model.dart';
import 'room_user_card.dart';

Future<void> showRoomManagementSheet(
  BuildContext context,
  RoomInteractionKey session,
  ProviderListenable<RoomPageState> roomState,
  RoomManagementSection section,
) => showRoomInteractionSheet<void>(
  context,
  (_) => section == RoomManagementSection.edit
      ? RoomEditInfoSheet(session: session, roomState: roomState)
      : _RoomManagementSheet(
          target: (session: session, section: section),
          roomState: roomState,
        ),
  backgroundColor: section == RoomManagementSection.edit
      ? AppColors.transparent
      : AppColors.roomMessageSurface,
);

class RoomManagementEntries extends StatelessWidget {
  const RoomManagementEntries({
    super.key,
    required this.session,
    required this.roomState,
  });
  final RoomInteractionKey session;
  final ProviderListenable<RoomPageState> roomState;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    children: [
      for (final section in RoomManagementSection.values)
        TextButton(
          onPressed: () =>
              showRoomManagementSheet(context, session, roomState, section),
          child: Text(_name(context, section)),
        ),
    ],
  );
}

String _name(BuildContext context, RoomManagementSection section) =>
    switch (section) {
      RoomManagementSection.edit => toolText(context, 'Edit info', '编辑资料'),
      RoomManagementSection.lock => toolText(context, 'Room lock', '房间锁'),
      RoomManagementSection.layout => toolText(context, 'Mic Layout', '麦位布局'),
      RoomManagementSection.location => toolText(context, 'Location', '位置'),
      RoomManagementSection.background => toolText(
        context,
        'Room background',
        '房间背景',
      ),
      RoomManagementSection.admins => toolText(context, 'Room Admin', '房间管理员'),
      RoomManagementSection.silenced => toolText(context, 'Silence', '禁言名单'),
      RoomManagementSection.blocked => toolText(context, 'Block List', '黑名单'),
    };

class _RoomManagementSheet extends HookConsumerWidget {
  const _RoomManagementSheet({required this.target, required this.roomState});
  final RoomManagementKey target;
  final ProviderListenable<RoomPageState> roomState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomState);
    final provider = roomManagementProvider(target);
    final state = ref.watch(provider);
    final vm = ref.read(provider.notifier);
    final pin = useTextEditingController();
    final locked = useState(room.roomInfo?.roomLock ?? false);
    listenRoomInteractionLifetime(
      context,
      ref,
      target.session,
      onClose: vm.close,
    );
    ref.listen(roomState, (_, next) {
      if (!next.isOwnerOrManager) {
        vm.close();
        final route = ModalRoute.of(context);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted && route?.isActive == true) {
            Navigator.of(context).removeRoute(route!);
          }
        });
      }
    });

    final section = target.section;
    Future<void> save(Future<bool> Function() task) async {
      if (await task() &&
          context.mounted &&
          ModalRoute.of(context)?.isCurrent == true) {
        Navigator.pop(context);
      }
    }

    final saveLabel = toolText(context, 'Save', '保存');
    final busy = state.busy || !room.isOwnerOrManager;
    return PopScope<void>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) vm.close();
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: RoomInteractionFrame(
          title: _name(context, section),
          child: ListView(
            padding: EdgeInsets.all(AppSpacing.lg.r),
            children: [
              if (state.busy) const LinearProgressIndicator(),
              if (state.error != null)
                Text(state.error!, style: AppTextStyles.roomMessageHint),
              if (state.error != null &&
                  (vm.list != null ||
                      section == RoomManagementSection.background))
                TextButton(
                  onPressed: busy ? null : vm.load,
                  child: Text(toolText(context, 'Retry', '重试')),
                ),
              if (section == RoomManagementSection.lock) ...[
                SwitchListTile(
                  value: locked.value,
                  onChanged: busy ? null : (value) => locked.value = value,
                  title: Text(
                    toolText(context, 'Lock the room', '锁定房间'),
                    style: AppTextStyles.roomMessageBody,
                  ),
                ),
                if (locked.value)
                  _RoomManagementField(
                    controller: pin,
                    enabled: !busy,
                    label: toolText(context, 'Four digit password', '四位数字密码'),
                    limit: 4,
                    password: true,
                  ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => save(() => vm.lock(locked.value, pin.text)),
                  child: Text(saveLabel),
                ),
              ],
              if (section == RoomManagementSection.layout)
                for (final (index, count) in const [
                  4,
                  8,
                  10,
                  12,
                  15,
                  20,
                ].indexed)
                  TextButton(
                    onPressed: busy || room.seats.length == count
                        ? null
                        : () async {
                            if (await confirmRoomAction(
                                  context,
                                  toolText(
                                    context,
                                    'Change the mic layout? Some members may be moved off the mic.',
                                    '更换麦位布局？部分成员可能会下麦。',
                                  ),
                                  session: target.session,
                                ) &&
                                context.mounted) {
                              await save(() => vm.layout(index + 1));
                            }
                          },
                    child: Text(
                      toolText(context, '$count seats', '$count 个麦位'),
                    ),
                  ),
              if (section == RoomManagementSection.location) ...[
                SwitchListTile(
                  value: room.roomInfo?.locationEnabled ?? false,
                  onChanged: busy ? null : vm.setLocation,
                  title: Text(
                    toolText(context, 'Show room location', '显示房间位置'),
                    style: AppTextStyles.roomMessageBody,
                  ),
                  subtitle: Text(
                    toolText(
                      context,
                      'Use an approximate location for this room.',
                      '使用设备的大致位置作为房间位置。',
                    ),
                    style: AppTextStyles.roomMessageHint,
                  ),
                ),
                if (room.roomInfo?.address case final String address
                    when address.isNotEmpty &&
                        room.roomInfo?.locationEnabled == true)
                  Text(address, style: AppTextStyles.roomMessageBody),
              ],
              if (section == RoomManagementSection.background) ...[
                if (!state.busy &&
                    state.error == null &&
                    state.backgrounds.isEmpty)
                  Text(
                    toolText(
                      context,
                      'No room backgrounds available',
                      '暂无可用背景',
                    ),
                    style: AppTextStyles.roomMessageHint,
                  ),
                if (state.canUploadVip)
                  TextButton(
                    onPressed: busy ? null : vm.setCustomBackground,
                    child: Text(
                      toolText(context, 'Choose VIP background', '选择 VIP 背景'),
                    ),
                  ),
                for (final background in state.backgrounds)
                  ListTile(
                    leading: RoomAudienceAvatar(
                      url: background.preview,
                      size: AppSpacing.roomMessageAvatar.r,
                    ),
                    title: Text(
                      background.custom
                          ? toolText(context, 'VIP background', 'VIP 背景')
                          : toolText(context, 'Room background', '房间背景'),
                      style: AppTextStyles.roomMessageBody,
                    ),
                    trailing: TextButton(
                      onPressed: busy
                          ? null
                          : () => vm.setBackground(background),
                      child: Text(
                        background.active
                            ? toolText(context, 'Remove', '取消使用')
                            : toolText(context, 'Use', '使用'),
                      ),
                    ),
                  ),
              ],
              if (vm.list case final list?) ...[
                if (!state.busy && state.error == null && state.members.isEmpty)
                  Text(
                    toolText(context, 'No members', '暂无成员'),
                    style: AppTextStyles.roomMessageHint,
                  ),
                for (final user in state.members)
                  ListTile(
                    leading: RoomAudienceAvatar(
                      url: user.userBase.avatar,
                      size: AppSpacing.roomMessageAvatar.r,
                    ),
                    title: Text(
                      user.userBase.nick,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.roomMessageBody,
                    ),
                    trailing: vm.canRemove(room.currentUid, user)
                        ? TextButton(
                            onPressed: busy
                                ? null
                                : () async {
                                    if (await confirmRoomAction(
                                          context,
                                          roomModerationLabel(
                                            context,
                                            list.action,
                                          ),
                                          session: target.session,
                                        ) &&
                                        context.mounted) {
                                      await vm.remove(user.uid);
                                    }
                                  },
                            child: Text(toolText(context, 'Remove', '移除')),
                          )
                        : null,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomManagementField extends StatelessWidget {
  const _RoomManagementField({
    required this.controller,
    required this.enabled,
    required this.label,
    required this.limit,
    this.password = false,
  });
  final TextEditingController controller;
  final bool enabled, password;
  final String label;
  final int limit;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    enabled: enabled,
    style: AppTextStyles.roomMessageBody,
    maxLength: limit,
    maxLines: 1,
    obscureText: password,
    keyboardType: password ? TextInputType.number : TextInputType.text,
    inputFormatters: password ? [FilteringTextInputFormatter.digitsOnly] : null,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.roomMessageHint,
      counterStyle: AppTextStyles.roomMessageHint,
      filled: true,
      fillColor: AppColors.roomMessageBubble,
    ),
  );
}
