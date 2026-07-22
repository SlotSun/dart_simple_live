import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';

void main() {
  ThemeData buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppDesignTokens.defaultSeedColor,
      brightness: brightness,
    );
    return brightness == Brightness.dark
        ? AppStyle.darkTheme(colorScheme: colorScheme)
        : AppStyle.light(colorScheme: colorScheme);
  }

  testWidgets('app visual system smoke renders in light and dark themes',
      (tester) async {
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(brightness),
          home: Scaffold(
            appBar: AppBar(title: const Text('Slive')),
            body: const Center(child: Text('visual smoke')),
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Slive'), findsOneWidget);
      expect(find.text('visual smoke'), findsOneWidget);
    }
  });

  testWidgets('navigation destinations keep touchable labels and icons',
      (tester) async {
    var selected = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              bottomNavigationBar: NavigationBar(
                selectedIndex: selected,
                onDestinationSelected: (value) {
                  setState(() => selected = value);
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: '首页',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.favorite_border),
                    selectedIcon: Icon(Icons.favorite),
                    label: '关注',
                  ),
                ],
              ),
              body: Center(child: Text('selected:$selected')),
            );
          },
        ),
      ),
    );

    expect(find.text('selected:0'), findsOneWidget);
    await tester.tap(find.text('关注'));
    await tester.pump();
    expect(find.text('selected:1'), findsOneWidget);
  });
}
