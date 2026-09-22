import 'package:flutter_test/flutter_test.dart';
import 'package:universal_app_lock/core/auth/pin_format_policy.dart';

void main() {
  group('PinFormatPolicy', () {
    const policy = PinFormatPolicy();

    test('accepts a valid 6-digit PIN', () {
      expect(policy.validate('123456').isValid, isTrue);
    });

    test('rejects empty', () {
      final r = policy.validate('');
      expect(r.isValid, isFalse);
      expect(r.reason, PinRejectReason.empty);
    });

    test('rejects non-digits', () {
      final r = policy.validate('12a4');
      expect(r.isValid, isFalse);
      expect(r.reason, PinRejectReason.nonDigit);
    });

    test('rejects too short / too long', () {
      expect(policy.validate('123').reason, PinRejectReason.length);
      expect(policy.validate('123456789').reason, PinRejectReason.length);
    });

    test('trivial detection', () {
      expect(policy.isTrivial('0000'), isTrue);
      expect(policy.isTrivial('1234'), isTrue);
      expect(policy.isTrivial('4321'), isTrue);
      expect(policy.isTrivial('195father'.substring(0, 4)), isFalse);
      expect(policy.isTrivial('1357'), isFalse);
    });

    test('does not reject trivial by default but does when configured', () {
      expect(const PinFormatPolicy().validate('1234').isValid, isTrue);
      expect(
        const PinFormatPolicy(rejectTrivial: true).validate('1234').reason,
        PinRejectReason.trivial,
      );
    });
  });
}
