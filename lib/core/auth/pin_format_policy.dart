/// PIN format policy for Universal App Lock.
///
/// This validates the *format* of a PIN only. It never stores, hashes, or
/// transmits the PIN — secret handling happens natively (Android Keystore).
/// Kept intentionally simple and not over-restrictive.
library;

class PinFormatPolicy {
  const PinFormatPolicy({
    this.minLength = 4,
    this.maxLength = 8,
    this.defaultLength = 6,
    this.rejectTrivial = false,
  });

  final int minLength;
  final int maxLength;
  final int defaultLength;

  /// When true, all-same-digit and strictly sequential PINs are rejected.
  /// Off by default to avoid frustrating users; surfaced as a soft warning.
  final bool rejectTrivial;

  PinValidation validate(String pin) {
    if (pin.isEmpty) {
      return const PinValidation(false, PinRejectReason.empty);
    }
    if (!RegExp(r'^\d+$').hasMatch(pin)) {
      return const PinValidation(false, PinRejectReason.nonDigit);
    }
    if (pin.length < minLength || pin.length > maxLength) {
      return const PinValidation(false, PinRejectReason.length);
    }
    if (rejectTrivial && isTrivial(pin)) {
      return const PinValidation(false, PinRejectReason.trivial);
    }
    return const PinValidation(true, null);
  }

  /// True for all-identical digits or strictly ascending/descending sequences.
  bool isTrivial(String pin) {
    if (pin.length < 2) return true;
    final codes = pin.codeUnits;
    final allSame = codes.every((c) => c == codes.first);
    if (allSame) return true;
    var asc = true;
    var desc = true;
    for (var i = 1; i < codes.length; i++) {
      if (codes[i] != codes[i - 1] + 1) asc = false;
      if (codes[i] != codes[i - 1] - 1) desc = false;
    }
    return asc || desc;
  }
}

enum PinRejectReason { empty, nonDigit, length, trivial }

class PinValidation {
  const PinValidation(this.isValid, this.reason);
  final bool isValid;
  final PinRejectReason? reason;
}
