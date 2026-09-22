import 'package:flutter/material.dart';

import '../about/about_screen.dart';

/// Minimal settings screen scaffold.
///
/// Real settings (lock policy, authentication method, protected apps) are NOT
/// implemented in this phase. This screen intentionally contains no functional
/// toggles so it does not imply behavior that does not exist yet.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('Settings are not implemented yet'),
            subtitle: Text(
              'Lock policy and preferences arrive in a later phase.',
            ),
          ),
          const Divider(),
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
