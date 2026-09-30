import 'dart:convert';

// CoreLog 由 barrel 一并导出，无需再引 src/common/core_log.dart
import 'package:simple_live_core/simple_live_core.dart';

/// 单条弹幕最多解析的表情数量，防止异常载荷放大内存与流量
const int _maxEmoticons = 8;

/// 表情名长度上限：B 站表情名都是几个字，超过基本可以认定 message 夹带了正文
const int _maxEmoticonNameLength = 12;

final RegExp _whitespace = RegExp(r'\s');

/// 解析 B 站 `DANMU_MSG` 的 `info` 字段里的表情包信息。
///
/// B 站有两种下发方式，可能同时出现：
/// 1. `info[0][13]`：整条弹幕就是一个表情，形如 `{"url": "...", "width": 20, ...}`
/// 2. `info[0][15]["extra"]`：JSON 字符串，`extra["emots"]` 是 `"[doge]" -> {...}` 的映射，
///    一条弹幕里可以混排多个表情。key 也可能是不带方括号的表情名（如 `"冲鸭"`），
///    这类表情 B 站是单独发送的，整条 message 就是它本身，判据见 [_canReplace]
///
/// 返回 null 表示这条弹幕没有表情。
///
/// 只会保留 [message] 里真正出现过的表情，避免把整个表情面板（几十个）
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

  // 先读 info[0][13]：它带不带可用 url 是「这条弹幕是不是大表情」的唯一依据。
  // 两个解析入口都拿它来定 large，否则同一个 message 会因为 extra 在不在
  // 而得到相反的尺寸口径（extra 先入队时 single 会被去重丢掉）。
  final single = _readSingleEmoticon(meta);

  final result = <LiveMessageEmoticon>[];
  final seenNames = <String>{};

  _parseExtraEmots(meta, message, single?.url, result, seenNames);
  _appendSingleEmoticon(single, message, result, seenNames);

  if (result.isEmpty) {
    return null;
  }
  return result;
}

/// `info[0][13]` 里的单表情对象；没有可用图片地址时返回 null。
///
/// 混排文字的弹幕这一位是字符串 `"{}"`（[_firstMap] 拿不到 Map），所以返回
/// null 就等价于「这条不是大表情」。
_SingleEmoticon? _readSingleEmoticon(List<dynamic> meta) {
  if (meta.length <= 13) {
    return null;
  }
  final single = _firstMap(meta[13]);
  if (single == null) {
    return null;
  }
  final url = _normalizeUrl(_asString(single['url']));
  if (url == null) {
    return null;
  }
  return _SingleEmoticon(
    url: url,
    width: _asInt(single['width']),
    height: _asInt(single['height']),
    emoticonUnique: _asString(single['emoticon_unique']),
  );
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
  String? bigEmoticonUrl,
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
    if (!_canReplace(name, message)) {
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
      // 与 info[0][13] 是同一张图，或整条弹幕就是这个裸名 key —— 两种都是
      // B 站单独发的大表情。不标 large 的话，随后 info[0][13] 会因 url 去重
      // 被丢弃，渲染层就按行内小表情口径把它画得很小
      large: url == bigEmoticonUrl ||
          (!_isPlaceholder(name) &&
              _standaloneEmoticonName(message.trim()) == name),
      emoticonUnique: _asString(value?['emoticon_unique']),
    ));
  }
}

/// 情况 1：`info[0][13]` 的单表情对象（已由 [_readSingleEmoticon] 校验过 url）
void _appendSingleEmoticon(
  _SingleEmoticon? single,
  String message,
  List<LiveMessageEmoticon> result,
  Set<String> seenNames,
) {
  if (single == null) {
    return;
  }
  // 上限在入口把关（见 [_isFull]）：不这样做的话「extra 已经凑满 8 个」时
  // 这条单独下发的表情会先被 add、再被出口截断掉，行为完全不可见。
  if (_isFull(result)) {
    return;
  }
  // extra.emots 可能已经解析过同一张图（同一条弹幕的两种下发方式同时出现）。
  // 拿不到 name 时去重集合用不上，而渲染层对 name == null 的表情是**无条件追加
  // 到消息末尾**的，于是同一条弹幕会多贴一张重复的图。
  if (result.any((e) => e.url == single.url)) {
    return;
  }

  final name = _standaloneEmoticonName(message.trim());
  if (name != null && !seenNames.add(name)) {
    return;
  }
  result.add(LiveMessageEmoticon(
    name: name,
    url: single.url,
    width: single.width,
    height: single.height,
    // info[0][13] 带可用 url 就是「大表情」，渲染层按物理像素换回逻辑像素放大显示
    large: true,
    emoticonUnique: single.emoticonUnique,
  ));
}

/// 整条 message 能不能当作单个表情名（决定渲染层是整串替换还是追加到末尾）。
///
/// 只接受两种：本身就是一个 `[xxx]` 占位符；或完全不含方括号的裸表情名
/// （B 站单独发表情时 message 就是它，如「冲鸭」「大胆！」）。
/// 出现「占位符 + 正文」的混排（如 `[大笑]哈哈哈`）时退回 null 交给渲染层追加：
/// 中文正文一般不含空白，光靠长度与空白判断挡不住这种形态，整串替换会把正文吞掉。
String? _standaloneEmoticonName(String trimmed) {
  if (trimmed.isEmpty) {
    return null;
  }
  if (_isPlaceholder(trimmed)) {
    return trimmed;
  }
  if (trimmed.contains('[') || trimmed.contains(']')) {
    return null;
  }
  if (trimmed.length > _maxEmoticonNameLength ||
      _whitespace.hasMatch(trimmed)) {
    return null;
  }
  return trimmed;
}

bool _isPlaceholder(String text) {
  return text.length > 2 && text.startsWith('[') && text.endsWith(']');
}

/// `emots` 的这个 key 能不能拿来替换 [message] 里的文字。
///
/// 渲染层是拿 key 做**子串替换**的，所以只有两种形态是安全的：
/// 1. `[xxx]` 占位符——本身足够独特，正文里出现即命中，一条弹幕可以混排多个；
/// 2. 整条弹幕就是这个 key——B 站从表情面板单独发的表情（如「冲鸭」）不带方括号，
///    但也不会夹带任何正文，整串替换吞不掉别的字。
///
/// 只满足 `message.contains(key)` 的非占位符 key（例如 "6"、"哈"）必须挡掉：
/// 那会把正文里每一处都换成图片。
bool _canReplace(String name, String message) {
  if (name.isEmpty) {
    return false;
  }
  if (_isPlaceholder(name)) {
    return message.contains(name);
  }
  // 与单表情路径共用同一判据：超长 / 含空白 / 含方括号的裸名 key 不允许整串替换，
  // 否则异常载荷下渲染层会把整条正文换成一张图
  return _standaloneEmoticonName(message.trim()) == name;
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

/// `info[0][13]` 的单表情对象，校验过 url 之后的形态。
///
/// 先读它再解析 emots，是为了让「这条弹幕是不是大表情」只有一个判据来源
/// （见 [_readSingleEmoticon]）。
class _SingleEmoticon {
  final String url;
  final int? width;
  final int? height;
  final String? emoticonUnique;

  const _SingleEmoticon({
    required this.url,
    this.width,
    this.height,
    this.emoticonUnique,
  });
}
