import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/utils/app_theme.dart';
import 'features/app_lock/dashboard_screen.dart';

void main() {
  runApp(const UniversalAppLock());
}

/// Root application widget for Universal App Lock.
///
/// This is a Phase 5 scaffold: it wires branding, theming, and navigation to
/// the dashboard, settings, and about screens. It contains no app-lock logic.
class UniversalAppLock extends StatelessWidget {
  const UniversalAppLock({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppInfo.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const DashboardScreen(),
    );
  }
}
