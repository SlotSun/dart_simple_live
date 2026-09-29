import 'package:material_ui/material_ui.dart';
import 'package:simple_live_core/simple_live_core.dart';

import 'player/danmaku_emoticon.dart';

/// 聊天区的行内表情渲染。
///
/// 与弹幕共用 [splitDanmakuSegments] 的分词结果，但聊天区不需要把表情
/// 栅格化成位图——[SelectableText.rich] 的 `WidgetSpan` 天然支持行内图片，
/// 图片走 `Image.network`。
///
/// 注意：这里的 `Image.network(..., cacheHeight: ...)` 会生成
/// `ResizeImage(NetworkImage(url), height: h)`，而弹幕渲染器用的是
/// `ResizeImage(NetworkImage(url), width: 256, height: 256, policy: fit)`；
/// `ImageCache` 以「provider + 尺寸参数」为键，两者**不是**同一条缓存条目，
/// 同一张表情在弹幕区与聊天区会各自解码一次，IO 平台上的 `NetworkImage` 也
/// 没有第二层 HTTP 响应缓存（只有内存里的 `ImageCache`），因此两处会各发一次
/// 请求。之所以不强行共用：弹幕区要的是「一次解码给同屏多条弹幕复用」，
/// 聊天区要的是「按显示高度解码」，统一成 256 反而让聊天区多占几十倍内存。
///
/// * 消息没有表情时原样返回纯文本 Span；
/// * 图片加载失败时回退显示占位符文本（如 `[doge]`），不丢字。
List<InlineSpan> buildChatMessageSpans(
  BuildContext context,
  LiveMessage message,
  TextStyle style,
) {
  final emoticons = message.emoticons;
  if (emoticons == null || emoticons.isEmpty) {
    return [TextSpan(text: message.message, style: style)];
  }

  final segments = splitDanmakuSegments(message.message, emoticons);
  if (segments.isEmpty ||
      (segments.length == 1 && segments.first is DanmakuTextSegment)) {
    return [TextSpan(text: message.message, style: style)];
  }

  final fontSize = style.fontSize ?? 14.0;
  final emoteHeight = fontSize * 1.2;
  final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;

  return segments.map((segment) {
    // 弹幕渲染器的内部片段类型（_ResolvedEmoticonSegment）对外不可见，
    // splitDanmakuSegments 的返回值里不会出现，通配兜底即可。
    final emoticon = switch (segment) {
      DanmakuEmoticonSegment(:final emoticon) => emoticon,
      _ => null,
    };
    if (emoticon == null) {
      return TextSpan(
        text: segment is DanmakuTextSegment ? segment.text : '',
        style: style,
      );
    }
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Image.network(
          emoticon.url,
          height: emoteHeight,
          // 解码完成前 RenderImage 的宽度是 0，不预留宽度会让这一行在图片到达后
          // 重新排版（聊天列表里表现为文字跳变）。服务端给了原始宽高就按它定宽，
          // 与弹幕渲染器的宽高比口径保持一致。
          width: _emoteWidth(emoticon, emoteHeight),
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          // 按显示尺寸解码，避免聊天区滚动时大图占内存
          cacheHeight: (emoteHeight * dpr).round(),
          errorBuilder: (_, __, ___) => Text(emoticon.name ?? '', style: style),
        ),
      ),
    );
  }).toList();
}

/// 表情的显示宽度：优先按服务端下发的原始宽高还原比例，缺失时按 1:1 兜底。
double _emoteWidth(LiveMessageEmoticon emoticon, double height) {
  final double? width = emoticon.width?.toDouble();
  final double? sourceHeight = emoticon.height?.toDouble();
  if (width == null ||
      sourceHeight == null ||
      width <= 0 ||
      sourceHeight <= 0) {
    return height;
  }
  return height * width / sourceHeight;
}
