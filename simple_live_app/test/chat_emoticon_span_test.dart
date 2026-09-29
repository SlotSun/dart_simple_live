// 回归测试：聊天区把 B 站表情占位符渲染成行内图片。
//
// 这条路径此前没有任何测试，项目里也不存在 `SelectableText.rich` + `WidgetSpan`
// 的先例（其它行内 widget 全挂在 `Text.rich` 上）。两者底层渲染路径不同：
// 一旦行内 widget 在 `SelectableText` 里不生效，占位符已经被替换成了 span，
// 正文不会退回文本，用户看到的就是「哈哈哈笑死」这种直接丢字的消息。
//
// 因此这里锁三件事：
//   1. 切分结果确实是「文本 / 表情 / 文本」，且表情在 `SelectableText.rich` 里
//      真的以 `Image` 形式出现，宽高按服务端下发比例预留（解码完成前不跳版）；
//   2. 没有表情的消息原样返回纯文本；
//   3. 取图失败时回退显示占位符文本，不丢字。
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:simple_live_app/modules/live_room/chat_emoticon_span.dart';
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
  });
}
