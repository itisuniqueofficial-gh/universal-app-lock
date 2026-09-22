import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_app_lock/features/authentication/pin_flows.dart';
import 'package:universal_app_lock/repositories/key_value_store.dart';
import 'package:universal_app_lock/services/auth/authentication_service.dart';

import 'support/fake_platform_service.dart';

void main() {
  late FakePlatformService fake;
  late AuthenticationService auth;

  setUp(() {
    fake = FakePlatformService();
    auth = AuthenticationService(
      platform: fake,
      store: InMemoryKeyValueStore(),
    );
  });

  Future<void> launch(
    WidgetTester tester,
    Future<bool> Function(BuildContext, AuthenticationService) flow,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => flow(ctx, auth),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, String pin) async {
    for (final d in pin.split('')) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
  }

  testWidgets('setUp stores a PIN when entry and confirmation match', (
    tester,
  ) async {
    await launch(tester, PinFlows.setUp);
    await enter(tester, '123456'); // Set PIN
    await enter(tester, '123456'); // Confirm PIN
    expect(fake.storedPin, '123456');
    expect(await auth.hasPin(), isTrue);
  });

  testWidgets('setUp does not store when confirmation mismatches', (
    tester,
  ) async {
    await launch(tester, PinFlows.setUp);
    await enter(tester, '123456');
    await enter(tester, '654321');
    expect(fake.storedPin, isNull);
    expect(await auth.hasPin(), isFalse);
  });

  testWidgets('remove clears PIN after correct verification', (tester) async {
    fake.storedPin = '123456';
    await launch(tester, PinFlows.remove);
    await enter(tester, '123456'); // verify current
    expect(fake.storedPin, isNull);
    expect(await auth.hasPin(), isFalse);
  });

  testWidgets('remove keeps PIN when verification fails', (tester) async {
    fake.storedPin = '123456';
    await launch(tester, PinFlows.remove);
    await enter(tester, '000000'); // wrong
    expect(fake.storedPin, '123456');
  });
}
