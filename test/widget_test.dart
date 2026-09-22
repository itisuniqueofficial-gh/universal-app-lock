import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:universal_app_lock/core/constants/app_constants.dart';
import 'package:universal_app_lock/features/about/about_screen.dart';
import 'package:universal_app_lock/main.dart';

void main() {
  testWidgets('App boots and shows the dashboard with branding',
      (WidgetTester tester) async {
    await tester.pumpWidget(const UniversalAppLock());
    // Title appears in the dashboard AppBar.
    expect(find.text(AppInfo.appName), findsWidgets);
    // Scaffold clearly states the engine is not implemented yet.
    expect(
      find.textContaining('not yet implemented'),
      findsOneWidget,
    );
  });

  testWidgets('Dashboard can navigate to the About screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const UniversalAppLock());
    await tester.tap(find.text('About & Credits'));
    await tester.pumpAndSettle();
    expect(find.text('About'), findsOneWidget);
  });

  testWidgets('About screen shows required Samsung attribution',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AboutScreen()));
    expect(
      find.textContaining('not affiliated with, sponsored by, or endorsed by'),
      findsOneWidget,
    );
    expect(find.textContaining(AppInfo.developer), findsWidgets);
    expect(find.textContaining(AppInfo.company), findsWidgets);
  });
}
