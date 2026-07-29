import 'package:flutter/material.dart';

class AppRadius {
  const AppRadius._();

  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 10;
  static const double xl = 12;
  static const double card = 14;
  static const double calendar = 20;
  static const double dialog = 40;
  static const double pill = 40;

  static const BorderRadius cardBorder = BorderRadius.all(
    Radius.circular(card),
  );
  static const BorderRadius fieldBorder = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius dialogBorder = BorderRadius.all(
    Radius.circular(dialog),
  );
  static const BorderRadius sheetBorder = BorderRadius.vertical(
    top: Radius.circular(calendar),
  );
  static const BorderRadius pillBorder = BorderRadius.all(
    Radius.circular(pill),
  );
}
