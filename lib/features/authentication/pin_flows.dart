import 'package:flutter/material.dart';

import '../../core/auth/pin_format_policy.dart';
import '../../services/auth/authentication_service.dart';
import 'pin_entry_screen.dart';

/// Orchestrates PIN setup/confirm/change/remove using the real
/// [AuthenticationService] (native Keystore-backed storage). No plaintext PIN
/// is stored or logged here; entered values are passed to native set/verify.
class PinFlows {
  const PinFlows._();

  /// Set up a new PIN (enter → confirm → store). Returns true if configured.
  static Future<bool> setUp(
    BuildContext context,
    AuthenticationService auth,
  ) async {
    final policy = auth.pinPolicy;
    final pin1 = await _enter(
      context,
      title: 'Set PIN',
      subtitle: 'Choose a PIN (${policy.minLength}–${policy.maxLength} digits)',
      minLength: policy.minLength,
      maxLength: policy.maxLength,
    );
    if (pin1 == null || !context.mounted) return false;

    final v = policy.validate(pin1);
    if (!v.isValid) {
      _snack(context, _reasonText(v.reason, policy));
      return false;
    }

    final pin2 = await _enter(
      context,
      title: 'Confirm PIN',
      subtitle: 'Re-enter your PIN',
      minLength: policy.minLength,
      maxLength: policy.maxLength,
    );
    if (pin2 == null || !context.mounted) return false;

    if (pin1 != pin2) {
      _snack(context, 'PINs do not match. Please try again.');
      return false;
    }

    final res = await auth.setPin(pin1);
    if (!context.mounted) return res.isOk;
    _snack(context, res.isOk ? 'PIN set.' : 'Could not set PIN.');
    return res.isOk;
  }

  /// Change PIN: verify current, then set a new one.
  static Future<bool> change(
    BuildContext context,
    AuthenticationService auth,
  ) async {
    final ok = await _verify(context, auth, 'Enter current PIN');
    if (!ok || !context.mounted) return false;
    return setUp(context, auth);
  }

  /// Remove PIN: requires verifying the current PIN first.
  static Future<bool> remove(
    BuildContext context,
    AuthenticationService auth,
  ) async {
    final ok = await _verify(context, auth, 'Enter PIN to remove');
    if (!ok || !context.mounted) return false;
    await auth.clearPin();
    if (context.mounted) _snack(context, 'PIN removed.');
    return true;
  }

  static Future<bool> _verify(
    BuildContext context,
    AuthenticationService auth,
    String title,
  ) async {
    final pin = await _enter(context, title: title);
    if (pin == null || !context.mounted) return false;
    final res = await auth.verifyPin(pin);
    if (!context.mounted) return res.isSuccess;
    switch (res.status) {
      case AuthStatus.success:
        return true;
      case AuthStatus.lockedOut:
        final secs = (res.lockoutMs / 1000).ceil();
        _snack(context, 'Too many attempts. Try again in ${secs}s.');
        return false;
      case AuthStatus.failed:
        _snack(context, 'Incorrect PIN.');
        return false;
      case AuthStatus.error:
        _snack(context, 'Authentication error. Please try again.');
        return false;
    }
  }

  static Future<String?> _enter(
    BuildContext context, {
    required String title,
    String subtitle = '',
    int minLength = 4,
    int maxLength = 8,
  }) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => PinEntryScreen(
          title: title,
          subtitle: subtitle,
          minLength: minLength,
          maxLength: maxLength,
        ),
      ),
    );
  }

  static void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  static String _reasonText(PinRejectReason? r, PinFormatPolicy p) {
    switch (r) {
      case PinRejectReason.empty:
        return 'Please enter a PIN.';
      case PinRejectReason.nonDigit:
        return 'PIN must contain digits only.';
      case PinRejectReason.length:
        return 'PIN must be ${p.minLength}–${p.maxLength} digits.';
      case PinRejectReason.trivial:
        return 'Please choose a less predictable PIN.';
      case null:
        return 'Invalid PIN.';
    }
  }
}
