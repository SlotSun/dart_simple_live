import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/get_state_manager/src/simple/get_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/modules/settings/safe_settings/safe_settings_controller.dart';
import 'package:simple_live_app/widgets/settings/settings_action.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';
import 'package:simple_live_app/widgets/settings/settings_switch.dart';

class SafeSettingPage extends GetView<SafeSettingsController> {
  const SafeSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("数据安全设置"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Utils.showInformationHelpDialog(
                content: [
                  const Text("Slive v1.8.15及以后使用了新的密钥存储方式.\n"),
                  const Text("Slive 是一款开源软件, 某些人通过某些方法获取到数据库中的第三方敏感数据，会造成一些不好的后果。\n"),
                  const Text("因此，Slive 会为每一个用户生成一个独一无二的密钥并将其存储到系统特定的区域中，使敏感数据无法轻易被破解，这也会导致部分厂商判断为风险，请自行斟酌。\n"),
                  const Text("你可以理解密钥是登录密码。\n"),
                  const Text("只加密第三方敏感数据，不加密所有数据。加/解密数据量极少，性能影响微乎其微。\n"),
                  const Text("密钥是base64编码32字节形式的，你可以自行生成使用并保存。\n"),
                  const Text("点击生成密钥后，请选择复制妥善保存。\n"),
                  const Text("当数据为加密数据时，需要开启安全模式输入密钥，否则你的部分敏感数据会因为解密失败无法使用。\n"),
                  const Text('数据远程同步过程中，请保持本地远端数据加密格式一致，否则会出现数据损坏。\n'),
                  const Text("如果密钥忘了也没关系，你可以重新设置数据，会覆盖加密数据，注意这个操作会使原来所有加密数据不再可用。\n"),
                  const Text("点击重置数据按钮后, 请重启app，确保其他数据正常。\n"),
                  const Text("为了你的数据安全，请在可信源下载使用Slive, 不要下载第三方网盘分发的App。\n"),
                ],
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: AppStyle.edgeInsetsA12,
        children: [
          SettingsCard(
            child: Column(
              children: [
                Obx(
                  () => SettingsSwitch(
                    value: AppSettingsController.instance.appStoreKey.value,
                    title: "启用安全模式",
                    subtitle: '当前数据格式为 ${AppSettingsController.instance.appSafeEnable.value ? '加密格式' : '明文格式'}',
                    onChanged: (e) async {
                      if (e) {
                        await controller.setStoreKey();
                      } else {
                        await controller.removeStoreKey();
                      }
                    },
                  ),
                ),
                Obx(
                  () => Visibility(
                    visible: AppSettingsController.instance.appStoreKey.value,
                    child: SettingsSwitch(
                      title: "加密数据",
                      subtitle: "加密 webdav/cookies",
                      value: AppSettingsController.instance.appSafeEnable.value,
                      onChanged: (e) async {
                        if (e) {
                          await controller.encodeData();
                        } else {
                          await controller.decodeData();
                        }
                      },
                    ),
                  ),
                ),
                AppStyle.divider,
                SettingsAction(
                  title: '敏感数据重置',
                  onTap: () async {
                    await controller.reset();
                  },
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
