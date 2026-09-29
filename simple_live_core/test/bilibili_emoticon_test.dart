// 回归测试：B 站弹幕表情包解析。
//
// 背景（Issue #153）：B 站的「表情包」弹幕，服务端只在 message 里下发占位符文本
// （如 `[doge]`），图片地址另放在 `info[0][13]` 或 `info[0][15]["extra"]["emots"]`。
// 这里只测解析层，**零网络**。
//
// 两个关键行为：
//   * 只保留 message 里真正出现过的占位符 —— 否则会把整个表情面板（几十个）
//     塞进每条消息对象，白白占内存与流量。
//   * 图片地址统一升到 https —— Android 上 http 图片会被明文策略拦掉。
import 'dart:convert';

import 'package:simple_live_core/simple_live_core.dart';
// 同包内引用 src 是允许的（lint 只限制跨包 implementation_imports）
import 'package:simple_live_core/src/platforms/bilibili/bilibili_emoticon.dart';
import 'package:test/test.dart';

/// 构造一条 DANMU_MSG 的 info 数组，索引与线上载荷对齐
List<dynamic> _infoOf({
  required String message,
  dynamic single,
  Map<String, dynamic>? emots,
}) {
  final meta = List<dynamic>.filled(16, null);
  meta[0] = <dynamic>[0, 0, 0, 16777215];
  meta[1] = message;
  meta[2] = <dynamic>[0, 'tester'];
  meta[3] = 16777215;
  meta[13] = single;
  meta[15] = {
    'extra': emots == null ? '' : json.encode({'emots': emots}),
  };
  return <dynamic>[
    meta,
    message,
    <dynamic>[0, 'tester'],
    0
  ];
}

Map<String, dynamic> _emot(String url, {int w = 20, int h = 20}) => {
      'url': url,
      'width': w,
      'height': h,
      'emoticon_unique': 'room_0_1',
    };

void main() {
  group('parseBilibiliEmoticons', () {
    test('从 extra.emots 解析出占位符与图片地址', () {
      final info = _infoOf(
        message: '哈哈哈[doge]笑死',
        emots: {
          '[doge]': _emot('https://i0.hdslb.com/bfs/live/doge.png'),
        },
      );

      final result = parseBilibiliEmoticons(info, info[1] as String);

      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result.first.name, '[doge]');
      expect(result.first.url, 'https://i0.hdslb.com/bfs/live/doge.png');
      expect(result.first.width, 20);
      expect(result.first.height, 20);
    });

    test('只保留 message 里出现过的占位符，未使用的不下发', () {
      // 线上 emot 面板一次会下发几十个，只有 1 个真的出现在这条弹幕里
      final emots = <String, dynamic>{
        for (var i = 0; i < 30; i++)
          '[$i号表情]': _emot('https://i0.hdslb.com/bfs/live/$i.png'),
      };
      final info = _infoOf(message: '只用[7号表情]', emots: emots);

      final result = parseBilibiliEmoticons(info, info[1] as String);

      expect(result!.length, 1);
      expect(result.first.name, '[7号表情]');
    });

    test('同一条弹幕可混排多个表情，顺序按 emots 下发顺序', () {
      final info = _infoOf(
        message: '[大笑]中间[大哭]',
        emots: {
          '[大笑]': _emot('https://i0.hdslb.com/bfs/live/laugh.png'),
          '[大哭]': _emot('https://i0.hdslb.com/bfs/live/cry.png'),
        },
      );

      final result = parseBilibiliEmoticons(info, info[1] as String);

      expect(result!.map((e) => e.name).toList(), ['[大笑]', '[大哭]']);
    });

    test('下发顺序与正文顺序相反时跟着 map 走（正文位置由渲染层重建）', () {
      // 本层只回答「哪些占位符有图」，占位符在正文里的位置由渲染层的
      // splitDanmakuSegments 重建，所以这里锁的是「按 map 顺序返回」这个契约。
      final info = _infoOf(
        message: '[大笑]中间[大哭]',
        emots: {
          '[大哭]': _emot('https://i0.hdslb.com/bfs/live/cry.png'),
          '[大笑]': _emot('https://i0.hdslb.com/bfs/live/laugh.png'),
        },
      );

      final result = parseBilibiliEmoticons(info, info[1] as String);

      expect(result!.map((e) => e.name).toList(), ['[大哭]', '[大笑]']);
    });

    test('info[0][13] 与 extra.emots 同时下发同一张图时不重复', () {
      // 两种下发方式同时出现，且 message 不是单个占位符 → 单表情的 name 为 null，
      // 去重集合用不上；渲染层对 name == null 的表情是无条件追加到末尾的，
      // 于是同一条弹幕会多贴一张重复的图。
      final info = _infoOf(
        message: '[大笑]哈哈哈',
        emots: {
          '[大笑]': _emot('https://i0.hdslb.com/bfs/live/laugh.png'),
        },
        single: _emot('https://i0.hdslb.com/bfs/live/laugh.png'),
      );

      final result = parseBilibiliEmoticons(info, info[1] as String);

      expect(result!.length, 1, reason: '同一张图只该有一条');
      expect(result.first.name, '[大笑]');
    });

    test('超过上限时在入口就挡下，不会「解析出来又被截断丢掉」', () {
      final info = _infoOf(
        message: List.generate(9, (i) => '[$i号表情]').join(),
        emots: {
          for (var i = 0; i < 9; i++)
            '[$i号表情]': _emot('https://i0.hdslb.com/bfs/live/$i.png'),
        },
        single: _emot('https://i0.hdslb.com/bfs/live/single.png'),
      );

      final result = parseBilibiliEmoticons(info, info[1] as String);

      expect(result!.length, 8, reason: '单条上限 8 个');
      expect(
        result.any((e) => e.url.endsWith('single.png')),
        isFalse,
        reason: 'extra 已凑满上限时，单表情在入口返回，而不是 add 后再被截掉',
      );
    });

    test('info[0][13] 单表情：message 是占位符时用它作为 name', () {
      final info = _infoOf(
        message: '[doge]',
        single: _emot('https://i0.hdslb.com/bfs/live/single.png', w: 40, h: 30),
      );

      final result = parseBilibiliEmoticons(info, info[1] as String);

      expect(result!.length, 1);
      expect(result.first.name, '[doge]');
      expect(result.first.width, 40);
      expect(result.first.height, 30);
    });

    test('info[0][13] 单表情：message 不是占位符时 name 为 null（交给渲染层追加）', () {
      final info = _infoOf(
        message: '',
        single: _emot('https://i0.hdslb.com/bfs/live/only.png'),
      );

      final result = parseBilibiliEmoticons(info, info[1] as String);

      expect(result!.length, 1);
      expect(result.first.name, isNull);
    });

    test('info[0][13] 单表情：只含一个对象的数组形态同样支持', () {
      final info = _infoOf(
        message: '[doge]',
        single: <dynamic>[
          _emot('https://i0.hdslb.com/bfs/live/single.png', w: 40, h: 30),
        ],
      );

      final result = parseBilibiliEmoticons(info, info[1] as String);

      expect(result!.length, 1);
      expect(result.first.name, '[doge]');
      expect(result.first.width, 40);
    });

    test('emots 的 key 不是 [xxx] 占位符形态时丢弃，避免子串替换吞掉正文', () {
      // 渲染层是拿 name 做子串替换的：若接受 "6" 这种 key，"666哈哈哈" 会被换掉
      final info = _infoOf(
        message: '666哈哈哈',
        emots: {
          '6': _emot('https://i0.hdslb.com/bfs/live/six.png'),
          '哈': _emot('https://i0.hdslb.com/bfs/live/ha.png'),
        },
      );

      expect(parseBilibiliEmoticons(info, info[1] as String), isNull);
    });

    test('图片地址统一升到 https', () {
      final info = _infoOf(
        message: '[a][b]',
        emots: {
          '[a]': _emot('//i0.hdslb.com/bfs/live/a.png'),
          '[b]': _emot('http://i0.hdslb.com/bfs/live/b.png'),
        },
      );

      final result = parseBilibiliEmoticons(info, info[1] as String);

      expect(
        result!.map((e) => e.url).toList(),
        [
          'https://i0.hdslb.com/bfs/live/a.png',
          'https://i0.hdslb.com/bfs/live/b.png',
        ],
      );
    });

    test('丢掉不能用的图片地址', () {
      final info = _infoOf(
        message: '[a][b][c]',
        emots: {
          '[a]': _emot('i0.hdslb.com/bfs/live/a.png'), // 相对路径
          '[b]': _emot('ftp://i0.hdslb.com/b.png'), // 不支持的协议
          '[c]': {'width': 20, 'height': 20}, // 没有 url
        },
      );

      expect(parseBilibiliEmoticons(info, info[1] as String), isNull);
    });

    test('extra 不是合法 JSON 时不抛异常', () {
      final meta = List<dynamic>.filled(16, null);
      meta[0] = <dynamic>[0, 0, 0, 16777215];
      meta[1] = '[a]';
      meta[2] = <dynamic>[0, 'tester'];
      meta[15] = {'extra': '{不是 json'};
      final info = <dynamic>[
        meta,
        '[a]',
        <dynamic>[0, 'tester'],
        0
      ];

      expect(parseBilibiliEmoticons(info, info[1] as String), isNull);
    });

    test('异常载荷返回 null 而不是崩溃', () {
      expect(parseBilibiliEmoticons(null, ''), isNull);
      expect(parseBilibiliEmoticons([], ''), isNull);
      expect(parseBilibiliEmoticons([0, 'x'], ''), isNull);
      expect(parseBilibiliEmoticons([<dynamic>[], 'x'], ''), isNull);
      // info[0] 长度不足，取不到 13 / 15
      expect(
          parseBilibiliEmoticons([
            <dynamic>[0, 'x'],
            'x'
          ], 'x'),
          isNull);
    });

    test('单条弹幕的表情数量有上限，防止异常载荷放大内存', () {
      final emots = <String, dynamic>{
        for (var i = 0; i < 30; i++)
          '[$i]': _emot('https://i0.hdslb.com/bfs/live/$i.png'),
      };
      final message = List.generate(30, (i) => '[$i]').join();
      final info = _infoOf(message: message, emots: emots);

      final result = parseBilibiliEmoticons(info, message);

      expect(result!.length, 8);
    });

    test('emots 与 info[0][13] 同时存在时不重复', () {
      final info = _infoOf(
        message: '[doge]',
        single: _emot('https://i0.hdslb.com/bfs/live/single.png'),
        emots: {
          '[doge]': _emot('https://i0.hdslb.com/bfs/live/from_emots.png'),
        },
      );

      final result = parseBilibiliEmoticons(info, info[1] as String);

      expect(result!.length, 1);
      expect(result.first.url, 'https://i0.hdslb.com/bfs/live/from_emots.png');
    });
  });

  test('LiveMessage 携带 emoticons 且可序列化', () {
    final msg = LiveMessage(
      type: LiveMessageType.chat,
      userName: 'u',
      message: '[doge]',
      color: LiveMessageColor.white,
      emoticons: const [
        LiveMessageEmoticon(
          name: '[doge]',
          url: 'https://i0.hdslb.com/bfs/live/doge.png',
          width: 20,
          height: 20,
        ),
      ],
    );

    expect(msg.toString(), contains('[doge]'));
    expect(msg.toString(), contains('doge.png'));

    // emoticons 必须序列化成「对象数组」，而不是「JSON 字符串数组」——
    // 否则消费方 json.decode 之后按对象取值会拿到字符串。
    final decoded = json.decode(msg.toString()) as Map<String, dynamic>;
    final list = decoded['emoticons'] as List<dynamic>;
    expect(list.single, isA<Map<String, dynamic>>());
    expect((list.single as Map<String, dynamic>)['name'], '[doge]');
    expect((list.single as Map<String, dynamic>)['url'], endsWith('doge.png'));

    // 不带表情的普通消息不受影响
    final plain = LiveMessage(
      type: LiveMessageType.chat,
      userName: 'u',
      message: 'hi',
      color: LiveMessageColor.white,
    );
    expect(plain.emoticons, isNull);
    expect(plain.toString(), isNot(contains('emoticons')));
  });
}
