import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/event_bus.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/services/local_storage_service.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/services.dart';

class WindowService extends GetxService
    with WidgetsBindingObserver
    implements WindowListener {
  static WindowService get instance => Get.find<WindowService>();

  static const MethodChannel _windowChannel = MethodChannel("slive/window");

  /// 深色模式下标题栏与内容区共用这个底色，避免出现一条浅色分隔线
  static const Color darkTitleBarColor = Color(0xFF121212);

  bool isPIP = false;
  bool isMaxAuto = false;
  bool isMaxState = false;

  WindowService() {
    windowManager.addListener(this);
  }

  /// Windows 原生标题栏属于非客户区，不会跟随 Flutter 主题，必须显式同步。
  /// 原生侧收到过一次应用主题后就不再跟随系统主题。
  Future<void> syncTitleBarTheme() async {
    if (!Platform.isWindows) {
      return;
    }
    final isDark = _resolveDarkTitleBar();
    try {
      await _windowChannel.invokeMethod("setTitleBarTheme", {
        "dark": isDark,
        "useCaptionColor": isDark,
        "captionColor": _toColorRef(darkTitleBarColor),
        "textColor": _toColorRef(Colors.white),
      });
    } catch (e) {
      Log.w("syncTitleBarTheme failed: $e", false);
    }
  }

  bool _resolveDarkTitleBar() {
    final mode =
        ThemeMode.values[AppSettingsController.instance.themeMode.value];
    if (mode == ThemeMode.dark) {
      return true;
    }
    if (mode == ThemeMode.light) {
      return false;
    }
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  /// Flutter Color -> Win32 COLORREF (0x00BBGGRR)
  int _toColorRef(Color color) {
    final value = color.toARGB32();
    final r = (value >> 16) & 0xFF;
    final g = (value >> 8) & 0xFF;
    final b = value & 0xFF;
    return (b << 16) | (g << 8) | r;
  }

  @override
  void didChangePlatformBrightness() {
    syncTitleBarTheme();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  Future<void> init() async {
    isMaxAuto = AppSettingsController.instance.windowMaxAuto.value;
    isMaxState = AppSettingsController.instance.windowMaxState.value;
    // 系统深浅色变化时同步标题栏（仅“跟随系统”模式下有意义）
    WidgetsBinding.instance.addObserver(this);
    // 窗口尚未显示，此时设置标题栏不会出现“先浅后深”的闪烁
    await syncTitleBarTheme();
    final width = LocalStorageService.instance.getValue(LocalStorageService.kWindowWidth, 1280.0);
    final height = LocalStorageService.instance.getValue(LocalStorageService.kWindowHeight, 720.0);
    final x = LocalStorageService.instance.getValue(LocalStorageService.kWindowX, 320.0);
    final y = LocalStorageService.instance.getValue(LocalStorageService.kWindowY, 180.0);

    AppSettingsController.instance.danmakuFontResize = await danmakuFontClamped();
    await windowManager.setPosition(Offset(x, y));
    WindowOptions windowOptions = WindowOptions(
      size: Size(width, height),
      minimumSize: Size(320, 280), // 防止无脑小窗导致界面报错
      center: false,
      title: "Slive",
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      // 最大化在显示之后 防止卡白屏
      if (isMaxAuto && isMaxState) {
        await WidgetsBinding.instance.endOfFrame;
        await windowManager.maximize();
      }
      await windowManager.focus();
    });
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
    // issues 同上
    await danmakuFontClamped();
  }

  @override
  Future<void> onWindowMaximize() async {
    if (AppSettingsController.instance.windowMaxAuto.value) {
      AppSettingsController.instance.setWindowMaxState(true);
    }
    await danmakuFontClamped();
  }

  @override
  void onWindowMinimize() {}

  @override
  Future<void> onWindowMove() async {}

  @override
  Future<void> onWindowMoved() async {
    await windowStateChanged();
  }

  @override
  Future<void> onWindowResize() async {}

  @override
  Future<void> onWindowResized() async {
    await windowStateChanged();
  }

  @override
  void onWindowRestore() {}

  @override
  void onWindowUndocked() {}

  @override
  Future<void> onWindowUnmaximize() async {
    AppSettingsController.instance.setWindowMaxState(false);
    await danmakuFontClamped();
  }

  Future<void> windowStateChanged() async {
    final size = await windowManager.getSize();
    final position = await windowManager.getPosition();
    if (!isPIP) {
      await danmakuFontClamped();
      _saveSizeAndPositon(size, position);
    } else {
      _savePipSizeAndPositon(size, position);
    }
  }

  void _saveSizeAndPositon(Size s, Offset position) {
    LocalStorageService.instance.setValue(LocalStorageService.kWindowX, position.dx);
    LocalStorageService.instance.setValue(LocalStorageService.kWindowY, position.dy);
    LocalStorageService.instance.setValue(LocalStorageService.kWindowWidth, s.width);
    LocalStorageService.instance.setValue(LocalStorageService.kWindowHeight, s.height);
  }

  void _savePipSizeAndPositon(Size s, Offset position) {
    AppSettingsController.instance.setWindowPipX(position.dx);
    AppSettingsController.instance.setWindowPipY(position.dy);
    AppSettingsController.instance.setWindowPipWidth(s.width);
    AppSettingsController.instance.setWindowPipHeight(s.height);
  }

  // 启用后，当 Resized/Maximize/full -> re 后调整
  // 通过service 通知 live_controller 更新 danmaku_option
  // 因为media_kit的 w/h 均为 null, 所以只能从外部window_manager设计
  Future<double> danmakuFontClamped() async {
    // 应该更进一步判断用户是否在直播间界面, 小窗模式恢复默认弹幕尺寸
    if (AppSettingsController.instance.danmakuFontClamped.value && !isPIP) {
      final size = await windowManager.getSize();
      var windowH = size.height;
      Log.i('player_danmaku_size_h: $windowH');
      // 窗口设计分辨率默认 1280x720
      var reSizeFont = Utils.scaleValue(
        value: AppSettingsController.instance.danmuSize.value,
        playerH: windowH,
        designH: 720.0,
        upSens: AppSettingsController.instance.danmakuFontClampUpSens.value / 10,
        downSens: AppSettingsController.instance.danmakuFontClampDownSens.value / 10,
        minSize: 8,
        maxSize: 48,
      );
      EventBus.instance.emit(Constant.kUpdateDanmaku, reSizeFont);
      Log.i('player_danmaku_size: $reSizeFont');
      return reSizeFont;
    } else {
      // 防御性，反复测试功能过程中弹幕
      EventBus.instance.emit(Constant.kUpdateDanmaku, AppSettingsController.instance.danmuSize.value);
      return AppSettingsController.instance.danmuSize.value;
    }
  }
}
