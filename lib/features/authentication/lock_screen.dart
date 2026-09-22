import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth/authentication_service.dart';
import '../../services/platform/platform_service.dart';
import '../apps/widgets/app_icon.dart';
import 'pin_entry_screen.dart';

/// The lock screen rendered inside the native `LockActivity` (route `lock/<pkg>`).
///
/// On correct PIN it grants a native unlock session and finishes the activity
/// (returning the user to the protected app). Back/gesture dismissal is blocked.
/// Biometric unlock and Forgot-PIN recovery are handled in a later branch.
class LockScreen extends StatelessWidget {
  const LockScreen({
    super.key,
    required this.packageName,
    required this.platform,
    required this.auth,
  });

  final String packageName;
  final PlatformService platform;
  final AuthenticationService auth;

  @override
  Widget build(BuildContext context) {
    return PinEntryScreen(
      title: 'Application Protected',
      subtitle: packageName,
      blockBack: true,
      headerIcon: AppIcon(
        platform: platform,
        packageName: packageName,
        size: 56,
      ),
      onSubmit: (pin) async {
        final res = await auth.verifyPin(pin);
        switch (res.status) {
          case AuthStatus.success:
            await platform.grantUnlock(packageName);
            await SystemNavigator.pop(); // finish LockActivity
            return null;
          case AuthStatus.lockedOut:
            final secs = (res.lockoutMs / 1000).ceil();
            return 'Too many attempts. Try again in ${secs}s.';
          case AuthStatus.failed:
            return 'Incorrect PIN';
          case AuthStatus.error:
            return 'Authentication error';
        }
      },
    );
  }
}
