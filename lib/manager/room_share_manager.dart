import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../model/room_share_models.dart';

final roomShareManagerProvider = Provider((ref) => RoomShareManager());

/// Only platform operations live here; no room state, HTTP, or navigation.
class RoomShareManager {
  Future<void> copyText(String text) =>
      Clipboard.setData(ClipboardData(text: text));

  Future<RoomShareOutcome> shareText({
    required String text,
    required Rect origin,
  }) async {
    if (origin.isEmpty || !origin.isFinite) {
      throw ArgumentError.value(origin, 'origin', 'Invalid share anchor');
    }
    final result = await SharePlus.instance.share(
      ShareParams(text: text, sharePositionOrigin: origin),
    );
    return switch (result.status) {
      ShareResultStatus.success => RoomShareOutcome.shared,
      ShareResultStatus.dismissed => RoomShareOutcome.cancelled,
      ShareResultStatus.unavailable => RoomShareOutcome.unavailable,
    };
  }
}
