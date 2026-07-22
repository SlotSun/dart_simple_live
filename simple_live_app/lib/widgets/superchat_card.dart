import 'package:flutter/material.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/widgets/net_image.dart';
import 'package:simple_live_core/simple_live_core.dart';

class SuperChatCard extends StatefulWidget {
  final LiveSuperChatMessage message;

  const SuperChatCard(
    this.message, {
    super.key,
  });

  @override
  State<SuperChatCard> createState() => _SuperChatCardState();
}

class _SuperChatCardState extends State<SuperChatCard> {
  int _remainSeconds() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final end = widget.message.endTime.millisecondsSinceEpoch ~/ 1000;
    return (end - now).clamp(0, 7200).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final remain = _remainSeconds();
    final semantic = context.appTheme;
    final theme = Theme.of(context);
    final headerColor = Utils.convertHexColor(widget.message.backgroundColor);
    final messageColor =
        Utils.convertHexColor(widget.message.backgroundBottomColor);
    final headerForeground =
        ThemeData.estimateBrightnessForColor(headerColor) == Brightness.dark
            ? Colors.white
            : const Color(0xE0000000);
    final messageForeground =
        ThemeData.estimateBrightnessForColor(messageColor) == Brightness.dark
            ? Colors.white
            : const Color(0xE0000000);

    return Semantics(
      container: true,
      label: '醒目留言，${widget.message.userName}，￥${widget.message.price}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: semantic.border),
            borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(
                color: headerColor,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      NetImage(
                        widget.message.face,
                        width: 42,
                        height: 42,
                        borderRadius: 21,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.message.userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: headerForeground,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '￥${widget.message.price}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: headerForeground.withAlpha(190),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_outlined,
                            size: 14,
                            color: headerForeground.withAlpha(190),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$remain 秒',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: headerForeground.withAlpha(190),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              ColoredBox(
                color: messageColor,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    widget.message.message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: messageForeground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
