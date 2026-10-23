import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../localization/app_localizations.dart';
import '../../../theme/app_theme.dart';
import 'room_local_music_track.dart';
import 'room_local_music_view_model.dart';
import 'room_music_controls.dart';
import 'room_music_widgets.dart';

Future<void> showRoomLocalMusicSheet(BuildContext context, String roomId) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: double.infinity),
      backgroundColor: AppColors.roomMoreSheet,
      barrierColor: AppColors.modalScrimStrong,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetBorder),
      builder: (_) => RoomLocalMusicSheet(roomId: roomId),
    );

class RoomLocalMusicSheet extends HookConsumerWidget {
  const RoomLocalMusicSheet({super.key, required this.roomId});
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = roomLocalMusicViewModelProvider(roomId);
    final state = ref.watch(provider);
    final model = ref.read(provider.notifier);
    useEffect(() {
      final listener = AppLifecycleListener(onResume: model.onResumed);
      return listener.dispose;
    }, [model]);
    ref.listen(provider, (previous, next) {
      if (next.completed && previous?.completed != true && context.mounted) {
        Navigator.of(context).pop();
      }
    });
    final tracks = state.visibleTracks;
    return RoomMusicPanel(
      key: const ValueKey('room-local-music-sheet'),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.t('room.music.localTitle'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.roomMoreSectionTitle,
                  ),
                ),
                TextButton(
                  key: const ValueKey('room-local-music-scan'),
                  onPressed: state.scanning || state.importing
                      ? null
                      : () => model.scan(requestPermission: true),
                  child: Text(context.l10n.t('room.music.scan')),
                ),
                RoomMusicImageButton(
                  label: context.l10n.t('app.cancel'),
                  asset: AppAssets.lanhuCloseCircle,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          RoomMusicSearchField(onChanged: model.search),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.t('room.music.selected', {
                      'count': '${state.selectedIds.length}',
                    }),
                    style: AppTextStyles.roomMoreHint,
                  ),
                ),
                TextButton(
                  key: const ValueKey('room-local-music-files'),
                  onPressed: state.importing || state.scanning
                      ? null
                      : model.importFiles,
                  child: Text(context.l10n.t('room.music.importFiles')),
                ),
              ],
            ),
          ),
          if (state.importing)
            const LinearProgressIndicator(color: AppColors.primaryPink),
          if (state.errorKey != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
              child: Text(
                context.l10n.t(state.errorKey!, {
                  'count': '${state.failedCount}',
                }),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.roomMoreHint.copyWith(
                  color: AppColors.danger,
                ),
              ),
            ),
          Expanded(
            child: state.scanning
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: AppColors.primaryPink,
                        ),
                        SizedBox(height: AppSpacing.lg.h),
                        Text(
                          context.l10n.t('room.music.scanning'),
                          style: AppTextStyles.roomAudienceName,
                        ),
                      ],
                    ),
                  )
                : state.errorKey == 'room.music.scanFailed'
                ? _MusicStatus(
                    message: context.l10n.t('room.music.scanFailed'),
                    action: context.l10n.t('app.retry'),
                    onTap: () => model.scan(requestPermission: true),
                  )
                : state.permission != RoomMusicPermission.granted
                ? _MusicStatus(
                    message: context.l10n.t('room.music.permissionDenied'),
                    action: context.l10n.t(
                      state.permission == RoomMusicPermission.permanentlyDenied
                          ? 'room.music.settings'
                          : 'room.music.allowAccess',
                    ),
                    onTap:
                        state.permission ==
                            RoomMusicPermission.permanentlyDenied
                        ? model.openSettings
                        : () => model.scan(requestPermission: true),
                  )
                : tracks.isEmpty
                ? _MusicStatus(
                    message: context.l10n.t(
                      state.query.trim().isEmpty
                          ? 'room.music.localEmpty'
                          : 'room.music.noMatches',
                    ),
                  )
                : ListView.builder(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: tracks.length,
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      final selected = state.selectedIds.contains(track.id);
                      return Semantics(
                        checked: selected,
                        child: InkWell(
                          key: ValueKey('room-local-track-${track.id}'),
                          onTap: state.importing
                              ? null
                              : () => model.select(track.id),
                          child: Container(
                            color: selected
                                ? AppColors.roomMusicStripSurface
                                : AppColors.transparent,
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl.w,
                              vertical: AppSpacing.sm.h,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        track.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.roomAudienceName,
                                      ),
                                      SizedBox(height: AppSpacing.xs.h),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              track.location,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTextStyles.roomMoreHint,
                                            ),
                                          ),
                                          SizedBox(width: AppSpacing.sm.w),
                                          Text(
                                            roomMusicDuration(track.duration),
                                            style: AppTextStyles.roomMoreHint,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Checkbox(
                                  value: selected,
                                  activeColor: AppColors.primaryPink,
                                  checkColor: AppColors.textInverse,
                                  side: const BorderSide(
                                    color: AppColors.roomMoreToolSubtle,
                                  ),
                                  onChanged: state.importing
                                      ? null
                                      : (_) => model.select(track.id),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: EdgeInsets.all(AppSpacing.xl.r),
            child: SizedBox(
              width: double.infinity,
              height: AppSpacing.controlHeightMd.h,
              child: FilledButton(
                key: const ValueKey('room-local-music-add'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  foregroundColor: AppColors.textInverse,
                  textStyle: AppTextStyles.roomAudienceName,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.fieldBorder,
                  ),
                ),
                onPressed:
                    state.selectedIds.isEmpty ||
                        state.importing ||
                        state.scanning
                    ? null
                    : model.addSelected,
                child: Text(
                  context.l10n.t(
                    state.importing
                        ? 'room.music.importing'
                        : 'room.music.addToPlayer',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MusicStatus extends StatelessWidget {
  const _MusicStatus({required this.message, this.action, this.onTap});
  final String message;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.xl.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.roomMoreHint,
          ),
          if (action != null)
            TextButton(onPressed: onTap, child: Text(action!)),
        ],
      ),
    ),
  );
}
