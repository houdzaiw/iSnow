import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../models/room_gift_models.dart';
import '../viewmodel/room_gift_state.dart';
import '../viewmodel/room_gift_view_model.dart';
import 'room_gift_footer.dart';
import 'room_gift_grid.dart';
import 'room_gift_target_bar.dart';

enum RoomGiftSheetResult { sent, openWallet }

Future<RoomGiftSheetResult?> showRoomGiftSheet({
  required BuildContext context,
  required String roomId,
  required int onlineCount,
  required int? currentUid,
  required List<RoomGiftRecipient> recipients,
}) {
  return showModalBottomSheet<RoomGiftSheetResult>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    barrierColor: AppColors.modalScrimStrong,
    builder: (_) => RoomGiftSheet(
      roomId: roomId,
      onlineCount: onlineCount,
      currentUid: currentUid,
      recipients: recipients,
    ),
  );
}

class RoomGiftSheet extends HookConsumerWidget {
  const RoomGiftSheet({
    super.key,
    required this.roomId,
    required this.onlineCount,
    required this.currentUid,
    required this.recipients,
  });

  final String roomId;
  final int onlineCount;
  final int? currentUid;
  final List<RoomGiftRecipient> recipients;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = roomGiftViewModelProvider(roomId);
    final state = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);

    useEffect(() {
      Future.microtask(
        () => viewModel.initialize(
          recipients: recipients,
          onlineCount: onlineCount,
          currentUid: currentUid,
        ),
      );
      return null;
    }, [roomId]);

    ref.listen<RoomGiftState>(provider, (previous, next) {
      if (next.issue == null ||
          (previous?.issue == next.issue &&
              previous?.issueMessage == next.issueMessage)) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_issueText(context, next))));
    });

    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final preferredHeight = AppSpacing.roomGiftPanelHeight.h + bottomPadding;
    final maxHeight =
        MediaQuery.sizeOf(context).height *
        AppSpacing.roomGiftPanelMaxHeightRatio;

    return SizedBox(
      width: double.infinity,
      height: math.min(preferredHeight, maxHeight),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.roomGiftSheet,
          borderRadius: AppRadius.roomGiftSheetBorder,
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Column(
            children: [
              RoomGiftTargetBar(state: state, viewModel: viewModel),
              const Divider(
                height: 0,
                thickness: 1,
                color: AppColors.roomGiftDivider,
              ),
              Expanded(
                child: _GiftBody(state: state, viewModel: viewModel),
              ),
              RoomGiftFooter(
                state: state,
                viewModel: viewModel,
                onOpenWallet: () =>
                    Navigator.pop(context, RoomGiftSheetResult.openWallet),
                onSent: () => Navigator.pop(context, RoomGiftSheetResult.sent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GiftBody extends StatelessWidget {
  const _GiftBody({required this.state, required this.viewModel});

  final RoomGiftState state;
  final RoomGiftViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      RoomGiftLoadStatus.initial || RoomGiftLoadStatus.loading => const Center(
        child: CircularProgressIndicator(color: AppColors.roomGiftGold),
      ),
      RoomGiftLoadStatus.error => _GiftStatus(
        message: state.loadErrorMessage?.isNotEmpty == true
            ? state.loadErrorMessage!
            : context.l10n.t('room.gift.loadFailed'),
        actionLabel: context.l10n.t('app.retry'),
        onAction: viewModel.load,
      ),
      RoomGiftLoadStatus.ready =>
        state.hasContent
            ? RoomGiftCatalogView(
                tabs: state.tabs,
                selectedTabId: state.selectedTabId,
                selectedGiftKey: state.selectedGiftKey,
                onTabSelected: viewModel.selectTab,
                onGiftSelected: viewModel.selectGift,
              )
            : _GiftStatus(message: context.l10n.t('room.gift.empty')),
    };
  }
}

class _GiftStatus extends StatelessWidget {
  const _GiftStatus({required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            AppAssets.lanhuRoomIconMissing,
            width: AppSpacing.iconSizeLg.r,
            height: AppSpacing.iconSizeLg.r,
          ),
          SizedBox(height: AppSpacing.sm.h),
          Text(message, style: AppTextStyles.roomGiftStatus),
          if (onAction != null && actionLabel != null) ...[
            SizedBox(height: AppSpacing.sm.h),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!, style: AppTextStyles.roomGiftCount),
            ),
          ],
        ],
      ),
    );
  }
}

String _issueText(BuildContext context, RoomGiftState state) {
  return switch (state.issue) {
    RoomGiftIssue.chooseGift => context.l10n.t('room.gift.chooseGift'),
    RoomGiftIssue.noRecipient => context.l10n.t('room.gift.noRecipient'),
    RoomGiftIssue.notEnoughCoin => context.l10n.t('room.gift.notEnoughCoin'),
    RoomGiftIssue.notEnoughGift => context.l10n.t('room.gift.notEnoughGift'),
    RoomGiftIssue.requestFailed =>
      state.issueMessage?.isNotEmpty == true
          ? state.issueMessage!
          : context.l10n.t('room.gift.sendFailed'),
    null => '',
  };
}
