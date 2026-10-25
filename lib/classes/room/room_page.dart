import 'package:cached_network_image/cached_network_image.dart';
import 'package:extended_tabs/extended_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../localization/app_localizations.dart';
import '../../manager/room_manager.dart';
import '../../theme/app_theme.dart';
import 'gift/models/room_gift_models.dart';
import 'gift/views/room_gift_sheet.dart';
import 'gift/views/room_gift_overlay.dart';
import 'gift/views/room_gift_slot_layer.dart';
import 'gift/views/room_gift_public_screen_item.dart';
import 'gift/event/room_gift_event_provider.dart';
import 'gift/trajectory/room_gift_seat_registry.dart';
import 'models/room_more_tools_models.dart';
import 'music/room_music_overlay.dart';
import 'music/room_music_view_model.dart';
import 'music/room_music_takeover_listener.dart';
import 'online/room_audience_avatar.dart';
import 'online/room_audience_sheet.dart';
import 'viewmodel/room_state.dart';
import 'viewmodel/room_more_tools_view_model.dart';
import 'viewmodel/room_view_model.dart';
import 'views/room_chat_clear_dialog.dart';
import 'views/room_exit_dialog.dart';
import 'more/room_tools_controller.dart';
import 'more/room_tools_widgets.dart';
import 'more/room_tools_strip.dart';
import 'more/room_settings_page.dart';
import 'more/room_report_page.dart';
import 'more/room_share_page.dart';
import 'more/room_pk_page.dart';
import 'more/room_lucky_box_page.dart';
import 'more/room_lobby_page.dart';
import 'more/room_game_page.dart';
import 'more/room_mic_wave.dart';
import 'more/room_vehicle_layer.dart';

part 'views/room_bottom_bar.dart';
part 'views/room_chat_panel.dart';
part 'views/room_header.dart';
part 'views/room_mic_grid.dart';
part 'views/room_music_strip.dart';
part 'views/room_more_tools_sheet.dart';

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
    final viewModel = ref.read(provider.notifier);
    final isExiting = useState(false);
    final exitDialog = useRef<DialogRoute<RoomExitAction>?>(null);
    final closingPage = useRef(false);
    final hadRoom = useRef(state.isInRoom);
    final pageRoute = ModalRoute.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final giftRoomId = state.currentRoomId.trim().isNotEmpty
        ? state.currentRoomId.trim()
        : roomId;
    final messageController = useTextEditingController();
    final giftRootKey = useMemoized(() => GlobalKey(), [giftRoomId]);
    final musicAnchorKey = useMemoized(() => GlobalKey(), [giftRoomId]);
    final bottomBarKey = useMemoized(() => GlobalKey(), [giftRoomId]);
    listenRoomMusicTakeover(context, ref, giftRoomId);
    ref.listen(roomMusicViewModelProvider(giftRoomId), (previous, next) {
      if (next.error != null &&
          next.error != previous?.error &&
          !next.takeover &&
          pageRoute?.isCurrent == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });
    final giftRegistry = useMemoized(() => RoomGiftSeatRegistry(giftRootKey), [
      giftRoomId,
    ]);
    final giftSlots = ref.watch(
      roomGiftEventManagerProvider(giftRoomId).select((value) => value.slots),
    );
    final moreFeatures = ref.watch(roomToolsControllerProvider(giftRoomId));
    ref.listen(
      roomToolsControllerProvider(
        giftRoomId,
      ).select((value) => value.luckyMessages),
      (_, messages) {
        viewModel.bindLuckyMessages(messages);
      },
    );
    ref.listen(
      roomToolsControllerProvider(giftRoomId).select((value) => value.error),
      (previous, next) {
        if (next != null && next != previous && pageRoute?.isCurrent == true) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(next)));
        }
      },
    );
    ref.listen(
      roomToolsControllerProvider(giftRoomId).select((value) => value.effects),
      (_, effects) {
        ref
            .read(roomGiftEventManagerProvider(giftRoomId).notifier)
            .setEffects(effects);
      },
    );
    useEffect(() {
      Future.microtask(() {
        if (!context.mounted) return;
        final manager = ref.read(
          roomGiftEventManagerProvider(giftRoomId).notifier,
        );
        if (manager.isAlive) manager.setEffects(moreFeatures.effects);
        if (viewModel.mounted) {
          viewModel.clearToolsPublicMessages = () => ref
              .read(roomToolsControllerProvider(giftRoomId).notifier)
              .clearLuckyPublicMessages();
          viewModel.bindLuckyMessages(
            ref.read(roomToolsControllerProvider(giftRoomId)).luckyMessages,
          );
        }
      });
      return null;
    }, [giftRoomId]);

    useEffect(() {
      Future.microtask(() {
        if (viewModel.mounted) {
          viewModel.enterRoom(roomPassword: roomPassword, followUid: followUid);
        }
      });
      return null;
    }, [roomId, roomPassword, followUid]);

    void dismissRoomModals() {
      if (pageRoute == null || !pageRoute.isActive) return;
      final path = GoRouter.of(context).state.uri.path;
      if (path != '/room/${Uri.encodeComponent(roomId)}') {
        final dialog = exitDialog.value;
        if (dialog != null && dialog.isActive) {
          rootNavigator.removeRoute(dialog);
        }
        exitDialog.value = null;
        return;
      }
      rootNavigator.popUntil((route) => identical(route, pageRoute));
      exitDialog.value = null;
    }

    void closePage() {
      if (!context.mounted ||
          closingPage.value ||
          pageRoute?.isActive != true) {
        return;
      }
      closingPage.value = true;
      dismissRoomModals();
      if (!pageRoute!.isCurrent) {
        // Room routes are outside ShellRoute. Preserve newer pushed pages when
        // the old room terminates; page-based routes cannot use removeRoute.
        final router = GoRouter.of(context);
        final configuration = router.routerDelegate.currentConfiguration;
        final page = pageRoute.settings;
        if (page is Page) {
          final matches = configuration.matches
              .where((match) => match.pageKey != page.key)
              .toList();
          if (matches.length != configuration.matches.length &&
              matches.isNotEmpty) {
            for (final match in configuration.matches) {
              if (match.pageKey == page.key && match is ImperativeRouteMatch) {
                match.complete(null);
              }
            }
            router.restore(
              RouteMatchList(
                matches: matches,
                uri: configuration.uri,
                pathParameters: configuration.pathParameters,
                extra: configuration.extra,
              ),
            );
          }
        }
        return;
      }
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/party');
      }
    }

    Future<void> showExitChoices() async {
      if (isExiting.value || closingPage.value || exitDialog.value != null) {
        return;
      }
      final dialog = DialogRoute<RoomExitAction>(
        context: context,
        barrierColor: AppColors.roomExitScrim,
        builder: (_) => const RoomExitDialog(),
      );
      exitDialog.value = dialog;
      final action = await rootNavigator.push(dialog);
      if (identical(exitDialog.value, dialog)) exitDialog.value = null;
      if (!context.mounted || closingPage.value || !viewModel.mounted) return;
      if (action == RoomExitAction.keep) {
        if (viewModel.minimizeRoom()) closePage();
      } else if (action == RoomExitAction.exit) {
        isExiting.value = true;
        final didLeave = await viewModel.leaveRoom();
        if (!context.mounted) return;
        if (didLeave) {
          closePage();
        } else {
          isExiting.value = false;
        }
      }
    }

    ref.listen<RoomPageState>(provider, (previous, next) {
      if (!next.isOnMic || next.isMinimized) {
        ref.read(roomMusicViewModelProvider(giftRoomId).notifier).collapse();
      }
      if (next.isInRoom) hadRoom.value = true;
      if (hadRoom.value &&
          (next.status == RoomStatus.leaving || !next.isInRoom)) {
        // A kick/logout/switch wins over an open Keep dialog or gift sheet.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted || closingPage.value) return;
          dismissRoomModals();
          if (!next.isInRoom && !isExiting.value) closePage();
        });
      }
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
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) showExitChoices();
        },
        child: Scaffold(
          // The composer/list routes handle their own keyboard insets. Keep the
          // fixed mic grid from overflowing behind those routes.
          resizeToAvoidBottomInset: false,
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
                child: RoomGiftSeatScope(
                  registry: giftRegistry,
                  child: Stack(
                    key: giftRootKey,
                    children: [
                      Column(
                        children: [
                          _RoomHeader(
                            state: state,
                            onFollowRoom: viewModel.followRoom,
                            onMinimize: () {
                              if (isExiting.value) return;
                              if (viewModel.minimizeRoom()) closePage();
                            },
                            onExit: showExitChoices,
                          ),
                          _RoomMicGrid(
                            seats: state.seats,
                            wavesEnabled: moreFeatures.effects.sound,
                            currency: moreFeatures.currency,
                            charmEnabled: moreFeatures.charmEnabled,
                            onCharmTap: (seat) {
                              if (seat.uid != null && state.isReady) {
                                pushRoomTool(
                                  context,
                                  RoomCharmRankPage(
                                    roomId: giftRoomId,
                                    targetUid: seat.uid!,
                                  ),
                                );
                              }
                            },
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
                          _RoomMusicStrip(
                            musicAnchorKey: musicAnchorKey,
                            state: state,
                            onMusicTap: () => _openRoomMusic(
                              context,
                              ref,
                              ref.read(provider),
                            ),
                            onAudienceTap: () async {
                              final roomId = state.currentRoomId;
                              final uid = await showRoomAudienceSheet(
                                context,
                                roomId,
                              );
                              if (uid == null || !context.mounted) return;
                              final current = ref.read(provider);
                              if (!current.isReady ||
                                  current.currentRoomId != roomId) {
                                return;
                              }
                              context.push('/profile-homepage/$uid');
                            },
                          ),
                          RoomToolsStrip(roomId: giftRoomId),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) => Column(
                                children: [
                                  if (giftSlots.any((slot) => slot != null))
                                    SizedBox(
                                      height:
                                          ((AppSpacing.giftSlotHeight +
                                                      AppSpacing.xs) *
                                                  2)
                                              .h
                                              .clamp(
                                                0,
                                                constraints.maxHeight *
                                                    AppSpacing
                                                        .giftSlotAreaMaxRatio,
                                              ),
                                      child: SingleChildScrollView(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: AppSpacing.lg.w,
                                          ),
                                          child: RoomGiftSlotLayer(
                                            slots: giftSlots,
                                            roomId: giftRoomId,
                                          ),
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: _RoomChatPanel(
                                      state: state,
                                      onClearMessages: () async {
                                        final current = ref.read(provider);
                                        if (!current.isReady ||
                                            !current.isOwnerOrManager ||
                                            current.clearingMessages) {
                                          return;
                                        }
                                        final confirmed =
                                            await showRoomChatClearDialog(
                                              context,
                                            );
                                        if (confirmed != true ||
                                            !context.mounted ||
                                            !viewModel.mounted ||
                                            !identical(
                                              ref.read(provider).enterResponse,
                                              current.enterResponse,
                                            )) {
                                          return;
                                        }
                                        await viewModel.clearMessages();
                                      },
                                      onFilterChanged: (filter) => ref
                                          .read(provider.notifier)
                                          .setChatFilter(filter),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _RoomBottomBar(
                            key: bottomBarKey,
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
                            onToggleSpeaker: () => ref
                                .read(
                                  roomToolsControllerProvider(
                                    giftRoomId,
                                  ).notifier,
                                )
                                .toggleVoice(),
                            onGiftTap: () => _showRoomGiftPanel(context, state),
                            onMoreTap: () =>
                                _showRoomMoreToolsSheet(context, ref, provider),
                          ),
                        ],
                      ),
                      RoomMusicOverlay(
                        roomId: giftRoomId,
                        rootKey: giftRootKey,
                        anchorKey: musicAnchorKey,
                        bottomBarKey: bottomBarKey,
                      ),
                      Positioned.fill(
                        child: RoomGiftOverlay(
                          roomId: giftRoomId,
                          registry: giftRegistry,
                        ),
                      ),
                      Positioned.fill(
                        child: RoomVehicleLayer(roomId: giftRoomId),
                      ),
                      if (state.isLoading) const _RoomLoadingOverlay(),
                    ],
                  ),
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

Future<void> _showRoomGiftPanel(
  BuildContext context,
  RoomPageState state,
) async {
  final roomId = state.currentRoomId.trim().isNotEmpty
      ? state.currentRoomId.trim()
      : state.roomId.trim();
  if (roomId.isEmpty) return;

  final recipients = state.seats
      .where((seat) => seat.isOccupied && seat.uid != null)
      .map(
        (seat) => RoomGiftRecipient(
          uid: seat.uid!,
          nickname: seat.nickname?.trim().isNotEmpty == true
              ? seat.nickname!.trim()
              : '${seat.uid}',
          avatar: seat.avatar,
          seatPosition: seat.position,
        ),
      )
      .toList(growable: false);
  final result = await showRoomGiftSheet(
    context: context,
    roomId: roomId,
    onlineCount: state.onlineCount,
    currentUid: state.currentUid,
    recipients: recipients,
  );
  if (!context.mounted || result == null) return;
  if (result == RoomGiftSheetResult.openWallet) {
    context.push('/wallet');
  }
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
        label: context.l10n.t('room.checkProfile'),
        onTap: () => _openSeatUserProfile(context, seat),
      ),
    );
  }

  if (seat.isOccupied) {
    if (isMine) {
      actions.add(
        _SeatAction(
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
        label: context.l10n.t(seat.isMuted ? 'room.unmuteMic' : 'room.muteMic'),
        onTap: () => notifier.setSeatMuted(seat, !seat.isMuted),
      ),
      _SeatAction(
        label: context.l10n.t('room.kickDownMic'),
        destructive: true,
        onTap: () => notifier.kickDownMic(seat),
      ),
      _SeatAction(
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
          label: context.l10n.t('room.takeMic'),
          onTap: () => notifier.upMic(seat.position),
        ),
      );
    }
    return actions;
  }

  actions.addAll([
    _SeatAction(
      label: context.l10n.t('room.takeMic'),
      onTap: () => notifier.upMic(seat.position),
    ),
    _SeatAction(
      label: context.l10n.t(seat.isMuted ? 'room.unmuteMic' : 'room.muteMic'),
      onTap: () => notifier.setSeatMuted(seat, !seat.isMuted),
    ),
    _SeatAction(
      label: context.l10n.t(seat.isLocked ? 'room.unlockMic' : 'room.lockMic'),
      onTap: () => notifier.setSeatLocked(seat, !seat.isLocked),
    ),
  ]);
  return actions;
}

class _SeatAction {
  const _SeatAction({
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool destructive;
}

class _SeatActionTile extends StatelessWidget {
  const _SeatActionTile({
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.danger : AppColors.textInverse;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: AppSpacing.controlHeightLg.h,
        width: double.infinity,
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.roomAction.copyWith(color: color),
          ),
        ),
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
