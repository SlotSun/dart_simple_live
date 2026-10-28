import 'package:get/get.dart';
import 'package:simple_live_tv_app/app/sites.dart';
import 'package:simple_live_tv_app/models/db/account.dart';
import 'package:simple_live_tv_app/modules/category/category_controller.dart';
import 'package:simple_live_tv_app/routes/route_path.dart';

/// APP页面跳转封装
/// * 需要参数的页面都应使用此类
/// * 如不需要参数，可以使用Get.toNamed
class AppNavigator {
  /// 跳转至直播间
  static void toLiveRoomDetail({required Site site, required String roomId}) async {
    Get.toNamed(RoutePath.kLiveRoomDetail, arguments: site, parameters: {
      "roomId": roomId,
    });
  }

  // 跳转至账号登录
  static Future toQRCoreLogin({required Account account}) async {
    Get.toNamed(RoutePath.kAccountQRLogin, arguments: account);
  }


  /// 跳转至分类详情
  static void toCategoryDetail(
      {required Site site, required LiveSubCategoryExt category}) {
    Get.toNamed(RoutePath.kCategoryDetail, arguments: [site, category]);
  }
}
