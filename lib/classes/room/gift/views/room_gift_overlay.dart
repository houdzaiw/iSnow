import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../effects/room_gift_effect_layer.dart';
import '../event/room_gift_event_provider.dart';
import '../trajectory/room_gift_seat_registry.dart';
import '../trajectory/room_gift_trajectory_layer.dart';
import '../viewmodel/room_gift_send_controller.dart';
import 'room_gift_banner_layer.dart';
import 'room_gift_combo_button.dart';
import 'room_lucky_gift_layer.dart';

class RoomGiftOverlay extends ConsumerWidget {
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
    if (!gifts.isVisible) return const SizedBox.shrink();
    return Stack(
      children: [
        Positioned.fill(
          child: RoomGiftFullScreenEffectLayer(
            tasks: gifts.effects,
            onCompleted: manager.completeEffect,
          ),
        ),
        Positioned.fill(
          child: RoomGiftTrajectoryLayer(
            events: gifts.flights,
            registry: registry,
            onConsumed: manager.completeFlight,
          ),
        ),
        if (gifts.banners.isNotEmpty)
          Positioned(
            top: AppSpacing.giftBannerTop.h,
            left: AppSpacing.lg.w,
            right: AppSpacing.lg.w,
            child: RoomGiftBannerLayer(
              key: ValueKey(gifts.banners.first.key),
              banner: gifts.banners.first,
              onEnd: () => manager.completeBanner(gifts.banners.first.key),
            ),
          ),
        if (gifts.lucky.isNotEmpty)
          Positioned(
            bottom: AppSpacing.giftLuckyBottom.h,
            right: AppSpacing.lg.w,
            left: AppSpacing.section.w,
            child: RoomLuckyGiftLayer(
              key: ValueKey(gifts.lucky.first.key),
              result: gifts.lucky.first,
              onEnd: () => manager.completeLucky(gifts.lucky.first.key),
            ),
          ),
        // A confirmed send must not wait for a broadcast slot to expose Combo.
        if ((sender.canContinue ||
                sender.isSending && sender.comboId.isNotEmpty) &&
            !gifts.slots.any(
              (slot) => slot != null && sender.matches(slot.message),
            ))
          Positioned(
            bottom: AppSpacing.giftOverlayBottom.h,
            right: AppSpacing.lg.w,
            child: RoomGiftComboButton(
              key: const ValueKey('room-gift-confirmed-combo'),
              size: AppSpacing.giftComboButtonSize,
              enabled: sender.canContinue,
              sending: sender.isSending,
              onTap: () => ref
                  .read(roomGiftSendControllerProvider(roomId).notifier)
                  .continueCombo(),
            ),
          ),
      ],
    );
  }
}
