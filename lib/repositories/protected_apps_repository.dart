import 'package:flutter/foundation.dart';

import 'key_value_store.dart';

/// ProtectedAppsRepository holds the user's local app-protection *policy*: the
/// set of package names selected for protection.
///
/// IMPORTANT: membership here means only "selected for protection" in local
/// policy. It does NOT lock or intercept anything — enforcement arrives in a
/// later phase. Storage is local only (no remote/cloud).
class ProtectedAppsRepository {
  ProtectedAppsRepository(this._store);

  static const String _key = 'protected_packages';

  final KeyValueStore _store;
  final Set<String> _packages = <String>{};
  bool _loaded = false;

  /// Notifies listeners (e.g. the dashboard) when the protected set changes.
  final ValueNotifier<Set<String>> listenable = ValueNotifier<Set<String>>(
    <String>{},
  );

  Future<void> load() async {
    final stored = await _store.getStringList(_key);
    _packages
      ..clear()
      ..addAll(stored.where((e) => e.trim().isNotEmpty));
    _loaded = true;
    _publish();
  }

  Future<void> _ensureLoaded() async {
    if (!_loaded) await load();
  }

  Future<Set<String>> getProtectedPackages() async {
    await _ensureLoaded();
    return Set<String>.unmodifiable(_packages);
  }

  Future<bool> isProtected(String packageName) async {
    await _ensureLoaded();
    return _packages.contains(packageName);
  }

  Future<void> addProtectedPackage(String packageName) async {
    if (packageName.trim().isEmpty) return;
    await _ensureLoaded();
    if (_packages.add(packageName)) await _persist();
  }

  Future<void> removeProtectedPackage(String packageName) async {
    await _ensureLoaded();
    if (_packages.remove(packageName)) await _persist();
  }

  /// Adds if absent, removes if present. Returns the new protection state.
  Future<bool> toggle(String packageName) async {
    await _ensureLoaded();
    final nowProtected = !_packages.contains(packageName);
    if (nowProtected) {
      _packages.add(packageName);
    } else {
      _packages.remove(packageName);
    }
    await _persist();
    return nowProtected;
  }

  Future<int> count() async {
    await _ensureLoaded();
    return _packages.length;
  }

  Future<void> _persist() async {
    await _store.setStringList(_key, _packages.toList()..sort());
    _publish();
  }

  void _publish() {
    listenable.value = Set<String>.unmodifiable(_packages);
  }
}
