import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/icons/live_icons.dart';
import 'package:simple_live_core/simple_live_core.dart';

class Sites {
  static final Map<String, Site> allSites = {
    Constant.kBiliBili: Site(
      id: Constant.kBiliBili,
      iconData: RemixIcons.bilibili_line,
      logo: "assets/images/bilibili_2.png",
      name: "哔哩哔哩",
      liveSite: BiliBiliSite(),
    ),
    Constant.kDouyu: Site(
      id: Constant.kDouyu,
      iconData: LiveIcons.douyu,
      logo: "assets/images/douyu.png",
      name: "斗鱼直播",
      liveSite: DouyuSite(),
    ),
    Constant.kHuya: Site(
      id: Constant.kHuya,
      iconData: LiveIcons.huya,
      logo: "assets/images/huya.png",
      name: "虎牙直播",
      liveSite: HuyaSite(),
    ),
    Constant.kDouyin: Site(
      id: Constant.kDouyin,
      iconData: RemixIcons.tiktok_line,
      logo: "assets/images/douyin.png",
      name: "抖音直播",
      liveSite: DouyinSite(),
    ),
    Constant.kTwitch: Site(
      id: Constant.kTwitch,
      iconData: RemixIcons.twitch_line,
      logo: "assets/images/Twitch.png",
      name: "Twitch",
      liveSite: TwitchSite(),
    )
  };

  static List<Site> get supportSites {
    return AppSettingsController.instance.siteSort
        .where((key) => Sites.allSites[key]?.name != 'Twitch')
        .map((key) => allSites[key]!)
        .toList();
  }
}

class Site {
  final String id;
  final String name;
  final String logo;
  final IconData iconData;
  final LiveSite liveSite;

  Site({
    required this.id,
    required this.liveSite,
    required this.logo,
    required this.name,
    required this.iconData,
  });
}
