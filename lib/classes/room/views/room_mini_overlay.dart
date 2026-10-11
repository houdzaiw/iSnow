import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../localization/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../viewmodel/room_session_view_model.dart';

class RoomMiniOverlay extends HookConsumerWidget {
  const RoomMiniOverlay({super.key, required this.router, required this.child});
  final GoRouter router;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(roomSessionViewModelProvider);
    final activePath = useState(router.routeInformationProvider.value.uri.path);
    useEffect(() {
      var disposed = false;
      var scheduled = false;
      void syncRoute() {
        if (scheduled) return;
        scheduled = true;
        // Router can notify while mounting below this root builder.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          scheduled = false;
          if (disposed || router.routerDelegate.currentConfiguration.isEmpty) {
            return;
          }
          activePath.value = router.state.uri.path;
        });
      }

      router.routerDelegate.addListener(syncRoute);
      syncRoute();
      return () {
        disposed = true;
        router.routerDelegate.removeListener(syncRoute);
      };
    }, [router]);
    final path = activePath.value;
    final publicPage =
        path == '/launch' ||
        path.startsWith('/login') ||
        path.startsWith('/register') ||
        path.startsWith('/agree-policy') ||
        path == '/agree_policy-view';
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (session.canShowMini && !publicPage && !path.startsWith('/room/'))
          _MiniRoom(
            key: ValueKey(session.room.currentRoomId),
            avatar: session.room.roomInfo?.avatar,
            busy: session.isBusy,
            onRestore: () {
              final viewModel = ref.read(roomSessionViewModelProvider.notifier);
              final roomId = viewModel.restoreRoom();
              if (roomId == null) return;
              try {
                unawaited(
                  router
                      .push<void>('/room/${Uri.encodeComponent(roomId)}')
                      .then(
                        (_) => viewModel.finishRestore(),
                        onError: (Object error, StackTrace stack) {
                          viewModel.finishRestore(
                            navigationFailed: true,
                            roomId: roomId,
                          );
                          debugPrint(
                            '[RoomSession] Restore navigation failed: $error',
                          );
                        },
                      ),
                );
              } catch (error) {
                viewModel.finishRestore(navigationFailed: true, roomId: roomId);
              }
            },
            onExit: () => ref
                .read(roomSessionViewModelProvider.notifier)
                .exitMinimizedRoom(),
          ),
      ],
    );
  }
}

class _MiniRoom extends HookWidget {
  const _MiniRoom({
    super.key,
    this.avatar,
    required this.busy,
    required this.onRestore,
    required this.onExit,
  });
  final String? avatar;
  final bool busy;
  final VoidCallback onRestore;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final position = useState<Offset?>(null);
    final dragging = useState(false);
    final lifecycle = useAppLifecycleState();
    final animation = useAnimationController(duration: AppMotion.roomMiniWave);
    useEffect(() {
      if (lifecycle == null || lifecycle == AppLifecycleState.resumed) {
        animation.repeat();
      } else {
        animation.stop();
      }
      return null;
    }, [lifecycle]);
    return LayoutBuilder(
      builder: (context, constraints) {
        final media = MediaQuery.of(context);
        final size = AppSpacing.roomMiniSize.r;
        final inset = AppSpacing.roomMiniEdgeInset.r;
        final left = media.padding.left + inset;
        final right = math.max(
          left,
          constraints.maxWidth - media.padding.right - inset - size,
        );
        final top = media.padding.top + inset;
        final bottom = math.max(
          top,
          constraints.maxHeight -
              math.max(
                media.padding.bottom + AppSpacing.roomMiniBottomInset.h,
                media.viewInsets.bottom + inset,
              ) -
              size,
        );
        Offset clamp(Offset value) =>
            Offset(value.dx.clamp(left, right), value.dy.clamp(top, bottom));
        final offset = clamp(position.value ?? Offset(right, bottom));
        return Stack(
          children: [
            AnimatedPositioned(
              duration: dragging.value ? Duration.zero : AppMotion.roomMiniSnap,
              curve: AppMotion.roomMiniSnapCurve,
              left: offset.dx,
              top: offset.dy,
              width: size,
              height: size,
              child: Material(
                color: AppColors.transparent,
                child: GestureDetector(
                  key: const ValueKey('room-mini-entry'),
                  onPanStart: busy ? null : (_) => dragging.value = true,
                  onPanUpdate: busy
                      ? null
                      : (event) => position.value = clamp(
                          (position.value ?? offset) + event.delta,
                        ),
                  onPanCancel: () => dragging.value = false,
                  onPanEnd: busy
                      ? null
                      : (_) {
                          final current = clamp(position.value ?? offset);
                          position.value = Offset(
                            current.dx < (left + right) / 2 ? left : right,
                            current.dy,
                          );
                          dragging.value = false;
                        },
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Semantics(
                          button: true,
                          label: context.l10n.t('room.restore'),
                          child: GestureDetector(
                            key: const ValueKey('room-mini-restore'),
                            behavior: HitTestBehavior.opaque,
                            onTap: busy ? null : onRestore,
                            child: AnimatedBuilder(
                              animation: animation,
                              builder: (context, child) => Stack(
                                alignment: Alignment.center,
                                children: [
                                  for (var index = 0; index < 2; index++)
                                    _Wave(
                                      progress:
                                          (animation.value + index / 2) % 1,
                                      size: size,
                                    ),
                                  child!,
                                ],
                              ),
                              child: ClipOval(
                                child: SizedBox.square(
                                  dimension: AppSpacing.roomMiniAvatarSize.r,
                                  child: (avatar?.isNotEmpty ?? false)
                                      ? CachedNetworkImage(
                                          imageUrl: avatar!,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) =>
                                              const _AvatarFallback(),
                                          errorWidget: (_, __, ___) =>
                                              const _AvatarFallback(),
                                        )
                                      : const _AvatarFallback(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Semantics(
                          button: true,
                          label: context.l10n.t('room.exit'),
                          child: GestureDetector(
                            key: const ValueKey('room-mini-exit'),
                            behavior: HitTestBehavior.opaque,
                            onTap: busy ? null : onExit,
                            child: Container(
                              width: AppSpacing.roomMiniCloseSize.r,
                              height: AppSpacing.roomMiniCloseSize.r,
                              decoration: const BoxDecoration(
                                color: AppColors.roomMiniSurface,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Image.asset(
                                AppAssets.roomMiniClose,
                                width: AppSpacing.roomMiniCloseIconSize.r,
                                height: AppSpacing.roomMiniCloseIconSize.r,
                                color: AppColors.textInverse,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Wave extends StatelessWidget {
  const _Wave({required this.progress, required this.size});
  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final avatarSize = AppSpacing.roomMiniAvatarSize.r;
    return IgnorePointer(
      child: Container(
        width: avatarSize + (size - avatarSize) * progress,
        height: avatarSize + (size - avatarSize) * progress,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.roomMiniWave.withValues(
              alpha: (1 - progress) * AppSpacing.roomMiniWaveMaxOpacity,
            ),
            width: AppSpacing.roomMiniWaveStroke.r,
          ),
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.roomMiniSurface,
    child: Image.asset(AppAssets.lanhuRoomIconMissing, fit: BoxFit.contain),
  );
}
