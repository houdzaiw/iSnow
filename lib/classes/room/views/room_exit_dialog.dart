import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../localization/app_localizations.dart';
import '../../../theme/app_theme.dart';

enum RoomExitAction { keep, exit }

class RoomExitDialog extends StatelessWidget {
  const RoomExitDialog({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Material(
      color: AppColors.transparent,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.xl.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Choice(
              action: RoomExitAction.keep,
              asset: AppAssets.roomExitKeep,
              label: context.l10n.t('room.keep'),
            ),
            SizedBox(height: AppSpacing.roomExitChoiceGap.h),
            _Choice(
              action: RoomExitAction.exit,
              asset: AppAssets.roomExitClose,
              label: context.l10n.t('room.exit'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.action,
    required this.asset,
    required this.label,
  });
  final RoomExitAction action;
  final String asset;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      key: ValueKey('room-exit-${action.name}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(action),
      child: SizedBox(
        width: AppSpacing.roomExitChoiceSize.r,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              asset,
              width: AppSpacing.roomExitChoiceSize.r,
              height: AppSpacing.roomExitChoiceSize.r,
              errorBuilder: (_, __, ___) =>
                  Image.asset(AppAssets.lanhuRoomIconMissing),
            ),
            SizedBox(height: AppSpacing.sm.h),
            Text(label, style: AppTextStyles.roomExitLabel),
          ],
        ),
      ),
    ),
  );
}
