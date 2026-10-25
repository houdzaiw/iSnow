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
    required this.anchorKey,
    required this.bottomBarKey,
  });
  final String roomId;
  final GlobalKey rootKey;
  final GlobalKey anchorKey;
  final GlobalKey bottomBarKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roomMusicViewModelProvider(roomId));
    if (!state.expanded) return const SizedBox.shrink();
    return Positioned.fill(
      child: CustomSingleChildLayout(
        delegate: _MusicBoxLayout(
          rootKey: rootKey,
          anchorKey: anchorKey,
          bottomBarKey: bottomBarKey,
          width: AppSpacing.musicBoxWidth.w,
          edge: AppSpacing.musicBoxEdge.w,
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
    required this.anchorKey,
    required this.bottomBarKey,
    required this.width,
    required this.edge,
    required this.keyboardInset,
  });
  final GlobalKey rootKey;
  final GlobalKey anchorKey;
  final GlobalKey bottomBarKey;
  final double width;
  final double edge;
  final double keyboardInset;

  double? _top(GlobalKey key) {
    final root = rootKey.currentContext?.findRenderObject();
    final target = key.currentContext?.findRenderObject();
    if (root is! RenderBox || target is! RenderBox || !target.hasSize) {
      return null;
    }
    return target.localToGlobal(Offset.zero, ancestor: root).dy;
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final bottom = math.min(
      _top(bottomBarKey) ?? constraints.maxHeight,
      constraints.maxHeight - keyboardInset,
    );
    final ratio = AppSpacing.musicBoxWidth / AppSpacing.musicBoxHeight;
    final availableHeight = math.max(0.0, bottom - edge);
    final boxWidth = math.max(
      0.0,
      math.min(
        width,
        math.min(constraints.maxWidth - edge * 2, availableHeight * ratio),
      ),
    );
    return BoxConstraints.tight(Size(boxWidth, boxWidth / ratio));
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final bottom = math.min(
      _top(bottomBarKey) ?? size.height,
      size.height - keyboardInset,
    );
    final maximum = math.max(0.0, bottom - childSize.height - edge);
    return Offset(edge, (_top(anchorKey) ?? 0).clamp(0.0, maximum));
  }

  @override
  bool shouldRelayout(covariant _MusicBoxLayout oldDelegate) => true;
}
