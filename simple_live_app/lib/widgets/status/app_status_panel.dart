import 'package:flutter/material.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';

class AppStatusPanel extends StatelessWidget {
  const AppStatusPanel({
    required this.visual,
    required this.title,
    this.message,
    this.actionLabel,
    this.onRefresh,
    super.key,
  });

  final Widget visual;
  final String title;
  final String? message;
  final String? actionLabel;
  final Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final semantic = context.appTheme;
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppDesignTokens.radius16);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.hasBoundedHeight && constraints.maxHeight < 320;
        final panel = ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: semantic.elevatedSurface,
              borderRadius: radius,
              border: Border.all(color: semantic.border),
              boxShadow: [
                BoxShadow(
                  color: semantic.shadow,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(compact ? 16 : 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: compact ? 72 : 112,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: visual,
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: semantic.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (message?.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Text(
                      message!,
                      maxLines: compact ? 2 : 4,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: semantic.textSecondary,
                      ),
                    ),
                  ],
                  if (onRefresh != null && actionLabel != null) ...[
                    SizedBox(height: compact ? 10 : 16),
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 44),
                      ),
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );

        final interactivePanel = onRefresh == null
            ? panel
            : Material(
                color: Colors.transparent,
                borderRadius: radius,
                child: InkWell(
                  borderRadius: radius,
                  onTap: onRefresh,
                  child: panel,
                ),
              );

        final minHeight = constraints.hasBoundedHeight &&
                constraints.maxHeight > 32
            ? constraints.maxHeight - 32
            : 0.0;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Center(child: interactivePanel),
          ),
        );
      },
    );
  }
}
