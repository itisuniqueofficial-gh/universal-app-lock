import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/utils/app_theme.dart';
import 'features/app_lock/dashboard_screen.dart';
import 'repositories/key_value_store.dart';
import 'repositories/protected_apps_repository.dart';
import 'services/platform/platform_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final platform = PlatformService();
  final repository = ProtectedAppsRepository(SharedPreferencesKeyValueStore());

  runApp(UniversalAppLock(platform: platform, repository: repository));
}

/// Root application widget for Universal App Lock.
///
/// Wires branding, the dark minimalist theme, and the dashboard. Dependencies
/// are injected so screens and tests share a single PlatformService and
/// ProtectedAppsRepository. Contains no app-lock logic.
class UniversalAppLock extends StatelessWidget {
  const UniversalAppLock({
    super.key,
    required this.platform,
    required this.repository,
  });

  final PlatformService platform;
  final ProtectedAppsRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppInfo.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      home: DashboardScreen(platform: platform, repository: repository),
    );
  }
}
