import '../../core/models/app_info.dart';

/// Filter selector for the application list.
enum AppFilter { all, user, system }

/// Pure, testable filter + case-insensitive search over an app list.
/// Matches against both application name and package name.
List<AppInfo> filterAndSearchApps(
  List<AppInfo> apps, {
  AppFilter filter = AppFilter.all,
  String query = '',
}) {
  final q = query.trim().toLowerCase();
  return apps.where((a) {
    final matchesFilter = switch (filter) {
      AppFilter.all => true,
      AppFilter.user => !a.isSystemApp,
      AppFilter.system => a.isSystemApp,
    };
    if (!matchesFilter) return false;
    if (q.isEmpty) return true;
    return a.applicationName.toLowerCase().contains(q) ||
        a.packageName.toLowerCase().contains(q);
  }).toList();
}
