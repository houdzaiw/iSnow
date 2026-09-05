import 'package:cached_network_image/cached_network_image.dart';
import 'package:extended_tabs/extended_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../localization/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'viewmodel/room_state.dart';
import 'viewmodel/room_view_model.dart';

part 'views/room_bottom_bar.dart';
part 'views/room_chat_panel.dart';
part 'views/room_header.dart';
part 'views/room_mic_grid.dart';

const Color _roomGold = Color(0xFFFFD86B);
const Color _roomPink = Color(0xFFFF4FA0);

class RoomPage extends HookConsumerWidget {
  const RoomPage({
    super.key,
    required this.roomId,
    this.roomPassword = '',
    this.followUid = 0,
  });

  final String roomId;
  final String roomPassword;
  final int followUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = roomViewModelProvider(roomId);
    final state = ref.watch(provider);
    final messageController = useTextEditingController();

    useEffect(() {
      Future.microtask(() {
        ref
            .read(provider.notifier)
            .enterRoom(roomPassword: roomPassword, followUid: followUid);
      });
      return null;
    }, [roomId, roomPassword, followUid]);

    ref.listen<RoomPageState>(provider, (previous, next) {
      final message = next.errorMessage;
      if (message == null || message == previous?.errorMessage) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF555563),
      ),
      child: PopScope<void>(
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) {
            ref.read(provider.notifier).minimizeRoom();
          }
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: const Color(0xFF1D0B34),
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1D0B34), Color(0xFF11174A)],
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF5E5E5E).withValues(alpha: 0.72),
              ),
              child: SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        _RoomHeader(
                          state: state,
                          onMinimize: () {
                            ref.read(provider.notifier).minimizeRoom();
                            context.pop();
                          },
                          onExit: () async {
                            await ref.read(provider.notifier).leaveRoom();
                            if (context.mounted && context.canPop()) {
                              context.pop();
                            }
                          },
                        ),
                        SizedBox(
                          height: 380.h,
                          child: _RoomMicGrid(
                            seats: state.seats,
                            currentUid: state.currentUid,
                            pendingSeatPosition: state.pendingSeatPosition,
                            onSeatTap: (seat) =>
                                _handleSeatTap(context, ref, provider, seat),
                            onSeatLongPress: (seat) => _handleSeatLongPress(
                              context,
                              ref,
                              provider,
                              seat,
                            ),
                          ),
                        ),
                        _RoomMusicStrip(state: state),
                        Expanded(
                          child: _RoomChatPanel(
                            state: state,
                            onFilterChanged: (filter) => ref
                                .read(provider.notifier)
                                .setChatFilter(filter),
                          ),
                        ),
                        _RoomBottomBar(
                          state: state,
                          onChatTap: () => _showRoomComposer(
                            context,
                            ref,
                            provider,
                            messageController,
                          ),
                          onToggleMic: () => ref
                              .read(provider.notifier)
                              .toggleLocalMicrophone(),
                          onToggleSpeaker: () =>
                              ref.read(provider.notifier).toggleSpeaker(),
                        ),
                      ],
                    ),
                    if (state.isLoading) const _RoomLoadingOverlay(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomLoadingOverlay extends StatelessWidget {
  const _RoomLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.18),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: _roomGold),
          ),
        ),
      ),
    );
  }
}

void _handleSeatTap(
  BuildContext context,
  WidgetRef ref,
  AutoDisposeStateNotifierProvider<RoomViewModel, RoomPageState> provider,
  RoomSeatViewData seat,
) {
  final state = ref.read(provider);
  if (state.pendingSeatPosition != null) return;

  final isMine = _isCurrentUserSeat(state, seat);
  if (seat.isOccupied) {
    if (isMine || state.isOwnerOrManager) {
      _showSeatActions(context, ref, provider, seat);
      return;
    }
    _openSeatUserProfile(context, seat);
    return;
  }

  if (state.isOwnerOrManager) {
    _showSeatActions(context, ref, provider, seat);
    return;
  }

  if (!seat.isLocked) {
    ref.read(provider.notifier).upMic(seat.position);
  }
}

void _handleSeatLongPress(
  BuildContext context,
  WidgetRef ref,
  AutoDisposeStateNotifierProvider<RoomViewModel, RoomPageState> provider,
  RoomSeatViewData seat,
) {
  final state = ref.read(provider);
  if (state.pendingSeatPosition != null) return;

  if (_isCurrentUserSeat(state, seat) || state.isOwnerOrManager) {
    _showSeatActions(context, ref, provider, seat);
    return;
  }

  if (seat.isOccupied) {
    _openSeatUserProfile(context, seat);
  }
}

bool _isCurrentUserSeat(RoomPageState state, RoomSeatViewData seat) {
  final uid = state.currentUid;
  return uid != null && uid > 0 && seat.uid == uid;
}

void _openSeatUserProfile(BuildContext context, RoomSeatViewData seat) {
  final uid = seat.uid;
  if (uid == null || uid <= 0) return;
  context.push('/profile-homepage/$uid');
}

void _showRoomComposer(
  BuildContext context,
  WidgetRef ref,
  AutoDisposeStateNotifierProvider<RoomViewModel, RoomPageState> provider,
  TextEditingController controller,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: 14.w,
          right: 14.w,
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 12.h,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF252532),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 8.w, 12.h),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    minLines: 1,
                    maxLines: 3,
                    maxLength: 120,
                    style: TextStyle(color: Colors.white, fontSize: 15.sp),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'Say something...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 15.sp,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Material(
                  color: _roomPink,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () async {
                      final text = controller.text;
                      if (text.trim().isEmpty) return;
                      await ref.read(provider.notifier).sendMessage(text);
                      controller.clear();
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                    },
                    child: SizedBox(
                      width: 44.r,
                      height: 44.r,
                      child: Center(
                        child: _RoomAssetIcon(
                          asset: AppAssets.lanhuRoomIconMissing,
                          size: 24.r,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void _showSeatActions(
  BuildContext context,
  WidgetRef ref,
  AutoDisposeStateNotifierProvider<RoomViewModel, RoomPageState> provider,
  RoomSeatViewData seat,
) {
  final state = ref.read(provider);
  final actions = _seatActionsFor(context, ref, provider, seat, state);
  if (actions.isEmpty) return;

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Container(
          margin: EdgeInsets.fromLTRB(
            AppSpacing.roomActionSheetHorizontalMargin.w,
            0,
            AppSpacing.roomActionSheetHorizontalMargin.w,
            AppSpacing.roomActionSheetBottomMargin.h,
          ),
          decoration: BoxDecoration(
            color: AppColors.roomActionSheet,
            borderRadius: BorderRadius.circular(AppRadius.roomActionSheet.r),
            border: Border.all(color: AppColors.roomActionSheetBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final action in actions)
                _SeatActionTile(
                  asset: action.asset,
                  label: action.label,
                  destructive: action.destructive,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    action.onTap();
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}

List<_SeatAction> _seatActionsFor(
  BuildContext context,
  WidgetRef ref,
  AutoDisposeStateNotifierProvider<RoomViewModel, RoomPageState> provider,
  RoomSeatViewData seat,
  RoomPageState state,
) {
  final notifier = ref.read(provider.notifier);
  final isMine = _isCurrentUserSeat(state, seat);
  final canManage = state.isOwnerOrManager;
  final actions = <_SeatAction>[];

  void addProfileAction() {
    actions.add(
      _SeatAction(
        asset: AppAssets.lanhuRoomIconMissing,
        label: context.l10n.t('room.checkProfile'),
        onTap: () => _openSeatUserProfile(context, seat),
      ),
    );
  }

  if (seat.isOccupied) {
    if (isMine) {
      actions.add(
        _SeatAction(
          asset: AppAssets.lanhuRoomIconMissing,
          label: context.l10n.t('room.leaveMic'),
          onTap: () => notifier.downMic(seat.position),
        ),
      );
      addProfileAction();
      return actions;
    }

    addProfileAction();
    if (!canManage) return actions;

    actions.addAll([
      _SeatAction(
        asset: AppAssets.lanhuRoomIconMissing,
        label: context.l10n.t(seat.isMuted ? 'room.unmuteMic' : 'room.muteMic'),
        onTap: () => notifier.setSeatMuted(seat, !seat.isMuted),
      ),
      _SeatAction(
        asset: AppAssets.lanhuRoomIconMissing,
        label: context.l10n.t('room.kickDownMic'),
        destructive: true,
        onTap: () => notifier.kickDownMic(seat),
      ),
      _SeatAction(
        asset: AppAssets.lanhuRoomIconMissing,
        label: context.l10n.t(
          seat.isLocked ? 'room.unlockMic' : 'room.lockMic',
        ),
        onTap: () => notifier.setSeatLocked(seat, !seat.isLocked),
      ),
    ]);
    return actions;
  }

  if (!canManage) {
    if (!seat.isLocked) {
      actions.add(
        _SeatAction(
          asset: AppAssets.lanhuRoomMicSeat,
          label: context.l10n.t('room.takeMic'),
          onTap: () => notifier.upMic(seat.position),
        ),
      );
    }
    return actions;
  }

  actions.addAll([
    _SeatAction(
      asset: AppAssets.lanhuRoomMicSeat,
      label: context.l10n.t('room.takeMic'),
      onTap: () => notifier.upMic(seat.position),
    ),
    _SeatAction(
      asset: AppAssets.lanhuRoomIconMissing,
      label: context.l10n.t(seat.isMuted ? 'room.unmuteMic' : 'room.muteMic'),
      onTap: () => notifier.setSeatMuted(seat, !seat.isMuted),
    ),
    _SeatAction(
      asset: AppAssets.lanhuRoomIconMissing,
      label: context.l10n.t(seat.isLocked ? 'room.unlockMic' : 'room.lockMic'),
      onTap: () => notifier.setSeatLocked(seat, !seat.isLocked),
    ),
  ]);
  return actions;
}

class _SeatAction {
  const _SeatAction({
    required this.asset,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final String asset;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
}

class _SeatActionTile extends StatelessWidget {
  const _SeatActionTile({
    required this.asset,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final String asset;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.danger : AppColors.textInverse;
    return ListTile(
      onTap: onTap,
      leading: _RoomAssetIcon(
        asset: asset,
        size: AppSpacing.roomActionIconSize.r,
      ),
      title: Text(
        label,
        style: AppTextStyles.roomAction.copyWith(color: color),
      ),
    );
  }
}

class _RoomAssetIcon extends StatelessWidget {
  const _RoomAssetIcon({required this.asset, required this.size});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) {
        if (asset == AppAssets.lanhuRoomIconMissing) {
          return SizedBox(width: size, height: size);
        }
        return Image.asset(
          AppAssets.lanhuRoomIconMissing,
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        );
      },
    );
  }
}
