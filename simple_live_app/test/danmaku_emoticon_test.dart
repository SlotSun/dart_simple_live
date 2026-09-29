// 表情弹幕的分词回归测试。
//
// 背景（Issue #153）：B 站的表情包弹幕，服务端只在 message 里给占位符文本
// （如 `[doge]`），图片地址单独下发。渲染前必须先把文本切成
// 「文本 / 表情」交替的片段，才能做行内混排。
//
// 这里只测纯函数，**不涉及网络与渲染**。
//
// 例外见文件末尾「图源句柄生命周期」一组：那几条会把图源换成内存图片，
// 用来锁住缓存的 clone / dispose 约定，不需要网络。
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_live_app/modules/live_room/player/danmaku_emoticon.dart';
import 'package:simple_live_core/simple_live_core.dart';

LiveMessageEmoticon _emot(String? name, String url) =>
    LiveMessageEmoticon(name: name, url: url, width: 20, height: 20);

/// 把片段列表压成便于断言的形式
List<String> _shape(List<DanmakuSegment> segments) {
  return segments.map((segment) {
    return switch (segment) {
      DanmakuTextSegment(:final text) => 'text:$text',
      DanmakuEmoticonSegment(:final emoticon) => 'emote:${emoticon.name}',
      _ => 'unknown',
    };
  }).toList();
}

void main() {
  // 句柄生命周期那组要走 ImageProvider / ui.Image，需要绑定与视图。
  TestWidgetsFlutterBinding.ensureInitialized();

  group('splitDanmakuSegments', () {
    test('表情在中间时切成 文本-表情-文本', () {
      final segments = splitDanmakuSegments(
        '哈哈哈[doge]笑死',
        [_emot('[doge]', 'https://i0.hdslb.com/doge.png')],
      );

      expect(_shape(segments), ['text:哈哈哈', 'emote:[doge]', 'text:笑死']);
    });

    test('整条弹幕只有表情时不产生空文本片段', () {
      final segments = splitDanmakuSegments(
        '[doge]',
        [_emot('[doge]', 'https://i0.hdslb.com/doge.png')],
      );

      expect(_shape(segments), ['emote:[doge]']);
    });

    test('多个表情按文本顺序排列', () {
      final segments = splitDanmakuSegments(
        '[大笑]中间[大哭][大笑]',
        [
          _emot('[大笑]', 'https://i0.hdslb.com/laugh.png'),
          _emot('[大哭]', 'https://i0.hdslb.com/cry.png'),
        ],
      );

      expect(_shape(segments), [
        'emote:[大笑]',
        'text:中间',
        'emote:[大哭]',
        'emote:[大笑]',
      ]);
    });

    test('name 为 null 的表情追加到末尾，不改动原文', () {
      final segments = splitDanmakuSegments(
        '只有文字',
        [_emot(null, 'https://i0.hdslb.com/only.png')],
      );

      expect(_shape(segments), ['text:只有文字', 'emote:null']);
    });

    test('name 在文本里没出现时保持原文本，不吞字', () {
      final segments = splitDanmakuSegments(
        '[不存在]正文',
        [_emot('[doge]', 'https://i0.hdslb.com/doge.png')],
      );

      // 该表情定位不到占位符，落到末尾追加；原文完整保留
      expect(_shape(segments), ['text:[不存在]正文', 'emote:[doge]']);
    });

    test('没有表情时返回单个文本片段（调用方据此退回纯文本渲染）', () {
      expect(_shape(splitDanmakuSegments('普通弹幕', [])), ['text:普通弹幕']);
      expect(_shape(splitDanmakuSegments('', [])), isEmpty);
    });

    test('同一位置多个占位符可匹配时取最长的', () {
      final segments = splitDanmakuSegments(
        '[a][b]',
        [
          _emot('[a]', 'https://i0.hdslb.com/a.png'),
          _emot('[a][b]', 'https://i0.hdslb.com/ab.png'),
        ],
      );

      expect(_shape(segments), ['emote:[a][b]']);
    });

    test('表情之间的空文本不产生额外片段', () {
      final segments = splitDanmakuSegments(
        '[a][b]',
        [
          _emot('[a]', 'https://i0.hdslb.com/a.png'),
          _emot('[b]', 'https://i0.hdslb.com/b.png'),
        ],
      );

      expect(_shape(segments), ['emote:[a]', 'emote:[b]']);
    });
  });

  group('DanmakuEmoticonRenderer.canRender', () {
    test('只认非空的表情列表', () {
      expect(DanmakuEmoticonRenderer.canRender(null), isFalse);
      expect(
          DanmakuEmoticonRenderer.canRender(<LiveMessageEmoticon>[]), isFalse);
      expect(DanmakuEmoticonRenderer.canRender('普通载荷'), isFalse);
      expect(
        DanmakuEmoticonRenderer.canRender([_emot('[doge]', 'https://x/y.png')]),
        isTrue,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 图源句柄的生命周期
  //
  // `ui.Image` 按句柄计数：只有全部句柄都 dispose 之后底层像素才会释放，
  // 而句柄集合本身是强引用，所以「少 dispose」是永久泄漏、「多 dispose」会
  // 直接崩掉正在绘制的弹幕。这几条用例锁住两条约定：
  //   1. 缓存命中时对外分发的是 clone 出来的独立句柄（否则第二次渲染会撞上
  //      「绘制已释放的图片」）；
  //   2. 清缓存释放的是缓存本体，不该把已经分发出去的合成位图一起释放。
  // ---------------------------------------------------------------------------
  group('DanmakuEmoticonRenderer 的图源句柄生命周期', () {
    late Uint8List png;

    const emoticon = LiveMessageEmoticon(
      name: '[doge]',
      url: 'https://i0.hdslb.com/bfs/live/doge.png',
      width: 20,
      height: 20,
    );

    setUpAll(() async {
      png = await _makePng();
    });

    tearDown(() {
      DanmakuEmoticonRenderer.debugImageProviderFactory = null;
      DanmakuEmoticonRenderer.clearCache();
    });

    Future<DanmakuEmoticonBitmap?> render() {
      return DanmakuEmoticonRenderer.render(
        text: '[doge]',
        emoticons: const [emoticon],
        option: const DanmakuOption(),
        color: const Color(0xFFFFFFFF),
      );
    }

    test('缓存命中时返回独立句柄：连续渲染两次都不会画到已释放的图', () async {
      DanmakuEmoticonRenderer.debugImageProviderFactory =
          (_) => MemoryImage(png);

      final first = await render();
      final second = await render();

      expect(first, isNotNull);
      expect(second, isNotNull);
      // 两条句柄互不影响，各自都能安全释放
      expect(first!.image.debugDisposed, isFalse);
      expect(second!.image.debugDisposed, isFalse);

      first.image.dispose();
      second.image.dispose();
    });

    test('clearCache 会把缓存的源图句柄一并释放（否则是永久泄漏）', () async {
      DanmakuEmoticonRenderer.debugImageProviderFactory =
          (_) => MemoryImage(png);

      final bitmap = await render();
      expect(bitmap, isNotNull);

      // 缓存里应当留下了一份源图句柄（防 ImageCache 淘汰后重复下载）
      final cached = DanmakuEmoticonRenderer.debugCachedSourceImages;
      expect(cached, isNotEmpty);
      expect(cached.every((image) => image.debugDisposed), isFalse);

      DanmakuEmoticonRenderer.clearCache();

      // ui.Image 按句柄计数，少 dispose 一次底层像素就永远回收不了
      expect(
        cached.every((image) => image.debugDisposed),
        isTrue,
        reason: '清缓存时必须逐条 dispose 缓存持有的源图句柄',
      );

      bitmap!.image.dispose();
    });

    test('clearCache 只释放缓存本体，不影响已分发出去的合成位图', () async {
      DanmakuEmoticonRenderer.debugImageProviderFactory =
          (_) => MemoryImage(png);

      final first = await render();
      expect(first, isNotNull);

      DanmakuEmoticonRenderer.clearCache();

      expect(first!.image.debugDisposed, isFalse);

      // 清空后重新取图 + 栅格化仍然可用
      final second = await render();
      expect(second, isNotNull);

      first.image.dispose();
      second!.image.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // apply：把已经加进弹幕库的那条弹幕就地换成表情位图
  //
  // 这段代码有两个只有出错时才暴露的分支：找不到 item（弹幕已被清空 / 已过期）
  // 时必须把位图释放，否则永久泄漏；命中时必须先释放库生成的文本位图再换新的。
  // 另外整条链路是 fire-and-forget 调用的（调用方 unawaited），异常冒出去会被
  // PlatformDispatcher.onError 记成 fatal，所以「不向外抛」也要锁住。
  // ---------------------------------------------------------------------------
  group('DanmakuEmoticonRenderer.apply', () {
    late Uint8List png;

    const emoticon = LiveMessageEmoticon(
      name: '[doge]',
      url: 'https://i0.hdslb.com/bfs/live/doge.png',
      width: 20,
      height: 20,
    );

    setUpAll(() async {
      png = await _makePng();
    });

    setUp(() {
      DanmakuEmoticonRenderer.debugImageProviderFactory =
          (_) => MemoryImage(png);
    });

    tearDown(() {
      DanmakuEmoticonRenderer.debugImageProviderFactory = null;
      DanmakuEmoticonRenderer.clearCache();
    });

    test('命中时释放库生成的文本位图，并换上表情位图', () async {
      final content = DanmakuContentItem<dynamic>('哈哈哈[doge]笑死');
      final textImage = _makeImage();
      final item = DanmakuItem<dynamic>(
        content: content,
        width: 80,
        height: 18,
        image: textImage,
      );

      await DanmakuEmoticonRenderer.apply(
        controller: _controllerWith([item]),
        content: content,
        emoticons: const [emoticon],
      );

      expect(textImage.debugDisposed, isTrue, reason: '旧位图不释放就是泄漏');
      expect(item.image, isNotNull);
      expect(identical(item.image, textImage), isFalse);
      expect(item.image!.debugDisposed, isFalse);
      expect(item.width, greaterThan(0));
      expect(item.height, greaterThan(0));

      item.image!.dispose();
    });

    test('找不到对应的弹幕项时静默返回，不抛异常', () async {
      // 弹幕已被 clear() / 已过期：库的列表里找不到，位图只能就地释放
      await expectLater(
        DanmakuEmoticonRenderer.apply(
          controller: _controllerWith(const []),
          content: DanmakuContentItem<dynamic>('[doge]'),
          emoticons: const [emoticon],
        ),
        completes,
      );
    });

    test('渲染链路抛异常时自己吞掉，不让异常外溢成 fatal', () async {
      _ThrowingImageStream.addListenerCalls = 0;
      DanmakuEmoticonRenderer.debugImageProviderFactory =
          (_) => _ThrowingImageProvider();

      await expectLater(
        DanmakuEmoticonRenderer.apply(
          controller: _controllerWith(const []),
          content: DanmakuContentItem<dynamic>('[doge]'),
          emoticons: const [emoticon],
        ),
        completes,
      );

      expect(
        _ThrowingImageStream.addListenerCalls,
        greaterThan(0),
        reason: '必须真的走到取图链路里抛异常的那一步，否则这条用例是假通过',
      );
    });
  });
}

/// 造一张最小的 ui.Image，用来模拟弹幕库为纯文本弹幕生成的占位符位图。
ui.Image _makeImage() {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    const ui.Rect.fromLTWH(0, 0, 4, 4),
    ui.Paint()..color = const ui.Color(0xFF0000FF),
  );
  final picture = recorder.endRecording();
  final image = picture.toImageSync(4, 4);
  picture.dispose();
  return image;
}

/// 一个「什么都不做」的 [DanmakuController]：本组用例只走 render + _findItem，
/// 不需要真的驱动弹幕库的画布。
DanmakuController<dynamic> _controllerWith(List<DanmakuItem<dynamic>> items) {
  return DanmakuController<dynamic>(
    addDanmaku: (_) {},
    updateOption: (_) {},
    pause: () {},
    resume: () {},
    clear: () {},
    getOption: () => const DanmakuOption(),
    isRunning: () => true,
    findDanmaku: (_) => const <DanmakuItem<dynamic>>[],
    findSingleDanmaku: (_) => null,
    getViewWidth: () => 360,
    getViewHeight: () => 200,
    scrollDanmaku: items,
    staticDanmaku: <DanmakuItem<dynamic>>[],
    specialDanmaku: <DanmakuItem<dynamic>>[],
  );
}

/// 加监听就抛异常的图源，用来验证 [DanmakuEmoticonRenderer.apply] 的兜底分支：
/// render 抛出的异常必须被它自己吞掉，不能外溢成 fatal。
///
/// 不能直接覆写 `ImageProvider.resolve`——它是 `@nonVirtual`（analyzer 会报
/// invalid_override_of_non_virtual_member）。改成覆写 `@protected` 的
/// [ImageProvider.createStream]，让 resolve 链路拿到一个会抛的流。
class _ThrowingImageProvider extends ImageProvider<Object> {
  @override
  Future<Object> obtainKey(ImageConfiguration configuration) async => this;

  @override
  ImageStream createStream(ImageConfiguration configuration) =>
      _ThrowingImageStream();
}

class _ThrowingImageStream extends ImageStream {
  /// 被调用次数：用例靠它确认异常确实来自取图链路的这一步，
  /// 而不是 resolve 在更早的地方就失败了（那样用例会假通过）。
  static int addListenerCalls = 0;

  @override
  void addListener(ImageStreamListener listener) {
    addListenerCalls++;
    throw StateError('模拟取图失败');
  }
}

/// 生成一张 4×4 的 PNG，作为不依赖网络的测试图源。
Future<Uint8List> _makePng() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    const ui.Rect.fromLTWH(0, 0, 4, 4),
    ui.Paint()..color = const ui.Color(0xFFFF0000),
  );
  final picture = recorder.endRecording();
  final image = picture.toImageSync(4, 4);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  picture.dispose();
  image.dispose();
  return data!.buffer.asUint8List();
}
