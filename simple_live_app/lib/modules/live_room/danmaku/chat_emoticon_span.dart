import 'package:material_ui/material_ui.dart';
import 'package:simple_live_core/simple_live_core.dart';

import 'danmaku_emoticon.dart';

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
/// * 消息没有表情、或 [emoticonsEnabled] 为 false 时原样返回纯文本 Span；
/// * 图片加载失败时回退显示占位符文本（如 `[doge]`），不丢字。
List<InlineSpan> buildChatMessageSpans(
  BuildContext context,
  LiveMessage message,
  TextStyle style, {
  bool emoticonsEnabled = true,
}) {
  final emoticons = message.emoticons;
  if (!emoticonsEnabled || emoticons == null || emoticons.isEmpty) {
    return [TextSpan(text: message.message, style: style)];
  }

  final segments = splitDanmakuSegments(message.message, emoticons);
  if (segments.isEmpty ||
      (segments.length == 1 && segments.first is DanmakuTextSegment)) {
    return [TextSpan(text: message.message, style: style)];
  }

  final fontSize = style.fontSize ?? 14.0;
  // 只依赖 devicePixelRatio：MediaQuery.maybeOf 会订阅整个 MediaQueryData，
  // 键盘弹起 / 内边距变化都会让聊天列表项无谓重建
  final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;

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
    final emoteHeight = emoteDisplayHeight(emoticon, fontSize: fontSize, dpr: dpr);
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
          // 不开 gaplessPlayback：聊天列表项无 key 且会从头部淘汰复用，
          // 开着会让复用的行在新图解码完成前继续显示上一条消息的表情
          filterQuality: FilterQuality.medium,
          // 按显示尺寸解码，避免聊天区滚动时大图占内存
          cacheHeight: (emoteHeight * dpr).round(),
          // 取图失败时回退成可见文字：name 为 null 的大表情（core 判定 message
          // 不是单个表情名）若回退成空串，这个槽位就成了不可见空白，用户既看不到
          // 表情也看不到占位符，等于丢字
          errorBuilder: (_, __, ___) => Text(
            emoticon.name ?? kEmoticonFallbackText,
            style: style,
          ),
        ),
      ),
    );
  }).toList();
}

/// `WidgetSpan` 在 `InlineSpan.toPlainText()` 里留下的对象替换符。
const String kEmoticonPlaceholder = '\uFFFC';

/// 取图失败、又没有占位符文本可回退时显示的文案。
const String kEmoticonFallbackText = '[表情]';

/// 剥掉表情占位符与首尾空白后，选区里剩下的真实文字。
String stripEmoticonPlaceholder(String text) =>
    text.replaceAll(kEmoticonPlaceholder, '').trim();

/// 这条选区该不该建上下文菜单。
///
/// 右键落在表情图片上时，Flutter 会把那个占位字符当成一个"词"选中：selection
/// 看着有效，但里面没有任何可复制 / 可屏蔽的文字。而 `TextSelection.isValid`
/// 只保证偏移非负、**不保证落在文本范围内**，直接拿它去取子串正是
/// `RangeError (start)` 的来源，所以先夹取再判断。
/// 混排消息（`白花300块[热]`）右键落在正文上时选区里有真实文字，仍然放行。
bool shouldShowContextMenu(String text, TextSelection selection) {
  if (!selection.isValid) {
    return false;
  }
  final start = selection.start.clamp(0, text.length);
  final end = selection.end.clamp(0, text.length);
  if (start >= end) {
    return false;
  }
  return stripEmoticonPlaceholder(text.substring(start, end)).isNotEmpty;
}

/// 表情的显示宽度：按 [emoteAspectRatio] 还原比例（服务端缺失或比例极端时
/// 由它夹到安全区间 / 1:1 兜底），与弹幕渲染器同一份口径。
double _emoteWidth(LiveMessageEmoticon emoticon, double height) {
  return height * emoteAspectRatio(emoticon, 1.0);
}
