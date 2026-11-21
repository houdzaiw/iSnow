import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Best-effort feedback; platform errors must never affect a paid request.
class RoomGiftFeedbackManager {
  const RoomGiftFeedbackManager._();

  static Future<void> lightImpact() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (error) {
      debugPrint('[RoomGift] Haptic unavailable: $error');
    }
  }
}
