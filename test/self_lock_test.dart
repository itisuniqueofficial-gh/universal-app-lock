import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_app_lock/features/permissions/security_permissions_screen.dart';
import 'package:universal_app_lock/repositories/key_value_store.dart';
import 'package:universal_app_lock/services/auth/authentication_service.dart';

import 'support/fake_platform_service.dart';

void main() {
  testWidgets('Self Lock cannot be enabled without a PIN', (tester) async {
    final fake = FakePlatformService(); // no PIN configured
    final auth = AuthenticationService(
      platform: fake,
      store: InMemoryKeyValueStore(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SecurityPermissionsScreen(platform: fake, auth: auth),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Self Lock'), findsOneWidget);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    // Rejected with guidance; native never enabled.
    expect(find.textContaining('Set up a PIN'), findsOneWidget);
    expect(fake.selfLock, isFalse);
  });

  testWidgets('Self Lock enables when a PIN exists', (tester) async {
    final fake = FakePlatformService()..storedPin = '123456';
    final auth = AuthenticationService(
      platform: fake,
      store: InMemoryKeyValueStore(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SecurityPermissionsScreen(platform: fake, auth: auth),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(fake.selfLock, isTrue);
  });
}
