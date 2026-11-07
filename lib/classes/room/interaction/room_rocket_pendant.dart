import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../theme/app_theme.dart';
import '../../web/web_view_page.dart';
import '../more/room_tools_widgets.dart';
import 'room_interaction_frame.dart';
import 'room_interaction_view_model.dart';
import 'room_rocket_view_model.dart';

class RoomRocketPendant extends ConsumerWidget {
  const RoomRocketPendant({super.key, required this.session});
  final RoomInteractionKey session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(roomRocketProvider(session));
    if (data == null) return const SizedBox.shrink();
    final art = AppAssets.roomRocketStages[data.stage - 1][data.level - 1];
    final label = toolText(context, 'Room Rocket', '房间火箭');
    return Semantics(
      label: '$label ${(data.progress * 100).round()}%',
      button: true,
      child: InkWell(
        key: const ValueKey('room-rocket-pendant'),
        onTap: () => showRoomInteractionSheet<void>(
          context,
          (_) => _RocketActivity(session: session),
        ),
        child: SizedBox(
          width: AppSpacing.controlHeightLg.r,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                art,
                height: AppSpacing.controlHeightLg.r,
                fit: BoxFit.contain,
              ),
              ClipRRect(
                borderRadius: AppRadius.pillBorder,
                child: LinearProgressIndicator(
                  value: data.progress,
                  minHeight: AppSpacing.roomMessageHandleHeight.h,
                  color: AppColors.primaryPink,
                  backgroundColor: AppColors.roomMusicStripSurface,
                ),
              ),
              SizedBox(height: AppSpacing.xs.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _RocketActivity extends ConsumerWidget {
  const _RocketActivity({required this.session});
  final RoomInteractionKey session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    listenRoomInteractionLifetime(context, ref, session);
    final rocket = ref.watch(roomRocketProvider(session));
    final language = Localizations.localeOf(context).languageCode;
    final activity = rocket?.link(language);
    final history = rocket?.link(language, results: true);
    final title = toolText(context, 'Room Rocket', '房间火箭');
    void open(Uri url) => showRoomInteractionSheet<void>(
      context,
      (_) => Consumer(
        builder: (context, ref, _) {
          listenRoomInteractionLifetime(context, ref, session);
          return RoomInteractionFrame(
            heightRatio: AppSpacing.roomInteractionRankHeight,
            child: WebViewPage(
              title: title,
              uri: url.toString(),
              hiddenAppBar: true,
            ),
          );
        },
      ),
    );
    return RoomInteractionFrame(
      title: title,
      child: ListView(
        padding: EdgeInsets.all(AppSpacing.lg.r),
        children: [
          if (rocket != null) ...[
            Center(
              child: Image.asset(
                AppAssets.roomRocketStages[rocket.stage - 1][rocket.level - 1],
                height: AppSpacing.roomInteractionMedia.r,
              ),
            ),
            Text(
              '${(rocket.progress * 100).round()}%',
              textAlign: TextAlign.center,
              style: AppTextStyles.roomMessageTitle,
            ),
          ],
          if (activity == null && history == null)
            Text(
              toolText(context, 'Activity unavailable', '活动暂不可用'),
              textAlign: TextAlign.center,
              style: AppTextStyles.roomMessageHint,
            ),
          if (activity != null)
            TextButton(
              onPressed: () => open(activity),
              child: Text(toolText(context, 'Open activity', '打开活动')),
            ),
          if (history != null)
            TextButton(
              onPressed: () => open(history),
              child: Text(toolText(context, 'Prize history', '中奖记录')),
            ),
        ],
      ),
    );
  }
}
