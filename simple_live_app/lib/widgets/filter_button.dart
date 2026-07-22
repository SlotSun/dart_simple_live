import 'package:flutter/material.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';

class FilterButton extends StatelessWidget {
  final bool selected;
  final String text;
  final Function()? onTap;

  const FilterButton({
    this.selected = false,
    required this.text,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.appTheme;
    final radius = BorderRadius.circular(999);
    final foreground = selected
        ? theme.colorScheme.primary
        : semantic.textSecondary;

    final shape = RoundedRectangleBorder(
      borderRadius: radius,
      side: BorderSide(
        color: selected
            ? theme.colorScheme.primary.withAlpha(90)
            : semantic.border,
      ),
    );
    final content = Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      alignment: Alignment.center,
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: foreground,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );

    return Semantics(
      button: onTap != null,
      selected: selected,
      child: Material(
        color: selected
            ? theme.colorScheme.primary.withAlpha(18)
            : semantic.secondarySurface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? content
            : InkWell(
                onTap: onTap,
                focusColor: theme.colorScheme.primary.withAlpha(18),
                hoverColor: theme.colorScheme.primary.withAlpha(12),
                child: content,
              ),
      ),
    );
  }
}
