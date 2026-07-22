import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';

void main() {
  group('AppStyle theme construction', () {
    test('builds the light semantic theme from a resolved color scheme', () {
      final sourceScheme = ColorScheme.fromSeed(
        seedColor: AppDesignTokens.defaultSeedColor,
        brightness: Brightness.light,
      );

      final theme = AppStyle.light(
        colorScheme: sourceScheme,
        fontFamily: 'CustomFont',
      );
      final semantic = theme.extension<AppThemeExtension>();

      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, sourceScheme.primary);
      expect(theme.colorScheme.surface, AppDesignTokens.lightBody);
      expect(theme.scaffoldBackgroundColor, AppDesignTokens.lightBody);
      expect(theme.cardColor, AppDesignTokens.lightSecondary);
      expect(semantic, isNotNull);
      expect(semantic!.secondarySurface, AppDesignTokens.lightSecondary);
      expect(semantic.textPrimary, AppDesignTokens.lightTextPrimary);
      expect(theme.textTheme.bodyMedium?.fontFamily, 'CustomFont');
      expect(
        theme.appBarTheme.systemOverlayStyle?.statusBarIconBrightness,
        Brightness.dark,
      );
    });

    test('builds the dark semantic theme from a resolved color scheme', () {
      final sourceScheme = ColorScheme.fromSeed(
        seedColor: AppDesignTokens.defaultSeedColor,
        brightness: Brightness.dark,
      );

      final theme = AppStyle.darkTheme(colorScheme: sourceScheme);
      final semantic = theme.extension<AppThemeExtension>();

      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, sourceScheme.primary);
      expect(theme.colorScheme.surface, AppDesignTokens.darkBody);
      expect(theme.scaffoldBackgroundColor, AppDesignTokens.darkBody);
      expect(theme.cardColor, AppDesignTokens.darkSecondary);
      expect(semantic, isNotNull);
      expect(semantic!.secondarySurface, AppDesignTokens.darkSecondary);
      expect(semantic.textSecondary, AppDesignTokens.darkTextSecondary);
      expect(
        theme.appBarTheme.systemOverlayStyle?.statusBarIconBrightness,
        Brightness.light,
      );
    });

    test('keeps semantic extensions interpolatable', () {
      final light = AppThemeExtension.light();
      final dark = AppThemeExtension.dark();
      final midpoint = light.lerp(dark, 0.5);

      expect(midpoint.body, Color.lerp(light.body, dark.body, 0.5));
      expect(
        midpoint.textSecondary,
        Color.lerp(light.textSecondary, dark.textSecondary, 0.5),
      );
    });
  });
}
