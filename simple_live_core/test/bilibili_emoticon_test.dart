// 回归测试：B 站弹幕表情包解析。
//
// 背景（Issue #153）：B 站的「表情包」弹幕，服务端只在 message 里下发占位符文本
// （如 `[doge]`），图片地址另放在 `info[0][13]` 或 `info[0][15]["extra"]["emots"]`。
// 这里只测解析层，**零网络**。
//
// 两个关键行为：
//   * 只保留 message 里真正出现过的表情（`[xxx]` 占位符，或整条弹幕就是表情名）
//     —— 否则会把整个表情面板（几十个）塞进每条消息对象，白白占内存与流量。
//   * 图片地址统一升到 https —— Android 上 http 图片会被明文策略拦掉。
import 'dart:convert';

import 'package:simple_live_core/simple_live_core.dart';
// 同包内引用 src 是允许的（lint 只限制跨包 implementation_imports）
import 'package:simple_live_core/src/platforms/bilibili/bilibili_emoticon.dart';
import 'package:test/test.dart';

/// 构造一条 DANMU_MSG 的 info 数组，索引与线上载荷对齐。
///
/// [withExtraSlot] 控制 `info[0]` 有没有第 15 位：大表情弹幕的真实载荷是
/// 「只到 13/14 位、没有 extra」，那是本功能最主要的场景。
List<dynamic> _infoOf({
  required String message,
  dynamic single,
  Map<String, dynamic>? emots,
  bool withExtraSlot = true,
}) {
  final meta = List<dynamic>.filled(withExtraSlot ? 16 : 15, null);
  meta[0] = <dynamic>[0, 0, 0, 16777215];
  meta[1] = message;
  meta[2] = <dynamic>[0, 'tester'];
  meta[3] = 16777215;
  meta[13] = single;
  if (withExtraSlot) {
    meta[15] = {
      'extra': emots == null ? '' : json.encode({'emots': emots}),
    };
  }
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

    test('info[0][13] 单表情：message 是不带方括号的表情名时整串作为 name', () {
      // B 站从表情面板单独发的表情（「冲鸭」「大胆！」）没有 [xxx] 占位符，
      // 也不带 extra.emots，message 就是表情名本身 → 整串替换，不能追加到末尾，
      // 否则就是「文字 + 图片」并存。
      final info = _infoOf(
        message: '大胆！',
        single: _emot('https://i0.hdslb.com/bfs/live/dadan.png', w: 60, h: 60),
      );

      final named = parseBilibiliEmoticons(info, info[1] as String);

      expect(named!.length, 1);
      expect(named.first.name, '大胆！');
    });

    test('info[0][13] 是空对象字符串时不产生表情（混排文字弹幕走 emots 路径）', () {
      final info = _infoOf(message: '白花300块', single: '{}');

      expect(parseBilibiliEmoticons(info, info[1] as String), isNull);
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

    test('key 不带方括号但整条弹幕就是它时命中（如「冲鸭」）', () {
      // B 站从表情面板单独发的表情不带 [] 占位符，message 就是表情名本身，
      // 且不夹带任何正文，所以整串替换吞不掉别的字。
      final info = _infoOf(
        message: '冲鸭',
        emots: {
          '冲鸭': _emot('https://i0.hdslb.com/bfs/live/chongya.png'),
        },
      );

      final result = parseBilibiliEmoticons(info, info[1] as String);

      expect(result!.length, 1);
      expect(result.first.name, '冲鸭');
      expect(result.first.url, 'https://i0.hdslb.com/bfs/live/chongya.png');
    });

    test('key 不带方括号且夹在正文里时仍然丢弃，不做子串替换', () {
      final info = _infoOf(
        message: '我们一起冲鸭',
        emots: {
          '冲鸭': _emot('https://i0.hdslb.com/bfs/live/chongya.png'),
        },
      );

      expect(parseBilibiliEmoticons(info, info[1] as String), isNull);
    });

    test('整条弹幕与 key 相等时忽略首尾空白', () {
      final info = _infoOf(
        message: '  冲鸭  ',
        emots: {
          '冲鸭': _emot('https://i0.hdslb.com/bfs/live/chongya.png'),
        },
      );

      final result = parseBilibiliEmoticons(info, info[1] as String);

      expect(result!.single.name, '冲鸭');
    });

    test('info[0][13] 带 url 但 message 夹带正文时退回追加，不整串替换', () {
      // 兜底：宁可「文字 + 图片」并存，也不能把整条正文替换成一张图
      final info = _infoOf(
        message: '冲鸭 哈哈哈',
        single: _emot('https://i0.hdslb.com/bfs/live/a.png'),
      );

      final result = parseBilibiliEmoticons(info, info[1] as String);

      expect(result!.single.name, isNull);
    });

    test('emots 裸名整串命中时记 large，避免被 info[0][13] 去重后画小', () {
      final info = _infoOf(
        message: '冲鸭',
        emots: {
          '冲鸭': _emot('https://i0.hdslb.com/bfs/live/chongya.png'),
        },
      );

      final result = parseBilibiliEmoticons(info, info[1] as String);

      expect(result!.single.large, isTrue);
    });

    test('large 区分两种下发方式，emoticon_unique 一并带出', () {      // 大表情的尺寸口径（物理像素 ÷ dpr、official/upower 分类）依赖这两个字段
      final viaSingle = _infoOf(
        message: '冲鸭',
        single: _emot('https://i0.hdslb.com/bfs/live/a.png'),
      );
      final viaEmots = _infoOf(
        message: '[doge]',
        emots: {
          '[doge]': _emot('https://i0.hdslb.com/bfs/live/b.png'),
        },
      );

      final a = parseBilibiliEmoticons(viaSingle, viaSingle[1] as String)!;
      final b = parseBilibiliEmoticons(viaEmots, viaEmots[1] as String)!;

      expect(a.single.large, isTrue);
      expect(a.single.emoticonUnique, 'room_0_1');
      expect(b.single.large, isFalse);
      expect(b.single.emoticonUnique, 'room_0_1');
    });

    test('大表情弹幕的真实载荷：info[0] 没有第 15 位也能解析', () {
      // 线上大表情弹幕就是「只到 13/14 位、没有 extra」，此前所有用例都造的是
      // 16 位数组，这条主路径其实没被覆盖过
      final info = _infoOf(
        message: '冲鸭',
        single: _emot('https://i0.hdslb.com/bfs/live/chongya.png', w: 108, h: 108),
        withExtraSlot: false,
      );

      final result = parseBilibiliEmoticons(info, info[1] as String);

      expect(result!.length, 1);
      expect(result.single.name, '冲鸭');
      expect(result.single.large, isTrue);
      expect(result.single.width, 108);
    });

    test('extra 与 info[0][13] 是同一张图时，large 不因 extra 先入队而丢失', () {
      // 两入口的 large 判据必须一致：否则同一条 [doge] 会因为 extra 在不在
      // 而得到相反的尺寸口径（被 extra 抢先记成行内小表情）
      final info = _infoOf(
        message: '[doge]',
        single: _emot('https://i0.hdslb.com/bfs/live/doge.png'),
        emots: {
          '[doge]': _emot('https://i0.hdslb.com/bfs/live/doge.png'),
        },
      );

      final result = parseBilibiliEmoticons(info, info[1] as String);

      expect(result!.length, 1);
      expect(result.single.large, isTrue);
    });

    test('占位符与正文混排时不整串替换（异常载荷兜底）', () {
      // 「[大笑]哈哈哈」这种既含占位符又含正文的载荷，若把整条 message 当 name，
      // 渲染层的最长匹配会把正文一起吞成一张图。中文正文不含空白，
      // 光靠长度/空白判断挡不住，必须靠「含方括号就不是单个表情名」
      final info = _infoOf(
        message: '[大笑]哈哈哈',
        single: _emot('https://i0.hdslb.com/bfs/live/a.png'),
      );

      final result = parseBilibiliEmoticons(info, info[1] as String);

      expect(result!.single.name, isNull);
    });

    test('裸表情名的长度上限是 12 字', () {
      final twelve = _infoOf(
        message: '一二三四五六七八九十甲乙',
        single: _emot('https://i0.hdslb.com/bfs/live/a.png'),
      );
      expect(
        parseBilibiliEmoticons(twelve, twelve[1] as String)!.single.name,
        '一二三四五六七八九十甲乙',
      );

      final thirteen = _infoOf(
        message: '一二三四五六七八九十甲乙丙',
        single: _emot('https://i0.hdslb.com/bfs/live/a.png'),
      );
      expect(
        parseBilibiliEmoticons(thirteen, thirteen[1] as String)!.single.name,
        isNull,
      );
    });

    test('无空白的「表情名+正文」按整串替换处理（已知取舍，锁住预期）', () {
      // 判据分不出「冲鸭哈哈哈」是长表情名还是表情+正文。B 站真实表情名里就有
      // 「哈哈哈」「么么哒」这类重复字，再收紧形态会先把合法表情误杀、退回
      // SlotSun 报的「文字 + 图片」并存。所以这里按整串替换处理：
      // 代价是伪造/异常载荷下自己这条弹幕会丢字，不崩也不涉及安全。
      final info = _infoOf(
        message: '冲鸭哈哈哈',
        single: _emot('https://i0.hdslb.com/bfs/live/a.png'),
      );

      expect(parseBilibiliEmoticons(info, info[1] as String)!.single.name,
          '冲鸭哈哈哈');
    });

    test('extra 的裸名 key 与单表情路径共用同一判据', () {
      // 不共用的话，超长 / 含空白的裸名 key 恰好等于整条正文时，extra 路径会
      // 整串替换吞掉正文，而单表情路径对同样的载荷是拒绝的
      final tooLong = _infoOf(
        message: '一二三四五六七八九十甲乙丙',
        emots: {
          '一二三四五六七八九十甲乙丙':
              _emot('https://i0.hdslb.com/bfs/live/x.png'),
        },
      );
      expect(parseBilibiliEmoticons(tooLong, tooLong[1] as String), isNull);

      final spaced = _infoOf(
        message: '冲鸭 哈哈哈',
        emots: {
          '冲鸭 哈哈哈': _emot('https://i0.hdslb.com/bfs/live/y.png'),
        },
      );
      expect(parseBilibiliEmoticons(spaced, spaced[1] as String), isNull);
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
