import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/models/db/follow_user.dart';
import 'package:simple_live_app/widgets/net_image.dart';

class FollowUserItem extends StatelessWidget {
  final FollowUser item;
  final Function()? onRemove;
  final Function()? onTap;
  final Function()? onLongPress;
  final bool playing;

  const FollowUserItem({
    required this.item,
    this.onRemove,
    this.onTap,
    this.onLongPress,
    this.playing = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final site = Sites.allSites[item.siteId]!;
    final semantic = context.appTheme;
    final theme = Theme.of(context);

    return ListTile(
      minVerticalPadding: 8,
      contentPadding: const EdgeInsets.only(left: 16, right: 8),
      leading: NetImage(
        item.face,
        width: 48,
        height: 48,
        borderRadius: 24,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              item.remark?.isNotEmpty == true ? item.remark! : item.userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                color: semantic.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Obx(() => _LiveStatus(status: item.liveStatus.value)),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Image.asset(site.logo, width: 16, height: 16),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                [
                  site.name,
                  item.watchDuration ?? '00:00:00',
                  item.tag.length > 8
                      ? '${item.tag.substring(0, 8)}...'
                      : item.tag,
                ].where((text) => text.isNotEmpty).join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: semantic.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
      trailing: playing
          ? SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.equalizer_rounded,
                color: theme.colorScheme.primary,
                semanticLabel: '正在播放',
              ),
            )
          : (onRemove == null
              ? null
              : IconButton(
                  onPressed: onRemove,
                  tooltip: '取消关注',
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  icon: const Icon(Remix.dislike_line, size: 20),
                )),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  String getStatus(int status) {
    if (status == 0) {
      return '读取中';
    } else if (status == 1) {
      return '未开播';
    } else {
      return '直播中';
    }
  }
}

class _LiveStatus extends StatelessWidget {
  const _LiveStatus({required this.status});

  final int status;

  @override
  Widget build(BuildContext context) {
    if (status == 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final semantic = context.appTheme;
    final isLive = status == 2;
    final color = isLive ? theme.colorScheme.primary : semantic.textTertiary;

    return Semantics(
      label: isLive ? '直播中' : '未开播',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isLive
              ? theme.colorScheme.primary.withAlpha(18)
              : semantic.secondarySurface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isLive
                ? theme.colorScheme.primary.withAlpha(54)
                : semantic.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLive ? Icons.sensors_rounded : Icons.pause_circle_outline,
              size: 12,
              color: color,
            ),
            const SizedBox(width: 3),
            Text(
              isLive ? '直播中' : '未开播',
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
