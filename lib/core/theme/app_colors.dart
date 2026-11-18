import 'package:flutter/material.dart';

/// Design tokens for Browcyl Delivery (matching Figma specifications)
class AppColors {
  AppColors._();

  // Core Brand & Theme Colors
  static const Color electricLime = Color(0xFFC6FF00); // 14.5:1 High Contrast Outdoor Accent
  static const Color electricLimeLight = Color(0xFFA3E635);
  static const Color matteCharcoal = Color(0xFF18181B); // Base Dark Surface
  static const Color darkSecondary = Color(0xFF27272A); // Elevated Dark Card
  static const Color darkBorder = Color(0xFF3F3F46);

  // Light Mode Surfaces
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color slate50 = Color(0xFFF1F5F9);

  // Text Colors
  static const Color textDark = Color(0xFF18181B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textLightMuted = Color(0xFFA1A1AA);

  // Status & Telemetry
  static const Color statusGreen = Color(0xFF047857);
  static const Color statusAmber = Color(0xFFF59E0B);
  static const Color statusAmberBg = Color(0xFFFFFBEB);
  static const Color statusRed = Color(0xFFEF4444);
  static const Color statusRedBg = Color(0xFFFEF2F2);
}

