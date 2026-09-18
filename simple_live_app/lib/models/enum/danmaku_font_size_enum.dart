enum DanmakuFontScale {
  small('1080P', 0.5, 0.3),  // 1080p
  medium('2k', 0.9, 0.5), // 2k
  large('4k', 1.1, 0.8); // 4k
  // 带鱼屏 or ... 后续补充或者允许用户自定义

  const DanmakuFontScale(this.label, this.upSens, this.downSens);

  final String label;
  /// 放大方向的指数
  final double upSens;
  final double downSens;
}
