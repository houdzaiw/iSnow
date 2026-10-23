import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../localization/app_localizations.dart';
import '../../../theme/app_theme.dart';
import 'room_music_controls.dart';

class RoomMusicPanel extends StatelessWidget {
  const RoomMusicPanel({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final available = math.max(
      0.0,
      media.size.height - media.viewInsets.bottom - media.padding.vertical,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: math.min(
            AppSpacing.musicSheetHeight.h,
            available * AppSpacing.musicSheetMaxHeightRatio,
          ),
          child: child,
        ),
      ),
    );
  }
}

class RoomMusicSearchField extends HookWidget {
  const RoomMusicSearchField({super.key, required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final text = useValueListenable(controller);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl.w,
        vertical: AppSpacing.xs.h,
      ),
      child: SizedBox(
        height: AppSpacing.controlHeightMd.h,
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: AppTextStyles.roomAudienceName,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => FocusScope.of(context).unfocus(),
          decoration: InputDecoration(
            hintText: context.l10n.t('room.music.search'),
            hintStyle: AppTextStyles.roomMoreHint,
            filled: true,
            fillColor: AppColors.roomMusicStripSurface,
            contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
            border: const OutlineInputBorder(
              borderRadius: AppRadius.fieldBorder,
              borderSide: BorderSide.none,
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.all(AppSpacing.lg.r),
              child: Image.asset(
                AppAssets.roomMusicSearch,
                width: AppSpacing.iconSizeSm.r,
                height: AppSpacing.iconSizeSm.r,
              ),
            ),
            suffixIcon: text.text.isEmpty
                ? null
                : RoomMusicImageButton(
                    label: context.l10n.t('room.music.clearSearch'),
                    asset: AppAssets.lanhuCloseCircle,
                    onTap: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

String roomMusicDuration(int milliseconds) {
  final seconds = math.max(0, milliseconds) ~/ 1000;
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}
