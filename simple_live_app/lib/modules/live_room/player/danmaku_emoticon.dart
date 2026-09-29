import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/painting.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_core/simple_live_core.dart';

/// 弹幕内容的一个片段：要么是一段纯文本，要么是一个表情。
sealed class DanmakuSegment {
  const DanmakuSegment();
}

final class DanmakuTextSegment extends DanmakuSegment {
  final String text;
  const DanmakuTextSegment(this.text);
}

final class DanmakuEmoticonSegment extends DanmakuSegment {
  final LiveMessageEmoticon emoticon;
  const DanmakuEmoticonSegment(this.emoticon);
}

/// 把弹幕文本按表情占位符拆成「文本 / 表情」交替的片段。
///
/// * 能定位到占位符的表情，替换它在文本里的**原始位置**（支持行内混排）；
/// * [LiveMessageEmoticon.name] 为 null 的（服务端没给占位符），追加到末尾；
/// * 文本里没出现过的占位符保持原样文本，不会丢字；
/// * 不产生空文本片段（空消息返回空列表）。
///
/// 拆不出表情时返回单个文本片段，调用方据此退回纯文本渲染。
List<DanmakuSegment> splitDanmakuSegments(
  String text,
  List<LiveMessageEmoticon> emoticons,
) {
  if (emoticons.isEmpty) {
    return text.isEmpty ? const [] : [DanmakuTextSegment(text)];
  }

  final located = <LiveMessageEmoticon>[];
  final appended = <LiveMessageEmoticon>[];
  for (final emoticon in emoticons) {
    final name = emoticon.name;
    if (name != null && name.isNotEmpty && text.contains(name)) {
      located.add(emoticon);
    } else {
      appended.add(emoticon);
    }
  }

  final segments = <DanmakuSegment>[];
  final buffer = StringBuffer();

  void flushText() {
    if (buffer.isNotEmpty) {
      segments.add(DanmakuTextSegment(buffer.toString()));
      buffer.clear();
    }
  }

  var index = 0;
  while (index < text.length) {
    // 同一个位置可能匹配到多个占位符（如 "[a]" 与 "[a][b]"），取最长的
    LiveMessageEmoticon? matched;
    for (final emoticon in located) {
      final name = emoticon.name!;
      if (!text.startsWith(name, index)) {
        continue;
      }
      if (matched == null || name.length > matched.name!.length) {
        matched = emoticon;
      }
    }

    if (matched == null) {
      buffer.write(text[index]);
      index++;
      continue;
    }

    flushText();
    segments.add(DanmakuEmoticonSegment(matched));
    index += matched.name!.length;
  }
  flushText();

  for (final emoticon in appended) {
    segments.add(DanmakuEmoticonSegment(emoticon));
  }
  return segments;
}

/// 已经栅格化好的表情弹幕位图。
///
/// [image] 是从缓存 [ui.Image.clone] 出来的独立句柄，调用方可以（且应该）
/// 在弹幕过期时把它交给弹幕库统一 dispose，不会影响缓存本体。
class DanmakuEmoticonBitmap {
  final ui.Image image;
  final double width;
  final double height;

  const DanmakuEmoticonBitmap({
    required this.image,
    required this.width,
    required this.height,
  });
}

/// 弹幕表情包的图片加载与位图合成。
///
/// 设计取舍（对应用户在 Issue #153 里提的三个顾虑）：
///
/// **流量**：图片一律走 [NetworkImage]，也就是 Flutter 自带的 `ImageCache`。
/// 同一个 URL 只会下载一次、并发请求会自动合并；下方 [_ImageHandleCache]
/// 再额外持有一层句柄缓存，避免图片被 `ImageCache` 淘汰后重复下载。
///
/// **缓存**：合成结果按「片段 + 字号 + 颜色 + dpr」做 LRU（[_CompositeCache]），
/// 命中时用 [ui.Image.clone] 分发独立句柄。这样同一条表情弹幕重复出现时
/// 不需要重新栅格化，而每个 [DanmakuItem] 各自持有的句柄仍能被单独释放。
///
/// **尺寸与透明度**：表情高度跟随弹幕字号（`fontSize * 1.25`，不超过行高），
/// 因此调大弹幕字号时表情同步变大；透明度不用单独处理 —— 弹幕库把整层包在
/// `Opacity(option.opacity)` 里，表情天然跟着一起变透明。
class DanmakuEmoticonRenderer {
  DanmakuEmoticonRenderer._();

  /// 表情高度相对弹幕字号的倍率
  static const double _emoteScale = 1.25;

  /// 表情与相邻内容的间距（相对字号）
  static const double _emoteGapScale = 0.15;

  /// 测试用：替换表情图源，让单测不必依赖网络与真实解码配置。
  ///
  /// 生产路径固定是 [ResizeImage] 包 [NetworkImage]；只有测试会写这个字段。
  @visibleForTesting
  static ImageProvider Function(String url)? debugImageProviderFactory;

  /// 测试用：缓存当前持有的源图句柄（用来断言清缓存时确实释放了它们）。
  @visibleForTesting
  static List<ui.Image> get debugCachedSourceImages =>
      _ImageHandleCache.debugCachedImages;

  /// [DanmakuContentItem.extra] 是否符合表情弹幕的载荷约定
  static bool canRender(Object? extra) {
    return extra is List<LiveMessageEmoticon> && extra.isNotEmpty;
  }

  /// 就地把刚加入的弹幕替换成表情位图。
  ///
  /// 找不到对应的 [DanmakuItem]（弹幕已被清空 / 已过期）时会释放位图，
  /// 不会泄漏。图片加载失败时静默退回库原本渲染的占位符文本。
  static Future<void> apply({
    required DanmakuController controller,
    required DanmakuContentItem content,
    required List<LiveMessageEmoticon> emoticons,
  }) async {
    final DanmakuEmoticonBitmap? bitmap;
    try {
      bitmap = await render(
        text: content.text,
        emoticons: emoticons,
        option: controller.option,
        color: content.color,
      );
    } catch (e, stackTrace) {
      // 调用方是 fire-and-forget 的 unawaited(...)，异常冒出去会被
      // PlatformDispatcher.onError 当成 fatal 上报。这里直接放弃替换，
      // 让弹幕库渲染的占位符文本兜底，与「取不到图就退回文本」保持一致。
      Log.e("表情弹幕渲染失败，退回占位符文本：$e", stackTrace);
      return;
    }
    if (bitmap == null) {
      return;
    }

    final item = _findItem(controller, content);
    if (item == null) {
      bitmap.image.dispose();
      return;
    }

    // 库为这条弹幕生成的纯文本位图已经没用了，先释放再换上表情位图
    item.image?.dispose();
    item.image = bitmap.image;
    item.width = bitmap.width;
    item.height = bitmap.height;
  }

  /// 栅格化表情弹幕位图；返回 null 表示应退回纯文本渲染。
  static Future<DanmakuEmoticonBitmap?> render({
    required String text,
    required List<LiveMessageEmoticon> emoticons,
    required DanmakuOption option,
    required Color color,
  }) async {
    final segments = splitDanmakuSegments(text, emoticons);
    if (!segments.any((e) => e is DanmakuEmoticonSegment)) {
      return null;
    }

    final emoteSegments =
        segments.whereType<DanmakuEmoticonSegment>().toList(growable: false);
    // 每个句柄都由调用方负责归还（见 [_ImageHandleCache.load]）：栅格化一结束
    // 就释放自己这一份，缓存本体与其它并发中的渲染都不受影响。
    final images = await Future.wait(
      emoteSegments.map((e) => _ImageHandleCache.load(e.emoticon.url)),
    );

    try {
      // 图片没取到的表情退回显示占位符文本，保证弹幕本身不丢
      final resolved = <DanmakuSegment>[];
      var imageIndex = 0;
      for (final segment in segments) {
        if (segment is! DanmakuEmoticonSegment) {
          resolved.add(segment);
          continue;
        }
        final image = images[imageIndex++];
        if (image == null) {
          final name = segment.emoticon.name;
          if (name != null && name.isNotEmpty) {
            resolved.add(DanmakuTextSegment(name));
          }
          continue;
        }
        resolved.add(_ResolvedEmoticonSegment(segment.emoticon, image));
      }

      if (!resolved.any((e) => e is _ResolvedEmoticonSegment)) {
        return null;
      }

      return _rasterize(
        text: text,
        segments: resolved,
        option: option,
        color: color,
      );
    } finally {
      for (final image in images) {
        image?.dispose();
      }
    }
  }

  static DanmakuEmoticonBitmap? _rasterize({
    required String text,
    required List<DanmakuSegment> segments,
    required DanmakuOption option,
    required Color color,
  }) {
    final fontSize = option.fontSize;
    final strokeWidth = option.strokeWidth;
    final fontWeight = _fontWeightOf(option.fontWeight);
    final fontFamily = option.fontFamily;
    final devicePixelRatio = _devicePixelRatio();

    final key = _cacheKey(segments, option, color, devicePixelRatio);
    final cached = _CompositeCache.get(key);
    if (cached != null) {
      // 分发独立句柄，缓存本体留给后续相同的弹幕复用
      return DanmakuEmoticonBitmap(
        image: cached.image.clone(),
        width: cached.width,
        height: cached.height,
      );
    }

    // 用与弹幕库一致的方式量出「一行」的高度，让表情弹幕与纯文本弹幕
    // 在同一轨道里高度一致
    final probe = _buildParagraph(
      text.isEmpty ? ' ' : text,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFamily: fontFamily,
    );
    final lineBox = probe.height;
    probe.dispose();

    final emoteHeight = math.min(fontSize * _emoteScale, lineBox);
    final emoteGap = fontSize * _emoteGapScale;
    final textOffsetY = strokeWidth / 2;
    final emoteOffsetY = strokeWidth / 2 + (lineBox - emoteHeight) / 2;

    final paragraphs = <ui.Paragraph>[];
    final emotes = <_PlacedEmoticon>[];
    var width = strokeWidth;

    for (final segment in segments) {
      switch (segment) {
        case DanmakuTextSegment(:final text):
          final paragraph = _buildParagraph(
            text,
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontFamily: fontFamily,
            color: color,
          );
          paragraphs.add(paragraph);
          emotes.add(_PlacedEmoticon(
            paragraph: paragraph,
            text: text,
            x: width,
          ));
          width += paragraph.maxIntrinsicWidth;
        case _ResolvedEmoticonSegment(:final emoticon, :final image):
          if (width > strokeWidth) {
            width += emoteGap;
          }
          final emoteWidth = emoteHeight * _aspectRatio(emoticon, image.image);
          emotes.add(_PlacedEmoticon(
            image: image.image,
            x: width,
            width: emoteWidth,
          ));
          width += emoteWidth;
        case DanmakuEmoticonSegment():
          // 取不到图的表情在 render() 里已经转成了文本片段，这里不会出现
          break;
      }
    }

    final totalWidth = width;
    final totalHeight = lineBox + strokeWidth;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)..scale(devicePixelRatio);
    final imagePaint = Paint()..filterQuality = FilterQuality.medium;

    for (final placed in emotes) {
      final paragraph = placed.paragraph;
      if (paragraph != null) {
        if (strokeWidth > 0) {
          // 复刻弹幕库的描边：文本有黑描边，图片字形不适用
          final strokePaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..color = const Color(0xFF000000);
          final strokeParagraph = _buildParagraph(
            placed.text!,
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontFamily: fontFamily,
            foreground: strokePaint,
          );
          canvas.drawParagraph(strokeParagraph, Offset(placed.x, textOffsetY));
          strokeParagraph.dispose();
        }
        canvas.drawParagraph(paragraph, Offset(placed.x, textOffsetY));
        continue;
      }

      final image = placed.image!;
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(
          placed.x,
          emoteOffsetY,
          placed.width,
          emoteHeight,
        ),
        imagePaint,
      );
    }

    final picture = recorder.endRecording();
    final ui.Image rasterized;
    try {
      rasterized = picture.toImageSync(
        (totalWidth * devicePixelRatio).ceil(),
        (totalHeight * devicePixelRatio).ceil(),
      );
    } finally {
      picture.dispose();
      for (final paragraph in paragraphs) {
        paragraph.dispose();
      }
    }

    _CompositeCache.put(
      key,
      DanmakuEmoticonBitmap(
        image: rasterized,
        width: totalWidth,
        height: totalHeight,
      ),
    );

    // 缓存持有本体，调用方拿到的是可以单独释放的克隆
    return DanmakuEmoticonBitmap(
      image: rasterized.clone(),
      width: totalWidth,
      height: totalHeight,
    );
  }

  /// 释放表情图片与合成位图缓存。
  ///
  /// 切换直播间时调用：表情是**分房间**下发的，留着上一个房间的位图只是白占内存。
  /// 注意源图句柄本来就归 Flutter 的 `ImageCache` 管，这里丢的只是我们的引用。
  static void clearCache() {
    _ImageHandleCache.clear();
    _CompositeCache.clear();
  }

  static double _aspectRatio(LiveMessageEmoticon emoticon, ui.Image image) {
    final width = emoticon.width;
    final height = emoticon.height;
    if (width != null && height != null && width > 0 && height > 0) {
      return width / height;
    }
    if (image.height == 0) {
      return 1;
    }
    return image.width / image.height;
  }

  static ui.Paragraph _buildParagraph(
    String text, {
    required double fontSize,
    required FontWeight fontWeight,
    String? fontFamily,
    Color? color,
    Paint? foreground,
  }) {
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.left,
      fontWeight: fontWeight,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      fontFamily: fontFamily,
    ))
      ..pushStyle(ui.TextStyle(
        // foreground 与 color 互斥，描边段落只给 foreground
        foreground: foreground,
        color: foreground == null ? (color ?? const Color(0xFFFFFFFF)) : null,
        fontSize: fontSize,
        fontFamily: fontFamily,
      ))
      ..addText(text);
    return builder.build()
      ..layout(const ui.ParagraphConstraints(width: double.infinity));
  }

  static String _cacheKey(
    List<DanmakuSegment> segments,
    DanmakuOption option,
    Color color,
    double devicePixelRatio,
  ) {
    final content = segments.map((segment) {
      return switch (segment) {
        DanmakuTextSegment(:final text) => 't:$text',
        DanmakuEmoticonSegment(:final emoticon) => 'e:${emoticon.url}',
        _ResolvedEmoticonSegment(:final emoticon) => 'e:${emoticon.url}',
      };
    }).join('\u0001');
    return [
      content,
      option.fontSize,
      option.fontWeight,
      option.fontFamily ?? '',
      option.strokeWidth,
      option.lineHeight,
      color.toARGB32(),
      devicePixelRatio,
    ].join('|');
  }

  static double _devicePixelRatio() {
    for (final view in ui.PlatformDispatcher.instance.views) {
      return view.devicePixelRatio;
    }
    return 1.0;
  }

  /// [DanmakuOption.fontWeight] 是 [FontWeight.values] 的下标。
  ///
  /// 该值来自持久化的用户设置，脏数据越界时退回 w500，而不是抛 RangeError
  /// 把整条渲染链路打断（弹幕库自己没做保护，我们这条路径不跟着一起炸）。
  static FontWeight _fontWeightOf(int index) {
    if (index < 0 || index >= FontWeight.values.length) {
      return FontWeight.w500;
    }
    return FontWeight.values[index];
  }

  static DanmakuItem<dynamic>? _findItem(
    DanmakuController controller,
    DanmakuContentItem content,
  ) {
    for (final item in controller.scrollDanmaku) {
      if (identical(item.content, content)) {
        return item;
      }
    }
    for (final item in controller.staticDanmaku) {
      if (identical(item.content, content)) {
        return item;
      }
    }
    return null;
  }
}

final class _ResolvedEmoticonSegment extends DanmakuSegment {
  final LiveMessageEmoticon emoticon;
  final ImageInfo image;
  const _ResolvedEmoticonSegment(this.emoticon, this.image);
}

class _PlacedEmoticon {
  final ui.Paragraph? paragraph;

  /// 文本片段的原文，画描边时要再建一个描边段落
  final String? text;
  final ui.Image? image;
  final double x;
  final double width;

  const _PlacedEmoticon({
    this.paragraph,
    this.text,
    this.image,
    required this.x,
    this.width = 0,
  });
}

/// 表情源图句柄缓存。
///
/// 缓存持有的是**自己的一份** [ImageInfo]：`ImageStreamListener` 回调拿到的本来就是
/// 引擎 `clone()` 出来的独立句柄（`ui.Image` 按句柄计数，只有全部句柄都 `dispose`
/// 之后底层像素才会被释放）。因此：
///
/// * 淘汰 / [clear] 时必须主动 `dispose`，否则这条句柄永远活着，即使 Flutter 的
///   `ImageCache` 已经淘汰了该 URL，内存也无法被回收；
/// * 对外分发时再 `clone()` 一份给调用方，这样缓存被淘汰或被清空时，正在渲染中的
///   调用方手里的图片依然有效，不会撞上「绘制已释放的图片」。调用方负责释放自己
///   那一份（见 [DanmakuEmoticonRenderer.render]）。
class _ImageHandleCache {
  static const int _maxEntries = 128;

  /// 解码尺寸上限（像素）。表情在实际显示时高度只有 `字号 × 1.25`，
  /// 这个上限足够宽松，同时挡住异常大的图。
  static const int _maxDecodeSize = 256;

  static final LinkedHashMap<String, ImageInfo> _cache = LinkedHashMap();

  /// 命中时返回一份新句柄，由调用方负责 `dispose`。
  static ImageInfo? _get(String url) {
    final info = _cache.remove(url);
    if (info == null) {
      return null;
    }
    _cache[url] = info;
    return info.clone();
  }

  static void _put(String url, ImageInfo info) {
    _cache.remove(url)?.dispose();
    _cache[url] = info;
    while (_cache.length > _maxEntries) {
      _cache.remove(_cache.keys.first)?.dispose();
    }
  }

  static Future<ImageInfo?> load(String url) {
    final cached = _get(url);
    if (cached != null) {
      return Future.value(cached);
    }

    // 按显示尺寸解码：弹幕表情最大也只有几十逻辑像素，这里给一个宽松上限
    // （覆盖高 dpr + 大字号），避免异常大的图按原尺寸解码后长期占内存。
    // 配合 fit 策略与默认的 allowUpscaling: false，小图不会被放大。
    final provider = DanmakuEmoticonRenderer.debugImageProviderFactory?.call(url) ??
        ResizeImage(
          NetworkImage(url),
          width: _maxDecodeSize,
          height: _maxDecodeSize,
          policy: ResizeImagePolicy.fit,
        );

    // 同 URL 的并发请求由 Flutter 的 ImageCache 合并，这里不重复去重
    final completer = Completer<ImageInfo?>();
    final stream = provider.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        stream.removeListener(listener);
        // 缓存留一份，调用方拿另一份，各自独立释放
        _put(url, info);
        if (!completer.isCompleted) {
          completer.complete(info.clone());
        }
      },
      onError: (error, stackTrace) {
        stream.removeListener(listener);
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  /// 仅供测试与内存压力兜底
  static void clear() {
    for (final info in _cache.values) {
      info.dispose();
    }
    _cache.clear();
  }

  /// 仅供测试：当前缓存持有的源图句柄。
  static List<ui.Image> get debugCachedImages =>
      _cache.values.map((info) => info.image).toList();
}

/// 合成位图缓存，命中时用 [ui.Image.clone] 分发独立句柄。
class _CompositeCache {
  static const int _maxEntries = 64;

  static final LinkedHashMap<String, DanmakuEmoticonBitmap> _cache =
      LinkedHashMap();

  static DanmakuEmoticonBitmap? get(String key) {
    final bitmap = _cache.remove(key);
    if (bitmap == null) {
      return null;
    }
    _cache[key] = bitmap;
    return bitmap;
  }

  static void put(String key, DanmakuEmoticonBitmap bitmap) {
    _cache.remove(key)?.image.dispose();
    _cache[key] = bitmap;
    while (_cache.length > _maxEntries) {
      final oldest = _cache.keys.first;
      _cache.remove(oldest)?.image.dispose();
    }
  }

  static void clear() {
    for (final bitmap in _cache.values) {
      bitmap.image.dispose();
    }
    _cache.clear();
  }
}
