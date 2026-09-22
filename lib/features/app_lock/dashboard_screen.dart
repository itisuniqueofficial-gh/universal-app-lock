import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/flat_card.dart';
import '../../repositories/protected_apps_repository.dart';
import '../../services/platform/platform_service.dart';
import '../about/about_screen.dart';
import '../apps/protected_apps_screen.dart';
import '../permissions/security_permissions_screen.dart';
import '../settings/settings_screen.dart';

/// Dashboard entry screen. Displays the real, non-faked state:
/// protection is not set up, the number of protected apps, and how many
/// required permissions are still missing. It performs no locking.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.platform,
    required this.repository,
  });

  final PlatformService platform;
  final ProtectedAppsRepository repository;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  int? _missingPermissions; // null = checking/unknown
  String _monitoring = 'stopped';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.repository.load();
    _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshPermissions();
  }

  Future<void> _refreshPermissions() async {
    try {
      final usage = await widget.platform.isUsageAccessGranted();
      final overlay = await widget.platform.isOverlayPermissionGranted();
      final monitoring = await widget.platform.getMonitoringStatus();
      final missing = (usage ? 0 : 1) + (overlay ? 0 : 1);
      if (mounted) {
        setState(() {
          _missingPermissions = missing;
          _monitoring = monitoring;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _missingPermissions = null;
          _monitoring = 'stopped';
        });
      }
    }
  }

  Future<void> _push(Widget screen) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
    // Refresh state after returning.
    _refreshPermissions();
  }

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
            onPressed: () => _push(
              SettingsScreen(
                platform: widget.platform,
                repository: widget.repository,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FlatCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Protection', style: theme.textTheme.labelMedium),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      _monitoring == 'running'
                          ? Icons.lock_outline
                          : Icons.lock_open_outlined,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _monitoring == 'running' ? 'Active' : 'Not active',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _monitoring == 'running'
                      ? 'The monitoring service is running.'
                      : 'Start protection from Security & Permissions after setting a PIN and granting permissions.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ValueListenableBuilder<Set<String>>(
                  valueListenable: widget.repository.listenable,
                  builder: (context, set, _) => _StatCard(
                    label: 'Protected Apps',
                    value: '${set.length}',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Security Setup',
                  value: _missingPermissions == null
                      ? '—'
                      : (_missingPermissions == 0
                            ? 'Ready'
                            : '$_missingPermissions to grant'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.security_outlined),
            label: const Text('Set Up Security'),
            onPressed: () =>
                _push(SecurityPermissionsScreen(platform: widget.platform)),
          ),
          const SizedBox(height: 12),
          FlatCard(
            onTap: () => _push(
              ProtectedAppsScreen(
                platform: widget.platform,
                repository: widget.repository,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.apps_outlined),
                const SizedBox(width: 12),
                const Expanded(child: Text('Protected Apps')),
                Text('Open', style: theme.textTheme.labelLarge),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FlatCard(
            onTap: () => _push(const AboutScreen()),
            child: Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 12),
                const Expanded(child: Text('About & Credits')),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
