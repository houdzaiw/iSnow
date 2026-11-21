import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../theme/app_theme.dart';
import '../gift/views/room_gift_image.dart';
import '../more/room_entry_flow.dart';
import '../more/room_game_page.dart';
import '../more/room_tool_navigation.dart';
import '../more/room_tools_widgets.dart';
import 'room_barrage_models.dart';
import 'room_barrage_provider.dart';
import 'room_barrage_view_model.dart';

/// Navigation adapter only. Permissions, sequence and session checks live in VM.
class RoomBarrageNavigation implements RoomBarrageNavigator {
  RoomBarrageNavigation(this.rootContext, this.ref);
  final BuildContext? Function() rootContext;
  final WidgetRef ref;
  final _ownedRoutes = <Route<dynamic>>{};
  @override
  void cancelPending() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final route in _ownedRoutes.toList()) {
        if (route.isActive) route.navigator?.removeRoute(route);
      }
      _ownedRoutes.clear();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  BuildContext? _context(bool Function() valid) {
    final context = rootContext();
    return context != null && context.mounted && valid() ? context : null;
  }

  @override
  Future<bool> enterRoom(String id, bool Function() valid) async {
    final context = _context(valid);
    return context != null &&
        await enterSharedRoomChecked(
          context,
          ref,
          id,
          isCurrent: valid,
          onOwnedRoute: _ownedRoutes.add,
        );
  }

  @override
  Future<void> profile(int uid, bool Function() valid) async {
    final context = _context(valid);
    if (context != null) {
      unawaited(context.push<void>('/profile-homepage/$uid'));
    }
  }

  @override
  Future<void> gift(String roomId, int giftId, bool Function() valid) async {
    await WidgetsBinding.instance.endOfFrame;
    final context = _context(valid);
    if (context != null && context.mounted) {
      await openRoomToolGift(context, ref, roomId, giftId: giftId);
    }
  }

  @override
  Future<void> game(String roomId, Uri url, bool Function() valid) async {
    await WidgetsBinding.instance.endOfFrame;
    final context = _context(valid);
    if (context != null && context.mounted) {
      await openRoomGame(context, ref, roomId, url.toString(), '');
    }
  }

  @override
  Future<void> web(Uri url, bool Function() valid) async {
    final context = _context(valid);
    if (context == null) return;
    final language = Localizations.localeOf(context).languageCode;
    final target = url.replace(
      queryParameters: {...url.queryParametersAll, 'language': language},
    );
    unawaited(
      context.push<void>(
        Uri(
          path: '/web-view',
          queryParameters: {'uri': target.toString()},
        ).toString(),
      ),
    );
  }

  @override
  Future<void> prize(RoomBarragePrize prize, bool Function() valid) async {
    final context = _context(valid);
    if (context == null) return;
    final route = DialogRoute<void>(
      context: context,
      builder: (context) => _OwnedPrize(valid: valid, prize: prize),
    );
    _ownedRoutes.add(route);
    try {
      await Navigator.of(context, rootNavigator: true).push(route);
    } finally {
      _ownedRoutes.remove(route);
    }
  }
}

class _OwnedPrize extends ConsumerWidget {
  const _OwnedPrize({required this.valid, required this.prize});
  final bool Function() valid;
  final RoomBarragePrize prize;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = ModalRoute.of(context);
    void dismissIfStale() {
      if (!context.mounted || valid() || route?.isActive != true) return;
      final navigator = route!.navigator;
      if (navigator != null) navigator.removeRoute(route);
    }

    ref.listen(roomBarrageProvider.select((state) => state.revision), (_, __) {
      WidgetsBinding.instance.addPostFrameCallback((_) => dismissIfStale());
    });
    if (!valid()) {
      WidgetsBinding.instance.addPostFrameCallback((_) => dismissIfStale());
    }
    return AlertDialog(
      backgroundColor: RoomBarrageTheme.background,
      title: Text(
        toolText(context, 'Game Big Win', '游戏大奖'),
        style: RoomBarrageTheme.title,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (prize.icon.isNotEmpty)
            RoomGiftImage(
              source: prize.icon,
              size: RoomBarrageTheme.prizeImage.r,
            ),
          if (prize.gameName.isNotEmpty)
            Text(prize.gameName, style: RoomBarrageTheme.title),
          if (prize.amount > 0)
            Text('${prize.amount}', style: AppTextStyles.giftLuckyAmount),
          if (prize.pool > 0)
            Text(
              '${toolText(context, 'Prize pool', '奖池')} · ${prize.pool}',
              style: RoomBarrageTheme.detail,
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            toolText(context, 'Close', '关闭'),
            style: RoomBarrageTheme.detail,
          ),
        ),
      ],
    );
  }
}
