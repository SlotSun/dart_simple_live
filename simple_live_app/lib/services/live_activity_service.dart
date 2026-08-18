import 'dart:io';

import 'package:flutter/services.dart';

/// 灵动岛 Live Activity 桥接服务（京东/美团外卖式实时活动）
///
/// 仅 iOS 生效，其他平台全部 no-op。原生实现见 AppDelegate.swift。
/// Live Activity 点击压缩态胶囊会直接打开 App（长按才展开），
/// 由系统管理，无需额外配置。
class LiveActivityService {
  static const MethodChannel _channel = MethodChannel('simple_live/live_activity');

  static bool _active = false;

  static bool get isActive => _active;

  /// 开始（或更新）直播灵动岛活动
  static void start({
    required String title,
    required String artist,
    String? thumbnailUrl,
    required bool isLive,
    required int online,
  }) {
    if (!Platform.isIOS) {
      return;
    }
    _active = true;
    _channel.invokeMethod('start', {
      'title': title,
      'artist': artist,
      'thumbnailUrl': thumbnailUrl ?? '',
      'isLive': isLive,
      'online': online,
    });
  }

  /// 更新在线人数/状态
  static void update({required int online, required bool isLive}) {
    if (!Platform.isIOS || !_active) {
      return;
    }
    _channel.invokeMethod('update', {'online': online, 'isLive': isLive});
  }

  /// 结束灵动岛活动
  static void end() {
    if (!Platform.isIOS || !_active) {
      return;
    }
    _active = false;
    _channel.invokeMethod('end');
  }
}
