import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/modules/mine/account/account_controller.dart';
import 'package:simple_live_app/services/bilibili_account_service.dart';
import 'package:simple_live_app/services/platform_service.dart';

class AccountPage extends GetView<AccountController> {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("账号管理"),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: AppStyle.edgeInsetsA12,
            child: Text(
              "哔哩哔哩账号需要登录才能看高清晰度的直播，其他平台暂无此限制。",
              textAlign: TextAlign.center,
            ),
          ),
          Obx(
            () => ListTile(
              leading: Image.asset(
                'assets/images/bilibili_2.png',
                width: 36,
                height: 36,
              ),
              title: const Text("哔哩哔哩"),
              subtitle: Text(BiliBiliAccountService.instance.name.value),
              trailing: BiliBiliAccountService.instance.logined.value
                  ? const Icon(Icons.logout)
                  : const Icon(Icons.chevron_right),
              onTap: controller.bilibiliTap,
            ),
          ),
          ListTile(
            leading: Image.asset(
              'assets/images/douyu.png',
              width: 36,
              height: 36,
            ),
            title: const Text("斗鱼直播"),
            subtitle: const Text("无需登录"),
            enabled: false,
            trailing: const Icon(Icons.chevron_right),
          ),
          Obx(
            () => ListTile(
              leading: Image.asset(
                'assets/images/huya.png',
                width: 36,
                height: 36,
              ),
              title: const Text("虎牙直播"),
              subtitle: Text(
                PlatformService.instance.huyaSdkUa.value.isEmpty ? "点击拉取最新配置" : "已自定义 HYSDK_UA",
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                var result = await Utils.showAlertDialog(
                  "是否从网络拉取虎牙最新配置？",
                  title: "拉取虎牙配置",
                );
                if (result) {
                  await PlatformService.instance.fetchHuyaSdkUa();
                }
              },
            ),
          ),
          Obx(
            () => ListTile(
              leading: Image.asset(
                'assets/images/douyin.png',
                width: 36,
                height: 36,
              ),
              title: const Text("抖音直播"),
              subtitle: Text(PlatformService.instance.douyinName.value),
              trailing: PlatformService.instance.douyinLogined.value
                  ? const Icon(Icons.logout)
                  : const Icon(Icons.chevron_right),
              onTap: controller.douyinTap,
            ),
          ),
        ],
      ),
    );
  }
}
