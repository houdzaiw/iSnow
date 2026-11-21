import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../effects/room_gift_asset_resolver.dart';
import '../effects/room_gift_effect_player.dart';
import '../effects/room_gift_playback_barrier.dart';
import '../models/room_gift_models.dart';

class RoomGiftPreview extends ConsumerStatefulWidget {
  const RoomGiftPreview({
    super.key,
    required this.gift,
    required this.onClose,
    required this.onRetry,
  });
  final RoomGift gift;
  final VoidCallback onClose, onRetry;
  @override
  ConsumerState<RoomGiftPreview> createState() => _RoomGiftPreviewState();
}

class _RoomGiftPreviewState extends ConsumerState<RoomGiftPreview> {
  final _player = GlobalKey<RoomGiftEffectPlayerState>();
  bool _closing = false, _failed = false, _playbackFailed = false;

  Future<void> _close() async {
    if (_closing || _failed || !mounted) return;
    setState(() => _closing = true);
    try {
      await _player.currentState?.stop();
      if (mounted) widget.onClose();
    } catch (error) {
      _releaseFailed(error);
    }
  }

  void _releaseFailed(Object error) {
    debugPrint('[RoomGiftPreview] Release blocked: $error');
    if (mounted) setState(() => _failed = true);
  }

  void _onEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) unawaited(_close());
  });

  Widget _error(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.all(AppSpacing.sm.r),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.t('room.gift.previewUnavailable'),
              textAlign: TextAlign.center,
              style: AppTextStyles.roomGiftStatus,
            ),
            TextButton(
              onPressed: _failed ? null : widget.onRetry,
              child: Text(
                context.l10n.t('app.retry'),
                style: AppTextStyles.roomGiftCount,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: AppColors.roomCustomBackdropScrim,
      borderRadius: AppRadius.cardBorder,
    ),
    child: Stack(
      children: [
        Positioned.fill(
          child: ref
              .watch(roomGiftAnimationProvider(widget.gift))
              .when(
                data: (resource) => _playbackFailed
                    ? _error(context)
                    : _closing && _player.currentState == null
                    ? const SizedBox.shrink()
                    : RoomGiftEffectPlayer(
                        key: _player,
                        resource: resource,
                        gift: widget.gift,
                        onEnd: _onEnd,
                        onReleaseFailed: _releaseFailed,
                        onPlaybackFailed: (_) {
                          if (mounted) setState(() => _playbackFailed = true);
                        },
                        playbackBarrier: ref.read(
                          roomGiftPlaybackBarrierProvider,
                        ),
                      ),
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.roomGiftAccent,
                  ),
                ),
                error: (_, __) => _error(context),
              ),
        ),
        PositionedDirectional(
          top: 0,
          end: 0,
          child: Semantics(
            button: true,
            label: context.l10n.t('room.gift.closePreview'),
            child: InkWell(
              onTap: () => unawaited(_close()),
              child: SizedBox.square(
                dimension: AppSpacing.iconSizeLg.r,
                child: Center(
                  child: Image.asset(
                    AppAssets.roomGiftEffectClose,
                    color: AppColors.textInverse,
                    width: AppSpacing.iconSizeSm.r,
                    height: AppSpacing.iconSizeSm.r,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_failed)
          Positioned.fill(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppSpacing.sm.r),
                child: Text(
                  context.l10n.t('room.gift.releaseFailed'),
                  style: AppTextStyles.roomGiftStatus,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
