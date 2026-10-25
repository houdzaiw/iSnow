import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../localization/app_localizations.dart';
import '../../../model/room_music_state.dart';
import '../../../theme/app_theme.dart';
import 'room_music_track.dart';
import 'room_music_view_model.dart';

/// Compact in-room controls. The playlist owns progress, time and stopping.
class RoomMusicControls extends StatelessWidget {
  const RoomMusicControls({
    super.key,
    required this.state,
    required this.viewModel,
    required this.onPlaylist,
  });
  final RoomMusicSheetState state;
  final RoomMusicViewModel viewModel;
  final VoidCallback onPlaylist;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = constraints.maxWidth / AppSpacing.musicBoxWidth;
      final music = state.playback;
      final enabled = !state.loading && !state.busy && !state.closing;
      final canPlay =
          enabled &&
          state.totalTracks > 0 &&
          music.status != RoomMusicPlayback.preparing;
      final title = music.title.isNotEmpty
          ? music.title
          : context.l10n.t('room.music.title');
      return Material(
        key: const ValueKey('room-music-box'),
        color: AppColors.musicBoxSurface,
        borderRadius: AppRadius.fieldBorder,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              top: AppSpacing.inlineActionGap * scale,
              right: AppSpacing.inlineActionGap * scale,
              child: RoomMusicImageButton(
                key: const ValueKey('room-music-close'),
                label: context.l10n.t('room.music.close'),
                asset: AppAssets.roomMusicClose,
                hitSize: AppSpacing.controlHeightXs * scale,
                iconSize: AppSpacing.iconSizeMd * scale,
                onTap: viewModel.close,
              ),
            ),
            Positioned(
              top: AppSpacing.musicBoxCollapseTop * scale,
              left: AppSpacing.md * scale,
              child: RoomMusicImageButton(
                key: const ValueKey('room-music-collapse'),
                label: context.l10n.t('room.music.collapse'),
                asset: AppAssets.roomMusicCollapse,
                hitSize: AppSpacing.controlHeightXs * scale,
                iconSize: AppSpacing.iconSizeMd * scale,
                onTap: viewModel.collapse,
              ),
            ),
            Positioned(
              left: AppSpacing.musicBoxTitleLeft * scale,
              top: AppSpacing.musicBoxTitleTop * scale,
              right: AppSpacing.musicBoxTitleRight * scale,
              child: Text(
                title,
                key: const ValueKey('room-music-title'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.musicBoxTitle,
              ),
            ),
            Positioned(
              left: AppSpacing.lg * scale,
              right: 0,
              top: AppSpacing.musicBoxControlsTop * scale,
              height: AppSpacing.musicBoxControlsHeight * scale,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  RoomMusicImageButton(
                    key: const ValueKey('room-music-mode'),
                    label: context.l10n.t('room.music.${state.mode.name}'),
                    asset: switch (state.mode) {
                      RoomMusicMode.loop => AppAssets.roomMusicLoop,
                      RoomMusicMode.single => AppAssets.roomMusicSingle,
                      RoomMusicMode.shuffle => AppAssets.roomMusicShuffle,
                    },
                    iconSize: AppSpacing.musicBoxIconSize * scale,
                    hitSize: AppSpacing.controlHeightMd * scale,
                    onTap: state.closing ? null : viewModel.cycleMode,
                  ),
                  RoomMusicImageButton(
                    label: context.l10n.t('room.music.previous'),
                    asset: AppAssets.roomMusicPrevious,
                    iconSize: AppSpacing.musicBoxIconSize * scale,
                    hitSize: AppSpacing.controlHeightMd * scale,
                    onTap: canPlay
                        ? () => viewModel.next(previous: true)
                        : null,
                  ),
                  SizedBox.square(
                    dimension: AppSpacing.controlHeightMd * scale,
                    child:
                        music.status == RoomMusicPlayback.preparing ||
                            state.busy
                        ? Center(
                            child: SizedBox.square(
                              dimension: AppSpacing.musicBoxPlaySize * scale,
                              child: const CircularProgressIndicator(
                                color: AppColors.textInverse,
                                strokeWidth: AppSpacing.xxs,
                              ),
                            ),
                          )
                        : RoomMusicImageButton(
                            key: const ValueKey('room-music-play'),
                            label: context.l10n.t(
                              music.status == RoomMusicPlayback.playing
                                  ? 'room.music.pause'
                                  : 'room.music.play',
                            ),
                            asset: music.status == RoomMusicPlayback.playing
                                ? AppAssets.roomMusicPause
                                : AppAssets.roomMusicPlay,
                            iconSize: AppSpacing.musicBoxPlaySize * scale,
                            hitSize: AppSpacing.controlHeightMd * scale,
                            onTap: canPlay ? viewModel.toggle : null,
                          ),
                  ),
                  RoomMusicImageButton(
                    label: context.l10n.t('room.music.next'),
                    asset: AppAssets.roomMusicNext,
                    iconSize: AppSpacing.musicBoxIconSize * scale,
                    hitSize: AppSpacing.controlHeightMd * scale,
                    onTap: canPlay ? viewModel.next : null,
                  ),
                  RoomMusicImageButton(
                    key: const ValueKey('room-music-playlist'),
                    label: context.l10n.t('room.music.playlist'),
                    asset: AppAssets.roomMusicPlaylist,
                    iconSize: AppSpacing.musicBoxIconSize * scale,
                    hitSize: AppSpacing.controlHeightMd * scale,
                    onTap: onPlaylist,
                  ),
                ],
              ),
            ),
            for (final system in [false, true])
              Positioned(
                left: AppSpacing.musicBoxVolumeLeft * scale,
                right: AppSpacing.xl * scale,
                top:
                    (system
                        ? AppSpacing.musicBoxSystemVolumeTop
                        : AppSpacing.musicBoxMusicVolumeTop) *
                    scale,
                height: AppSpacing.controlHeightSm * scale,
                child: _VolumeRow(
                  scale: scale,
                  system: system,
                  state: state,
                  viewModel: viewModel,
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _VolumeRow extends HookWidget {
  const _VolumeRow({
    required this.scale,
    required this.system,
    required this.state,
    required this.viewModel,
  });
  final double scale;
  final bool system;
  final RoomMusicSheetState state;
  final RoomMusicViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final drag = useState<double?>(null);
    final label = context.l10n.t(
      system ? 'room.music.systemVolume' : 'room.music.sharedVolume',
    );
    final enabled =
        !state.closing &&
        (!system || (state.systemVolume != null && !state.systemVolumeError));
    Future<void> change(double value) => system
        ? viewModel.systemVolume(value)
        : viewModel.volume((value * 100).round());
    return Row(
      children: [
        Tooltip(
          message: system && state.systemVolumeError
              ? context.l10n.t('room.music.systemVolumeUnavailable')
              : label,
          child: Image.asset(
            system
                ? AppAssets.roomMusicSystemVolume
                : AppAssets.roomMusicVolume,
            width: AppSpacing.musicBoxVolumeIconSize * scale,
            height: AppSpacing.musicBoxVolumeIconSize * scale,
          ),
        ),
        SizedBox(width: AppSpacing.inlineActionGap * scale),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: AppSpacing.musicSliderTrackHeight * scale,
              activeTrackColor: AppColors.textInverse,
              inactiveTrackColor: AppColors.musicSliderInactive,
              disabledActiveTrackColor: AppColors.musicSliderInactive,
              disabledInactiveTrackColor: AppColors.musicSliderInactive,
              thumbColor: AppColors.textInverse,
              overlayShape: SliderComponentShape.noOverlay,
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: AppSpacing.musicSliderThumbRadius * scale,
                disabledThumbRadius: AppSpacing.musicSliderThumbRadius * scale,
              ),
            ),
            child: Semantics(
              label: label,
              child: Slider(
                key: ValueKey(
                  system ? 'room-music-system-volume' : 'room-music-volume',
                ),
                padding: EdgeInsets.zero,
                value:
                    (drag.value ??
                            (system
                                ? state.systemVolume ?? 0
                                : state.playback.volume / 100))
                        .clamp(0, 1),
                onChanged: enabled
                    ? (value) {
                        drag.value = value;
                        change(value);
                      }
                    : null,
                onChangeEnd: enabled
                    ? (value) async {
                        await change(value);
                        if (context.mounted) drag.value = null;
                      }
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class RoomMusicImageButton extends StatelessWidget {
  const RoomMusicImageButton({
    super.key,
    required this.label,
    required this.asset,
    this.onTap,
    this.hitSize,
    this.iconSize,
  });
  final String label;
  final String asset;
  final VoidCallback? onTap;
  final double? hitSize;
  final double? iconSize;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Semantics(
      button: true,
      label: label,
      enabled: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: SizedBox.square(
          dimension: hitSize ?? AppSpacing.controlHeightMd.r,
          child: Center(
            child: Opacity(
              opacity: onTap == null ? AppSpacing.disabledControlOpacity : 1,
              child: Image.asset(
                asset,
                width: iconSize ?? AppSpacing.iconSizeMd.r,
                height: iconSize ?? AppSpacing.iconSizeMd.r,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
