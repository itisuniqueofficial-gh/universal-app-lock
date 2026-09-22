import 'package:flutter/material.dart';

import '../../core/models/app_info.dart';
import '../../repositories/protected_apps_repository.dart';
import '../../services/platform/platform_service.dart';
import 'app_filter.dart';
import 'widgets/app_icon.dart';

/// Lets the user browse installed launchable apps, search/filter them, and
/// select which are "protected" in local policy.
///
/// NOTE: selecting an app only adds it to the local protection policy. It does
/// NOT lock or intercept the app — enforcement is a later phase.
class ProtectedAppsScreen extends StatefulWidget {
  const ProtectedAppsScreen({
    super.key,
    required this.platform,
    required this.repository,
  });

  final PlatformService platform;
  final ProtectedAppsRepository repository;

  @override
  State<ProtectedAppsScreen> createState() => _ProtectedAppsScreenState();
}

class _ProtectedAppsScreenState extends State<ProtectedAppsScreen> {
  late Future<List<AppInfo>> _appsFuture;
  final Set<String> _protected = <String>{};
  AppFilter _filter = AppFilter.user;
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Single native query (includes system apps); filtered locally afterwards.
    _appsFuture = widget.platform.getInstalledApplications(includeSystem: true);
    _loadProtected();
  }

  Future<void> _loadProtected() async {
    final set = await widget.repository.getProtectedPackages();
    if (mounted) {
      setState(() {
        _protected
          ..clear()
          ..addAll(set);
      });
    }
  }

  Future<void> _toggle(AppInfo app) async {
    final nowProtected = await widget.repository.toggle(app.packageName);
    setState(() {
      if (nowProtected) {
        _protected.add(app.packageName);
      } else {
        _protected.remove(app.packageName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Protected Apps')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search apps or package names',
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'User',
                  selected: _filter == AppFilter.user,
                  onTap: () => setState(() => _filter = AppFilter.user),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'System',
                  selected: _filter == AppFilter.system,
                  onTap: () => setState(() => _filter = AppFilter.system),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'All',
                  selected: _filter == AppFilter.all,
                  onTap: () => setState(() => _filter = AppFilter.all),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    return FutureBuilder<List<AppInfo>>(
      future: _appsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorState(
            message: 'Could not read installed applications.',
            detail: '${snapshot.error}',
          );
        }
        final apps = snapshot.data ?? const <AppInfo>[];
        final visible = filterAndSearchApps(
          apps,
          filter: _filter,
          query: _query,
        );
        if (visible.isEmpty) {
          return const _ErrorState(message: 'No applications match.');
        }
        return ListView.separated(
          itemCount: visible.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: Theme.of(context).dividerColor),
          itemBuilder: (context, i) {
            final app = visible[i];
            final isProtected = _protected.contains(app.packageName);
            return ListTile(
              leading: AppIcon(
                platform: widget.platform,
                packageName: app.packageName,
              ),
              title: Text(app.applicationName),
              subtitle: Text(
                app.packageName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Switch(
                value: isProtected,
                onChanged: (_) => _toggle(app),
              ),
              onTap: () => _toggle(app),
            );
          },
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, this.detail});

  final String message;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (detail != null) ...[
              const SizedBox(height: 4),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
