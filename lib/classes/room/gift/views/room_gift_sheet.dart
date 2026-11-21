import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../models/room_gift_models.dart';
import '../viewmodel/room_gift_state.dart';
import '../viewmodel/room_gift_view_model.dart';
import '../viewmodel/room_gift_panel_view_model.dart';
import 'room_gift_panel_extras.dart';
import 'room_gift_preview.dart';
import 'room_gift_footer.dart';
import 'room_gift_grid.dart';
import 'room_gift_promotion_bar.dart';
import 'room_gift_target_bar.dart';

enum RoomGiftSheetResult { sent, openWallet }

Future<RoomGiftSheetResult?> showRoomGiftSheet({
  required BuildContext context,
  required String roomId,
  required int onlineCount,
  required int? currentUid,
  required List<RoomGiftRecipient> recipients,
  int? targetUid,
  int? presetGiftId,
  bool backpack = false,
}) {
  return showModalBottomSheet<RoomGiftSheetResult>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    barrierColor: AppColors.modalScrimStrong,
    builder: (sheetContext) => RoomGiftSheet(
      roomId: roomId,
      onlineCount: onlineCount,
      currentUid: currentUid,
      recipients: recipients,
      targetUid: targetUid,
      presetGiftId: presetGiftId,
      backpack: backpack,
      onOpenCampaign: (gift) {
        final url = gift.resolvedCampaignUrl(
          Localizations.localeOf(context).languageCode,
        );
        if (url.isEmpty) return;
        Navigator.of(sheetContext).pop();
        if (!context.mounted) return;
        context.push(
          Uri(
            path: '/web-view',
            queryParameters: {
              'title': gift.name,
              'uri': url,
              'hiddenAppBar': 'true',
            },
          ).toString(),
        );
      },
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
    this.onOpenCampaign,
    this.targetUid,
    this.presetGiftId,
    this.backpack = false,
  });

  final String roomId;
  final int onlineCount;
  final int? currentUid;
  final List<RoomGiftRecipient> recipients;
  final ValueChanged<RoomGift>? onOpenCampaign;
  final int? targetUid, presetGiftId;
  final bool backpack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = roomGiftViewModelProvider(roomId);
    final state = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);
    final panelState = ref.watch(roomGiftPanelViewModelProvider(roomId));
    final panelModel = ref.read(
      roomGiftPanelViewModelProvider(roomId).notifier,
    );
    final routeCurrent = ModalRoute.of(context)?.isCurrent ?? true;
    useEffect(() {
      Future.microtask(() {
        if (panelModel.mounted) panelModel.setVisible(routeCurrent);
      });
      return null;
    }, [routeCurrent]);
    useOnAppLifecycleStateChange((previous, next) {
      panelModel.setVisible(next == AppLifecycleState.resumed && routeCurrent);
      if (next == AppLifecycleState.resumed) {
        unawaited(viewModel.refreshBalance());
      }
    });

    useEffect(() {
      Future.microtask(() async {
        await viewModel.initialize(
          recipients: recipients,
          onlineCount: onlineCount,
          currentUid: currentUid,
        );
        if (viewModel.mounted) {
          viewModel.applyPreset(
            targetUid: targetUid,
            giftId: presetGiftId,
            backpack: backpack,
          );
        }
      });
      return null;
    }, [roomId]);

    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final hasExtras =
        panelState.snapshot != null ||
        panelState.error != null ||
        panelState.loading ||
        panelState.jackpot?.enabled == true;
    final preferredHeight =
        AppSpacing.roomGiftPanelHeight.h +
        bottomPadding +
        (hasExtras ? AppSpacing.giftPanelExtrasHeight.h : 0);
    final maxHeight =
        MediaQuery.sizeOf(context).height *
        AppSpacing.roomGiftPanelMaxHeightRatio;
    final hasIssue = state.issue != null;
    final panelHeight = math.min(preferredHeight, maxHeight);
    final summary = hasIssue
        ? _issueText(context, state)
        : state.selectedGift?.isBackpack == true
        ? '${state.targetCount} recipients · ${state.totalGiftCount} gifts'
        : '${state.targetCount} recipients · ${state.totalCoinCost} coins';

    final panel = SizedBox(
      width: double.infinity,
      height: panelHeight,
      child: Column(
        children: [
          RoomGiftPromotionBar(
            bannerUrl: state.selectedGift?.banner,
            onOpenCampaign:
                state.selectedGift?.banner?.isNotEmpty == true &&
                    state.selectedGift!
                        .resolvedCampaignUrl(
                          Localizations.localeOf(context).languageCode,
                        )
                        .isNotEmpty &&
                    onOpenCampaign != null
                ? () => onOpenCampaign!(state.selectedGift!)
                : null,
            onOpenWallet: () =>
                Navigator.pop(context, RoomGiftSheetResult.openWallet),
          ),
          if (hasExtras)
            RoomGiftPanelExtras(
              state: panelState,
              onRetry: panelModel.retrySnapshots,
              animate: panelModel.canAnimatePanel,
            ),
          Expanded(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.roomGiftSheet,
                border: Border(
                  top: BorderSide(
                    color: AppColors.roomGiftDivider,
                    width: AppSpacing.hairline,
                  ),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: Column(
                  children: [
                    RoomGiftTargetBar(state: state, viewModel: viewModel),
                    Expanded(
                      child: _GiftBody(
                        state: state,
                        viewModel: viewModel,
                        onReplayPreview: panelModel.replayPreview,
                      ),
                    ),
                    SizedBox(
                      height: AppSpacing.giftPanelSummaryHeight.h,
                      child: Semantics(
                        liveRegion: hasIssue,
                        child: Tooltip(
                          message: summary,
                          child: Text(
                            summary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: hasIssue
                                ? AppTextStyles.roomGiftStatus.copyWith(
                                    color: AppColors.danger,
                                  )
                                : AppTextStyles.roomGiftStatus,
                          ),
                        ),
                      ),
                    ),
                    RoomGiftFooter(
                      state: state,
                      viewModel: viewModel,
                      onOpenWallet: () => Navigator.pop(
                        context,
                        RoomGiftSheetResult.openWallet,
                      ),
                      onSent: () =>
                          Navigator.pop(context, RoomGiftSheetResult.sent),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    final previewHeight = math.min(
      AppSpacing.giftPreviewMaxHeight.h,
      maxHeight - panelHeight,
    );
    final preview = panelState.preview;
    final hasPreview =
        preview != null &&
        panelModel.isVisible &&
        previewHeight >= AppSpacing.giftPreviewMinHeight.h;
    return AbsorbPointer(
      absorbing: state.isSending,
      child: !hasPreview
          ? panel
          : SizedBox(
              height: panelHeight + previewHeight,
              child: Stack(
                children: [
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: panelHeight,
                    child: panel,
                  ),
                  PositionedDirectional(
                    bottom: panelHeight + AppSpacing.sm.h,
                    end: AppSpacing.lg.w,
                    width: AppSpacing.giftPreviewMaxWidth.w,
                    height: previewHeight - AppSpacing.sm.h,
                    child: RoomGiftPreview(
                      key: ValueKey(
                        'gift-preview-${panelState.previewRevision}',
                      ),
                      gift: preview,
                      onRetry: panelModel.retryPreview,
                      onClose: () =>
                          panelModel.closePreview(panelState.previewRevision),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _GiftBody extends StatelessWidget {
  const _GiftBody({
    required this.state,
    required this.viewModel,
    required this.onReplayPreview,
  });

  final RoomGiftState state;
  final RoomGiftViewModel viewModel;
  final VoidCallback onReplayPreview;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      RoomGiftLoadStatus.initial || RoomGiftLoadStatus.loading => const Center(
        child: CircularProgressIndicator(color: AppColors.roomGiftAccent),
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
                selectedCount: state.giftCount,
                onTabSelected: viewModel.selectTab,
                onGiftSelected: (gift) {
                  final repeated = state.selectedGiftKey == gift.selectionKey;
                  viewModel.selectGift(gift);
                  if (repeated) onReplayPreview();
                },
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
    RoomGiftIssue.roomUnavailable => context.l10n.t(
      'room.gift.roomUnavailable',
    ),
    RoomGiftIssue.invalidCount => context.l10n.t('room.gift.invalidCount'),
    RoomGiftIssue.requestFailed =>
      state.issueMessage?.isNotEmpty == true
          ? state.issueMessage!
          : context.l10n.t('room.gift.sendFailed'),
    null => '',
  };
}
