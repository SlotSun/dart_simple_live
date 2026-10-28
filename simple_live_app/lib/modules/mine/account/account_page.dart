import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/modules/mine/account/account_controller.dart';
import 'package:simple_live_app/services/platform_service.dart';
import 'package:simple_live_app/widgets/site_setting_card.dart';

class AccountPage extends GetView<AccountController> {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("平台配置"),
      ),
      body: Obx(
        () => ListView(
          children: [
            const Padding(
              padding: AppStyle.edgeInsetsA12,
              child: Text(
                "哔哩哔哩账号/斗鱼需要登录才能看高清晰度的直播，其他平台暂无此限制。",
                textAlign: TextAlign.center,
              ),
            ),
            ...controller.accountList.map(
              (acItem) => SiteSettingCard(
                acItem,
                onTap: () => controller.tap(acItem),
              ),
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
          ],
        ),
      ),
    );
  }
}
