import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/platform_info.dart';
import '../../services/platform/platform_service.dart';
import '../about/about_screen.dart';
import '../settings/settings_screen.dart';

/// Dashboard is the app entry screen.
///
/// In this phase it presents branding, a clear "app-lock engine not yet
/// implemented" status, and a read-only platform diagnostic panel that
/// exercises the [PlatformService] bridge. It performs no locking.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.platformService});

  /// Injectable for testing; falls back to a default instance at runtime.
  final PlatformService? platformService;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final PlatformService _platform =
      widget.platformService ?? PlatformService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppInfo.appName),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SettingsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(AppInfo.tagline, style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.construction_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'App-lock engine is not yet implemented. '
                      'This build is a scaffold (Phase 5).',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Diagnostics', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _DiagnosticsPanel(platform: _platform),
          const SizedBox(height: 24),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.info_outline),
            label: const Text('About & Credits'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reads harmless platform info via the bridge. On any failure (e.g. running in
/// a host/test environment without the native side), it shows a neutral
/// "unavailable" message rather than crashing.
class _DiagnosticsPanel extends StatelessWidget {
  const _DiagnosticsPanel({required this.platform});

  final PlatformService platform;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PlatformInfo>(
      future: platform.getPlatformInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: ListTile(
              leading: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: Text('Reading platform info...'),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Card(
            child: ListTile(
              leading: Icon(Icons.help_outline),
              title: Text('Platform diagnostics unavailable'),
              subtitle: Text('Native bridge not attached in this environment.'),
            ),
          );
        }
        final info = snapshot.data!;
        return Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.android),
                title: const Text('OS'),
                trailing: Text('${info.os} (SDK ${info.sdkInt})'),
              ),
              ListTile(
                leading: const Icon(Icons.smartphone),
                title: const Text('Device'),
                trailing: Text('${info.manufacturer} ${info.model}'),
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Bridge version'),
                trailing: Text('${info.bridgeVersion}'),
              ),
            ],
          ),
        );
      },
    );
  }
}
