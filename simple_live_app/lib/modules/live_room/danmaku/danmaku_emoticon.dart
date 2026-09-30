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

/// 缓存世代：[DanmakuEmoticonRenderer.clearCache] 时自增。
///
/// 在途的取图 / 合成在写回缓存前核对世代，否则「退出直播间清空缓存之后，
/// 在途结果又落回静态缓存」，要等到下一次进/出房间才被清掉。
int _cacheGeneration = 0;

/// 表情宽高比的安全区间，挡极端比例的载荷把消息行 / 弹幕位图撑爆
const double kMinEmoteAspectRatio = 0.25;
const double kMaxEmoteAspectRatio = 4.0;

/// 大表情（`info[0][13]` 单独下发）里 upower 系的固定物理像素边长——服务端不给尺寸。
/// 口径与 PiliNara 一致。
const double kUpowerEmotePhysicalPx = 162.0;

/// 表情显示高度的绝对兜底上限（逻辑像素）。
///
/// 正常情况下限由调用方按「最多占两个轨道 / 两行」给（见 [emoteDisplayHeight] 的
/// `maxHeight`），这里只防异常载荷把位图撑到几百像素。
const double kMaxEmoteLogicalHeight = 240.0;

/// 表情最多占多少个轨道 / 多少行。
///
/// 上游的要求：大表情再大也不许超过两行，否则弹幕密集时会把画面挡得太多。
const double kMaxEmoteLines = 2.0;

/// 表情的显示高度，聊天区与弹幕渲染器共用这一份**大表情**口径。
///
/// 行内小表情不经过这里：聊天区是 `fontSize * 1.2`、弹幕区是
/// `min(fontSize * 1.25, 行高)`，两处历来就不同，各自保留。
/// 大表情服务端下发的是**物理像素**，换回逻辑像素后大于单行行高：official 系再放大
/// 1.25，upower 系用固定边长，服务端没给尺寸时兜底两行。
///
/// [maxHeight] 是这一处允许占多少行/轨道（弹幕区传两个轨道高、聊天区传两行高），
/// 上游明确要求大表情最多占 [kMaxEmoteLines] 行，不许霸屏；没传时只用
/// [kMaxEmoteLogicalHeight] 这个绝对兜底。
double emoteDisplayHeight(
  LiveMessageEmoticon emoticon, {
  required double fontSize,
  required double dpr,
  double? maxHeight,
}) {
  if (!emoticon.large) {
    return fontSize * 1.2;
  }
  final double raw;
  if (emoticon.isUpower) {
    raw = kUpowerEmotePhysicalPx / dpr;
  } else {
    final serverHeight = emoticon.height?.toDouble();
    if (serverHeight == null || serverHeight <= 0) {
      raw = fontSize * 1.2 * kMaxEmoteLines;
    } else {
      raw = serverHeight / dpr * (emoticon.isOfficial ? 1.25 : 1.0);
    }
  }
  // 下界也要夹进上界内：fontSize 来自持久化设置，脏数据把它撑到极大时下界会
  // 反超上界，`num.clamp` 直接抛 ArgumentError；聊天区是在 build 里同步调它，
  // 异常会打断整帧渲染。
  final ceiling = maxHeight == null
      ? kMaxEmoteLogicalHeight
      : math.min(maxHeight, kMaxEmoteLogicalHeight);
  return raw.clamp(math.min(fontSize * 1.2, ceiling), ceiling);
}

/// 表情的宽高比，夹在安全区间内（服务端比例极端时不撑爆行宽）
double emoteAspectRatio(LiveMessageEmoticon emoticon, double fallbackRatio) {
  final width = emoticon.width?.toDouble();
  final height = emoticon.height?.toDouble();
  if (width == null || height == null || width <= 0 || height <= 0) {
    return fallbackRatio.clamp(kMinEmoteAspectRatio, kMaxEmoteAspectRatio);
  }
  return (width / height).clamp(kMinEmoteAspectRatio, kMaxEmoteAspectRatio);
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
/// **尺寸与透明度**：行内小表情的高度跟随弹幕字号（`fontSize * 1.25`，不超过
/// 行高），调大弹幕字号时表情同步变大；大表情（[LiveMessageEmoticon.large]）按
/// 服务端物理像素换回逻辑像素，最多占 [kMaxEmoteLines] 个轨道高（见
/// [emoteDisplayHeight]）。弹幕库的滚动轨道是等高网格、排轨不认单条 `item.height`，
/// 所以超过一行的大表情会与相邻轨道重叠，这是上游确认接受的取舍。
/// 透明度不用单独处理 —— 弹幕库把整层包在 `Opacity(option.opacity)` 里，
/// 表情天然跟着一起变透明。
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
    DanmakuEmoticonBitmap? bitmap;
    var handedOver = false;
    try {
      bitmap = await render(
        text: content.text,
        emoticons: emoticons,
        option: controller.option,
        color: content.color,
      );
      if (bitmap == null) {
        return;
      }

      final item = _findItem(controller, content);
      if (item == null) {
        return;
      }

      // 库为这条弹幕生成的纯文本位图已经没用了，先释放再换上表情位图。
      // 等图的这几百毫秒里该条可能已被库回收并 dispose 过位图，这一句会抛，
      // 所以整段都要在 try 里（见下方注释）。
      item.image?.dispose();
      item.image = bitmap.image;
      handedOver = true;
      item.width = bitmap.width;
      item.height = bitmap.height;
    } catch (e, stackTrace) {
      // 调用方是 fire-and-forget 的 unawaited(...)，异常冒出去会被
      // PlatformDispatcher.onError 当成 fatal 上报（Crashlytics 记 fatal）。
      // 这里直接放弃替换，让弹幕库渲染的占位符文本兜底，与「取不到图就退回
      // 文本」保持一致。
      Log.e("表情弹幕渲染失败，退回占位符文本：$e", stackTrace);
    } finally {
      // 没交接给弹幕项的一律由我们回收：含「找不到弹幕项」与「dispose 旧位图
      // 时抛异常」两条路径，否则这张合成位图就永久泄漏。
      if (!handedOver) {
        bitmap?.image.dispose();
      }
    }
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
    final generation = _cacheGeneration;
    final dpr = _devicePixelRatio();
    // 每个句柄都由调用方负责归还（见 [_ImageHandleCache.load]）：栅格化一结束
    // 就释放自己这一份，缓存本体与其它并发中的渲染都不受影响。
    // 单个 url 取图失败不能让整个 Future.wait 抛出去：那样其余已 clone 出来的
    // 句柄拿不到引用、永远无法 dispose，是 ui.Image 句柄泄漏。用 async 闭包包
    // 一层，连「load 在返回 Future 之前就同步抛出」也一并收敛成 null。
    final images = await Future.wait(
      emoteSegments.map((e) async {
        try {
          return await _ImageHandleCache.load(
            e.emoticon.url,
            _decodeTargetPx(
              e.emoticon,
              fontSize: option.fontSize,
              dpr: dpr,
            ),
          );
        } catch (_) {
          return null;
        }
      }),
    );

    try {
      // 等图期间缓存被清过（换房间 / 退出直播间）：这批结果已经没人要了，
      // 合成位图也不该再落回缓存，直接放弃
      if (generation != _cacheGeneration) {
        return null;
      }
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

    final emoteGap = fontSize * _emoteGapScale;

    final paragraphs = <ui.Paragraph>[];
    final emotes = <_PlacedEmoticon>[];
    // 左右各留 strokeWidth / 2：描边会向字形外扩 strokeWidth / 2，只留一侧会把
    // 最右侧字形的描边裁掉，还会让内容相对预留框整体偏移
    var width = strokeWidth / 2;
    var maxEmoteHeight = 0.0;
    var placedAny = false;
    var lastWasEmote = false;

    for (final segment in segments) {
      switch (segment) {
        case DanmakuTextSegment(:final text):
          // 表情与文字之间两侧都要有间隙：只在表情前插会让 `[doge]你好` 紧贴，
          // 与聊天区左右对称的 Padding 口径不一致
          if (placedAny && lastWasEmote) {
            width += emoteGap;
          }
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
          placedAny = true;
          lastWasEmote = false;
        case _ResolvedEmoticonSegment(:final emoticon, :final image):
          if (placedAny) {
            width += emoteGap;
          }
          // 大表情按物理像素换回逻辑像素，会比单行高出一截，最多允许占两个轨道。
          // 弹幕库的轨道是等高网格、不认单条高度，所以哪怕只占两轨也会与相邻轨道
          // 重叠，这是上游确认过的取舍。
          final h = emoticon.large
              ? emoteDisplayHeight(
                  emoticon,
                  fontSize: fontSize,
                  dpr: devicePixelRatio,
                  maxHeight: (lineBox + strokeWidth) * kMaxEmoteLines,
                )
              : math.min(fontSize * _emoteScale, lineBox);
          if (h > maxEmoteHeight) {
            maxEmoteHeight = h;
          }
          final emoteWidth = h * _aspectRatio(emoticon, image.image);
          emotes.add(_PlacedEmoticon(
            image: image.image,
            x: width,
            width: emoteWidth,
            height: h,
          ));
          width += emoteWidth;
          placedAny = true;
          lastWasEmote = true;
        case DanmakuEmoticonSegment():
          // 取不到图的表情在 render() 里已经转成了文本片段，这里不会出现
          break;
      }
    }

    final totalWidth = width + strokeWidth / 2;
    final contentHeight = math.max(lineBox, maxEmoteHeight);
    final totalHeight = contentHeight + strokeWidth;
    final textOffsetY = strokeWidth / 2 + (contentHeight - lineBox) / 2;

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
          strokeWidth / 2 + (contentHeight - placed.height) / 2,
          placed.width,
          placed.height,
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
    // 在途的取图 / 合成写回缓存前会核对世代，见 [_cacheGeneration]
    _cacheGeneration++;
    _ImageHandleCache.clear();
    _CompositeCache.clear();
  }

  static double _aspectRatio(LiveMessageEmoticon emoticon, ui.Image image) {
    final width = emoticon.width;
    final height = emoticon.height;
    if (width != null && height != null && width > 0 && height > 0) {
      return emoteAspectRatio(emoticon, 1);
    }
    if (image.height == 0) {
      return 1;
    }
    return emoteAspectRatio(emoticon, image.width / image.height);
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
    // 弹幕文本用户可控，可能恰好包含分隔符；带长度前缀后内容与分隔符不会混淆，
    // 避免两条不同弹幕拼出同一个 key 而命中彼此的合成位图
    final content = segments.map((segment) {
      return switch (segment) {
        DanmakuTextSegment(:final text) => 't:${text.length}:$text',
        // 同一个 url 可能以大表情 / 行内小表情两种口径出现，尺寸不同不能共用缓存
        DanmakuEmoticonSegment(:final emoticon) => _emoteKey(emoticon),
        _ResolvedEmoticonSegment(:final emoticon) => _emoteKey(emoticon),
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

  static String _emoteKey(LiveMessageEmoticon emoticon) {
    // 与文本片段一样带长度前缀：url 与 emoticon_unique 都来自服务端，只用 `:`
    // 拼接会让字段边界被挪动（url 尾部含 "true" 之类），拼出同一个 key 命中
    // 彼此的合成位图
    final url = emoticon.url;
    final unique = emoticon.emoticonUnique ?? '';
    return 'e:${url.length}:$url:${emoticon.large}:${unique.length}:$unique:'
        '${emoticon.width ?? 0}x${emoticon.height ?? 0}';
  }

  /// 源图的期望解码尺寸（物理像素），按「显示尺寸 × dpr」推导。
  ///
  /// 只为把高 dpr 下的大表情往上抬（显示高度可到 [kMaxEmoteLogicalHeight]，
  /// 解码尺寸跟不上会欠采样）。这里只给期望值，夹取在 [_ImageHandleCache.load]
  /// 里做，下限与历史一致——解码期缩放的质量比绘制期差，不能按小尺寸提前缩。
  static double _decodeTargetPx(
    LiveMessageEmoticon emoticon, {
    required double fontSize,
    required double dpr,
  }) {
    final display = emoticon.large
        ? emoteDisplayHeight(emoticon, fontSize: fontSize, dpr: dpr)
        : fontSize * _emoteScale;
    return display * dpr;
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

  /// 表情自己的显示高度，大表情会比单行行高高，绘制时按它垂直居中
  final double height;

  const _PlacedEmoticon({
    this.paragraph,
    this.text,
    this.image,
    required this.x,
    this.width = 0,
    this.height = 0,
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

  /// 解码尺寸的区间（物理像素）。期望值由「显示尺寸 × dpr」推导
  /// （见 [DanmakuEmoticonRenderer._decodeTargetPx]），这里只做夹取。
  ///
  /// 下限必须留在 256：`ResizeImage` 是在**解码阶段**缩放的，用的是解码器的
  /// 廉价降采样，比「按较大尺寸解码 + 绘制时 `filterQuality.medium` 缩放」明显
  /// 更糊（实测大表情按显示尺寸解码后反而糊了）。所以只在高 dpr + 大表情真的
  /// 需要更多像素时才往上调，绝不低于原来的 256。
  static const int _baselineDecodeSize = 256;
  static const int _maxDecodeSize = 512;

  static final LinkedHashMap<String, ImageInfo> _cache = LinkedHashMap();

  /// 同一张表情会按不同显示尺寸解码（字号 / dpr 不同，大表情与行内小表情也不同），
  /// key 带上尺寸，避免后算出来的小尺寸把大尺寸那份覆盖掉、大表情发糊。
  static String _key(String url, int target) => '$url@$target';

  /// 命中时返回一份新句柄，由调用方负责 `dispose`。
  static ImageInfo? _get(String key) {
    final info = _cache.remove(key);
    if (info == null) {
      return null;
    }
    _cache[key] = info;
    return info.clone();
  }

  static void _put(String key, ImageInfo info) {
    _cache.remove(key)?.dispose();
    _cache[key] = info;
    while (_cache.length > _maxEntries) {
      _cache.remove(_cache.keys.first)?.dispose();
    }
  }

  static Future<ImageInfo?> load(String url, double desiredPhysicalPx) {
    final target = desiredPhysicalPx.ceil().clamp(_baselineDecodeSize, _maxDecodeSize);
    final key = _key(url, target);
    final cached = _get(key);
    if (cached != null) {
      return Future.value(cached);
    }
    final generation = _cacheGeneration;

    // 按实际显示尺寸解码：配合 fit 策略与默认的 allowUpscaling: false，
    // 小图不会被放大，大图也只解到用得到的尺寸。
    final provider = DanmakuEmoticonRenderer.debugImageProviderFactory?.call(url) ??
        ResizeImage(
          NetworkImage(url),
          width: target,
          height: target,
          policy: ResizeImagePolicy.fit,
        );

    // 同 URL + 同尺寸的并发请求由 Flutter 的 ImageCache 合并，这里不重复去重
    final completer = Completer<ImageInfo?>();
    final stream = provider.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        stream.removeListener(listener);
        // 等图期间缓存被清过：这份结果已经没人要，直接释放，不落缓存也不分发
        if (generation != _cacheGeneration) {
          info.dispose();
          if (!completer.isCompleted) {
            completer.complete(null);
          }
          return;
        }
        // 缓存留一份，调用方拿另一份，各自独立释放
        _put(key, info);
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
