/// Permission state modeling for onboarding.
///
/// Permissions are not simple booleans: a permission may be granted, denied,
/// unavailable on this device/OS, not required by the current feature set, or
/// unknown (not yet checked).
library;

enum PermissionStatus { granted, denied, unavailable, notRequired, unknown }

/// Identifies a permission/capability shown during onboarding.
enum PermissionKind { usageAccess, overlay, biometricCapability }

/// A single permission/capability row for the setup screen.
class PermissionInfo {
  const PermissionInfo({
    required this.kind,
    required this.title,
    required this.description,
    required this.status,
    required this.required,
  });

  final PermissionKind kind;
  final String title;
  final String description;
  final PermissionStatus status;

  /// Whether this permission is required by the features implemented so far.
  /// (Discovery works without extra permissions; Usage Access / Overlay are
  /// prerequisites for future locking and are surfaced but not yet enforced.)
  final bool required;

  bool get isGranted => status == PermissionStatus.granted;

  PermissionInfo copyWith({PermissionStatus? status}) => PermissionInfo(
    kind: kind,
    title: title,
    description: description,
    status: status ?? this.status,
    required: required,
  );
}
