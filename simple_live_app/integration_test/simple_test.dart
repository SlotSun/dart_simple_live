import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('visual shell smoke test', (tester) async {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppDesignTokens.defaultSeedColor,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppStyle.light(colorScheme: colorScheme),
        home: Scaffold(
          appBar: AppBar(title: const Text('Slive')),
          body: const Center(child: Text('visual smoke')),
        ),
      ),
    );

    expect(find.text('Slive'), findsOneWidget);
    expect(find.text('visual smoke'), findsOneWidget);
  });
}
