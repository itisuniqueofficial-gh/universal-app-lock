import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/utils/app_theme.dart';
import 'features/app_lock/dashboard_screen.dart';
import 'features/authentication/lock_screen.dart';
import 'repositories/key_value_store.dart';
import 'repositories/protected_apps_repository.dart';
import 'services/auth/authentication_service.dart';
import 'services/platform/platform_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final platform = PlatformService();
  final route = WidgetsBinding.instance.platformDispatcher.defaultRouteName;

  // The native LockActivity launches Flutter with initial route "lock/<pkg>".
  if (route.startsWith('lock/')) {
    final pkg = route.substring('lock/'.length);
    final auth = AuthenticationService(
      platform: platform,
      store: SharedPreferencesKeyValueStore(),
    );
    runApp(LockApp(platform: platform, auth: auth, packageName: pkg));
    return;
  }

  final repository = ProtectedAppsRepository(SharedPreferencesKeyValueStore());
  runApp(UniversalAppLock(platform: platform, repository: repository));
}

/// Root of the normal (configuration) app.
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

/// Root shown inside the native LockActivity — only the lock screen.
class LockApp extends StatelessWidget {
  const LockApp({
    super.key,
    required this.platform,
    required this.auth,
    required this.packageName,
  });

  final PlatformService platform;
  final AuthenticationService auth;
  final String packageName;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppInfo.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      home: LockScreen(
        platform: platform,
        auth: auth,
        packageName: packageName,
      ),
    );
  }
}
