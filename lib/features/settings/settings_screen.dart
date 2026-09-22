import 'package:flutter/material.dart';

import '../../repositories/protected_apps_repository.dart';
import '../../services/platform/platform_service.dart';
import '../about/about_screen.dart';
import '../apps/protected_apps_screen.dart';
import '../permissions/security_permissions_screen.dart';

/// Settings hub. Every entry navigates to a functional screen; there are no
/// non-functional toggles or placeholders.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.platform,
    required this.repository,
  });

  final PlatformService platform;
  final ProtectedAppsRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Security & Permissions'),
            subtitle: const Text('PIN, permissions and security status'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SecurityPermissionsScreen(platform: platform),
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.apps_outlined),
            title: const Text('Protected Applications'),
            subtitle: const Text('Choose which apps to protect'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ProtectedAppsScreen(
                  platform: platform,
                  repository: repository,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('About & Credits'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
