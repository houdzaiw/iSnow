import 'package:flutter/animation.dart';

class AppMotion {
  const AppMotion._();

  static const roomGiftReveal = Duration(milliseconds: 500);
  static const roomGiftRevealScale = Duration(milliseconds: 1000);
  static const roomGiftFlight = Duration(milliseconds: 666);
  static const roomGiftBurst = Duration(milliseconds: 1166);
  static const roomGiftRevealCurve = Curves.elasticOut;
  static const roomGiftFlightCurve = Curves.easeInSine;
}
