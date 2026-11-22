import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../more/room_entry_flow.dart';
import 'room_recovery_view_model.dart';

class RoomRecoveryNavigation implements RoomRecoveryNavigator {
  RoomRecoveryNavigation(this.rootContext, this.ref);
  final BuildContext? Function() rootContext;
  final WidgetRef ref;
  final _routes = <Route<dynamic>>{};

  @override
  Future<bool> enterRoom(
    String roomId,
    bool Function() isCurrent,
    VoidCallback onPrompt,
  ) async {
    final context = rootContext();
    if (context == null || !context.mounted || !isCurrent()) return false;
    try {
      return await enterSharedRoomChecked(
        context,
        ref,
        roomId,
        isCurrent: isCurrent,
        onOwnedRoute: (route) {
          _routes.add(route);
          onPrompt();
        },
      );
    } finally {
      _routes.removeWhere((route) => !route.isActive);
    }
  }

  @override
  void cancelPending() {
    final routes = _routes.toList();
    _routes.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final route in routes) {
        if (route.isActive) route.navigator?.removeRoute(route);
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }
}
