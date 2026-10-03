import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:simple_live_tv_app/app/app_style.dart';
import 'package:simple_live_tv_app/app/utils.dart';
import 'package:simple_live_tv_app/modules/account/douyu/qr_login_controller.dart';
import 'package:simple_live_tv_app/services/douyu_account_service.dart';
import 'package:simple_live_tv_app/widgets/app_scaffold.dart';
import 'package:simple_live_tv_app/widgets/button/highlight_button.dart';

class DouyuQRLoginPage extends GetView<DouyuQRLoginController> {
  const DouyuQRLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(
        children: [
          AppStyle.vGap32,
          Row(
            children: [
              AppStyle.hGap48,
              HighlightButton(
                focusNode: controller.backFocus,
                iconData: Icons.arrow_back,
                text: '返回',
                autofocus: true,
                onTap: Get.back,
              ),
              AppStyle.hGap32,
              Text('斗鱼扫码登录', style: TextStyle(fontSize: 36.w)),
              const Spacer(),
              HighlightButton(
                focusNode: controller.refreshFocus,
                iconData: Icons.refresh,
                text: '刷新二维码',
                onTap: controller.refreshQrCode,
              ),
              AppStyle.hGap24,
              HighlightButton(
                focusNode: controller.logoutFocus,
                iconData: Icons.logout,
                text: '退出登录',
                onTap: () async {
                  if (await Utils.showAlertDialog('确定要退出斗鱼登录吗？',
                      title: '退出登录')) {
                    await DouyuAccountService.instance.logout();
                    controller.refreshQrCode();
                  }
                },
              ),
              AppStyle.hGap48,
            ],
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(() => controller.loading.value
                      ? SizedBox(
                          width: 64.w,
                          height: 64.w,
                          child: const CircularProgressIndicator())
                      : controller.qrUrl.value.isEmpty
                          ? Icon(Icons.qr_code, size: 160.w)
                          : QrImageView(
                              data: controller.qrUrl.value,
                              size: 380.w,
                              padding: EdgeInsets.all(20.w),
                              backgroundColor: Colors.white,
                            )),
                  AppStyle.vGap32,
                  Obx(() => Text(controller.message.value,
                      style: TextStyle(fontSize: 30.w),
                      textAlign: TextAlign.center)),
                  AppStyle.vGap24,
                  Text('登录信息会保存在电视上，重启后仍可自动刷新 Cookie。',
                      style: TextStyle(fontSize: 26.w),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
