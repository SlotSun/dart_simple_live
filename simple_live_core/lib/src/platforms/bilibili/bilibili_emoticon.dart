import 'dart:convert';

// CoreLog 由 barrel 一并导出，无需再引 src/common/core_log.dart
import 'package:simple_live_core/simple_live_core.dart';

/// 单条弹幕最多解析的表情数量，防止异常载荷放大内存与流量
const int _maxEmoticons = 8;

/// 解析 B 站 `DANMU_MSG` 的 `info` 字段里的表情包信息。
///
/// B 站有两种下发方式，可能同时出现：
/// 1. `info[0][13]`：整条弹幕就是一个表情，形如 `{"url": "...", "width": 20, ...}`
/// 2. `info[0][15]["extra"]`：JSON 字符串，`extra["emots"]` 是 `"[doge]" -> {...}` 的映射，
///    一条弹幕里可以混排多个表情
///
/// 返回 null 表示这条弹幕没有表情。
///
/// 只会保留 [message] 里真正出现过的占位符，避免把整个表情面板（几十个）
/// 都塞进消息对象，白白占内存。
List<LiveMessageEmoticon>? parseBilibiliEmoticons(
  List<dynamic>? info,
  String message,
) {
  if (info == null || info.length < 2) {
    return null;
  }
  final meta = info[0];
  if (meta is! List || meta.isEmpty) {
    return null;
  }

  final result = <LiveMessageEmoticon>[];
  final seenNames = <String>{};

  _parseExtraEmots(meta, message, result, seenNames);
  _parseSingleEmoticon(meta, message, result, seenNames);

  if (result.isEmpty) {
    return null;
  }
  return result;
}

/// 是否已达到单条弹幕的表情数量上限。
///
/// 两个解析入口共用同一个判据，因此 [result] 的最终长度就是上限本身，
/// 出口不需要再 `sublist` 截断一次——截断会掩盖「已经解析出来又被丢掉」
/// 这类看不见的行为（单表情恰好是整条弹幕唯一的表情时尤其致命）。
bool _isFull(List<LiveMessageEmoticon> result) =>
    result.length >= _maxEmoticons;

/// 情况 2：`info[0][15]["extra"]["emots"]` 的占位符映射
void _parseExtraEmots(
  List<dynamic> meta,
  String message,
  List<LiveMessageEmoticon> result,
  Set<String> seenNames,
) {
  if (meta.length <= 15 || message.isEmpty) {
    return;
  }
  final extra = _asString(_asMap(meta[15])?['extra']);
  if (extra == null || extra.isEmpty) {
    return;
  }

  final emots = _asMap(_tryDecodeJson(extra))?['emots'];
  final emotMap = _asMap(emots);
  if (emotMap == null) {
    return;
  }

  for (final entry in emotMap.entries) {
    // 到量就停：后面即使还有命中项也不再解析，省掉无谓的 contains 计算
    if (_isFull(result)) {
      break;
    }
    final name = entry.key;
    // 渲染层是拿 name 做**子串替换**的，非占位符形态的 key（例如 "6"、"哈"）
    // 会把正文里每一处 "6" 都换成图片、把文字吞掉。这里与单表情路径
    // （[_parseSingleEmoticon] 里的 [_isPlaceholder]）保持一致，只接受 [xxx] 形态。
    if (!_isPlaceholder(name) || !message.contains(name)) {
      continue;
    }
    final value = _asMap(entry.value);
    final url = _normalizeUrl(_asString(value?['url']));
    if (url == null || !seenNames.add(name)) {
      continue;
    }
    result.add(LiveMessageEmoticon(
      name: name,
      url: url,
      width: _asInt(value?['width']),
      height: _asInt(value?['height']),
    ));
  }
}

/// 情况 1：`info[0][13]` 的单表情对象
void _parseSingleEmoticon(
  List<dynamic> meta,
  String message,
  List<LiveMessageEmoticon> result,
  Set<String> seenNames,
) {
  if (meta.length <= 13) {
    return;
  }
  final single = _firstMap(meta[13]);
  if (single == null) {
    return;
  }
  final url = _normalizeUrl(_asString(single['url']));
  if (url == null) {
    return;
  }
  // 上限在入口把关（见 [_isFull]）：不这样做的话「extra 已经凑满 8 个」时
  // 这条单独下发的表情会先被 add、再被出口截断掉，行为完全不可见。
  if (_isFull(result)) {
    return;
  }
  // extra.emots 可能已经解析过同一张图（同一条弹幕的两种下发方式同时出现）。
  // message 不是单个占位符时 name 为 null，去重集合用不上，而渲染层对
  // name == null 的表情是**无条件追加到消息末尾**的，于是同一条弹幕会多贴
  // 一张重复的图。
  if (result.any((e) => e.url == url)) {
    return;
  }

  // 单表情弹幕的 message 就是表情名（如 "[doge]"），才能定位到占位符；
  // 否则置 null，交给渲染层追加到末尾。
  final trimmed = message.trim();
  final name = _isPlaceholder(trimmed) ? trimmed : null;
  if (name != null && !seenNames.add(name)) {
    return;
  }
  result.add(LiveMessageEmoticon(
    name: name,
    url: url,
    width: _asInt(single['width']),
    height: _asInt(single['height']),
  ));
}

bool _isPlaceholder(String text) {
  return text.length > 2 && text.startsWith('[') && text.endsWith(']');
}

/// 图片地址规范化：补全协议并统一升到 https
String? _normalizeUrl(String? raw) {
  if (raw == null) {
    return null;
  }
  var url = raw.trim();
  if (url.isEmpty) {
    return null;
  }
  if (url.startsWith('//')) {
    return 'https:$url';
  }
  if (url.startsWith('http://')) {
    return 'https://${url.substring('http://'.length)}';
  }
  // 相对路径或协议不合法的一律丢弃，避免渲染层拿到不能用的地址
  return url.startsWith('https://') ? url : null;
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  return null;
}

/// `info[0][13]` 可能是对象，也可能是只含一个对象的数组
Map<String, dynamic>? _firstMap(dynamic value) {
  if (value is List) {
    if (value.isEmpty) {
      return null;
    }
    return _asMap(value.first);
  }
  return _asMap(value);
}

dynamic _tryDecodeJson(String text) {
  try {
    return json.decode(text);
  } catch (e) {
    CoreLog.error(e);
    return null;
  }
}

String? _asString(dynamic value) => value is String ? value : null;

int? _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}
