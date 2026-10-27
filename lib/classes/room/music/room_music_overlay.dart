import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../theme/app_theme.dart';
import 'room_music_controls.dart';
import 'room_music_sheet.dart';
import 'room_music_view_model.dart';

/// A positioned child only, not a route or modal barrier. Outside taps pass through.
class RoomMusicOverlay extends ConsumerWidget {
  const RoomMusicOverlay({
    super.key,
    required this.roomId,
    required this.rootKey,
    required this.bottomBarKey,
  });
  final String roomId;
  final GlobalKey rootKey;
  final GlobalKey bottomBarKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roomMusicViewModelProvider(roomId));
    if (!state.expanded) return const SizedBox.shrink();
    return Positioned.fill(
      child: CustomSingleChildLayout(
        delegate: _MusicBoxLayout(
          rootKey: rootKey,
          bottomBarKey: bottomBarKey,
          width: AppSpacing.musicBoxWidth.w,
          edge: AppSpacing.musicBoxEdge.w,
          padding: MediaQuery.paddingOf(context),
          keyboardInset: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: RoomMusicControls(
          state: state,
          viewModel: ref.read(roomMusicViewModelProvider(roomId).notifier),
          onPlaylist: () => showRoomMusicSheet(context, roomId),
        ),
      ),
    );
  }
}

class _MusicBoxLayout extends SingleChildLayoutDelegate {
  _MusicBoxLayout({
    required this.rootKey,
    required this.bottomBarKey,
    required this.width,
    required this.edge,
    required this.padding,
    required this.keyboardInset,
  });
  final GlobalKey rootKey;
  final GlobalKey bottomBarKey;
  final double width;
  final double edge;
  final EdgeInsets padding;
  final double keyboardInset;

  double? _top(GlobalKey key) {
    final root = rootKey.currentContext?.findRenderObject();
    final target = key.currentContext?.findRenderObject();
    if (root is! RenderBox || target is! RenderBox || !target.hasSize) {
      return null;
    }
    return target.localToGlobal(Offset.zero, ancestor: root).dy;
  }

  Rect _visibleBounds(Size size) {
    final left = padding.left.clamp(0.0, size.width);
    final top = padding.top.clamp(0.0, size.height);
    return Rect.fromLTRB(
      left,
      top,
      math.max(left, size.width - padding.right),
      math.max(top, size.height - math.max(padding.bottom, keyboardInset)),
    );
  }

  Rect _availableBounds(Size size) {
    final visible = _visibleBounds(size);
    final bottom = (_top(bottomBarKey) ?? visible.bottom).clamp(
      visible.top,
      visible.bottom,
    );
    final horizontalInset = math.min(edge, visible.width / 2);
    final verticalInset = math.min(edge, (bottom - visible.top) / 2);
    return Rect.fromLTRB(
      visible.left + horizontalInset,
      visible.top + verticalInset,
      visible.right - horizontalInset,
      bottom - verticalInset,
    );
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final available = _availableBounds(constraints.biggest);
    final ratio = AppSpacing.musicBoxWidth / AppSpacing.musicBoxHeight;
    final boxWidth = math.min(
      width,
      math.min(available.width, available.height * ratio),
    );
    return BoxConstraints.tight(Size(boxWidth, boxWidth / ratio));
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final visible = _visibleBounds(size);
    final available = _availableBounds(size);
    return Offset(
      (visible.center.dx - childSize.width / 2).clamp(
        available.left,
        math.max(available.left, available.right - childSize.width),
      ),
      (visible.center.dy - childSize.height / 2).clamp(
        available.top,
        math.max(available.top, available.bottom - childSize.height),
      ),
    );
  }

  @override
  bool shouldRelayout(covariant _MusicBoxLayout oldDelegate) => true;
}
