import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/widgets/liquid_glass_navigation_bar.dart';

/// iOS 一律使用原生液态玻璃底部栏（UIGlassEffect，原生侧用 #available 判断版本），
/// 非 iOS 平台回退到 Flutter 毛玻璃近似。
///
/// 注：Flutter 3.47 的 Platform.operatingSystemVersion 运行时格式不可靠，
/// 版本判断交给原生侧（iOS < 26 时原生视图自动使用普通毛玻璃背景兜底）。
bool get useNativeGlassTabBar => Platform.isIOS;

/// 原生 iOS 26 液态玻璃底部导航栏（平台视图）
class NativeGlassTabBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<LiquidGlassDestination> destinations;

  const NativeGlassTabBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  State<NativeGlassTabBar> createState() => _NativeGlassTabBarState();
}

class _NativeGlassTabBarState extends State<NativeGlassTabBar> {
  static const _channel = MethodChannel('simple_live/native_glass_tab');
  static const _viewType = 'simple_live/native_glass_tab_bar';

  @override
  void initState() {
    super.initState();
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onTabSelected') {
        final args = call.arguments;
        final index = args is Map ? args['index'] as int? : null;
        if (index != null) {
          widget.onDestinationSelected(index);
        }
      }
    });
    _syncIndex();
  }

  @override
  void didUpdateWidget(covariant NativeGlassTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _syncIndex();
    }
  }

  void _syncIndex() {
    _channel.invokeMethod('setIndex', {'index': widget.selectedIndex});
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final creationParams = <String, dynamic>{
      'tabs': widget.destinations
          .map((d) => {'icon': _sfSymbol(d.icon), 'label': d.label})
          .toList(),
    };
    return SizedBox(
      height: 64 + bottomPad,
      child: UiKitView(
        viewType: _viewType,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      ),
    );
  }

  /// Remix 图标映射到 SF Symbols（原生观感）
  static String _sfSymbol(IconData icon) {
    if (icon.codePoint == Remix.home_smile_line.codePoint) {
      return 'house.fill';
    }
    if (icon.codePoint == Remix.heart_line.codePoint) {
      return 'heart.fill';
    }
    if (icon.codePoint == Remix.apps_line.codePoint) {
      return 'square.grid.2x2.fill';
    }
    if (icon.codePoint == Remix.user_smile_line.codePoint) {
      return 'person.fill';
    }
    return 'circle';
  }
}
