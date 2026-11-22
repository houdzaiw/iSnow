import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../localization/app_localizations.dart';
import '../../../model/room_recovery_notice.dart';
import '../../../theme/room_recovery_theme.dart';
import 'room_recovery_navigation.dart';
import 'room_recovery_view_model.dart';

/// Root-level notice remains available after a terminal exit closes RoomPage.
class RoomRecoveryHost extends HookConsumerWidget {
  const RoomRecoveryHost({
    super.key,
    required this.router,
    required this.child,
  });
  final GoRouter router;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roomRecoveryProvider);
    final vm = ref.read(roomRecoveryProvider.notifier);
    final navigation = useMemoized(
      () => RoomRecoveryNavigation(
        () => context.mounted
            ? router.routerDelegate.navigatorKey.currentState?.overlay?.context
            : null,
        ref,
      ),
      [router],
    );
    final notice = state.notice;
    final reason = switch (notice?.reason) {
      RoomDisconnectReason.authenticationTimeout => 'room.recovery.authTimeout',
      RoomDisconnectReason.audioClosed => 'room.recovery.audioClosed',
      _ => 'room.recovery.socketClosed',
    };
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (notice != null && !state.prompt)
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  RoomRecoveryTheme.edge.w,
                  RoomRecoveryTheme.edge.h,
                  RoomRecoveryTheme.edge.w,
                  MediaQuery.viewInsetsOf(context).bottom +
                      RoomRecoveryTheme.edge.h,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: RoomRecoveryTheme.maxWidth.w,
                    ),
                    child: Material(
                      key: const ValueKey('room-recovery-notice'),
                      color: RoomRecoveryTheme.surface,
                      borderRadius: RoomRecoveryTheme.border,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: RoomRecoveryTheme.surface,
                          borderRadius: RoomRecoveryTheme.border,
                          boxShadow: RoomRecoveryTheme.shadows,
                        ),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(RoomRecoveryTheme.padding.r),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                context.l10n.t('room.recovery.title'),
                                style: RoomRecoveryTheme.title,
                              ),
                              SizedBox(height: RoomRecoveryTheme.gap.h),
                              Text(
                                context.l10n.t(reason),
                                style: RoomRecoveryTheme.body,
                              ),
                              if (state.issue != null) ...[
                                SizedBox(height: RoomRecoveryTheme.gap.h),
                                Text(
                                  context.l10n.t(state.issue!),
                                  style: RoomRecoveryTheme.body,
                                ),
                              ],
                              SizedBox(height: RoomRecoveryTheme.gap.h),
                              ElevatedButton(
                                key: const ValueKey('room-recovery-reenter'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: RoomRecoveryTheme.accent,
                                  minimumSize: Size(
                                    0,
                                    RoomRecoveryTheme.buttonHeight.h,
                                  ),
                                ),
                                onPressed: state.busy
                                    ? null
                                    : () => vm.retry(navigation),
                                child: Text(
                                  context.l10n.t(
                                    state.busy
                                        ? 'room.recovery.checking'
                                        : 'room.recovery.reenter',
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: vm.dismiss,
                                child: Text(
                                  context.l10n.t('room.recovery.later'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
