import 'package:flutter/material.dart';

import '../../core/models/permission_status.dart';
import '../../core/utils/app_theme.dart';
import '../../core/widgets/flat_card.dart';
import '../../repositories/key_value_store.dart';
import '../../services/auth/authentication_service.dart';
import '../../services/platform/platform_service.dart';
import '../authentication/pin_flows.dart';
import 'permission_health.dart';

/// Security & Permissions health screen.
///
/// Shows the REAL state of each permission/capability (never faked), with an
/// honest explanation, what depends on it, and actions to open the correct
/// Android settings and re-check. Status refreshes when returning from Settings.
class SecurityPermissionsScreen extends StatefulWidget {
  SecurityPermissionsScreen({
    super.key,
    required this.platform,
    AuthenticationService? auth,
  }) : auth =
           auth ??
           AuthenticationService(
             platform: platform,
             store: SharedPreferencesKeyValueStore(),
           );

  final PlatformService platform;
  final AuthenticationService auth;

  @override
  State<SecurityPermissionsScreen> createState() =>
      _SecurityPermissionsScreenState();
}

class _SecurityPermissionsScreenState extends State<SecurityPermissionsScreen>
    with WidgetsBindingObserver {
  bool _loading = true;
  bool _hasPin = false;
  PermissionStatus _usage = PermissionStatus.unknown;
  PermissionStatus _overlay = PermissionStatus.unknown;
  PermissionStatus _biometric = PermissionStatus.unknown;
  String _monitoring = 'stopped';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final hasPin = await _safe(() => widget.platform.authHasPin(), false);
    final usage = await _safeStatus(
      () => widget.platform.isUsageAccessGranted(),
    );
    final overlay = await _safeStatus(
      () => widget.platform.isOverlayPermissionGranted(),
    );
    PermissionStatus bio;
    try {
      final b = await widget.platform.getBiometricAvailability();
      bio = b == 'available'
          ? PermissionStatus.granted
          : (b == 'unavailable'
                ? PermissionStatus.unavailable
                : PermissionStatus.denied);
    } catch (_) {
      bio = PermissionStatus.unknown;
    }
    if (!mounted) return;
    final monitoring = await _safe(
      () => widget.platform.getMonitoringStatus(),
      'stopped',
    );
    if (!mounted) return;
    setState(() {
      _hasPin = hasPin;
      _usage = usage;
      _overlay = overlay;
      _biometric = bio;
      _monitoring = monitoring;
      _loading = false;
    });
  }

  Future<T> _safe<T>(Future<T> Function() f, T fallback) async {
    try {
      return await f();
    } catch (_) {
      return fallback;
    }
  }

  Future<PermissionStatus> _safeStatus(Future<bool> Function() f) async {
    try {
      return (await f()) ? PermissionStatus.granted : PermissionStatus.denied;
    } catch (_) {
      return PermissionStatus.unknown;
    }
  }

  Future<void> _openUsage() => _open(widget.platform.openUsageAccessSettings());
  Future<void> _openOverlay() => _open(widget.platform.openOverlaySettings());

  Future<void> _setUpPin() async {
    await PinFlows.setUp(context, widget.auth);
    if (mounted) _load();
  }

  Future<void> _changePin() async {
    await PinFlows.change(context, widget.auth);
    if (mounted) _load();
  }

  Future<void> _removePin() async {
    await PinFlows.remove(context, widget.auth);
    if (mounted) _load();
  }

  Future<void> _startMonitoring() async {
    try {
      await widget.platform.startMonitoring();
    } catch (_) {}
    if (mounted) _load();
  }

  Future<void> _stopMonitoring() async {
    try {
      await widget.platform.stopMonitoring();
    } catch (_) {}
    if (mounted) _load();
  }

  Future<void> _open(Future<bool> action) async {
    try {
      await action;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the settings screen.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final health = computeSecurityHealth(
      hasPin: _hasPin,
      usageGranted: _usage == PermissionStatus.granted,
      overlayGranted: _overlay == PermissionStatus.granted,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security & Permissions'),
        actions: [
          IconButton(
            tooltip: 'Re-check',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _OverallBanner(health: health),
                  const SizedBox(height: 16),
                  _PinCard(
                    hasPin: _hasPin,
                    onSetUp: _setUpPin,
                    onChange: _changePin,
                    onRemove: _removePin,
                  ),
                  const SizedBox(height: 12),
                  _PermissionCard(
                    kind: PermissionKind.usageAccess,
                    status: _usage,
                    required: true,
                    onOpenSettings: _openUsage,
                  ),
                  const SizedBox(height: 12),
                  _PermissionCard(
                    kind: PermissionKind.overlay,
                    status: _overlay,
                    required: true,
                    onOpenSettings: _openOverlay,
                  ),
                  const SizedBox(height: 12),
                  _PermissionCard(
                    kind: PermissionKind.biometricCapability,
                    status: _biometric,
                    required: false,
                    onOpenSettings: null,
                  ),
                  const SizedBox(height: 12),
                  _MonitoringCard(
                    status: _monitoring,
                    onStart: _startMonitoring,
                    onStop: _stopMonitoring,
                  ),
                  const SizedBox(height: 16),
                  const _DeviceNote(),
                ],
              ),
            ),
    );
  }
}

class _OverallBanner extends StatelessWidget {
  const _OverallBanner({required this.health});
  final SecurityHealth health;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FlatCard(
      child: Row(
        children: [
          Icon(
            health == SecurityHealth.ready
                ? Icons.verified_user_outlined
                : Icons.gpp_maybe_outlined,
            color: health == SecurityHealth.ready
                ? AppTheme.blue
                : Colors.amber,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overall', style: theme.textTheme.labelMedium),
                const SizedBox(height: 2),
                Text(
                  securityHealthLabel(health),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PinCard extends StatelessWidget {
  const _PinCard({
    required this.hasPin,
    required this.onSetUp,
    required this.onChange,
    required this.onRemove,
  });

  final bool hasPin;
  final VoidCallback onSetUp;
  final VoidCallback onChange;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasPin ? Icons.check_circle : Icons.warning_amber_rounded,
                color: hasPin ? AppTheme.blue : AppTheme.warning,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'PIN',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                hasPin ? 'Configured' : 'Not configured',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasPin
                ? 'Your PIN is stored as a salted, Keystore-backed hash — never in plain text.'
                : 'Securely protect your applications with a PIN.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (!hasPin)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onSetUp,
                child: const Text('SET UP PIN'),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onChange,
                    child: const Text('CHANGE PIN'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRemove,
                    child: const Text('REMOVE PIN'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.kind,
    required this.status,
    required this.required,
    required this.onOpenSettings,
  });

  final PermissionKind kind;
  final PermissionStatus status;
  final bool required;
  final Future<void> Function()? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ex = permissionExplanations[kind]!;
    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _statusIcon(status),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ex.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                required ? 'Required' : 'Optional',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Why: ${ex.why}', style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text('Depends on: ${ex.dependsOn}', style: theme.textTheme.bodySmall),
          if (ex.weDont.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'We do not: ${ex.weDont.join(' ')}',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (onOpenSettings != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: onOpenSettings,
                child: Text(
                  status == PermissionStatus.granted
                      ? 'Review in Settings'
                      : 'Open Settings',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusIcon(PermissionStatus s) {
    switch (s) {
      case PermissionStatus.granted:
        return const Icon(Icons.check_circle, color: AppTheme.blue);
      case PermissionStatus.denied:
        return const Icon(Icons.warning_amber_rounded, color: Colors.amber);
      case PermissionStatus.unavailable:
        return const Icon(Icons.block, color: Colors.grey);
      case PermissionStatus.notRequired:
      case PermissionStatus.unknown:
        return const Icon(Icons.help_outline, color: Colors.grey);
    }
  }
}

class _DeviceNote extends StatelessWidget {
  const _DeviceNote();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Your device may manage these permissions differently. If a settings '
      'screen does not open directly, open Settings and search for the '
      'permission by name.',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

class _MonitoringCard extends StatelessWidget {
  const _MonitoringCard({
    required this.status,
    required this.onStart,
    required this.onStop,
  });

  final String status; // "running" | "stopped"
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final running = status == 'running';
    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                running ? Icons.check_circle : Icons.pause_circle_outline,
                color: running ? AppTheme.success : AppTheme.warning,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Monitoring service',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                running ? 'RUNNING' : 'STOPPED',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Runs a foreground service that detects protected apps and shows the '
            'lock screen. Requires Usage Access and Display over other apps.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: running
                ? OutlinedButton(
                    onPressed: onStop,
                    child: const Text('STOP MONITORING'),
                  )
                : FilledButton(
                    onPressed: onStart,
                    child: const Text('START MONITORING'),
                  ),
          ),
        ],
      ),
    );
  }
}
