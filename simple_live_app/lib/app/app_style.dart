import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';

class AppColors {
  static const Color defaultSeedColor = AppDesignTokens.defaultSeedColor;
  static const Color black333 = Color(0xFF333333);
}

class AppStyle {
  static ThemeData light({
    required ColorScheme colorScheme,
    String? fontFamily,
  }) {
    return _buildTheme(
      brightness: Brightness.light,
      colorScheme: colorScheme,
      fontFamily: fontFamily,
    );
  }

  static ThemeData darkTheme({
    required ColorScheme colorScheme,
    String? fontFamily,
  }) {
    return _buildTheme(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      fontFamily: fontFamily,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required ColorScheme colorScheme,
    String? fontFamily,
  }) {
    final isDark = brightness == Brightness.dark;
    final semantic = isDark
        ? AppThemeExtension.dark()
        : AppThemeExtension.light();
    final resolvedFontFamily = AppTypography.resolveFontFamily(fontFamily);
    final resolvedColorScheme = colorScheme.copyWith(
      brightness: brightness,
      surface: semantic.body,
      onSurface: semantic.textPrimary,
      surfaceContainerLowest: semantic.body,
      surfaceContainerLow: semantic.secondarySurface,
      surfaceContainer: semantic.secondarySurface,
      surfaceContainerHigh: semantic.elevatedSurface,
      surfaceContainerHighest: semantic.elevatedSurface,
      surfaceTint: Colors.transparent,
      outline: semantic.border,
      outlineVariant: semantic.divider,
      shadow: semantic.shadow,
      scrim: Colors.black,
    );
    final textTheme = _buildTextTheme(
      brightness: brightness,
      fontFamily: resolvedFontFamily,
      semantic: semantic,
    );
    final overlayStyle = (isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark)
        .copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    );
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
    );
    final borderedControlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
      side: BorderSide(color: semantic.border),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: resolvedColorScheme,
      scaffoldBackgroundColor: semantic.body,
      canvasColor: semantic.body,
      cardColor: semantic.secondarySurface,
      dividerColor: semantic.divider,
      disabledColor: semantic.textDisabled,
      fontFamily: resolvedFontFamily,
      textTheme: textTheme,
      primaryTextTheme: textTheme.apply(
        bodyColor: resolvedColorScheme.onPrimary,
        displayColor: resolvedColorScheme.onPrimary,
      ),
      visualDensity: VisualDensity.standard,
      extensions: <ThemeExtension<dynamic>>[semantic],
      appBarTheme: AppBarTheme(
        backgroundColor: semantic.body,
        foregroundColor: semantic.textPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: semantic.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: semantic.textPrimary),
        actionsIconTheme: IconThemeData(color: semantic.textPrimary),
        systemOverlayStyle: overlayStyle,
      ),
      cardTheme: CardThemeData(
        color: semantic.secondarySurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: semantic.shadow,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
          side: BorderSide(color: semantic.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: semantic.elevatedSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: semantic.shadow,
        elevation: 8,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radius16),
          side: BorderSide(color: semantic.border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: semantic.elevatedSurface,
        modalBackgroundColor: semantic.elevatedSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: semantic.shadow,
        elevation: 8,
        modalElevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDesignTokens.radius16),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: semantic.divider,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: semantic.textSecondary,
        textColor: semantic.textPrimary,
        subtitleTextStyle: textTheme.bodySmall,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDesignTokens.space16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: semantic.body,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        indicatorColor: resolvedColorScheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? resolvedColorScheme.primary
                : semantic.textSecondary,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? resolvedColorScheme.primary
                : semantic.textSecondary,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: semantic.body,
        elevation: 0,
        indicatorColor: resolvedColorScheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: resolvedColorScheme.primary),
        unselectedIconTheme: IconThemeData(color: semantic.textSecondary),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: resolvedColorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: semantic.body,
        elevation: 0,
        selectedItemColor: resolvedColorScheme.primary,
        unselectedItemColor: semantic.textSecondary,
        selectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: textTheme.labelSmall,
        type: BottomNavigationBarType.fixed,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: resolvedColorScheme.primary,
        unselectedLabelColor: semantic.textSecondary,
        indicatorColor: resolvedColorScheme.primary,
        dividerColor: Colors.transparent,
        overlayColor: WidgetStatePropertyAll(
          resolvedColorScheme.primary.withAlpha(16),
        ),
        labelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: textTheme.labelLarge,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: semantic.secondarySurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDesignTokens.space12,
          vertical: AppDesignTokens.space12,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: semantic.textTertiary,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: semantic.textSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radius10),
          borderSide: BorderSide(color: semantic.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radius10),
          borderSide: BorderSide(color: semantic.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radius10),
          borderSide: BorderSide(
            color: resolvedColorScheme.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radius10),
          borderSide: BorderSide(color: resolvedColorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radius10),
          borderSide: BorderSide(
            color: resolvedColorScheme.error,
            width: 1.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: resolvedColorScheme.primary,
          foregroundColor: resolvedColorScheme.onPrimary,
          disabledBackgroundColor: semantic.secondarySurface,
          disabledForegroundColor: semantic.textDisabled,
          shadowColor: Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesignTokens.space16,
            vertical: AppDesignTokens.space12,
          ),
          shape: controlShape,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesignTokens.space16,
            vertical: AppDesignTokens.space12,
          ),
          shape: controlShape,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: semantic.textPrimary,
          disabledForegroundColor: semantic.textDisabled,
          side: BorderSide(color: semantic.border),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesignTokens.space16,
            vertical: AppDesignTokens.space12,
          ),
          shape: borderedControlShape,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: resolvedColorScheme.primary,
          disabledForegroundColor: semantic.textDisabled,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesignTokens.space12,
            vertical: AppDesignTokens.space8,
          ),
          shape: controlShape,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: semantic.textSecondary,
          disabledForegroundColor: semantic.textDisabled,
          highlightColor: resolvedColorScheme.primary.withAlpha(20),
          shape: controlShape,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: resolvedColorScheme.primary,
        foregroundColor: resolvedColorScheme.onPrimary,
        hoverColor: resolvedColorScheme.primaryContainer,
        focusColor: resolvedColorScheme.primaryContainer,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 3,
        highlightElevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radius16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: semantic.secondarySurface,
        selectedColor: resolvedColorScheme.primaryContainer,
        disabledColor: semantic.secondarySurface,
        side: BorderSide(color: semantic.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
        ),
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: resolvedColorScheme.onPrimaryContainer,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesignTokens.space8,
          vertical: AppDesignTokens.space4,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: semantic.elevatedSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: semantic.shadow,
        elevation: 4,
        textStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radius10),
          side: BorderSide(color: semantic.border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? semantic.secondarySurface
            : AppDesignTokens.darkSecondary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppDesignTokens.darkTextPrimary,
        ),
        actionTextColor: isDark
            ? resolvedColorScheme.primary
            : resolvedColorScheme.primaryContainer,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radius10),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark
              ? AppDesignTokens.lightSecondary
              : AppDesignTokens.darkSecondary,
          borderRadius: BorderRadius.circular(AppDesignTokens.radius6),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: isDark
              ? AppDesignTokens.lightTextPrimary
              : AppDesignTokens.darkTextPrimary,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return states.contains(WidgetState.selected)
                ? resolvedColorScheme.primary.withAlpha(96)
                : Colors.transparent;
          }
          if (states.contains(WidgetState.selected)) {
            return resolvedColorScheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.disabled)
              ? resolvedColorScheme.onSurface.withAlpha(96)
              : resolvedColorScheme.onPrimary;
        }),
        side: WidgetStateBorderSide.resolveWith((states) {
          return BorderSide(
            color: states.contains(WidgetState.disabled)
                ? semantic.textDisabled
                : semantic.textTertiary,
            width: 1.5,
          );
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radius6),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return semantic.textDisabled;
          }
          return states.contains(WidgetState.selected)
              ? resolvedColorScheme.primary
              : semantic.textTertiary;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return semantic.textDisabled;
          }
          return states.contains(WidgetState.selected)
              ? resolvedColorScheme.onPrimary
              : semantic.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return semantic.secondarySurface;
          }
          return states.contains(WidgetState.selected)
              ? resolvedColorScheme.primary
              : semantic.secondarySurface;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return semantic.border;
          }
          return states.contains(WidgetState.selected)
              ? Colors.transparent
              : semantic.border;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: resolvedColorScheme.primary,
        linearTrackColor: semantic.secondarySurface,
        circularTrackColor: semantic.secondarySurface,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(semantic.textTertiary),
        trackColor: const WidgetStatePropertyAll(Colors.transparent),
        radius: const Radius.circular(AppDesignTokens.radius8),
        thickness: const WidgetStatePropertyAll(5.0),
      ),
    );
  }

  static TextTheme _buildTextTheme({
    required Brightness brightness,
    required String? fontFamily,
    required AppThemeExtension semantic,
  }) {
    final baseTextTheme = ThemeData(
      brightness: brightness,
      useMaterial3: true,
    ).textTheme.apply(
          fontFamily: fontFamily,
          bodyColor: semantic.textPrimary,
          displayColor: semantic.textPrimary,
        );

    return baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        color: semantic.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        color: semantic.textPrimary,
        height: 1.45,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: semantic.textPrimary,
        height: 1.45,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        color: semantic.textSecondary,
        height: 1.4,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        color: semantic.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        color: semantic.textSecondary,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        color: semantic.textTertiary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  static const vGap4 = SizedBox(height: 4);
  static const vGap8 = SizedBox(height: 8);
  static const vGap12 = SizedBox(height: 12);
  static const vGap24 = SizedBox(height: 24);
  static const vGap32 = SizedBox(height: 32);
  static const vGap48 = SizedBox(height: 48);

  static const hGap4 = SizedBox(width: 4);
  static const hGap8 = SizedBox(width: 8);
  static const hGap12 = SizedBox(width: 12);
  static const hGap16 = SizedBox(width: 16);
  static const hGap24 = SizedBox(width: 24);
  static const hGap32 = SizedBox(width: 32);
  static const hGap48 = SizedBox(width: 48);

  static const edgeInsetsH4 = EdgeInsets.symmetric(horizontal: 4);
  static const edgeInsetsH8 = EdgeInsets.symmetric(horizontal: 8);
  static const edgeInsetsH12 = EdgeInsets.symmetric(horizontal: 12);
  static const edgeInsetsH16 = EdgeInsets.symmetric(horizontal: 16);
  static const edgeInsetsH20 = EdgeInsets.symmetric(horizontal: 20);
  static const edgeInsetsH24 = EdgeInsets.symmetric(horizontal: 24);

  static const edgeInsetsV4 = EdgeInsets.symmetric(vertical: 4);
  static const edgeInsetsV8 = EdgeInsets.symmetric(vertical: 8);
  static const edgeInsetsV12 = EdgeInsets.symmetric(vertical: 12);
  static const edgeInsetsV24 = EdgeInsets.symmetric(vertical: 24);

  static const edgeInsetsA4 = EdgeInsets.all(4);
  static const edgeInsetsA8 = EdgeInsets.all(8);
  static const edgeInsetsA12 = EdgeInsets.all(12);
  static const edgeInsetsA16 = EdgeInsets.all(16);
  static const edgeInsetsA20 = EdgeInsets.all(20);
  static const edgeInsetsA24 = EdgeInsets.all(24);

  static const edgeInsetsR4 = EdgeInsets.only(right: 4);
  static const edgeInsetsR8 = EdgeInsets.only(right: 8);
  static const edgeInsetsR12 = EdgeInsets.only(right: 12);
  static const edgeInsetsR16 = EdgeInsets.only(right: 16);
  static const edgeInsetsR20 = EdgeInsets.only(right: 20);
  static const edgeInsetsR24 = EdgeInsets.only(right: 24);

  static const edgeInsetsL4 = EdgeInsets.only(left: 4);
  static const edgeInsetsL8 = EdgeInsets.only(left: 8);
  static const edgeInsetsL12 = EdgeInsets.only(left: 12);
  static const edgeInsetsL16 = EdgeInsets.only(left: 16);
  static const edgeInsetsL20 = EdgeInsets.only(left: 20);
  static const edgeInsetsL24 = EdgeInsets.only(left: 24);

  static const edgeInsetsT4 = EdgeInsets.only(top: 4);
  static const edgeInsetsT8 = EdgeInsets.only(top: 8);
  static const edgeInsetsT12 = EdgeInsets.only(top: 12);
  static const edgeInsetsT24 = EdgeInsets.only(top: 24);

  static const edgeInsetsB4 = EdgeInsets.only(bottom: 4);
  static const edgeInsetsB8 = EdgeInsets.only(bottom: 8);
  static const edgeInsetsB12 = EdgeInsets.only(bottom: 12);
  static const edgeInsetsB24 = EdgeInsets.only(bottom: 24);

  static final BorderRadius radius4 = BorderRadius.circular(4);
  static final BorderRadius radius6 = BorderRadius.circular(6);
  static final BorderRadius radius8 = BorderRadius.circular(8);
  static final BorderRadius radius10 = BorderRadius.circular(10);
  static final BorderRadius radius12 = BorderRadius.circular(12);
  static final BorderRadius radius16 = BorderRadius.circular(16);
  static final BorderRadius radius24 = BorderRadius.circular(24);
  static final BorderRadius radius32 = BorderRadius.circular(32);
  static final BorderRadius radius48 = BorderRadius.circular(48);

  /// 顶部状态栏的高度
  static double get statusBarHeight => MediaQuery.of(Get.context!).padding.top;

  /// 底部导航条的高度
  static double get bottomBarHeight =>
      MediaQuery.of(Get.context!).padding.bottom;

  static Divider get divider {
    final context = Get.context;
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: context == null
          ? AppDesignTokens.lightDivider
          : Theme.of(context).dividerColor,
    );
  }
}
