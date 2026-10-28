import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../theme/app_theme.dart';
import 'room_tools_controller.dart';
import 'room_tools_widgets.dart';

class RoomEffectSettingsContent extends ConsumerWidget {
  const RoomEffectSettingsContent({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = roomToolsControllerProvider(roomId);
    final state = ref.watch(provider);
    final vm = ref.read(provider.notifier);
    final values = {'all_effect': state.effects.all, ...state.effects.toJson()};
    final enabled =
        state.sessionActive &&
        state.preferencesReady &&
        !state.busy.contains('effects');
    final labels = {
      'all_effect': toolText(context, 'All animations', '全部动画'),
      'car_effect': toolText(context, 'Vehicle animation', '进场动画'),
      'gift_effect': toolText(context, 'Gift animation', '礼物动画'),
      'gift_big_effect': toolText(context, 'Full-screen gifts', '全屏礼物动画'),
      'sound_effect': toolText(context, 'Sound wave animation', '麦位声波'),
      'screen_top_effect': toolText(context, 'Floating screen effects', '房间横幅'),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!state.preferencesReady && state.error != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(state.error!, style: AppTextStyles.roomSettingsDescription),
              TextButton(
                onPressed:
                    !state.sessionActive || state.busy.contains('effects')
                    ? null
                    : vm.reloadEffectPreferences,
                child: Text(toolText(context, 'Retry', '重试')),
              ),
            ],
          ),
        if (!state.preferencesReady && state.error == null)
          const LinearProgressIndicator(),
        for (final entry in values.entries)
          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: AppSpacing.roomSettingsRowHeight.h,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md.h),
              child: Row(
                children: [
                  Expanded(
                    child: _SettingLabel(
                      title: labels[entry.key]!,
                      description:
                          entry.key == 'all_effect' &&
                              !entry.value &&
                              state.effects.toJson().values.any(
                                (v) => v == true,
                              )
                          ? toolText(context, 'Partially enabled', '部分开启')
                          : entry.value
                          ? toolText(context, 'Enabled', '已开启')
                          : toolText(context, 'Disabled', '已关闭'),
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm.w),
                  SizedBox(
                    width: AppSpacing.roomSettingsSwitchWidth.w,
                    height: AppSpacing.roomSettingsSwitchHeight.h,
                    child: Transform.scale(
                      scale: AppSpacing.roomSettingsSwitchScale,
                      child: Semantics(
                        label: labels[entry.key],
                        child: Theme(
                          data: AppTheme.roomSettingsSwitch(Theme.of(context)),
                          child: Switch(
                            key: ValueKey('room-effect-${entry.key}'),
                            value: entry.value,
                            activeTrackColor: AppColors.primaryPink,
                            inactiveTrackColor:
                                AppColors.roomToolsSwitchInactive,
                            thumbColor: const WidgetStatePropertyAll(
                              AppColors.roomToolsSheet,
                            ),
                            trackOutlineColor: const WidgetStatePropertyAll(
                              AppColors.transparent,
                            ),
                            onChanged: !enabled
                                ? null
                                : (value) async {
                                    final success = await vm.setEffect(
                                      entry.key,
                                      value,
                                    );
                                    if (!context.mounted || success) return;
                                    _showSettingsError(context, vm);
                                  },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class RoomCharmCurrencyContent extends ConsumerWidget {
  const RoomCharmCurrencyContent({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roomToolsControllerProvider(roomId));
    final vm = ref.read(roomToolsControllerProvider(roomId).notifier);
    if (!vm.canManage) return const SizedBox.shrink();
    final enabled = state.sessionActive && !state.busy.contains('currency');

    Future<void> select(int? value) async {
      if (!enabled || value == null) return;
      final success = await vm.setCurrency(value);
      if (!context.mounted || success) return;
      _showSettingsError(context, vm);
    }

    return RadioGroup<int>(
      groupValue: state.currency,
      onChanged: select,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (![1, 2].contains(state.currency))
            Text(
              toolText(
                context,
                'Select a currency to calculate charm.',
                '请选择魅力值统计币种。',
              ),
              style: AppTextStyles.roomSettingsDescription,
            ),
          for (final value in [1, 2])
            InkWell(
              key: ValueKey('room-currency-$value'),
              onTap: enabled ? () => select(value) : null,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: AppSpacing.roomSettingsRowHeight.h,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm.h),
                  child: Row(
                    children: [
                      SizedBox(
                        width: AppSpacing.roomSettingsRadioSize.r,
                        child: Radio<int>(
                          value: value,
                          enabled: enabled,
                          activeColor: AppColors.primaryPink,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      SizedBox(width: AppSpacing.xs.w),
                      Expanded(
                        child: _SettingLabel(
                          title: value == 1
                              ? toolText(context, 'Coins', '金币')
                              : toolText(context, 'Diamonds', '钻石'),
                          description: value == 1
                              ? toolText(
                                  context,
                                  'Charm is calculated from coins received as gifts.',
                                  '根据收到礼物的金币数量计算魅力值。',
                                )
                              : toolText(
                                  context,
                                  'Charm is calculated from diamonds received as gifts.',
                                  '根据收到礼物的钻石数量计算魅力值。',
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingLabel extends StatelessWidget {
  const _SettingLabel({required this.title, required this.description});
  final String title, description;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AppTextStyles.roomSettingsTitle),
      SizedBox(height: AppSpacing.xxs.h),
      Text(description, style: AppTextStyles.roomSettingsDescription),
    ],
  );
}

void _showSettingsError(BuildContext context, RoomToolsController vm) {
  if (!vm.active || vm.snapshot.error == null) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(vm.snapshot.error!)));
}
