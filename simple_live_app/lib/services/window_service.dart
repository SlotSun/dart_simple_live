import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/event_bus.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/services/local_storage_service.dart';
import 'package:window_manager/window_manager.dart';

class WindowService extends GetxService {
  static WindowService get instance => Get.find<WindowService>();

  List<int> _windows = []; // new window->add window.id
  int? _windowId;

  static final Window mainWindow = WindowManager.instance.getCurrent()!;

  bool isPIP = false;
  bool isMaxAuto = false;
  bool isMaxState = false;

  // because moved and resize return data always, so timer need
  static const _eDuration = Duration(milliseconds: 200);
  Timer? _moveTimer;
  Timer? _resizeTimer;

  WindowService();

  Future<void> init() async {
    isMaxAuto = AppSettingsController.instance.windowMaxAuto.value;
    isMaxState = AppSettingsController.instance.windowMaxState.value;
    final width = LocalStorageService.instance.getValue(LocalStorageService.kWindowWidth, 1280.0);
    final height = LocalStorageService.instance.getValue(LocalStorageService.kWindowHeight, 720.0);
    final x = LocalStorageService.instance.getValue(LocalStorageService.kWindowX, 320.0);
    final y = LocalStorageService.instance.getValue(LocalStorageService.kWindowY, 180.0);

    AppSettingsController.instance.danmakuFontResize = danmakuFontClamped();
    mainWindow.position = Offset(x, y).toNative();
    mainWindow.setSize(Size(width, height).toNative(), false);
    mainWindow.minimumSize = Size(320, 280).toNative();
    mainWindow.title = 'Slive';
    mainWindow.show();
    if (isMaxAuto && isMaxState) {
      await WidgetsBinding.instance.endOfFrame;
      mainWindow.maximize();
    }
    mainWindow.focus();

    _windowId = mainWindow.addListener(
      (event) async {
        switch (event) {
          case WindowMovedEvent():
            _moveTimer?.cancel();
            _moveTimer = Timer(_eDuration, windowStateChanged);
            break;
          case WindowFocusedEvent():
            break;
          case WindowBlurredEvent():
            break;
          case WindowMinimizedEvent():
            break;
          case WindowMaximizedEvent():
            if (AppSettingsController.instance.windowMaxAuto.value) {
              AppSettingsController.instance.setWindowMaxState(true);
            }
            danmakuFontClamped();
            break;
          case WindowRestoredEvent():
            break;
          case WindowResizedEvent():
            _resizeTimer?.cancel();
            _resizeTimer = Timer(_eDuration, windowStateChanged);
            break;
          case WindowCreatedEvent():
            break;
          case WindowClosedEvent():
            if (Platform.isLinux) {
              exit(0);
            }
            break;
          case WindowEnteredFullScreenEvent():
            danmakuFontClamped();
            break;
          case WindowExitedFullScreenEvent():
            danmakuFontClamped();
            break;

          case WindowCloseRequestedEvent():
            onClose();
            break;
          case WindowPropertyChangedEvent():
            break;
          case WindowOcclusionChangedEvent():
            break;
        }
      },
    );
  }

  void windowStateChanged() {
    final size = mainWindow.size.toSize();
    final position = mainWindow.position.toOffset();
    if (!isPIP) {
      danmakuFontClamped();
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
  double danmakuFontClamped() {
    // 应该更进一步判断用户是否在直播间界面, 小窗模式恢复默认弹幕尺寸
    if (AppSettingsController.instance.danmakuFontClamped.value && !isPIP) {
      final size = mainWindow.size.toSize();
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

  @override
  void onClose(){
    _moveTimer?.cancel();
    _resizeTimer?.cancel();
    mainWindow.removeListener(_windowId!);
    super.onClose();
  }
}
