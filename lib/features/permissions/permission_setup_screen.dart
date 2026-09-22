import 'package:flutter/material.dart';

import '../../core/models/permission_status.dart';
import '../../core/widgets/flat_card.dart';
import '../../services/platform/platform_service.dart';

/// Shows the real state of the permissions/capabilities relevant to app
/// locking, and lets the user open the appropriate Android settings screens.
///
/// This screen enforces nothing. Usage Access and Overlay are prerequisites for
/// future locking; the UI states clearly that they do not lock apps yet.
class PermissionSetupScreen extends StatefulWidget {
  const PermissionSetupScreen({super.key, required this.platform});

  final PlatformService platform;

  @override
  State<PermissionSetupScreen> createState() => _PermissionSetupScreenState();
}

class _PermissionSetupScreenState extends State<PermissionSetupScreen>
    with WidgetsBindingObserver {
  List<PermissionInfo>? _items;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check permissions after returning from Android Settings.
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    PermissionStatus usage;
    PermissionStatus overlay;
    PermissionStatus biometric;
    try {
      usage = (await widget.platform.isUsageAccessGranted())
          ? PermissionStatus.granted
          : PermissionStatus.denied;
    } catch (_) {
      usage = PermissionStatus.unknown;
    }
    try {
      overlay = (await widget.platform.isOverlayPermissionGranted())
          ? PermissionStatus.granted
          : PermissionStatus.denied;
    } catch (_) {
      overlay = PermissionStatus.unknown;
    }
    try {
      final b = await widget.platform.getBiometricAvailability();
      biometric = b == 'available'
          ? PermissionStatus.granted
          : (b == 'unavailable'
                ? PermissionStatus.unavailable
                : PermissionStatus.denied);
    } catch (_) {
      biometric = PermissionStatus.unknown;
    }

    final items = <PermissionInfo>[
      PermissionInfo(
        kind: PermissionKind.usageAccess,
        title: 'Usage Access',
        description:
            'Lets the app detect which application is in the foreground. This '
            'is a prerequisite for locking — it does not lock apps by itself.',
        status: usage,
        required: true,
      ),
      PermissionInfo(
        kind: PermissionKind.overlay,
        title: 'Display over other apps',
        description:
            'Required later so the lock screen can appear above protected '
            'applications. It is not enforcing any lock yet.',
        status: overlay,
        required: true,
      ),
      PermissionInfo(
        kind: PermissionKind.biometricCapability,
        title: 'Biometric availability',
        description:
            'Whether this device has enrolled biometrics. Informational only; '
            'biometric unlock is not implemented yet.',
        status: biometric,
        required: false,
      ),
    ];

    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  Future<void> _open(PermissionKind kind) async {
    try {
      if (kind == PermissionKind.usageAccess) {
        await widget.platform.openUsageAccessSettings();
      } else if (kind == PermissionKind.overlay) {
        await widget.platform.openOverlaySettings();
      }
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
    return Scaffold(
      appBar: AppBar(title: const Text('Security Setup')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Grant the permissions below to prepare Universal App Lock '
                    'for locking. Nothing is locked yet in this build.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  for (final item in _items!) ...[
                    _PermissionCard(item: item, onOpen: () => _open(item.kind)),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.item, required this.onOpen});

  final PermissionInfo item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final canOpen =
        item.kind == PermissionKind.usageAccess ||
        item.kind == PermissionKind.overlay;
    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusIcon(status: item.status),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (!item.required)
                Text('Optional', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.description, style: Theme.of(context).textTheme.bodySmall),
          if (canOpen) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: onOpen,
                child: Text(
                  item.isGranted ? 'Review in Settings' : 'Open Settings',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final PermissionStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case PermissionStatus.granted:
        return const Icon(Icons.check_circle, color: Color(0xFF3B82F6));
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
