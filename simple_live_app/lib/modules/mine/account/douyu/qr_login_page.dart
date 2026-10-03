import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:simple_live_app/modules/mine/account/douyu/qr_login_controller.dart';

class DouyuQRLoginPage extends GetView<DouyuQRLoginController> {
  const DouyuQRLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('斗鱼扫码登录')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() => controller.loading.value
                  ? const CircularProgressIndicator()
                  : controller.qrUrl.value.isEmpty
                      ? const Icon(Icons.qr_code, size: 96)
                      : QrImageView(
                          data: controller.qrUrl.value,
                          size: 260,
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        )),
              const SizedBox(height: 24),
              Obx(() => Text(controller.message.value, textAlign: TextAlign.center)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: controller.refreshQrCode,
                icon: const Icon(Icons.refresh),
                label: const Text('刷新二维码'),
              ),
              const SizedBox(height: 16),
              const Text('登录信息会保存在本机，重启后仍可自动刷新 Cookie。', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
