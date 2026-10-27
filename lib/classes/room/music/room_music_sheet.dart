import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../localization/app_localizations.dart';
import '../../../theme/app_theme.dart';
import 'room_music_controls.dart';
import 'room_music_playlist_footer.dart';
import 'room_music_takeover_listener.dart';
import 'room_music_view_model.dart';
import 'room_local_music_sheet.dart';
import 'room_music_widgets.dart';

Future<void> showRoomMusicSheet(BuildContext context, String roomId) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: double.infinity),
    backgroundColor: AppColors.roomMoreSheet,
    barrierColor: AppColors.modalScrimStrong,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetBorder),
    builder: (_) => RoomMusicSheet(roomId: roomId),
  );
}

class RoomMusicSheet extends HookConsumerWidget {
  const RoomMusicSheet({super.key, required this.roomId});
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = roomMusicViewModelProvider(roomId);
    final state = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);
    useEffect(() {
      unawaited(Future<void>.microtask(viewModel.initialize));
      return null;
    }, [viewModel]);
    listenRoomMusicTakeover(context, ref, roomId);
    return RoomMusicPanel(
      key: const ValueKey('room-music-sheet'),
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
                  onPressed: state.busy || state.loading || state.closing
                      ? null
                      : () {
                          FocusScope.of(context).unfocus();
                          if (viewModel.supportsLocalScan) {
                            showRoomLocalMusicSheet(context, roomId);
                          } else {
                            viewModel.add();
                          }
                        },
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
          RoomMusicSearchField(onChanged: viewModel.search),
          if (state.loading || state.busy)
            const LinearProgressIndicator(color: AppColors.primaryPink),
          if ((state.error != null || state.noticeKey != null) &&
              !state.takeover)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
              child: Text(
                state.error ?? context.l10n.t(state.noticeKey!),
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
                      state.loading
                          ? ''
                          : context.l10n.t(
                              state.query.trim().isEmpty
                                  ? 'room.music.empty'
                                  : 'room.music.noMatches',
                            ),
                      style: AppTextStyles.roomMoreHint,
                    ),
                  )
                : ListView.builder(
                    itemCount: state.tracks.length,
                    itemBuilder: (context, index) {
                      final track = state.tracks[index];
                      final selected =
                          state.playback.path?.endsWith('/${track.fileName}') ==
                          true;
                      return InkWell(
                        key: ValueKey('room-music-track-${track.id}'),
                        onTap: state.busy || state.closing
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
                              if (track.duration > 0)
                                Text(
                                  roomMusicDuration(track.duration),
                                  style: AppTextStyles.roomMoreHint,
                                ),
                              RoomMusicImageButton(
                                label: context.l10n.t('room.music.delete'),
                                asset: AppAssets.roomMusicDelete,
                                color: AppColors.textInverse,
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
          if (MediaQuery.viewInsetsOf(context).bottom == 0)
            RoomMusicPlaylistFooter(state: state, viewModel: viewModel),
        ],
      ),
    );
  }
}
