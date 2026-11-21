import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../theme/app_theme.dart';
import '../more/room_tools_controller.dart';
import '../more/room_tools_widgets.dart';
import '../viewmodel/room_session_view_model.dart';
import 'room_barrage_banner.dart';
import 'room_barrage_navigation.dart';
import 'room_barrage_provider.dart';
import 'room_barrage_view_model.dart';

class RoomBarrageHost extends HookConsumerWidget {
  const RoomBarrageHost({
    super.key,
    required this.router,
    required this.child,
    this.navigator,
  });
  final GoRouter router;
  final Widget child;
  final RoomBarrageNavigator? navigator;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roomBarrageProvider);
    final vm = ref.read(roomBarrageProvider.notifier);
    final room = ref.watch(roomSessionViewModelProvider).room;
    final path = useState(router.routeInformationProvider.value.uri.path);
    final live = useRef(true);
    useEffect(() {
      live.value = true;
      void changed() {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (live.value && context.mounted) {
            path.value = router.routeInformationProvider.value.uri.path;
          }
        });
      }

      router.routeInformationProvider.addListener(changed);
      return () {
        live.value = false;
        router.routeInformationProvider.removeListener(changed);
      };
    }, [router]);
    final public =
        path.value == '/launch' ||
        path.value.startsWith('/login') ||
        path.value.startsWith('/register') ||
        path.value.startsWith('/agree');
    final lifecycle = useState(WidgetsBinding.instance.lifecycleState);
    useOnAppLifecycleStateChange((_, next) => lifecycle.value = next);
    final visible =
        !public &&
        (lifecycle.value == null ||
            lifecycle.value == AppLifecycleState.resumed);
    useEffect(() {
      Future.microtask(() {
        if (vm.mounted) vm.setVisible(visible);
      });
      return null;
    }, [vm, visible]);
    final tools = room.isInRoom && room.currentRoomId != null
        ? ref.watch(
            roomToolsControllerProvider(
              room.currentRoomId!,
            ).select((state) => (state.effects, state.config)),
          )
        : null;
    useEffect(() {
      Future.microtask(() {
        if (vm.mounted && tools != null) {
          vm.updateSettings(tools.$1, functions: tools.$2);
        }
      });
      return null;
    }, [vm, tools]);
    final navigation =
        navigator ??
        RoomBarrageNavigation(
          () => live.value
              ? router
                    .routerDelegate
                    .navigatorKey
                    .currentState
                    ?.overlay
                    ?.context
              : null,
          ref,
        );
    ref.listen(roomBarrageProvider.select((state) => state.issue), (_, issue) {
      if (issue == null || !context.mounted) return;
      final target =
          router.routerDelegate.navigatorKey.currentState?.overlay?.context;
      if (target != null) {
        ScaffoldMessenger.maybeOf(target)?.showSnackBar(
          SnackBar(
            content: Text(
              issue == 'room.barrage.playbackUnavailable'
                  ? toolText(
                      context,
                      'Animation unavailable. Please restart the app.',
                      '动画暂不可用，请重启应用。',
                    )
                  : issue,
            ),
          ),
        );
      }
    });
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (visible && state.visible && state.active != null)
          Positioned(
            top: MediaQuery.paddingOf(context).top + RoomBarrageTheme.top.h,
            left: MediaQuery.paddingOf(context).left + RoomBarrageTheme.edge.w,
            right:
                MediaQuery.paddingOf(context).right + RoomBarrageTheme.edge.w,
            child: RoomBarrageBanner(
              key: ValueKey((state.uid, state.epoch, state.active!.task.key)),
              prepared: state.active!,
              busy: state.actionBusy,
              onPresented: () =>
                  vm.presented(state.active!.task.key, epoch: state.epoch),
              onEnd: () =>
                  vm.complete(state.active!.task.key, epoch: state.epoch),
              onFailure: (error) => vm.blockPlayback(
                state.active!.task.key,
                error,
                epoch: state.epoch,
              ),
              onTap: () => vm.activate(state.active!.task, navigation),
            ),
          ),
      ],
    );
  }
}
