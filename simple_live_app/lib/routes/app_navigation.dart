import 'dart:io';

import 'package:get/get.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/models/db/account.dart';
import 'package:simple_live_app/models/db/follow_user.dart';
import 'package:simple_live_app/models/sync_client_info_model.dart';
import 'package:simple_live_app/routes/route_path.dart';
import 'package:simple_live_app/services/sync_service.dart';
import 'package:simple_live_core/simple_live_core.dart';

/// APP页面跳转封装
/// * 需要参数的页面都应使用此类
/// * 如不需要参数，可以使用Get.toNamed
class AppNavigator {
  /// 跳转至分类详情
  static void toCategoryDetail({required Site site, required LiveSubCategory category}) {
    Get.toNamed(RoutePath.kCategoryDetail, arguments: [site, category]);
  }

  /// 跳转至直播间
  static void toLiveRoomDetail({required Site site, required String roomId}) async {
    // 不再提示
    Get.toNamed(RoutePath.kLiveRoomDetail, arguments: site, parameters: {
      "roomId": roomId,
    });
  }

  static Future toQRCoreLogin({required Account account}) async {
    Get.toNamed(RoutePath.kAccountQRLogin, arguments: account);
  }

  /// 跳转至哔哩哔哩网页登录
  static Future toBiliBiliWebLogin({required Account account}) async {
    Get.toNamed(RoutePath.kBiliBiliWebLogin, arguments: account);
  }

  /// 跳转至哔哩哔哩登录
  static Future toBiliBiliLogin() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await Get.toNamed(RoutePath.kBiliBiliWebLogin);
    } else {
      await Get.toNamed(RoutePath.kBiliBiliQRLogin);
    }
  }

  /// 跳转至同步设备
  static Future toSyncDevice(SyncClinet client, SyncClientInfoModel info) async {
    await Get.toNamed(
      RoutePath.kLocalSyncDevice,
      arguments: {
        "client": client,
        "info": info,
      },
    );
  }

  /// 跳转至关注用户信息详情
  static void toFollowInfo(FollowUser follow) {
    Get.toNamed(RoutePath.kFollowInfo, arguments: follow);
  }
}
