import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  // Primary text
  static const Color onSurface = Color(0xFF1A1A1A);
  static const Color onSurfaceMuted = Color(0xFF8A8A8A);
  static const Color onSurfaceDisabled = Color(0xFFBDBDBD);

  // Accent / Brand
  static const Color accent = Color(0xFFC8A96E);
  static const Color accentDark = Color(0xFF9D7D45);
  static const Color accentLight = Color(0xFFEDD9A3);
  static const Color accentSurface = Color(0xFFFDF6E7);

  // Semantic
  static const Color error = Color(0xFFD94F4F);
  static const Color errorSurface = Color(0xFFFDF0F0);
  static const Color success = Color(0xFF4CAF7D);
  static const Color successSurface = Color(0xFFEDF7F2);
  static const Color warning = Color(0xFFF5A623);

  // Dividers & borders
  static const Color divider = Color(0xFFEBEBEB);
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderFocused = Color(0xFFC8A96E);

  // Overlay
  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x1A000000);

  // Shimmer
  static const Color shimmerBase = Color(0xFFEEEEEE);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // Gradient for accent elements
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFC8A96E), Color(0xFFE8C98A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkOverlayGradient = LinearGradient(
    colors: [Colors.transparent, Color(0xCC1A1A1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
