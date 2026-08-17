import 'dart:ui';

import 'package:flutter/material.dart';

/// 液态玻璃风格的底部导航项数据
class LiquidGlassDestination {
  final IconData icon;
  final String label;

  const LiquidGlassDestination({required this.icon, required this.label});
}

/// iOS 液态玻璃风格的底部导航栏（毛玻璃近似）
///
/// 使用 [BackdropFilter] 模糊背后的页面内容 + 半透明主题色着色 + 描边高光，
/// 浮动圆角胶囊样式。需要配合 Scaffold 的 extendBody: true 使用，
/// 让页面内容能滚动到玻璃栏下方被模糊。
class LiquidGlassNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<LiquidGlassDestination> destinations;
  final double height;

  const LiquidGlassNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.height = 56,
  });

  static const double _borderRadius = 28;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    // 半透明主题色着色：亮色偏浅、暗色偏深
    final tint = scheme.surface.withAlpha(isDark ? 120 : 150);
    // 描边：亮色深色描边、暗色浅色描边，营造玻璃边缘
    final borderColor = (isDark ? Colors.white : Colors.black).withAlpha(26);
    final highlightColor = (isDark ? Colors.white : Colors.white).withAlpha(28);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 8),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 60 : 30),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 30,
              sigmaY: 30,
              tileMode: TileMode.clamp,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: tint,
                border: Border.all(color: borderColor, width: 0.8),
                borderRadius: BorderRadius.circular(_borderRadius),
              ),
              child: Stack(
                children: [
                  // 顶部高光，模拟液态玻璃的反光
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(_borderRadius),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            highlightColor,
                            highlightColor.withAlpha(0),
                            Colors.transparent,
                          ],
                          stops: const [0, 0.4, 1],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < destinations.length; i++)
                        Expanded(
                          child: _LiquidGlassItem(
                            selected: i == selectedIndex,
                            icon: destinations[i].icon,
                            onTap: () => onDestinationSelected(i),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiquidGlassItem extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  const _LiquidGlassItem({
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: 44,
          decoration: BoxDecoration(
            color: selected
                ? scheme.secondaryContainer.withAlpha(180)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            icon,
            size: 24,
            color: selected
                ? scheme.onSecondaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
