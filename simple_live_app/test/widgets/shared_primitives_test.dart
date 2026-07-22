import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/widgets/desktop_refresh_button.dart';
import 'package:simple_live_app/widgets/filter_button.dart';
import 'package:simple_live_app/widgets/none_border_circular_textfield.dart';
import 'package:simple_live_app/widgets/settings/settings_action.dart';
import 'package:simple_live_app/widgets/settings/settings_switch.dart';
import 'package:simple_live_app/widgets/shadow_card.dart';

void main() {
  Widget buildApp(Widget child, {bool disableAnimations = false}) {
    return MaterialApp(
      theme: AppStyle.light(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppDesignTokens.defaultSeedColor,
        ),
      ),
      builder: (context, appChild) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: disableAnimations,
          ),
          child: appChild!,
        );
      },
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('shared interaction primitives', () {
    testWidgets('ShadowCard forwards tap and long press', (tester) async {
      var taps = 0;
      var longPresses = 0;

      await tester.pumpWidget(
        buildApp(
          ShadowCard(
            onTap: () => taps++,
            onLongPress: () => longPresses++,
            child: const SizedBox(width: 120, height: 72),
          ),
        ),
      );

      await tester.tap(find.byType(ShadowCard));
      await tester.pump();
      expect(taps, 1);

      await tester.longPress(find.byType(ShadowCard));
      await tester.pump();
      expect(longPresses, 1);
    });

    testWidgets('ShadowCard avoids interaction wrappers without callbacks',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
          const ShadowCard(
            child: SizedBox(width: 120, height: 72),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(ShadowCard),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
    });

    testWidgets('ShadowCard disables transform motion when requested',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
          ShadowCard(
            onTap: () {},
            child: const SizedBox(width: 120, height: 72),
          ),
          disableAnimations: true,
        ),
      );

      expect(find.byType(AnimatedScale), findsNothing);
    });

    testWidgets('FilterButton is tappable and keeps a 44px target',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildApp(
          FilterButton(
            selected: true,
            text: '直播中',
            onTap: () => tapped = true,
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(FilterButton)).height,
        greaterThanOrEqualTo(44),
      );
      await tester.tap(find.text('直播中'));
      expect(tapped, isTrue);
    });

    testWidgets('DesktopRefreshButton swaps action for progress',
        (tester) async {
      var refreshes = 0;
      await tester.pumpWidget(
        buildApp(
          DesktopRefreshButton(
            refreshing: false,
            onPressed: () => refreshes++,
          ),
        ),
      );

      await tester.tap(find.byTooltip('刷新'));
      expect(refreshes, 1);

      await tester.pumpWidget(
        buildApp(
          DesktopRefreshButton(
            refreshing: true,
            onPressed: () => refreshes++,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byTooltip('刷新'), findsNothing);
    });
  });

  group('shared form and settings primitives', () {
    testWidgets('NoneBorderCircularTextField preserves controller callbacks',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var changed = '';

      await tester.pumpWidget(
        buildApp(
          NoneBorderCircularTextField(
            editingController: controller,
            hintText: '搜索',
            needPadding: false,
            onChanged: (value) => changed = value,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '音乐');
      expect(controller.text, '音乐');
      expect(changed, '音乐');
    });

    testWidgets('SettingsAction renders value and forwards tap',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        buildApp(
          SettingsAction(
            title: '播放设置',
            subtitle: '调整播放器行为',
            value: '默认',
            onTap: () => taps++,
          ),
        ),
      );

      expect(find.text('播放设置'), findsOneWidget);
      expect(find.text('调整播放器行为'), findsOneWidget);
      expect(find.text('默认'), findsOneWidget);
      await tester.tap(find.text('播放设置'));
      expect(taps, 1);
    });

    testWidgets('SettingsSwitch forwards the selected value', (tester) async {
      bool? changed;
      await tester.pumpWidget(
        buildApp(
          SettingsSwitch(
            value: false,
            title: '自动播放',
            onChanged: (value) => changed = value,
          ),
        ),
      );

      await tester.tap(find.byType(Switch));
      expect(changed, isTrue);
    });
  });
}
