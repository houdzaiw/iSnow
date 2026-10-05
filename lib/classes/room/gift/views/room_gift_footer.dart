import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
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
            Expanded(
              child: InkWell(
                onTap: onOpenWallet,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      AppAssets.lanhuRoomGiftCoin,
                      width: AppSpacing.roomGiftCoinSize.r,
                      height: AppSpacing.roomGiftCoinSize.r,
                    ),
                    SizedBox(width: AppSpacing.xs.w),
                    Flexible(
                      child: Text(
                        '${state.balance}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.roomGiftBalance,
                      ),
                    ),
                    SizedBox(width: AppSpacing.xs.w),
                    Image.asset(
                      AppAssets.lanhuRoomGiftBalanceArrow,
                      width: AppSpacing.roomGiftBalanceArrowWidth.r,
                      height: AppSpacing.roomGiftBalanceArrowSize.r,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: AppSpacing.sm.w),
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
    final quickOptions = options.take(4).toList();
    if (!quickOptions.contains(state.giftCount)) {
      if (quickOptions.length == 4) quickOptions.removeLast();
      quickOptions.add(state.giftCount);
    }
    return Container(
      width: AppSpacing.roomGiftSendControlWidth.w,
      height: AppSpacing.roomGiftSendHeight.h,
      decoration: const BoxDecoration(
        color: AppColors.roomGiftQuantitySurface,
        borderRadius: AppRadius.pillBorder,
      ),
      clipBehavior: Clip.hardEdge,
      child: Row(
        children: [
          for (final count in quickOptions)
            Expanded(
              child: InkWell(
                key: ValueKey('room-gift-count-$count'),
                onTap: state.isSending
                    ? null
                    : () => viewModel.setGiftCount(count),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$count',
                      style: state.giftCount == count
                          ? AppTextStyles.roomGiftCount
                          : AppTextStyles.roomGiftCountInactive,
                    ),
                  ),
                ),
              ),
            ),
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
            child: SizedBox(
              width: AppSpacing.xxl.w,
              height: AppSpacing.roomGiftSendHeight.h,
              child: Center(
                child: Image.asset(
                  AppAssets.lanhuRoomGiftCountArrow,
                  width: AppSpacing.roomGiftCountArrowSize.r,
                  height: AppSpacing.roomGiftCountArrowSize.r,
                ),
              ),
            ),
          ),
          InkWell(
            onTap: state.isSending
                ? null
                : () async {
                    final sent = await viewModel.sendSelectedGift();
                    if (sent && context.mounted) onSent();
                  },
            child: Container(
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

Future<int?> _showCustomCountDialog(BuildContext context, int currentCount) {
  return showDialog<int>(
    context: context,
    builder: (_) => _GiftCountDialog(currentCount: currentCount),
  );
}

class _GiftCountDialog extends HookWidget {
  const _GiftCountDialog({required this.currentCount});

  final int currentCount;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: '$currentCount');
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
          onPressed: () => Navigator.pop(context),
          child: Text(
            context.l10n.t('app.cancel'),
            style: AppTextStyles.roomGiftTarget,
          ),
        ),
        TextButton(
          onPressed: () {
            final value = int.tryParse(controller.text.trim());
            if (value != null && value > 0) {
              Navigator.pop(context, value);
            }
          },
          child: Text(
            context.l10n.t('room.gift.confirm'),
            style: AppTextStyles.roomGiftCount,
          ),
        ),
      ],
    );
  }
}
