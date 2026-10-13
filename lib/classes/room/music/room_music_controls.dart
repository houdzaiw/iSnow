import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../localization/app_localizations.dart';
import '../../../model/room_music_state.dart';
import '../../../theme/app_theme.dart';
import 'room_music_track.dart';
import 'room_music_view_model.dart';

class RoomMusicControls extends HookWidget {
  const RoomMusicControls({
    super.key,
    required this.state,
    required this.viewModel,
  });
  final RoomMusicSheetState state;
  final RoomMusicViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final music = state.playback;
    final seek = useState<double?>(null);
    final volume = useState<double?>(null);
    final enabled = !state.loading && !state.busy;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            music.title,
            key: const ValueKey('room-music-title'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.roomAudienceName,
          ),
          Slider(
            key: const ValueKey('room-music-progress'),
            activeColor: AppColors.primaryPink,
            max: music.duration > 0 ? music.duration.toDouble() : 1,
            value: (seek.value ?? music.position.toDouble()).clamp(
              0,
              music.duration > 0 ? music.duration.toDouble() : 1,
            ),
            onChanged: enabled && music.isActive && music.duration > 0
                ? (value) => seek.value = value
                : null,
            onChangeEnd: (value) async {
              await viewModel.seek(value.toInt());
              if (context.mounted) seek.value = null;
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_time(music.position), style: AppTextStyles.roomMoreHint),
              Text(_time(music.duration), style: AppTextStyles.roomMoreHint),
            ],
          ),
          SizedBox(
            height: AppSpacing.musicTransportHeight.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                RoomMusicImageButton(
                  label: context.l10n.t('room.music.previous'),
                  asset: AppAssets.roomMusicPrevious,
                  onTap: enabled && state.tracks.isNotEmpty
                      ? () => viewModel.next(previous: true)
                      : null,
                ),
                RoomMusicImageButton(
                  key: const ValueKey('room-music-play'),
                  label: context.l10n.t(
                    music.status == RoomMusicPlayback.playing
                        ? 'room.music.pause'
                        : 'room.music.play',
                  ),
                  asset: music.status == RoomMusicPlayback.playing
                      ? AppAssets.roomMusicPause
                      : AppAssets.roomMusicPlay,
                  onTap:
                      enabled &&
                          state.tracks.isNotEmpty &&
                          music.status != RoomMusicPlayback.preparing
                      ? viewModel.toggle
                      : null,
                ),
                RoomMusicImageButton(
                  label: context.l10n.t('room.music.next'),
                  asset: AppAssets.roomMusicNext,
                  onTap: enabled && state.tracks.isNotEmpty
                      ? viewModel.next
                      : null,
                ),
                RoomMusicImageButton(
                  key: const ValueKey('room-music-stop'),
                  label: context.l10n.t('room.music.stop'),
                  asset: AppAssets.roomMusicStop,
                  onTap: enabled && music.path != null ? viewModel.stop : null,
                ),
              ],
            ),
          ),
          SegmentedButton<RoomMusicMode>(
            showSelectedIcon: false,
            segments: [
              for (final mode in RoomMusicMode.values)
                ButtonSegment(
                  value: mode,
                  label: Text(
                    context.l10n.t('room.music.${mode.name}'),
                    style: AppTextStyles.roomMoreHint,
                  ),
                ),
            ],
            selected: {state.mode},
            onSelectionChanged: enabled
                ? (selection) => viewModel.changeMode(selection.single)
                : null,
          ),
          Row(
            children: [
              Tooltip(
                message: context.l10n.t('room.music.volume'),
                child: Image.asset(
                  AppAssets.roomMusicVolume,
                  width: AppSpacing.iconSizeMd.r,
                  height: AppSpacing.iconSizeMd.r,
                ),
              ),
              Expanded(
                child: Slider(
                  key: const ValueKey('room-music-volume'),
                  activeColor: AppColors.primaryPink,
                  max: 100,
                  value: volume.value ?? music.volume.toDouble(),
                  onChanged: enabled ? (value) => volume.value = value : null,
                  onChangeEnd: (value) async {
                    await viewModel.volume(value.toInt());
                    if (context.mounted) volume.value = null;
                  },
                ),
              ),
              Text(
                '${(volume.value ?? music.volume).toInt()}%',
                style: AppTextStyles.roomMoreHint,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _time(int milliseconds) {
    final seconds = milliseconds ~/ 1000;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }
}

class RoomMusicImageButton extends StatelessWidget {
  const RoomMusicImageButton({
    super.key,
    required this.label,
    required this.asset,
    this.onTap,
  });
  final String label;
  final String asset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Semantics(
      button: true,
      label: label,
      enabled: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: AppSpacing.controlHeightMd.r,
          height: AppSpacing.controlHeightMd.r,
          child: Center(
            child: Image.asset(
              asset,
              width: AppSpacing.iconSizeMd.r,
              height: AppSpacing.iconSizeMd.r,
            ),
          ),
        ),
      ),
    ),
  );
}
