import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../theme/app_theme.dart';
import '../more/room_tools_controller.dart';
import '../more/room_tools_widgets.dart';
import '../room_repository.dart';
import '../gift/effects/room_gift_asset_resolver.dart';
import '../gift/effects/room_gift_effect_player.dart';
import '../gift/effects/room_gift_playback_barrier.dart';

Future<void> showRoomActivitySheet(
  BuildContext context,
  String id,
  Widget content,
) {
  final room = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(roomRepositoryProvider);
  final generation = room.roomGeneration;
  if (!room.roomState.isInRoom || room.roomState.currentRoomId != id) {
    return Future.value();
  }
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: RoomActivityTheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: RoomActivityTheme.radius),
    builder: (_) =>
        _OwnedActivitySheet(roomId: id, generation: generation, child: content),
  );
}

class _OwnedActivitySheet extends ConsumerWidget {
  const _OwnedActivitySheet({
    required this.roomId,
    required this.generation,
    required this.child,
  });
  final String roomId;
  final int generation;
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tools = ref.watch(roomToolsControllerProvider(roomId));
    final room = ref.read(roomRepositoryProvider);
    if (!tools.sessionActive ||
        room.roomGeneration != generation ||
        !room.roomState.isInRoom ||
        room.roomState.isMinimized) {
      final route = ModalRoute.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (route?.isActive == true) route?.navigator?.removeRoute(route);
      });
    }
    return child;
  }
}

class RoomActivityPanel extends StatelessWidget {
  const RoomActivityPanel({
    super.key,
    required this.title,
    required this.child,
    this.light = false,
  });
  final String title;
  final Widget child;
  final bool light;
  @override
  Widget build(BuildContext context) => Material(
    color: light ? RoomActivityTheme.luckySurface : RoomActivityTheme.surface,
    borderRadius: RoomActivityTheme.radius,
    child: SafeArea(
      top: false,
      child: SizedBox(
        height:
            MediaQuery.sizeOf(context).height * RoomActivityTheme.sheetRatio,
        child: Padding(
          padding: EdgeInsets.all(RoomActivityTheme.edge.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: light
                          ? RoomActivityTheme.darkTitle
                          : RoomActivityTheme.title,
                    ),
                  ),
                  RoomActivityClose(
                    onTap: () => Navigator.of(context).pop(),
                    light: light,
                  ),
                ],
              ),
              SizedBox(height: RoomActivityTheme.gap.h),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    ),
  );
}

class RoomActivityClose extends StatelessWidget {
  const RoomActivityClose({super.key, required this.onTap, this.light = false});
  final bool light;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    label: toolText(context, 'Close', '关闭'),
    button: true,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(RoomActivityTheme.gap.r),
        child: SizedBox.square(
          dimension: RoomActivityTheme.icon.r,
          child: Image.asset(
            AppAssets.roomActivityIcPkResultClose,
            color: light ? RoomActivityTheme.luckyText : null,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) =>
                Image.asset(AppAssets.lanhuRoomIconMissing),
          ),
        ),
      ),
    ),
  );
}

class RoomActivityError extends StatelessWidget {
  const RoomActivityError(
    this.message, {
    super.key,
    this.retry,
    this.light = false,
  });
  final bool light;
  final String message;
  final VoidCallback? retry;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        message,
        style: light ? RoomActivityTheme.darkBody : RoomActivityTheme.body,
      ),
      if (retry != null)
        TextButton(
          onPressed: retry,
          child: Text(toolText(context, 'Retry', '重试')),
        ),
    ],
  );
}

class RoomActivityImageButton extends StatelessWidget {
  const RoomActivityImageButton({
    super.key,
    required this.asset,
    required this.text,
    this.onTap,
    this.busy = false,
  });
  final String asset, text;
  final VoidCallback? onTap;
  final bool busy;
  @override
  Widget build(BuildContext context) => Opacity(
    opacity: onTap == null ? .5 : 1,
    child: InkWell(
      onTap: busy ? null : onTap,
      child: Container(
        height: RoomActivityTheme.action.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          image: DecorationImage(image: AssetImage(asset), fit: BoxFit.fill),
        ),
        child: busy
            ? const CircularProgressIndicator()
            : Text(text, style: RoomActivityTheme.title),
      ),
    ),
  );
}

final roomActivityResourceProvider = FutureProvider.autoDispose
    .family<RoomGiftAnimationResource, String>(
      (ref, source) => ref
          .read(roomGiftAssetResolverProvider)
          .resolveSource(
            source,
            format: RoomGiftAssetResolver.formatForSource(source),
          ),
    );
final _localActivityBarrier = Provider.family<RoomGiftPlaybackBarrier, String>(
  (ref, source) => RoomGiftPlaybackBarrier(),
);

/// Uses the existing resource resolver/player, including its native release barrier.
class RoomActivityArtwork extends ConsumerWidget {
  const RoomActivityArtwork({
    super.key,
    required this.source,
    this.repeat = false,
    this.fullscreen = false,
    this.onEnd,
  });
  final String source;
  final bool repeat, fullscreen;
  final VoidCallback? onEnd;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(roomActivityResourceProvider(source))
      .when(
        data: (data) => RoomGiftEffectPlayer(
          key: ValueKey(source),
          resource: data,
          repeat: repeat,
          onEnd: onEnd ?? () {},
          onPlaybackFailed: (_) => onEnd?.call(),
          onReleaseFailed: (_) => onEnd?.call(),
          playbackBarrier: fullscreen
              ? ref.read(roomGiftPlaybackBarrierProvider)
              : ref.read(_localActivityBarrier(source)),
        ),
        loading: () => const SizedBox.shrink(),
        error: (_, __) {
          if (onEnd != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) => onEnd?.call());
          }
          return Image.asset(AppAssets.lanhuRoomIconMissing);
        },
      );
}
