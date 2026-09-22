import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_app_lock/features/authentication/pin_entry_screen.dart';

void main() {
  Future<String?> drive(
    WidgetTester tester,
    List<String> taps, {
    bool submit = true,
  }) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await Navigator.of(ctx).push<String>(
                    MaterialPageRoute<String>(
                      builder: (_) => const PinEntryScreen(title: 'Set PIN'),
                    ),
                  );
                },
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    for (final t in taps) {
      await tester.tap(find.text(t));
      await tester.pump();
    }
    if (submit) {
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
    }
    return result;
  }

  testWidgets('submits the entered PIN', (tester) async {
    final result = await drive(tester, ['1', '2', '3', '4', '5', '6']);
    expect(result, '123456');
  });

  testWidgets('rejects too-short PIN and shows error', (tester) async {
    final result = await drive(tester, ['1', '2']);
    // Did not pop; still on the entry screen with an error.
    expect(result, isNull);
    expect(find.textContaining('at least 4 digits'), findsOneWidget);
  });
}
