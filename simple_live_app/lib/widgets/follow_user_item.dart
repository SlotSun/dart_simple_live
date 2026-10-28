import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/app_style.dart';
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
    var site = Sites.allSites[item.siteId]!;
    return Ink(
      decoration: BoxDecoration(
        gradient: playing
            ? LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.red.withValues(alpha: 0.06),
                  Colors.transparent,
                ],
              )
            : null,
      ),
      child: ListTile(
        contentPadding: AppStyle.edgeInsetsL16.copyWith(right: 4),
        leading: NetImage(
          item.face,
          width: 48,
          height: 48,
          borderRadius: 24,
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                item.remark?.isNotEmpty == true ? item.remark! : item.userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Obx(
              () => Offstage(
                offstage: item.liveStatus.value == 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppStyle.hGap12,
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: LiveStatus.fromCode(item.liveStatus.value, playing: playing).color,
                        borderRadius: AppStyle.radius12,
                      ),
                    ),
                    AppStyle.hGap4,
                    Text(
                      LiveStatus.fromCode(item.liveStatus.value, playing: playing).label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                        color: item.liveStatus.value == 2 ? null : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        subtitle: Wrap(
          runSpacing: 1.0,
          children: [
            Image.asset(
              site.logo,
              width: 16,
            ),
            AppStyle.hGap4,
            Text(
              site.name,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            AppStyle.hGap4,
            Text.rich(
              TextSpan(
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.bottom,
                    child: Icon(Remix.timer_2_line, size: 15, color: Colors.grey),
                  ),
                  const TextSpan(text: '_'),
                  TextSpan(
                    text: "${(item.watchDurationSec / 3600).toStringAsFixed(1)}h",
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            AppStyle.hGap4,
            Text.rich(
              TextSpan(
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.bottom,
                    child: Icon(Remix.price_tag_3_line, size: 15, color: Colors.grey),
                  ),
                  const TextSpan(text: '_'),
                  TextSpan(text: item.tag),
                ],
              ),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: onRemove == null
            ? null
            : IconButton(
                onPressed: () {
                  onRemove?.call();
                },
                icon: const Icon(Remix.dislike_line),
              ),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}

enum LiveStatus {
  reading('读取中', Colors.grey),
  notLiving('未开播', Colors.grey),
  living('直播中', Colors.green),
  watching('观看中', Colors.red);

  const LiveStatus(this.label, this.color);

  final String label;
  final Color color;

  static LiveStatus fromCode(int status, {bool playing = false}) {
    if (playing) {
      return LiveStatus.watching;
    }
    if (status == 0) {
      return LiveStatus.reading;
    } else if (status == 1) {
      return LiveStatus.notLiving;
    } else {
      return LiveStatus.living;
    }
  }
}
