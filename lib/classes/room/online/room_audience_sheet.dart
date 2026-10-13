import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../localization/app_localizations.dart';
import '../../../model/room_models.dart';
import '../../../model/room_user_info.dart';
import '../../../theme/app_theme.dart';
import 'room_audience_avatar.dart';
import 'room_audience_view_model.dart';

Future<int?> showRoomAudienceSheet(BuildContext context, String roomId) {
  return showModalBottomSheet<int>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: AppColors.roomMoreSheet,
    barrierColor: AppColors.modalScrimStrong,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetBorder),
    builder: (_) => RoomAudienceSheet(roomId: roomId),
  );
}

class RoomAudienceSheet extends ConsumerWidget {
  const RoomAudienceSheet({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = roomAudienceViewModelProvider(roomId);
    final state = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);
    return SafeArea(
      top: false,
      child: SizedBox(
        key: const ValueKey('room-audience-sheet'),
        width: double.infinity,
        height: math.min(
          AppSpacing.roomAudienceSheetHeight.h,
          MediaQuery.sizeOf(context).height *
              AppSpacing.roomAudienceSheetMaxHeightRatio,
        ),
        child: Column(
          children: [
            SizedBox(
              height: AppSpacing.roomAudienceHeaderHeight.h,
              child: Center(
                child: Text(
                  '${context.l10n.t('room.audience.users')} (${state.onlineCount})',
                  key: const ValueKey('room-audience-count'),
                  style: AppTextStyles.roomAudienceName,
                ),
              ),
            ),
            if (state.loadingAudience)
              const LinearProgressIndicator(color: AppColors.primaryPink),
            if (state.audienceError != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.t('room.audience.loadFailed'),
                        style: AppTextStyles.roomMoreHint,
                      ),
                    ),
                    TextButton(
                      onPressed: state.loadingAudience
                          ? null
                          : viewModel.refresh,
                      child: Text(context.l10n.t('app.retry')),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: viewModel.refresh,
                color: AppColors.primaryPink,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
                  itemCount: state.audience.isEmpty ? 1 : state.audience.length,
                  itemBuilder: (context, index) {
                    if (state.audience.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.all(AppSpacing.section.r),
                        child: Center(
                          child: Text(
                            state.loadingAudience || state.audienceError != null
                                ? ''
                                : context.l10n.t('room.audience.empty'),
                            style: AppTextStyles.roomMoreHint,
                          ),
                        ),
                      );
                    }
                    return _AudienceRow(user: state.audience[index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudienceRow extends StatelessWidget {
  const _AudienceRow({required this.user});

  final RoomUserInfo user;

  @override
  Widget build(BuildContext context) {
    final owner = user.roomIdentity == UserRoomIdentity.owner;
    return InkWell(
      key: ValueKey('room-audience-user-${user.uid}'),
      onTap: () => Navigator.of(context).pop(user.uid),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm.h),
        child: Row(
          children: [
            RoomAudienceAvatar(
              url: user.userBase.avatar,
              size: AppSpacing.roomAudienceAvatarSize.r,
            ),
            SizedBox(width: AppSpacing.lg.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.userBase.nick,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.roomAudienceName,
                  ),
                  SizedBox(height: AppSpacing.xs.h),
                  Text(
                    'ID: ${user.userBase.userNo ?? user.uid}',
                    style: AppTextStyles.roomMoreHint,
                  ),
                ],
              ),
            ),
            if (user.roomIdentity.isOwnerOrManager)
              Container(
                margin: EdgeInsets.only(left: AppSpacing.sm.w),
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm.w,
                  vertical: AppSpacing.xs.h,
                ),
                decoration: BoxDecoration(
                  color: owner
                      ? AppColors.roomAudienceOwner
                      : AppColors.roomAudienceManager,
                  borderRadius: AppRadius.fieldBorder,
                ),
                child: Text(
                  context.l10n.t(
                    owner ? 'room.audience.owner' : 'room.audience.manager',
                  ),
                  style: AppTextStyles.roomMoreTool,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
