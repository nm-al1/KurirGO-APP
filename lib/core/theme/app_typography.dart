import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTypography {
  static const _base = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: ['Roboto', 'Arial', 'sans-serif'],
    color: AppColors.textLight,
  );
  static final displayHero = _base.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    height: 1.15,
  );
  static final pageTitle = _base.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    height: 1.2,
  );
  static final heading = _base.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    height: 1.25,
  );
  static final sectionTitle = _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    height: 1.3,
  );
  static final buttonCta = _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w800,
  );
  static final bodyStreet = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
  static final caption = _base.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
}
