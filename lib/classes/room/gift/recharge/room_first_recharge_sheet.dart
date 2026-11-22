import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import 'room_first_recharge_models.dart';
import 'room_first_recharge_view_model.dart';

Future<void> showRoomFirstRechargeSheet(BuildContext context, String roomId) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: RoomFirstRechargeTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: RoomFirstRechargeTheme.radius,
      ),
      builder: (_) => RoomFirstRechargeSheet(roomId: roomId),
    );

class RoomFirstRechargeSheet extends ConsumerWidget {
  const RoomFirstRechargeSheet({super.key, required this.roomId});
  final String roomId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = roomFirstRechargeProvider(roomId);
    final state = ref.watch(provider);
    final vm = ref.read(provider.notifier);
    ref.listen(provider.select((s) => s.active), (_, active) {
      if (active) return;
      final route = ModalRoute.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (route?.isActive == true) route?.navigator?.removeRoute(route);
      });
    });
    if (!state.active) {
      final route = ModalRoute.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (route?.isActive == true) route?.navigator?.removeRoute(route);
      });
      return const SizedBox.shrink();
    }
    return SafeArea(
      child: SizedBox(
        height:
            MediaQuery.sizeOf(context).height *
            RoomFirstRechargeTheme.maxHeightRatio,
        child: Padding(
          padding: EdgeInsets.all(RoomFirstRechargeTheme.padding.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.t('room.gift.firstRecharge'),
                      style: RoomFirstRechargeTheme.title,
                    ),
                  ),
                  Semantics(
                    label: context.l10n.t('app.back'),
                    button: true,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: Image.asset(
                        AppAssets.roomGiftEffectClose,
                        width: RoomFirstRechargeTheme.closeSize.r,
                        height: RoomFirstRechargeTheme.closeSize.r,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: RoomFirstRechargeTheme.gap.h),
              if (state.loading) const LinearProgressIndicator(),
              Expanded(
                child: ListView(
                  children: [
                    if (state.error != null) ...[
                      Text(
                        context.l10n.t(state.error!),
                        style: RoomFirstRechargeTheme.body,
                      ),
                      TextButton(
                        onPressed: state.loading || state.paying
                            ? null
                            : () => vm.load(),
                        child: Text(context.l10n.t('app.retry')),
                      ),
                    ],
                    if (!state.loading && !state.eligible)
                      Text(
                        context.l10n.t(
                          state.completed
                              ? 'wallet.paymentSuccess'
                              : 'room.gift.firstRechargeUnavailable',
                        ),
                        style: RoomFirstRechargeTheme.body,
                      ),
                    if (!state.loading &&
                        state.eligible &&
                        state.packs.isEmpty) ...[
                      Text(
                        context.l10n.t('room.gift.firstRechargeEmpty'),
                        style: RoomFirstRechargeTheme.body,
                      ),
                      TextButton(
                        onPressed: vm.load,
                        child: Text(context.l10n.t('app.retry')),
                      ),
                    ],

                    for (final pack in state.packs) ...[
                      _PackCard(
                        pack: pack,
                        selected: pack.id == state.selectedId,
                        onTap: () => vm.select(pack.id),
                      ),
                      SizedBox(height: RoomFirstRechargeTheme.gap.h),
                    ],
                  ],
                ),
              ),
              SizedBox(height: RoomFirstRechargeTheme.gap.h),
              SizedBox(
                height: RoomFirstRechargeTheme.actionHeight.h,
                child: ElevatedButton(
                  onPressed: state.canBuy ? vm.buy : null,
                  child: Text(
                    state.paying
                        ? context.l10n.t('wallet.purchasePending')
                        : state.selected == null
                        ? context.l10n.t('room.gift.firstRecharge')
                        : state.selected!.price,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  const _PackCard({
    required this.pack,
    required this.selected,
    required this.onTap,
  });
  final RoomFirstRechargePack pack;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.all(RoomFirstRechargeTheme.padding.r),
      decoration: BoxDecoration(
        color: RoomFirstRechargeTheme.card,
        borderRadius: RoomFirstRechargeTheme.cardRadius,
        border: Border.all(
          color: selected
              ? RoomFirstRechargeTheme.accent
              : RoomFirstRechargeTheme.card,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pack.name.isEmpty
                ? context.l10n.t('room.gift.firstRecharge')
                : pack.name,
            style: RoomFirstRechargeTheme.title,
          ),
          SizedBox(height: RoomFirstRechargeTheme.smallGap.h),
          Text(
            '${pack.coin} ${context.l10n.t('room.gift.coins')} · ${pack.price}',
            style: RoomFirstRechargeTheme.amount,
          ),
          if (pack.originalPrice > pack.dollarAmount)
            Text(
              'USD ${(pack.originalPrice / 100).toStringAsFixed(2)}',
              style: RoomFirstRechargeTheme.originalPrice,
            ),
          if (!pack.isBuy)
            Text(
              context.l10n.t('room.gift.firstRechargePurchased'),
              style: RoomFirstRechargeTheme.body,
            ),
          if (pack.rewards.isNotEmpty) ...[
            SizedBox(height: RoomFirstRechargeTheme.gap.h),
            Wrap(
              spacing: RoomFirstRechargeTheme.gap.w,
              runSpacing: RoomFirstRechargeTheme.gap.h,
              children: [
                for (final reward in pack.rewards)
                  SizedBox(
                    width: RoomFirstRechargeTheme.rewardSize.w * 2,
                    child: Column(
                      children: [
                        if (reward.icon.trim().isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: reward.icon,
                            width: RoomFirstRechargeTheme.rewardSize.r,
                            height: RoomFirstRechargeTheme.rewardSize.r,
                            errorWidget: (_, __, ___) =>
                                Image.asset(AppAssets.lanhuRoomIconMissing),
                          )
                        else
                          Image.asset(
                            AppAssets.lanhuRoomIconMissing,
                            width: RoomFirstRechargeTheme.rewardSize.r,
                            height: RoomFirstRechargeTheme.rewardSize.r,
                          ),
                        Text(
                          reward.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: RoomFirstRechargeTheme.body,
                        ),
                        if (reward.amount > 0)
                          Text(
                            '×${reward.amount}',
                            style: RoomFirstRechargeTheme.body,
                          ),
                        if (reward.days > 0)
                          Text(
                            context.l10n.t('room.gift.rewardDays', {
                              'days': '${reward.days}',
                            }),
                            style: RoomFirstRechargeTheme.body,
                          ),
                        if (reward.permanent)
                          Text(
                            context.l10n.t('room.gift.rewardPermanent'),
                            style: RoomFirstRechargeTheme.body,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}
