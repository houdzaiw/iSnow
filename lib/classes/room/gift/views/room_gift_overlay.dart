import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../effects/room_gift_effect_layer.dart';
import '../event/room_gift_event_provider.dart';
import '../event/room_gift_event_manager.dart';
import '../trajectory/room_gift_seat_registry.dart';
import '../trajectory/room_gift_trajectory_layer.dart';
import '../viewmodel/room_gift_send_controller.dart';
import '../room_gift_repository.dart';
import 'room_gift_combo_button.dart';
import 'room_lucky_gift_layer.dart';

class RoomGiftOverlay extends HookConsumerWidget {
  const RoomGiftOverlay({
    super.key,
    required this.roomId,
    required this.registry,
  });
  final String roomId;
  final RoomGiftSeatRegistry registry;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gifts = ref.watch(roomGiftEventManagerProvider(roomId));
    final sender = ref.watch(roomGiftSendControllerProvider(roomId));
    final manager = ref.read(roomGiftEventManagerProvider(roomId).notifier);
    final routeVisible = TickerMode.of(context);
    useEffect(() {
      Future.microtask(() {
        if (manager.isAlive) manager.setRouteVisible(routeVisible);
      });
      return null;
    }, [manager, routeVisible]);
    ref.listen(roomGiftSendControllerProvider(roomId), (previous, next) {
      if (next.issue == null || next.issue == previous?.issue) return;
      final localized = context.l10n.t('room.gift.${next.issue}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localized == 'room.gift.${next.issue}' ? next.issue! : localized,
          ),
        ),
      );
    });
    if (!gifts.isVisible || !routeVisible) return const SizedBox.shrink();
    return Stack(
      children: [
        if (gifts.canPlayFullscreen)
          Positioned.fill(
            key: const ValueKey('room-gift-fullscreen-host'),
            child: RoomGiftFullScreenEffectLayer(
              tasks: gifts.effects,
              onCompleted: manager.completeEffect,
              onStarted: manager.startEntranceVehicle,
              stopRequestedKey: gifts.stopEffectKey,
            ),
          ),
        Positioned.fill(
          key: const ValueKey('room-gift-flight-host'),
          child: RoomGiftTrajectoryLayer(
            quality: ref.watch(roomGiftPerformanceProvider(roomId)),
            maxPerTarget:
                ref
                    .read(roomGiftRepositoryProvider)
                    .cachedCatalog
                    ?.flightLimit ??
                8,
            events: gifts.flights,
            registry: registry,
            onConsumed: manager.completeFlight,
          ),
        ),
        if (gifts.canPlayLucky && gifts.lucky.isNotEmpty)
          Positioned.fill(
            key: const ValueKey('room-gift-numeric-host'),
            child: RoomLuckyGiftLayer(
              key: ValueKey(gifts.lucky.first.key),
              result: gifts.lucky.first,
              currentUid: manager.currentUid,
              stopRequested: gifts.stopLuckyKey == gifts.lucky.first.key,
              onEnd: () => manager.completeLucky(gifts.lucky.first.key),
            ),
          ),
        if (sender.canContinue || sender.isSending && sender.comboId.isNotEmpty)
          Positioned(
            bottom:
                AppSpacing.giftOverlayBottom.h +
                MediaQuery.paddingOf(context).bottom,
            left: 0,
            right: 0,
            child: Center(
              child: RoomGiftComboButton(
                key: const ValueKey('room-gift-confirmed-combo'),
                size: AppSpacing.giftComboButtonSize,
                enabled: sender.canContinue,
                sending: sender.isSending,
                remainingMilliseconds: sender.remainingMilliseconds,
                tapCount: sender.tapCount,
                onTap: () => ref
                    .read(roomGiftSendControllerProvider(roomId).notifier)
                    .continueCombo(),
              ),
            ),
          ),
      ],
    );
  }
}
