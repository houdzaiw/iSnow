import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../localization/app_localizations.dart';
import '../../../theme/app_theme.dart';
import 'room_music_controls.dart';
import 'room_music_view_model.dart';
import 'room_music_widgets.dart';

class RoomMusicPlaylistFooter extends HookWidget {
  const RoomMusicPlaylistFooter({
    super.key,
    required this.state,
    required this.viewModel,
  });
  final RoomMusicSheetState state;
  final RoomMusicViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final seek = useState<double?>(null);
    final music = state.playback;
    final maximum = music.duration > 0 ? music.duration.toDouble() : 1.0;
    final enabled =
        !state.busy && !state.closing && music.isActive && music.duration > 0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            key: const ValueKey('room-music-progress'),
            activeColor: AppColors.primaryPink,
            max: maximum,
            value: (seek.value ?? music.position.toDouble()).clamp(0, maximum),
            onChanged: enabled ? (value) => seek.value = value : null,
            onChangeEnd: enabled
                ? (value) async {
                    await viewModel.seek(value.toInt());
                    if (context.mounted) seek.value = null;
                  }
                : null,
          ),
          Row(
            children: [
              Text(
                roomMusicDuration(music.position),
                style: AppTextStyles.roomMoreHint,
              ),
              const Spacer(),
              Text(
                roomMusicDuration(music.duration),
                style: AppTextStyles.roomMoreHint,
              ),
              RoomMusicImageButton(
                key: const ValueKey('room-music-stop'),
                label: context.l10n.t('room.music.stop'),
                asset: AppAssets.roomMusicStop,
                onTap: state.closing || (music.path == null && !state.busy)
                    ? null
                    : viewModel.stop,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
