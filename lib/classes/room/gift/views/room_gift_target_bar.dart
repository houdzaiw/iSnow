import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../models/room_gift_models.dart';
import '../viewmodel/room_gift_state.dart';
import '../viewmodel/room_gift_view_model.dart';

class RoomGiftTargetBar extends StatelessWidget {
  const RoomGiftTargetBar({
    super.key,
    required this.state,
    required this.viewModel,
  });

  final RoomGiftState state;
  final RoomGiftViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final showRecipients =
        state.targetMode != RoomGiftTargetMode.allRoom &&
        state.recipients.isNotEmpty;
    return SizedBox(
      height: AppSpacing.roomGiftTargetHeight.h,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.roomGiftFooterHorizontalInset.w,
        ),
        child: Row(
          children: [
            Expanded(
              child: showRecipients
                  ? SizedBox(
                      height: AppSpacing.roomGiftRecipientAvatarSize.r,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: state.recipients.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(width: AppSpacing.roomGiftRecipientGap.w),
                        itemBuilder: (context, index) {
                          final recipient = state.recipients[index];
                          return _RecipientAvatar(
                            recipient: recipient,
                            selected: state.selectedRecipientUids.contains(
                              recipient.uid,
                            ),
                            onTap: state.isSending
                                ? null
                                : () =>
                                      viewModel.toggleRecipient(recipient.uid),
                          );
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            SizedBox(width: AppSpacing.lg.w),
            PopupMenuButton<RoomGiftTargetMode>(
              enabled: !state.isSending,
              color: AppColors.roomGiftPopupSurface,
              position: PopupMenuPosition.under,
              constraints: BoxConstraints.tightFor(
                width: AppSpacing.roomGiftMenuWidth.w,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.roomGiftPopupBorder,
              ),
              onSelected: viewModel.selectTargetMode,
              itemBuilder: (context) => [
                if (state.recipients.isNotEmpty)
                  _targetMenuItem(
                    context,
                    RoomGiftTargetMode.selected,
                    state.recipients.length,
                  ),
                if (state.recipients.isNotEmpty)
                  _targetMenuItem(
                    context,
                    RoomGiftTargetMode.allMic,
                    state.recipients.length,
                  ),
                _targetMenuItem(
                  context,
                  RoomGiftTargetMode.allRoom,
                  state.onlineCount,
                ),
              ],
              child: Container(
                width: AppSpacing.roomGiftTargetWidth.w,
                height: AppSpacing.roomGiftTargetControlHeight.h,
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs.w),
                decoration: const BoxDecoration(
                  color: AppColors.roomGiftTargetSurface,
                  borderRadius: AppRadius.roomGiftTargetBorder,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _targetLabel(context, state.targetMode),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.roomGiftTargetCount,
                      ),
                    ),
                    Image.asset(
                      AppAssets.lanhuRoomGiftTargetArrow,
                      width: AppSpacing.roomGiftTargetArrowSize.r,
                      height: AppSpacing.roomGiftTargetArrowSize.r,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<RoomGiftTargetMode> _targetMenuItem(
    BuildContext context,
    RoomGiftTargetMode mode,
    int count,
  ) {
    return PopupMenuItem<RoomGiftTargetMode>(
      value: mode,
      height: AppSpacing.roomGiftMenuItemHeight.h,
      child: Row(
        children: [
          Expanded(
            child: Text(
              _targetLabel(context, mode),
              style: AppTextStyles.roomGiftTarget,
            ),
          ),
          Text('($count)', style: AppTextStyles.roomGiftTargetCount),
        ],
      ),
    );
  }
}

class _RecipientAvatar extends StatelessWidget {
  const _RecipientAvatar({
    required this.recipient,
    required this.selected,
    required this.onTap,
  });

  final RoomGiftRecipient recipient;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: recipient.nickname,
      selected: selected,
      button: true,
      child: InkWell(
        key: ValueKey('room-gift-recipient-${recipient.uid}'),
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: AppSpacing.roomGiftRecipientAvatarSize.r,
          height: AppSpacing.roomGiftRecipientAvatarSize.r,
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? AppColors.roomGiftSelectedAvatar
                  : AppColors.roomGiftTextMuted,
            ),
            shape: BoxShape.circle,
          ),
          child: Stack(
            children: [
              ClipOval(child: _RecipientImage(url: recipient.avatar)),
              PositionedDirectional(
                end: 0,
                bottom: 0,
                child: Container(
                  height: AppSpacing.roomGiftRecipientBadgeHeight.h,
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxs.w),
                  decoration: const BoxDecoration(
                    color: AppColors.roomGiftTargetSurface,
                    borderRadius: AppRadius.roomGiftRecipientBadgeBorder,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${recipient.seatPosition + 1}',
                    style: AppTextStyles.roomGiftCornerMark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipientImage extends StatelessWidget {
  const _RecipientImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url?.trim() ?? '';
    if (imageUrl.isEmpty) return _fallback();
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: AppSpacing.roomGiftRecipientAvatarSize.r,
      height: AppSpacing.roomGiftRecipientAvatarSize.r,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
    return Image.asset(
      AppAssets.roomGiftRecipient,
      width: AppSpacing.roomGiftRecipientAvatarSize.r,
      height: AppSpacing.roomGiftRecipientAvatarSize.r,
      fit: BoxFit.cover,
    );
  }
}

String _targetLabel(BuildContext context, RoomGiftTargetMode mode) {
  return switch (mode) {
    RoomGiftTargetMode.allMic => context.l10n.t('room.gift.allMic'),
    RoomGiftTargetMode.allRoom => context.l10n.t('room.gift.allRoom'),
    RoomGiftTargetMode.room => context.l10n.t('room.gift.room'),
    RoomGiftTargetMode.selected => context.l10n.t('room.gift.select'),
  };
}
