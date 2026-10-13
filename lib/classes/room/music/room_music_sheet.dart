import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../localization/app_localizations.dart';
import '../../../theme/app_theme.dart';
import 'room_music_controls.dart';
import 'room_music_view_model.dart';

Future<void> showRoomMusicSheet(BuildContext context, String roomId) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppColors.roomMoreSheet,
      barrierColor: AppColors.modalScrimStrong,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetBorder),
      builder: (_) => RoomMusicSheet(roomId: roomId),
    );

class RoomMusicSheet extends ConsumerWidget {
  const RoomMusicSheet({super.key, required this.roomId});
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = roomMusicViewModelProvider(roomId);
    final state = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);
    ref.listen(provider, (previous, next) async {
      if (!next.takeover || previous?.takeover == true) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.roomMoreSheet,
          title: Text(
            context.l10n.t('room.music.takeover'),
            style: AppTextStyles.roomMoreSectionTitle,
          ),
          content: Text(
            next.error ?? '',
            style: AppTextStyles.roomAudienceName,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.l10n.t('app.cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.l10n.t('room.music.takeover')),
            ),
          ],
        ),
      );
      if (context.mounted && viewModel.mounted) {
        await viewModel.confirmTakeover(confirm == true);
      }
    });
    return SafeArea(
      top: false,
      child: SizedBox(
        key: const ValueKey('room-music-sheet'),
        width: double.infinity,
        height: math.min(
          AppSpacing.musicSheetHeight.h,
          MediaQuery.sizeOf(context).height *
              AppSpacing.musicSheetMaxHeightRatio,
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.t('room.music.title'),
                      style: AppTextStyles.roomMoreSectionTitle,
                    ),
                  ),
                  TextButton(
                    key: const ValueKey('room-music-add'),
                    onPressed: state.busy || state.loading
                        ? null
                        : viewModel.add,
                    child: Text(context.l10n.t('room.music.add')),
                  ),
                  RoomMusicImageButton(
                    label: context.l10n.t('app.cancel'),
                    asset: AppAssets.lanhuCloseCircle,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            if (state.loading || state.busy)
              const LinearProgressIndicator(color: AppColors.primaryPink),
            if (state.error != null && !state.takeover)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
                child: Text(
                  state.error!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.roomMoreHint.copyWith(
                    color: AppColors.danger,
                  ),
                ),
              ),
            Expanded(
              child: state.tracks.isEmpty
                  ? Center(
                      child: Text(
                        state.loading ? '' : context.l10n.t('room.music.empty'),
                        style: AppTextStyles.roomMoreHint,
                      ),
                    )
                  : ListView.builder(
                      itemCount: state.tracks.length,
                      itemBuilder: (context, index) {
                        final track = state.tracks[index];
                        final selected =
                            state.playback.path?.endsWith(
                              '/${track.fileName}',
                            ) ==
                            true;
                        return InkWell(
                          key: ValueKey('room-music-track-${track.id}'),
                          onTap: state.busy
                              ? null
                              : () => viewModel.play(track),
                          child: Container(
                            height: AppSpacing.musicTrackHeight.h,
                            color: selected
                                ? AppColors.roomMusicStripSurface
                                : AppColors.transparent,
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl.w,
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  AppAssets.lanhuRoomMusicIcon,
                                  width: AppSpacing.iconSizeMd.r,
                                  height: AppSpacing.iconSizeMd.r,
                                ),
                                SizedBox(width: AppSpacing.lg.w),
                                Expanded(
                                  child: Text(
                                    track.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.roomAudienceName
                                        .copyWith(
                                          color: selected
                                              ? AppColors.primaryPink
                                              : AppColors.textInverse,
                                        ),
                                  ),
                                ),
                                RoomMusicImageButton(
                                  label: context.l10n.t('room.music.delete'),
                                  asset: AppAssets.roomMusicDelete,
                                  onTap: state.busy
                                      ? null
                                      : () => viewModel.remove(track),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            RoomMusicControls(state: state, viewModel: viewModel),
          ],
        ),
      ),
    );
  }
}
