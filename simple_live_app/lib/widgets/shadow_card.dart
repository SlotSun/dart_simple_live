import 'package:flutter/material.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';

class ShadowCard extends StatefulWidget {
  final Widget child;
  final double radius;
  final Function()? onTap;
  final Function()? onLongPress;

  const ShadowCard({
    required this.child,
    this.radius = AppDesignTokens.radius12,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  @override
  State<ShadowCard> createState() => _ShadowCardState();
}

class _ShadowCardState extends State<ShadowCard> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _interactive =>
      widget.onTap != null || widget.onLongPress != null;

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  void _setFocused(bool value) {
    if (_focused == value) return;
    setState(() => _focused = value);
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 140);
    final emphasized = _interactive && (_hovered || _focused);
    final borderColor = emphasized
        ? colorScheme.primary.withAlpha(90)
        : semantic.border;
    final shadowAlphaFactor =
        _pressed ? 0.35 : (emphasized ? 0.9 : 0.65);

    Widget surface = AnimatedContainer(
      duration: duration,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: semantic.elevatedSurface,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: semantic.shadow.withValues(
              alpha: semantic.shadow.a * shadowAlphaFactor,
            ),
            blurRadius: emphasized ? 12 : 8,
            offset: Offset(0, emphasized ? 4 : 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(widget.radius),
        child: _interactive
            ? InkWell(
                borderRadius: BorderRadius.circular(widget.radius),
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
                onHover: _setHovered,
                onFocusChange: _setFocused,
                onHighlightChanged: _setPressed,
                focusColor: colorScheme.primary.withAlpha(18),
                hoverColor: colorScheme.primary.withAlpha(12),
                highlightColor: colorScheme.primary.withAlpha(16),
                child: widget.child,
              )
            : widget.child,
      ),
    );

    if (!_interactive || reduceMotion) {
      return surface;
    }

    return AnimatedScale(
      duration: duration,
      curve: Curves.easeOutCubic,
      scale: _pressed ? 0.99 : (emphasized ? 1.006 : 1),
      child: surface,
    );
  }
}
