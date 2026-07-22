import 'package:flutter/material.dart';

abstract final class AppDesignTokens {
  static const int defaultSeedValue = 0xFF335EEA;
  static const Color defaultSeedColor = Color(defaultSeedValue);

  static const Color lightBody = Color(0xFFFFFFFF);
  static const Color lightSecondary = Color(0xFFF5F5F7);
  static const Color darkBody = Color(0xFF222222);
  static const Color darkSecondary = Color(0xFF323232);

  static const Color lightTextPrimary = Color(0xE0000000);
  static const Color lightTextSecondary = Color(0xAD000000);
  static const Color lightTextTertiary = Color(0x8A000000);
  static const Color lightTextDisabled = Color(0x61000000);
  static const Color darkTextPrimary = Color(0xE0FFFFFF);
  static const Color darkTextSecondary = Color(0xADFFFFFF);
  static const Color darkTextTertiary = Color(0x8AFFFFFF);
  static const Color darkTextDisabled = Color(0x61FFFFFF);

  static const Color lightBorder = Color(0x14000000);
  static const Color lightDivider = Color(0x0F000000);
  static const Color lightShadow = Color(0x14000000);
  static const Color darkBorder = Color(0x1FFFFFFF);
  static const Color darkDivider = Color(0x14FFFFFF);
  static const Color darkShadow = Color(0x52000000);

  static const double radius6 = 6;
  static const double radius8 = 8;
  static const double radius10 = 10;
  static const double radius12 = 12;
  static const double radius16 = 16;

  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space24 = 24;
}

abstract final class AppTypography {
  // Reserved for a properly licensed bundled family. A user-selected custom
  // family must continue to take precedence when one is configured.
  static const String? bundledDefaultFontFamily = null;

  static String? resolveFontFamily(String? customFontFamily) {
    return customFontFamily ?? bundledDefaultFontFamily;
  }
}
