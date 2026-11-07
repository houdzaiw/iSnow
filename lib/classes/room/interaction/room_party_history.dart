import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../localization/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../more/room_share_page.dart';
import '../more/room_tools_widgets.dart';
import 'room_detail_sheet.dart';
import 'room_detail_view_model.dart';
import 'room_interaction_frame.dart';
import 'room_interaction_repository.dart';
import 'room_interaction_view_model.dart';
import 'room_profile_widgets.dart';

class RoomPartyHistorySheet extends ConsumerWidget {
  const RoomPartyHistorySheet({super.key, required this.session});
  final RoomInteractionKey session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    listenRoomInteractionLifetime(context, ref, session);
    return RoomProfileSheet(
      height: RoomProfileTheme.historyHeight,
      header: RoomProfileHeader(
        title: toolText(context, 'Party history', '派对历史'),
        onBack: () => Navigator.pop(context),
      ),
      child: RoomLinkedPartiesView(session: session, history: true),
    );
  }
}

class RoomLinkedPartiesView extends ConsumerWidget {
  const RoomLinkedPartiesView({
    super.key,
    required this.session,
    this.history = false,
  });
  final RoomInteractionKey session;
  final bool history;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = roomLinkedPartiesProvider((
      session: session,
      history: history,
    ));
    final state = ref.watch(provider);
    final vm = ref.read(provider.notifier);
    return NotificationListener<ScrollNotification>(
      onNotification: (notice) {
        if (notice.metrics.extentAfter <
                RoomProfileTheme.paginationThreshold.h &&
            !state.loading &&
            state.more &&
            state.error == null &&
            state.items.isNotEmpty) {
          vm.load();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () => vm.load(refresh: true),
        child: ListView(
          key: PageStorageKey('room-detail-party-$history'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(RoomProfileTheme.section.r),
          children: [
            if (!history)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => showRoomInteractionSheet<void>(
                    context,
                    (_) => RoomPartyHistorySheet(session: session),
                    backgroundColor: AppColors.transparent,
                  ),
                  child: Text(
                    toolText(context, 'Party History', '派对历史'),
                    style: RoomProfileTheme.link,
                  ),
                ),
              ),
            for (final item in state.items)
              Padding(
                padding: EdgeInsets.only(bottom: RoomProfileTheme.mediumGap.h),
                child: RoomLinkedPartyCard(
                  item: item,
                  onTap: () async {
                    await showRoomPartyDetails(context, session, item.id);
                    if (context.mounted && vm.mounted) {
                      await vm.load(refresh: true);
                    }
                  },
                  onShare: () =>
                      showRoomShareSheet(context, session.roomId, party: item),
                ),
              ),
            if (state.loading) const Center(child: CircularProgressIndicator()),
            if (state.error != null) ...[
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: RoomProfileTheme.secondary,
              ),
              TextButton(
                onPressed: vm.load,
                child: Text(
                  context.l10n.t('app.retry'),
                  style: RoomProfileTheme.link,
                ),
              ),
            ],
            if (!state.loading && state.error == null && state.items.isEmpty)
              Padding(
                padding: EdgeInsets.all(RoomProfileTheme.wideGap.r),
                child: Text(
                  toolText(context, 'No parties yet', '暂无派对'),
                  textAlign: TextAlign.center,
                  style: RoomProfileTheme.secondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class RoomLinkedPartyCard extends StatelessWidget {
  const RoomLinkedPartyCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onShare,
  });
  final RoomLinkedParty item;
  final VoidCallback onTap, onShare;

  @override
  Widget build(BuildContext context) {
    final status = switch (item.status) {
      1 => toolText(context, 'Live', '进行中'),
      2 => toolText(context, 'Upcoming', '即将开始'),
      3 => toolText(context, 'Ended', '已结束'),
      4 => toolText(context, 'Canceled', '已取消'),
      _ => '',
    };
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: RoomProfileTheme.surface,
        borderRadius: RoomProfileTheme.cardRadius,
        boxShadow: RoomProfileTheme.shadows,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: RoomProfileTheme.cardRadius,
        child: Padding(
          padding: EdgeInsets.all(RoomProfileTheme.cardPadding.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: RoomProfileTheme.imageRadius,
                child: AspectRatio(
                  aspectRatio: RoomProfileTheme.partyCoverRatio,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      RoomProfilePicture(url: item.cover),
                      Align(
                        alignment: AlignmentDirectional.topStart,
                        child: Container(
                          margin: EdgeInsets.all(RoomProfileTheme.smallGap.r),
                          padding: EdgeInsets.symmetric(
                            horizontal: RoomProfileTheme.gap.w,
                            vertical: RoomProfileTheme.smallGap.h,
                          ),
                          decoration: const BoxDecoration(
                            color: RoomProfileTheme.badgeScrim,
                            borderRadius: RoomProfileTheme.pillRadius,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RoomProfileAsset(
                                asset: AppAssets.roomPartyHistoryReminder,
                                size: RoomProfileTheme.smallIcon.r,
                              ),
                              SizedBox(width: RoomProfileTheme.smallGap.w),
                              Text(
                                '${item.subscribeNum}',
                                style: RoomProfileTheme.tiny,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: RoomProfileTheme.section.h),
              Row(
                children: [
                  SizedBox.square(
                    dimension: RoomProfileTheme.creatorAvatar.r,
                    child: ClipOval(
                      child: RoomProfilePicture(url: item.creatorAvatar),
                    ),
                  ),
                  SizedBox(width: RoomProfileTheme.smallGap.w),
                  Expanded(
                    child: Text(
                      item.creatorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: RoomProfileTheme.small,
                    ),
                  ),
                  if (status.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: RoomProfileTheme.gap.w,
                        vertical: RoomProfileTheme.smallGap.h,
                      ),
                      decoration: const BoxDecoration(
                        color: RoomProfileTheme.field,
                        borderRadius: RoomProfileTheme.pillRadius,
                      ),
                      child: Text(status, style: RoomProfileTheme.secondary),
                    ),
                ],
              ),
              SizedBox(height: RoomProfileTheme.mediumGap.h),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: RoomProfileTheme.title,
                    ),
                  ),
                  SizedBox(width: RoomProfileTheme.gap.w),
                  Semantics(
                    label: toolText(context, 'Share Party', '分享派对'),
                    button: true,
                    child: InkWell(
                      onTap: onShare,
                      child: SizedBox(
                        width: RoomProfileTheme.shareWidth.w,
                        height: RoomProfileTheme.shareHeight.h,
                        child: Center(
                          child: RoomProfileAsset(
                            asset: AppAssets.roomPartyHistoryShare,
                            width: RoomProfileTheme.shareWidth.w,
                            height: RoomProfileTheme.shareHeight.h,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
