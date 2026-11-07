import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../theme/app_theme.dart';
import '../more/room_tools_widgets.dart';
import '../viewmodel/room_state.dart';
import 'room_detail_view_model.dart';
import 'room_interaction_frame.dart';
import 'room_interaction_view_model.dart';
import 'room_management_sheet.dart';
import 'room_management_view_model.dart';
import 'room_profile_widgets.dart';
import 'room_user_card.dart';

class RoomProfileDetails extends HookConsumerWidget {
  const RoomProfileDetails({
    super.key,
    required this.session,
    required this.roomState,
    required this.onShare,
  });
  final RoomInteractionKey session;
  final ProviderListenable<RoomPageState> roomState;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomState);
    final lockKey = (session: session, section: RoomManagementSection.lock);
    final lockState = ref.watch(roomManagementProvider(lockKey));
    final lockVm = ref.read(roomManagementProvider(lockKey).notifier);
    final count = room.isOwnerOrManager
        ? ref.watch(roomAdminCountProvider(session))
        : const AsyncData<int>(0);
    final maximum = room.roomInfo?.managerMaxNum ?? 20;

    Future<void> manage(RoomManagementSection section) async {
      await showRoomManagementSheet(context, session, roomState, section);
      if (context.mounted && section == RoomManagementSection.admins) {
        ref.invalidate(roomAdminCountProvider(session));
      }
    }

    Future<void> changeLock(bool enabled) async {
      String? password = '';
      if (enabled) {
        password = await showDialog<String>(
          context: context,
          useRootNavigator: true,
          builder: (_) => _RoomLockPassword(session: session),
        );
        if (password == null) return;
      } else if (!await confirmRoomAction(
        context,
        toolText(context, 'Unlock this room?', '确认解除房间锁？'),
        session: session,
      )) {
        return;
      }
      if (context.mounted && lockVm.active) {
        await lockVm.lock(enabled, password);
      }
    }

    return ListView(
      key: const PageStorageKey('room-detail-profile'),
      padding: EdgeInsets.fromLTRB(
        RoomProfileTheme.section.w,
        AppSpacing.xxs.h,
        RoomProfileTheme.section.w,
        RoomProfileTheme.section.h,
      ),
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: RoomProfileTheme.imageRadius,
              child: SizedBox.square(
                dimension: RoomProfileTheme.cover.r,
                child: RoomProfilePicture(url: room.roomAvatar),
              ),
            ),
            SizedBox(width: RoomProfileTheme.mediumGap.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      RoomProfileCountry(code: room.roomInfo?.countryCode),
                      Expanded(
                        child: Text(
                          room.roomTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: RoomProfileTheme.title,
                        ),
                      ),
                    ],
                  ),
                  if (room.roomNo.isNotEmpty)
                    InkWell(
                      onTap: () => copyRoomIdentifier(context, room.roomNo),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: RoomProfileTheme.smallGap.h,
                        ),
                        child: Text(
                          'ID:${room.roomNo}',
                          style: RoomProfileTheme.secondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (room.isOwnerOrManager)
              Semantics(
                label: toolText(context, 'Edit info', '编辑资料'),
                button: true,
                child: InkWell(
                  onTap: () => manage(RoomManagementSection.edit),
                  child: SizedBox.square(
                    dimension: RoomProfileTheme.touch.r,
                    child: Center(
                      child: RoomProfileAsset(
                        asset: AppAssets.roomProfileEdit,
                        size: RoomProfileTheme.smallIcon.r,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: RoomProfileTheme.mediumGap.h),
        if (room.roomDesc?.trim().isNotEmpty == true)
          Container(
            constraints: BoxConstraints(
              minHeight: RoomProfileTheme.descriptionMinHeight.h,
            ),
            padding: EdgeInsets.all(RoomProfileTheme.gap.r),
            decoration: const BoxDecoration(
              color: RoomProfileTheme.field,
              borderRadius: RoomProfileTheme.imageRadius,
            ),
            child: Text(room.roomDesc!, style: RoomProfileTheme.description),
          ),
        SizedBox(height: RoomProfileTheme.section.h),
        if (room.isOwnerOrManager) ...[
          _ProfileManagementRow(
            title: toolText(context, 'Room Lock', '房间锁'),
            trailing: Transform.scale(
              scale: RoomProfileTheme.rowSwitchScale,
              child: Switch(
                value: room.roomInfo?.roomLock ?? false,
                activeTrackColor: RoomProfileTheme.pink,
                thumbColor: const WidgetStatePropertyAll(AppColors.textInverse),
                trackOutlineColor: const WidgetStatePropertyAll(
                  AppColors.transparent,
                ),
                onChanged: lockState.busy || room.roomInfo?.roomLock == null
                    ? null
                    : changeLock,
              ),
            ),
          ),
          if (lockState.error != null)
            Text(lockState.error!, style: RoomProfileTheme.secondary),
          _ProfileManagementRow(
            title: toolText(context, 'Room Admin', '房间管理员'),
            value: '${count.valueOrNull ?? '—'}/$maximum',
            onTap: () => manage(RoomManagementSection.admins),
          ),
          _ProfileManagementRow(
            title: toolText(context, 'Room background', '房间背景'),
            onTap: () => manage(RoomManagementSection.background),
          ),
          _ProfileManagementRow(
            title: toolText(context, 'Block List', '黑名单'),
            onTap: () => manage(RoomManagementSection.blocked),
          ),
          _ProfileManagementRow(
            title: toolText(context, 'Silence', '禁言名单'),
            onTap: () => manage(RoomManagementSection.silenced),
          ),
          _ProfileManagementRow(
            title: toolText(context, 'Mic Layout', '麦位布局'),
            value:
                '${(room.enterResponse?.lobbyType ?? 0) > 0 ? toolText(context, 'Game', '游戏') : toolText(context, 'Chat', '聊天')} ${room.seats.length} Mic',
            onTap: () => manage(RoomManagementSection.layout),
          ),
        ],
        TextButton(
          onPressed: onShare,
          child: Text(
            toolText(context, 'Share', '分享'),
            style: RoomProfileTheme.link,
          ),
        ),
      ],
    );
  }
}

class _ProfileManagementRow extends StatelessWidget {
  const _ProfileManagementRow({
    required this.title,
    this.value,
    this.trailing,
    this.onTap,
  });
  final String title;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: SizedBox(
      height: RoomProfileTheme.rowHeight.h,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: RoomProfileTheme.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (value != null) ...[
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: RoomProfileTheme.rowValueMaxWidth.w,
              ),
              child: Text(
                value!,
                style: RoomProfileTheme.body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: RoomProfileTheme.gap.w),
          ],
          if (trailing != null)
            trailing!
          else
            const RoomProfileAsset(asset: AppAssets.roomProfileChevron),
        ],
      ),
    ),
  );
}

class _RoomLockPassword extends HookConsumerWidget {
  const _RoomLockPassword({required this.session});
  final RoomInteractionKey session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = useTextEditingController();
    useListenable(input);
    listenRoomInteractionLifetime(context, ref, session);
    return AlertDialog(
      backgroundColor: RoomProfileTheme.surface,
      title: Text(
        toolText(context, 'Room Lock', '房间锁'),
        style: RoomProfileTheme.heading,
      ),
      content: TextField(
        controller: input,
        autofocus: true,
        keyboardType: TextInputType.number,
        obscureText: true,
        style: RoomProfileTheme.body,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
        decoration: InputDecoration(
          hintText: toolText(
            context,
            'Enter a four digit password',
            '请输入四位数字密码',
          ),
          hintStyle: RoomProfileTheme.secondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(toolText(context, 'Cancel', '取消')),
        ),
        TextButton(
          onPressed: input.text.length != 4
              ? null
              : () => Navigator.pop(context, input.text),
          child: Text(toolText(context, 'Save', '保存')),
        ),
      ],
    );
  }
}
