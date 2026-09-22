import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:universal_app_lock/core/constants/app_constants.dart';
import 'package:universal_app_lock/features/about/about_screen.dart';
import 'package:universal_app_lock/features/app_lock/dashboard_screen.dart';
import 'package:universal_app_lock/repositories/key_value_store.dart';
import 'package:universal_app_lock/repositories/protected_apps_repository.dart';

import 'support/fake_platform_service.dart';

Widget _dashboard() {
  final repo = ProtectedAppsRepository(InMemoryKeyValueStore());
  return MaterialApp(
    home: DashboardScreen(platform: FakePlatformService(), repository: repo),
  );
}

void main() {
  testWidgets('Dashboard shows real, non-faked state', (tester) async {
    await tester.pumpWidget(_dashboard());
    await tester.pumpAndSettle();

    expect(find.text(AppInfo.appName), findsWidgets);
    // Protection must NOT be shown as active.
    expect(find.text('Not set up'), findsOneWidget);
    expect(find.text('Protected Apps'), findsWidgets);
    // With no permissions granted, 2 must be reported as needing to be granted.
    expect(find.text('2 to grant'), findsOneWidget);
  });

  testWidgets('Dashboard navigates to About', (tester) async {
    await tester.pumpWidget(_dashboard());
    await tester.pumpAndSettle();
    await tester.tap(find.text('About & Credits'));
    await tester.pumpAndSettle();
    expect(find.text('About'), findsOneWidget);
  });

  testWidgets('About screen shows required Samsung attribution', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AboutScreen()));
    expect(
      find.textContaining('not affiliated with, sponsored by, or endorsed by'),
      findsOneWidget,
    );
    expect(find.textContaining(AppInfo.developer), findsWidgets);
    expect(find.textContaining(AppInfo.company), findsWidgets);
  });
}
