import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../viewmodel/room_gift_state.dart';
import '../viewmodel/room_gift_view_model.dart';

class RoomGiftFooter extends StatelessWidget {
  const RoomGiftFooter({
    super.key,
    required this.state,
    required this.viewModel,
    required this.onOpenWallet,
    required this.onSent,
  });

  final RoomGiftState state;
  final RoomGiftViewModel viewModel;
  final VoidCallback onOpenWallet;
  final VoidCallback onSent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.roomGiftFooterHeight.h,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.roomGiftFooterHorizontalInset.w,
        ),
        child: Row(
          children: [
            InkWell(
              onTap: onOpenWallet,
              child: Row(
                children: [
                  Image.asset(
                    AppAssets.lanhuRoomGiftCoin,
                    width: AppSpacing.roomGiftCoinSize.r,
                    height: AppSpacing.roomGiftCoinSize.r,
                  ),
                  SizedBox(width: AppSpacing.xs.w),
                  Text(
                    '${state.balance}',
                    style: AppTextStyles.roomGiftBalance,
                  ),
                  SizedBox(width: AppSpacing.xs.w),
                  Image.asset(
                    AppAssets.lanhuRoomGiftBalanceArrow,
                    width: AppSpacing.roomGiftBalanceArrowSize.r,
                    height: AppSpacing.roomGiftBalanceArrowSize.r,
                    color: AppColors.roomGiftTextMuted,
                  ),
                ],
              ),
            ),
            const Spacer(),
            _GiftSendControl(
              state: state,
              viewModel: viewModel,
              onSent: onSent,
            ),
          ],
        ),
      ),
    );
  }
}

class _GiftSendControl extends StatelessWidget {
  const _GiftSendControl({
    required this.state,
    required this.viewModel,
    required this.onSent,
  });

  final RoomGiftState state;
  final RoomGiftViewModel viewModel;
  final VoidCallback onSent;

  @override
  Widget build(BuildContext context) {
    final options = state.selectedGift?.countOptions ?? const [1, 8, 18, 888];
    return Container(
      height: AppSpacing.roomGiftSendHeight.h,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.roomGiftSelectedBorder),
        borderRadius: AppRadius.pillBorder,
      ),
      clipBehavior: Clip.hardEdge,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<int>(
            enabled: !state.isSending,
            color: AppColors.roomGiftPopupSurface,
            position: PopupMenuPosition.over,
            constraints: BoxConstraints.tightFor(
              width: AppSpacing.roomGiftMenuWidth.w,
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.roomGiftPopupBorder,
            ),
            onSelected: (value) async {
              if (value > 0) {
                viewModel.setGiftCount(value);
                return;
              }
              final count = await _showCustomCountDialog(
                context,
                state.giftCount,
              );
              if (count != null) viewModel.setGiftCount(count);
            },
            itemBuilder: (context) => [
              PopupMenuItem<int>(
                value: 0,
                height: AppSpacing.roomGiftMenuItemHeight.h,
                child: Text(
                  context.l10n.t('room.gift.other'),
                  style: AppTextStyles.roomGiftTarget,
                ),
              ),
              for (final count in options)
                PopupMenuItem<int>(
                  value: count,
                  height: AppSpacing.roomGiftMenuItemHeight.h,
                  child: Text('$count', style: AppTextStyles.roomGiftTarget),
                ),
            ],
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
              child: Row(
                children: [
                  Text(
                    '${state.giftCount}',
                    style: AppTextStyles.roomGiftCount,
                  ),
                  SizedBox(width: AppSpacing.xs.w),
                  Image.asset(
                    AppAssets.lanhuRoomGiftCountArrow,
                    width: AppSpacing.roomGiftCountArrowSize.r,
                    height: AppSpacing.roomGiftCountArrowSize.r,
                    color: AppColors.roomGiftTextMuted,
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: state.isSending
                ? null
                : () async {
                    final sent = await viewModel.sendSelectedGift();
                    if (sent) onSent();
                  },
            child: Ink(
              width: AppSpacing.roomGiftSendWidth.w,
              height: AppSpacing.roomGiftSendHeight.h,
              decoration: const BoxDecoration(
                gradient: AppGradients.roomGiftSend,
              ),
              child: Center(
                child: state.isSending
                    ? SizedBox(
                        width: AppSpacing.iconSizeSm.r,
                        height: AppSpacing.iconSizeSm.r,
                        child: const CircularProgressIndicator(
                          strokeWidth: AppSpacing.xxs,
                          color: AppColors.roomGiftSendText,
                        ),
                      )
                    : Text(
                        context.l10n.t('room.gift.send'),
                        style: AppTextStyles.roomGiftSend,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<int?> _showCustomCountDialog(
  BuildContext context,
  int currentCount,
) async {
  final controller = TextEditingController(text: '$currentCount');
  final count = await showDialog<int>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: AppColors.roomGiftPopupSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.roomGiftPopupBorder,
        ),
        title: Text(
          context.l10n.t('room.gift.customCount'),
          style: AppTextStyles.roomMoreSectionTitle,
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: AppTextStyles.roomGiftCount,
          decoration: InputDecoration(
            hintText: context.l10n.t('room.gift.countHint'),
            hintStyle: AppTextStyles.roomGiftStatus,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              context.l10n.t('app.cancel'),
              style: AppTextStyles.roomGiftTarget,
            ),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              Navigator.pop(dialogContext, value);
            },
            child: Text(
              context.l10n.t('room.gift.confirm'),
              style: AppTextStyles.roomGiftCount,
            ),
          ),
        ],
      );
    },
  );
  controller.dispose();
  return count;
}
