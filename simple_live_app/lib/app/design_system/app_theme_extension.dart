import 'package:flutter/material.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';

@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.body,
    required this.secondarySurface,
    required this.elevatedSurface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.border,
    required this.divider,
    required this.shadow,
  });

  factory AppThemeExtension.light() {
    return const AppThemeExtension(
      body: AppDesignTokens.lightBody,
      secondarySurface: AppDesignTokens.lightSecondary,
      elevatedSurface: Colors.white,
      textPrimary: AppDesignTokens.lightTextPrimary,
      textSecondary: AppDesignTokens.lightTextSecondary,
      textTertiary: AppDesignTokens.lightTextTertiary,
      textDisabled: AppDesignTokens.lightTextDisabled,
      border: AppDesignTokens.lightBorder,
      divider: AppDesignTokens.lightDivider,
      shadow: AppDesignTokens.lightShadow,
    );
  }

  factory AppThemeExtension.dark() {
    return const AppThemeExtension(
      body: AppDesignTokens.darkBody,
      secondarySurface: AppDesignTokens.darkSecondary,
      elevatedSurface: Color(0xFF2A2A2A),
      textPrimary: AppDesignTokens.darkTextPrimary,
      textSecondary: AppDesignTokens.darkTextSecondary,
      textTertiary: AppDesignTokens.darkTextTertiary,
      textDisabled: AppDesignTokens.darkTextDisabled,
      border: AppDesignTokens.darkBorder,
      divider: AppDesignTokens.darkDivider,
      shadow: AppDesignTokens.darkShadow,
    );
  }

  final Color body;
  final Color secondarySurface;
  final Color elevatedSurface;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;
  final Color border;
  final Color divider;
  final Color shadow;

  @override
  AppThemeExtension copyWith({
    Color? body,
    Color? secondarySurface,
    Color? elevatedSurface,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
    Color? border,
    Color? divider,
    Color? shadow,
  }) {
    return AppThemeExtension(
      body: body ?? this.body,
      secondarySurface: secondarySurface ?? this.secondarySurface,
      elevatedSurface: elevatedSurface ?? this.elevatedSurface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textDisabled: textDisabled ?? this.textDisabled,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppThemeExtension lerp(
    covariant AppThemeExtension? other,
    double t,
  ) {
    if (other == null) {
      return this;
    }
    return AppThemeExtension(
      body: Color.lerp(body, other.body, t)!,
      secondarySurface:
          Color.lerp(secondarySurface, other.secondarySurface, t)!,
      elevatedSurface: Color.lerp(elevatedSurface, other.elevatedSurface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppThemeExtension get appTheme {
    return Theme.of(this).extension<AppThemeExtension>()!;
  }
}
