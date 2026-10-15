import 'package:material_ui/material_ui.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/models/db/follow_user.dart';
import 'package:simple_live_app/routes/app_navigation.dart';
import 'package:simple_live_app/widgets/net_image.dart';
import 'package:simple_live_app/widgets/shadow_card.dart';

class FollowUserCard extends StatelessWidget {
  final FollowUser item;
  final Function()? onLongPress;
  final Function()? onFollowRemove;

  const FollowUserCard(this.item, {super.key, this.onLongPress, this.onFollowRemove});

  @override
  Widget build(BuildContext context) {
    Site site = Sites.allSites[item.siteId]!;
    return ShadowCard(
      onTap: () {
        AppNavigator.toLiveRoomDetail(site: site, roomId: item.roomId);
      },
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                child: NetImage(
                  item.cover.value,
                  fit: BoxFit.cover,
                  height: 110,
                  width: double.infinity,
                ),
              ),
              Positioned(
                right: 0,
                left: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black87,
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            WidgetSpan(
                              alignment: PlaceholderAlignment.bottom,
                              child: Icon(Remix.price_tag_3_line, size: 14, color: Colors.white),
                            ),
                            TextSpan(
                              text: '_${item.tag}',
                            ),
                          ]
                        ),
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                      const Spacer(),
                      Icon(
                        site.iconData,
                        color: Colors.white,
                        size: 14,
                      ),
                      AppStyle.hGap4,
                      Text(
                        Utils.onlineToString(item.online.value),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: AppStyle.edgeInsetsH8.copyWith(
              top: 8,
              bottom: 8,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text.rich(
                        TextSpan(
                          text: item.userName,
                        ),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (onFollowRemove != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: onFollowRemove,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Remix.dislike_line),
                  )
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
