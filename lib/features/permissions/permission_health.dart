/// Security & Permissions health: pure aggregation logic and honest, accurate
/// permission explanations. No secret handling here.
library;

import '../../core/models/permission_status.dart';

/// Overall security posture derived from real permission/state values.
enum SecurityHealth { notConfigured, actionRequired, limited, ready }

/// Computes the overall health from real state:
/// - no PIN                                   -> notConfigured
/// - PIN + all required permissions granted   -> ready
/// - PIN + some (not all) required granted     -> limited
/// - PIN + none of the required granted        -> actionRequired
SecurityHealth computeSecurityHealth({
  required bool hasPin,
  required bool usageGranted,
  required bool overlayGranted,
}) {
  if (!hasPin) return SecurityHealth.notConfigured;
  final grantedCount = (usageGranted ? 1 : 0) + (overlayGranted ? 1 : 0);
  if (grantedCount == 2) return SecurityHealth.ready;
  if (grantedCount == 0) return SecurityHealth.actionRequired;
  return SecurityHealth.limited;
}

String securityHealthLabel(SecurityHealth h) {
  switch (h) {
    case SecurityHealth.notConfigured:
      return 'NOT CONFIGURED';
    case SecurityHealth.actionRequired:
      return 'ACTION REQUIRED';
    case SecurityHealth.limited:
      return 'LIMITED';
    case SecurityHealth.ready:
      return 'READY';
  }
}

/// Accurate, non-exaggerated explanation for a permission/capability.
/// The claims here MUST match the actual implementation.
class PermissionExplanation {
  const PermissionExplanation({
    required this.title,
    required this.why,
    required this.dependsOn,
    this.weDo = const [],
    this.weDont = const [],
  });

  final String title;
  final String why;
  final String dependsOn;
  final List<String> weDo;
  final List<String> weDont;
}

const Map<PermissionKind, PermissionExplanation> permissionExplanations = {
  PermissionKind.usageAccess: PermissionExplanation(
    title: 'Usage Access',
    why:
        'Lets Universal App Lock detect which application is currently in the '
        'foreground so it can decide whether a protected app must be unlocked.',
    dependsOn: 'Foreground app detection (app-lock enforcement).',
    weDo: ['Read the current foreground package name.'],
    weDont: [
      'Read your messages, content, or keystrokes.',
      'Upload usage data anywhere.',
    ],
  ),
  PermissionKind.overlay: PermissionExplanation(
    title: 'Display over other apps',
    why:
        'Allows the Universal App Lock authentication screen to appear above a '
        'protected application when you open it.',
    dependsOn: 'Showing the lock screen over protected apps.',
    weDo: ['Display the Universal App Lock authentication interface.'],
    weDont: [
      'Read the contents of other applications.',
      'Capture or record your screen.',
    ],
  ),
  PermissionKind.biometricCapability: PermissionExplanation(
    title: 'Biometric authentication',
    why:
        'If your device has enrolled biometrics, you can unlock protected apps '
        'with biometrics instead of typing your PIN.',
    dependsOn: 'Optional biometric unlock (PIN always remains available).',
    weDo: ['Use the Android system biometric prompt.'],
    weDont: ['Store or transmit any biometric data.'],
  ),
};
