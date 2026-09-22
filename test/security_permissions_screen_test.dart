import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_app_lock/features/permissions/security_permissions_screen.dart';

import 'support/fake_platform_service.dart';

void main() {
  testWidgets('shows NOT CONFIGURED and permission cards when nothing is set', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SecurityPermissionsScreen(platform: FakePlatformService()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Security & Permissions'), findsOneWidget);
    expect(find.text('NOT CONFIGURED'), findsOneWidget);
    expect(find.text('Display over other apps'), findsOneWidget);
    expect(find.text('Usage Access'), findsOneWidget);
    // Two required permissions expose an Open Settings action.
    expect(find.text('Open Settings'), findsNWidgets(2));
  });

  testWidgets('shows READY when PIN set and required permissions granted', (
    tester,
  ) async {
    final fake = FakePlatformService(
      usageGranted: true,
      overlayGranted: true,
      biometric: 'available',
    )..storedPin = '123456';

    await tester.pumpWidget(
      MaterialApp(home: SecurityPermissionsScreen(platform: fake)),
    );
    await tester.pumpAndSettle();

    expect(find.text('READY'), findsOneWidget);
    // Granted permissions offer "Review in Settings" instead of "Open Settings".
    expect(find.text('Review in Settings'), findsNWidgets(2));
  });
}
