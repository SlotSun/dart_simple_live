import 'dart:io';

import 'package:flutter/services.dart';

/// 系统 Now Playing（锁屏/控制中心/灵动岛媒体控制）桥接服务
///
/// 仅 iOS 生效，其他平台全部 no-op。原生实现见 AppDelegate.swift。
/// 直播场景使用 isLiveStream 标记，系统会显示 LIVE 标识，点击媒体卡片自动回到 App。
class NowPlayingService {
  static const MethodChannel _channel = MethodChannel('simple_live/now_playing');

  /// 原生侧远程控制命令回调：play / pause / stop
  static Function(String command)? onRemoteCommand;

  /// 注册方法通道回调，幂等，可在播放器初始化时调用
  static void init() {
    if (!Platform.isIOS) {
      return;
    }
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onRemoteCommand') {
        final command = call.arguments as String?;
        if (command != null) {
          onRemoteCommand?.call(command);
        }
      }
    });
  }

  /// 重新激活音频会话
  static void configure() {
    if (!Platform.isIOS) {
      return;
    }
    _channel.invokeMethod('configure');
  }

  /// 更新正在播放的直播信息
  static void updateNowPlaying({
    required String title,
    required String artist,
    String? artworkUrl,
    bool isLive = true,
  }) {
    if (!Platform.isIOS) {
      return;
    }
    _channel.invokeMethod('update', {
      'title': title,
      'artist': artist,
      'artworkUrl': artworkUrl ?? '',
      'isLive': isLive,
    });
  }

  /// 同步播放/暂停状态到系统媒体中心
  static void setPlaying(bool playing) {
    if (!Platform.isIOS) {
      return;
    }
    _channel.invokeMethod('setPlaying', {'playing': playing});
  }

  /// 清空媒体中心信息（退出直播间时调用）
  static void clear() {
    if (!Platform.isIOS) {
      return;
    }
    _channel.invokeMethod('clear');
  }
}
