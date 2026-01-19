import 'package:flutter/cupertino.dart';
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
      icon: Icon(
        RemixIcons.bilibili_line,
        color: Colors.white,
        size: 14,
      ),
      logo: "assets/images/bilibili_2.png",
      name: "哔哩哔哩",
      liveSite: BiliBiliSite(),
    ),
    Constant.kDouyu: Site(
      id: Constant.kDouyu,
      icon: Icon(
        LiveIcons.douyu,
        color: Colors.white,
        size: 14,
      ),
      logo: "assets/images/douyu.png",
      name: "斗鱼直播",
      liveSite: DouyuSite(),
    ),
    Constant.kHuya: Site(
      id: Constant.kHuya,
      icon: Icon(
        LiveIcons.huya,
        color: Colors.white,
        size: 14,
      ),
      logo: "assets/images/huya.png",
      name: "虎牙直播",
      liveSite: HuyaSite(),
    ),
    Constant.kDouyin: Site(
      id: Constant.kDouyin,
      icon: Icon(
        RemixIcons.tiktok_line,
        color: Colors.white,
        size: 14,
      ),
      logo: "assets/images/douyin.png",
      name: "抖音直播",
      liveSite: DouyinSite(),
    ),
    Constant.kTwitch: Site(
      id: Constant.kTwitch,
      icon: Icon(
        RemixIcons.twitch_line,
        color: Colors.white,
        size: 14,
      ),
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
  final Icon icon;
  final LiveSite liveSite;

  Site({
    required this.id,
    required this.liveSite,
    required this.logo,
    required this.name,
    required this.icon,
  });
}
