import 'package:flutter/material.dart';

/// Owns only the temporary UI selection during a linked, cross-category drag.
/// Tab controllers remain owned and disposed by the sheet's hooks.
class RoomRankTabNavigation {
  RoomRankTabNavigation({required this.categories, required this.periods});

  final TabController categories;
  final List<TabController> periods;
  ({int target, int previous})? _preview;
  bool _disposed = false;

  bool onScroll(ScrollNotification notification) {
    if (_disposed ||
        notification.depth != 0 ||
        notification.metrics.axis != Axis.horizontal) {
      return false;
    }
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _beginSwipe();
    } else if (notification is ScrollEndNotification && _preview != null) {
      // A title tap can end the old drag synchronously before its onTap runs.
      if (categories.indexIsChanging) {
        _cancelPreview();
        return false;
      }
      final preview = _preview!;
      _preview = null;
      if (categories.index != preview.target) {
        periods[preview.target].index = preview.previous;
      }
    }
    return false;
  }

  void _beginSwipe() {
    if (_preview != null || categories.indexIsChanging) return;
    final source = categories.index;
    final sourcePeriod = periods[source].animation!.value.round();
    if (source == 0 && sourcePeriod != 2 || source == 1 && sourcePeriod != 0) {
      return;
    }
    final target = 1 - source;
    final boundary = source == 0 ? 0 : 2;
    _preview = (target: target, previous: periods[target].index);
    // Prepare before the parent's first drag update paints the incoming page.
    periods[target].index = boundary;
  }

  void onCategoryTap(int index) => _cancelPreview();

  void onPeriodTap(int category, int index) {
    _cancelPreview();
    if (periods[category].index != index) periods[category].animateTo(index);
  }

  void _cancelPreview() {
    final preview = _preview;
    _preview = null;
    if (!_disposed && preview != null) {
      periods[preview.target].index = preview.previous;
    }
  }

  void dispose() {
    _disposed = true;
    _preview = null;
  }
}
