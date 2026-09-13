import 'dart:io';
import 'dart:ui';

import 'package:get/get.dart';
import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/event_bus.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/models/enum/danmaku_font_size_enum.dart';
import 'package:simple_live_app/services/local_storage_service.dart';
import 'package:window_manager/window_manager.dart';

class WindowService extends GetxService implements WindowListener {
  static WindowService get instance => Get.find<WindowService>();

  bool isPIP = false;

  WindowService() {
    windowManager.addListener(this);
  }

  Future<void> init() async {
    await resize();
    WindowOptions windowOptions = WindowOptions(
      minimumSize: Size(280, 280),
      center: false,
      title: "Slive",
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  Future<void> resize() async {
    // 初始分辨率默认 1920×1080
    final width = LocalStorageService.instance.getValue(LocalStorageService.kWindowWidth, 1280.0);
    final height = LocalStorageService.instance.getValue(LocalStorageService.kWindowHeight, 720.0);
    final x = LocalStorageService.instance.getValue(LocalStorageService.kWindowX, 320.0);
    final y = LocalStorageService.instance.getValue(LocalStorageService.kWindowY, 180.0);
    windowManager.setBounds(Rect.fromLTWH(x, y, width, height));
  }

  @override
  void onWindowBlur() {}

  @override
  void onWindowClose() {
    if (Platform.isLinux) {
      exit(0);
    }
  }

  @override
  void onWindowDocked() {}

  @override
  Future<void> onWindowEnterFullScreen() async {
    // https://github.com/leanflutter/window_manager/issues/560
    // https://github.com/leanflutter/window_manager/pull/531
    await danmakuFontClamped();
  }

  @override
  void onWindowEvent(String eventName) {}

  @override
  void onWindowFocus() {}

  @override
  Future<void> onWindowLeaveFullScreen() async {
    await danmakuFontClamped();
  }

  @override
  Future<void> onWindowMaximize() async {
    await danmakuFontClamped();
  }

  @override
  void onWindowMinimize() {}

  @override
  Future<void> onWindowMove() async {}

  @override
  Future<void> onWindowMoved() async {
    if (!isPIP) {
      final bounds = await windowManager.getBounds();
      _saveBounds(bounds);
    }
  }

  @override
  Future<void> onWindowResize() async {}

  @override
  Future<void> onWindowResized() async {
    if (!isPIP) {
      final bounds = await windowManager.getBounds();
      await danmakuFontClamped();
      _saveBounds(bounds);
    }
  }

  @override
  void onWindowRestore() {}

  @override
  void onWindowUndocked() {}

  @override
  Future<void> onWindowUnmaximize() async {
    await danmakuFontClamped();
  }

  void _saveBounds(Rect bounds) {
    LocalStorageService.instance.setValue(LocalStorageService.kWindowX, bounds.left);
    LocalStorageService.instance.setValue(LocalStorageService.kWindowY, bounds.top);
    LocalStorageService.instance.setValue(LocalStorageService.kWindowWidth, bounds.width);
    LocalStorageService.instance.setValue(LocalStorageService.kWindowHeight, bounds.height);
  }

  // 启用后，当 Resized/Maximize/full -> re 后调整
  // 通过service 通知 live_controller 更新 danmaku_option
  // 因为media_kit的 w/h 均为 null, 所以只能从外部window_manager设计
  Future<void> danmakuFontClamped() async {
    if (AppSettingsController.instance.danmakuFontClamped.value) {
      final bounds = await windowManager.getBounds();
      var windowH = bounds.height;
      Log.i('player_danmaku_size_h: $windowH');
      // 窗口设计分辨率默认 1280x720
      var reSizeFont =  Utils.scaleValue(
        value: AppSettingsController.instance.danmuSize.value,
        playerH: windowH,
        designH: 720.0,
        upSens: DanmakuFontScale.medium.upSens,
        downSens: DanmakuFontScale.medium.downSens,// 暂时写死2k，后续允许用户自定义调整
        minSize: 8,
        maxSize: 48,
      );
      EventBus.instance.emit(Constant.kUpdateDanmaku, reSizeFont);
      Log.i('player_danmaku_size: $reSizeFont');
    } else {
      return;
    }
  }
}
