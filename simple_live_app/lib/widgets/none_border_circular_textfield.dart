import 'package:flutter/material.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';

class NoneBorderCircularTextField extends StatelessWidget {
  final TextEditingController editingController;
  final String? hintText;
  final String? helperText;
  final String? labelText;
  final String? errorText;
  final Widget? prefixIcon;
  final bool obscureText;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final TextAlign textAlign;
  final Widget? trailing;
  final TextInputType? inputType;
  final int? maxLines;
  final bool autoFocus;
  final FocusNode? focusNode;
  final bool? enable;
  final bool readOnly;
  final bool needPadding;

  const NoneBorderCircularTextField({
    super.key,
    required this.editingController,
    this.hintText,
    this.helperText,
    this.labelText,
    this.errorText,
    this.prefixIcon,
    this.textAlign = TextAlign.start,
    this.obscureText = false,
    this.maxLines = 1,
    this.onEditingComplete,
    this.trailing,
    this.autoFocus = false,
    this.focusNode,
    this.inputType,
    this.onChanged,
    this.onTap,
    this.enable,
    this.readOnly = false,
    this.needPadding = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.appTheme;
    final radius = BorderRadius.circular(AppDesignTokens.radius12);
    final common = TextField(
      enabled: enable,
      readOnly: readOnly,
      decoration: InputDecoration(
        prefixIcon: prefixIcon,
        hintText: hintText,
        filled: true,
        fillColor: semantic.secondarySurface,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 14,
        ),
        suffix: trailing,
        helperText: helperText,
        helperMaxLines: 3,
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: radius,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: semantic.border),
          borderRadius: radius,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 1.5,
          ),
          borderRadius: radius,
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: semantic.divider),
          borderRadius: radius,
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.error),
          borderRadius: radius,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 1.5,
          ),
          borderRadius: radius,
        ),
        labelText: labelText,
        errorText: errorText,
        errorMaxLines: 3,
      ),
      cursorColor: theme.colorScheme.primary,
      textAlign: textAlign,
      autofocus: autoFocus,
      keyboardType: inputType,
      maxLines: maxLines,
      controller: editingController,
      obscureText: obscureText,
      onEditingComplete: onEditingComplete,
      onChanged: onChanged,
      onTap: onTap,
      focusNode: focusNode,
    );

    if (!needPadding) {
      return common;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: common,
    );
  }
}
