import 'package:extended_tabs/extended_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../localization/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../more/room_tools_widgets.dart';
import '../more/room_share_page.dart';
import '../online/room_audience_avatar.dart';
import '../viewmodel/room_state.dart';
import 'room_detail_view_model.dart';
import 'room_interaction_frame.dart';
import 'room_interaction_view_model.dart';
import 'room_party_history.dart';
import 'room_profile_details.dart';
import 'room_profile_widgets.dart';
import 'room_user_card.dart';

class RoomDetailSheet extends HookConsumerWidget {
  const RoomDetailSheet({
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
    final tabs = useTabController(initialLength: 2);
    listenRoomInteractionLifetime(context, ref, session);
    return RoomProfileSheet(
      height: RoomProfileTheme.detailHeight,
      header: SizedBox(
        height: RoomProfileTheme.headerHeight.h,
        child: Center(
          child: ExtendedTabBar(
            controller: tabs,
            isScrollable: true,
            labelPadding: EdgeInsets.symmetric(
              horizontal: RoomProfileTheme.tabHorizontalPadding.w,
            ),
            labelColor: RoomProfileTheme.ink,
            labelStyle: RoomProfileTheme.heading,
            unselectedLabelColor: RoomProfileTheme.inactive,
            indicatorSize: TabBarIndicatorSize.label,
            indicator: UnderlineTabIndicator(
              borderRadius: RoomProfileTheme.pillRadius,
              borderSide: BorderSide(
                color: RoomProfileTheme.pink,
                width: RoomProfileTheme.indicatorHeight.h,
              ),
              insets: EdgeInsets.symmetric(
                horizontal:
                    ((RoomProfileTheme.tabLabel -
                                RoomProfileTheme.indicatorWidth) /
                            2)
                        .w,
              ),
            ),
            dividerColor: AppColors.transparent,
            tabs: [
              for (final title in [
                toolText(context, 'Profile', '房间资料'),
                toolText(context, 'Party', '派对'),
              ])
                Tab(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: RoomProfileTheme.tabLabel.w,
                    ),
                    child: Center(child: Text(title, maxLines: 1)),
                  ),
                ),
            ],
          ),
        ),
      ),
      child: ExtendedTabBarView(
        controller: tabs,
        children: [
          RoomProfileDetails(
            session: session,
            roomState: roomState,
            onShare: onShare,
          ),
          RoomLinkedPartiesView(session: session),
        ],
      ),
    );
  }
}

Future<void> showRoomPartyDetails(
  BuildContext context,
  RoomInteractionKey session,
  int id,
) => showRoomInteractionSheet<void>(
  context,
  (_) => _RoomPartyDetails(session: session, id: id),
);

class _RoomPartyDetails extends ConsumerWidget {
  const _RoomPartyDetails({required this.session, required this.id});
  final RoomInteractionKey session;
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = roomPartyDetailsProvider((session: session, id: id));
    final state = ref.watch(provider);
    final vm = ref.read(provider.notifier);
    listenRoomInteractionLifetime(context, ref, session, onClose: vm.close);
    final item = state.item;
    final start = item?.startsAt?.toLocal();
    return PopScope<void>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) vm.close();
      },
      child: RoomInteractionFrame(
        title: item?.title ?? toolText(context, 'Party', '派对'),
        child: ListView(
          padding: EdgeInsets.all(AppSpacing.lg.r),
          children: [
            if (state.busy) const LinearProgressIndicator(),
            if (state.error != null) ...[
              Text(state.error!, style: AppTextStyles.roomMessageHint),
              TextButton(
                onPressed: vm.load,
                child: Text(context.l10n.t('app.retry')),
              ),
            ],
            if (item != null) ...[
              Center(
                child: RoomAudienceAvatar(
                  url: item.cover,
                  size: AppSpacing.roomInteractionAvatar.r,
                ),
              ),
              if (start != null)
                Text(
                  MaterialLocalizations.of(context).formatMediumDate(start),
                  style: AppTextStyles.roomMessageHint,
                ),
              Text(item.description, style: AppTextStyles.roomMessageBody),
              if (!state.busy && (item.status == 1 || item.status == 2))
                TextButton(
                  onPressed: () =>
                      showRoomShareSheet(context, session.roomId, party: item),
                  child: Text(toolText(context, 'Share Party', '分享派对')),
                ),
              if (!state.busy &&
                  item.status == 2 &&
                  state.actor != null &&
                  item.ownerUid > 0)
                if (item.ownerUid == state.actor)
                  TextButton(
                    onPressed: () async {
                      if (await confirmRoomAction(
                            context,
                            toolText(context, 'Cancel this party?', '取消该派对？'),
                            session: session,
                          ) &&
                          context.mounted) {
                        await vm.cancel();
                      }
                    },
                    child: Text(toolText(context, 'Cancel Party', '取消派对')),
                  )
                else
                  TextButton(
                    onPressed: () async {
                      if (item.subscribed &&
                          !await confirmRoomAction(
                            context,
                            toolText(context, 'Cancel the reminder?', '取消提醒？'),
                            session: session,
                          )) {
                        return;
                      }
                      if (context.mounted) await vm.reminder();
                    },
                    child: Text(
                      item.subscribed
                          ? toolText(context, 'Reminded', '已设置提醒')
                          : toolText(context, 'Remind', '提醒我'),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
