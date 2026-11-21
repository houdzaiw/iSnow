import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../event/room_gift_event_manager.dart';
import 'room_gift_asset_resolver.dart';
import 'room_gift_effect_player.dart';
import 'room_gift_playback_barrier.dart';

class RoomGiftFullScreenEffectLayer extends StatelessWidget {
  const RoomGiftFullScreenEffectLayer({
    super.key,
    required this.tasks,
    required this.onCompleted,
    this.stopRequestedKey,
    this.onStarted,
  });
  final List<RoomGiftEffectTask> tasks;
  final ValueChanged<String> onCompleted;
  final String? stopRequestedKey;
  final ValueChanged<String>? onStarted;
  @override
  Widget build(BuildContext context) => tasks.isEmpty
      ? const SizedBox.shrink()
      : _EffectTask(
          key: ValueKey(tasks.first.key),
          task: tasks.first,
          onCompleted: onCompleted,
          onStarted: onStarted,
          stopRequested: tasks.first.key == stopRequestedKey,
        );
}

class _EffectTask extends ConsumerStatefulWidget {
  const _EffectTask({
    super.key,
    required this.task,
    required this.onCompleted,
    required this.stopRequested,
    this.onStarted,
  });
  final RoomGiftEffectTask task;
  final ValueChanged<String> onCompleted;
  final bool stopRequested;
  final ValueChanged<String>? onStarted;

  @override
  ConsumerState<_EffectTask> createState() => _EffectTaskState();
}

class _EffectTaskState extends ConsumerState<_EffectTask> {
  final _player = GlobalKey<RoomGiftEffectPlayerState>();
  bool _finishing = false, _scheduled = false, _failed = false;

  @override
  void initState() {
    super.initState();
    if (widget.stopRequested) _completeAfterFrame();
  }

  @override
  void didUpdateWidget(_EffectTask oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stopRequested) _completeAfterFrame();
  }

  Future<void> _finish() async {
    if (_finishing || _failed || !mounted) return;
    setState(() => _finishing = true);
    try {
      await _player.currentState?.stop();
      if (mounted) widget.onCompleted(widget.task.key);
    } catch (error) {
      _releaseFailed(error);
    }
  }

  void _releaseFailed(Object error) {
    debugPrint('[RoomGift] Handover blocked: $error');
    if (mounted) setState(() => _failed = true);
  }

  void _completeAfterFrame() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_finish());
    });
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final resource = ref.watch(roomGiftTaskAnimationProvider(task));
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(Localizations.localeOf(context));
    final top = MediaQuery.paddingOf(context).top + AppSpacing.sm.h;
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: resource.when(
              data: (data) =>
                  (_finishing || widget.stopRequested) &&
                      _player.currentState == null
                  ? const SizedBox.shrink()
                  : RoomGiftEffectPlayer(
                      key: _player,
                      resource: data,
                      gift: task.message.gift,
                      fit: BoxFit.cover,
                      onEnd: _completeAfterFrame,
                      onStarted: () => widget.onStarted?.call(task.key),
                      onReleaseFailed: _releaseFailed,
                      playbackBarrier: ref.read(
                        roomGiftPlaybackBarrierProvider,
                      ),
                      startBefore: task.kind == RoomGiftEffectKind.entrance
                          ? task.createdAt.add(const Duration(seconds: 30))
                          : null,
                    ),
              loading: () => const SizedBox.shrink(),
              error: (error, _) {
                debugPrint('[RoomGift] Resource failed: $error');
                _completeAfterFrame();
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        PositionedDirectional(
          top: top,
          end: AppSpacing.xl.w,
          child: Semantics(
            button: true,
            label: l10n.t('room.gift.closeEffect'),
            child: Material(
              color: AppColors.roomCustomBackdropScrim,
              shape: const CircleBorder(),
              child: InkWell(
                key: const ValueKey('room-gift-effect-close'),
                customBorder: const CircleBorder(),
                onTap: _finishing || _failed ? null : _finish,
                child: SizedBox.square(
                  dimension: AppSpacing.iconSizeLg.r,
                  child: Center(
                    child: Image.asset(
                      AppAssets.roomGiftEffectClose,
                      color: AppColors.textInverse,
                      width: AppSpacing.iconSizeMd.r,
                      height: AppSpacing.iconSizeMd.r,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_failed)
          PositionedDirectional(
            top: top + AppSpacing.iconSizeLg.r + AppSpacing.sm.h,
            end: AppSpacing.xl.w,
            width: AppSpacing.giftEffectErrorWidth.w,
            child: Text(
              l10n.t('room.gift.releaseFailed'),
              style: AppTextStyles.giftEffectSubtitle,
              textAlign: TextAlign.end,
            ),
          ),
      ],
    );
  }
}
