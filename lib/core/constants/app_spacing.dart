import 'package:flutter/material.dart';

/// Spacing system based on 4px base unit.
/// Use these consistently throughout the app.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double huge = 64;

  // Page horizontal padding
  static const double pagePadding = 20;
  static const EdgeInsets pageInsets = EdgeInsets.symmetric(horizontal: pagePadding);
  static const EdgeInsets pageInsetsWithBottom = EdgeInsets.fromLTRB(pagePadding, 0, pagePadding, pagePadding);

  // Card padding
  static const EdgeInsets cardInsets = EdgeInsets.all(base);
  static const EdgeInsets cardInsetsSm = EdgeInsets.all(md);

  // Border radii
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusFull = 100;

  static const BorderRadius borderRadiusSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderRadiusMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderRadiusLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius borderRadiusXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius borderRadiusFull = BorderRadius.all(Radius.circular(radiusFull));
}
