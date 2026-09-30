// 回归测试：聊天区把 B 站表情占位符渲染成行内图片。
//
// 这条路径此前没有任何测试，项目里也不存在 `SelectableText.rich` + `WidgetSpan`
// 的先例（其它行内 widget 全挂在 `Text.rich` 上）。两者底层渲染路径不同：
// 一旦行内 widget 在 `SelectableText` 里不生效，占位符已经被替换成了 span，
// 正文不会退回文本，用户看到的就是「哈哈哈笑死」这种直接丢字的消息。
//
// 因此这里锁四件事：
//   1. 切分结果确实是「文本 / 表情 / 文本」，且表情在 `SelectableText.rich` 里
//      真的以 `Image` 形式出现，宽高按服务端下发比例预留（解码完成前不跳版）；
//   2. 没有表情的消息原样返回纯文本；
//   3. 取图失败时回退显示占位符文本，不丢字；
//   4. 关掉表情包开关时整段退回纯文本，同样不丢字。
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:simple_live_app/modules/live_room/danmaku/chat_emoticon_span.dart';
import 'package:simple_live_app/modules/live_room/danmaku/danmaku_emoticon.dart';
import 'package:simple_live_core/simple_live_core.dart';

const double _fontSize = 14;

LiveMessage _message(String text, List<LiveMessageEmoticon>? emoticons) {
  return LiveMessage(
    type: LiveMessageType.chat,
    userName: 'tester',
    message: text,
    color: LiveMessageColor.white,
    emoticons: emoticons,
  );
}

const _doge = LiveMessageEmoticon(
  name: '[doge]',
  url: 'https://example.com/doge.png',
  width: 40,
  height: 30,
);

/// 与生产一致：spans 挂在 `SelectableText.rich` 上（见 live_room_page.dart）。
Widget _host(LiveMessage message) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => SelectableText.rich(
          TextSpan(
            style: const TextStyle(fontSize: _fontSize),
            children: buildChatMessageSpans(
              context,
              message,
              const TextStyle(fontSize: _fontSize),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('buildChatMessageSpans', () {
    testWidgets('占位符切成「文本 / 表情 / 文本」三段', (tester) async {
      late List<InlineSpan> spans;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              spans = buildChatMessageSpans(
                context,
                _message('哈哈哈[doge]笑死', const [_doge]),
                const TextStyle(fontSize: _fontSize),
              );
              return const SizedBox();
            },
          ),
        ),
      );

      expect(spans, hasLength(3));
      expect((spans[0] as TextSpan).text, '哈哈哈');
      expect(spans[1], isA<WidgetSpan>());
      expect((spans[2] as TextSpan).text, '笑死');
    });

    testWidgets('SelectableText.rich 里真的渲染出图片，且按服务端比例预留宽高', (tester) async {
      await tester.pumpWidget(_host(_message('哈哈哈[doge]笑死', const [_doge])));

      // 这一条是本次测试的核心：行内 widget 在 SelectableText 里必须真的生效
      final image = tester.widget<Image>(find.byType(Image));
      final emoteHeight = _fontSize * 1.2;
      expect(image.height, closeTo(emoteHeight, 0.001));
      expect(
        image.width,
        closeTo(emoteHeight * 40 / 30, 0.001),
        reason: '宽度要按服务端下发的 40x30 预留，否则图片到达前这一行宽度是 0',
      );
    });

    testWidgets('没有表情的消息返回纯文本', (tester) async {
      await tester.pumpWidget(_host(_message('哈哈哈笑死', null)));

      expect(find.byType(Image), findsNothing);
      expect(find.textContaining('哈哈哈笑死'), findsOneWidget);
    });

    testWidgets('取图失败时退回占位符文本，不丢字', (tester) async {
      // widget test 里没有真实网络，Image.network 必然失败 → 走 errorBuilder
      await tester.pumpWidget(_host(_message('哈哈哈[doge]笑死', const [_doge])));
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsOneWidget);
      expect(
        find.textContaining('[doge]'),
        findsOneWidget,
        reason: '图片取不到时必须还能看到占位符，而不是整段消失',
      );
    });

    testWidgets('关掉表情包开关时正文一字不少，也不渲染图片', (tester) async {
      late List<InlineSpan> spans;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              spans = buildChatMessageSpans(
                context,
                _message('哈哈哈[doge]笑死', const [_doge]),
                const TextStyle(fontSize: _fontSize),
                emoticonsEnabled: false,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      expect(spans, hasLength(1));
      expect(
        (spans.single as TextSpan).text,
        '哈哈哈[doge]笑死',
        reason: '关掉开关必须整段退回占位符文本；一旦已经切成 span 又不出图，'
            '用户看到的就是直接丢字',
      );
    });

    testWidgets('大表情按服务端物理像素 ÷ dpr 显示，而不是挤在单行里', (tester) async {
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      const big = LiveMessageEmoticon(
        name: '冲鸭',
        url: 'https://example.com/big.png',
        width: 300,
        height: 300,
        large: true,
      );
      await tester.pumpWidget(_host(_message('冲鸭', const [big])));

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.height, closeTo(300 / 2, 0.001));
      expect(image.width, closeTo(300 / 2, 0.001));
    });

    testWidgets('official 系大表情再放大 1.25，upower 系用固定边长', (tester) async {
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      const official = LiveMessageEmoticon(
        name: '害怕',
        url: 'https://example.com/official.png',
        width: 200,
        height: 100,
        large: true,
        emoticonUnique: 'official_12',
      );
      const upower = LiveMessageEmoticon(
        name: '充电',
        url: 'https://example.com/upower.png',
        large: true,
        emoticonUnique: 'upower_[充电]',
      );

      late List<InlineSpan> officialSpans;
      late List<InlineSpan> upowerSpans;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          officialSpans = buildChatMessageSpans(
            context,
            _message('害怕', const [official]),
            const TextStyle(fontSize: _fontSize),
          );
          upowerSpans = buildChatMessageSpans(
            context,
            _message('充电', const [upower]),
            const TextStyle(fontSize: _fontSize),
          );
          return const SizedBox();
        }),
      ));

      Image imageOf(List<InlineSpan> spans) =>
          ((spans.single as WidgetSpan).child as Padding).child as Image;

      // 200x100 物理像素 ÷ dpr2 = 100x50，official 再 ×1.25 → 高 62.5、宽按 2:1 = 125
      expect(imageOf(officialSpans).height, closeTo(62.5, 0.001));
      expect(imageOf(officialSpans).width, closeTo(125, 0.001));
      // upower 不给尺寸：162 物理像素 ÷ dpr2 = 81，1:1
      expect(imageOf(upowerSpans).height, closeTo(81, 0.001));
      expect(imageOf(upowerSpans).width, closeTo(81, 0.001));
    });

    testWidgets('行内表情高度跟随传入 style 的字号', (tester) async {
      // 回归：调用方只传 color 不传字号时，表情会永远按 14pt 算，
      // 用户调「聊天字号」后文字与表情尺寸脱节
      late List<InlineSpan> spans;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              spans = buildChatMessageSpans(
                context,
                _message('哈哈哈[doge]笑死', const [_doge]),
                const TextStyle(fontSize: 28),
              );
              return const SizedBox();
            },
          ),
        ),
      );

      final image = ((spans[1] as WidgetSpan).child as Padding).child as Image;
      expect(image.height, closeTo(28 * 1.2, 0.001));
    });

    testWidgets('大表情的高度与宽高比都有上限，异常载荷不撑爆消息行', (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      const absurd = LiveMessageEmoticon(
        name: '冲鸭',
        url: 'https://example.com/absurd.png',
        width: 1000000,
        height: 100000,
        large: true,
      );
      await tester.pumpWidget(_host(_message('冲鸭', const [absurd])));

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.height, closeTo(kMaxEmoteLogicalHeight, 0.001));
      // 1000000 / 100000 = 10 → 夹到 4:1
      expect(
        image.width,
        closeTo(kMaxEmoteLogicalHeight * kMaxEmoteAspectRatio, 0.001),
      );
    });

    testWidgets('name 为 null 的大表情取图失败时显示可见兜底文案', (tester) async {
      // core 判定 message 不是单个表情名时 name 为 null，此时若回退成空串，
      // 这个槽位就成了不可见空白：用户既看不到表情也看不到占位符，等于丢字
      const big = LiveMessageEmoticon(
        name: null,
        url: 'https://example.com/big.png',
        large: true,
      );
      await tester.pumpWidget(_host(_message('', const [big])));
      await tester.pumpAndSettle();

      expect(find.text(kEmoticonFallbackText), findsOneWidget);
    });
  });

  // 右键落在表情图片上时，Flutter 会把 \uFFFC 当成一个"词"选中：selection 有效
  // 但没有任何可复制 / 可屏蔽的文字。前两版分别栽在「按消息是否含表情一刀切禁掉」
  // （混排消息也没菜单了）和「只看 selection.isValid」（菜单又出来了、还能复制出
  // 占位符）上，所以这条判据单独锁住。
  group('shouldShowContextMenu', () {
    const mixed = '白花300块\uFFFC';

    test('选区只剩表情占位符时不建菜单', () {
      expect(
        shouldShowContextMenu(
          mixed,
          const TextSelection(baseOffset: 6, extentOffset: 7),
        ),
        isFalse,
      );
    });

    test('选区含真实文字时建菜单（混排消息右键正文）', () {
      expect(
        shouldShowContextMenu(
          mixed,
          const TextSelection(baseOffset: 0, extentOffset: 6),
        ),
        isTrue,
      );
    });

    test('selection 无效、折叠或越界时不建菜单，也不抛', () {
      // 右键落在占位符上时框架给的就是这种 -1 / -1 的无效选区
      expect(
        shouldShowContextMenu(
          mixed,
          const TextSelection(baseOffset: -1, extentOffset: -1),
        ),
        isFalse,
      );
      expect(
        shouldShowContextMenu(
          mixed,
          const TextSelection.collapsed(offset: 3),
        ),
        isFalse,
      );
      // isValid 只保证偏移非负、不保证落在文本范围内：越界必须被夹住，
      // 不能在这里抛出它本来要防的 RangeError
      expect(
        shouldShowContextMenu(
          mixed,
          const TextSelection(baseOffset: 3, extentOffset: 999),
        ),
        isTrue,
      );
    });
  });
}
