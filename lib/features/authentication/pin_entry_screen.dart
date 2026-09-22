import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/app_theme.dart';

/// A reusable, sharp-cornered PIN entry screen with a numeric keypad.
///
/// Collects a PIN and returns it via `Navigator.pop<String>(pin)` when the user
/// submits (✓). Returns null if dismissed. Digits are shown only as filled
/// squares — never the actual numbers. No secret is stored or logged here; the
/// entered value is handed to the caller for native verification/storage.
class PinEntryScreen extends StatefulWidget {
  const PinEntryScreen({
    super.key,
    required this.title,
    this.subtitle = '',
    this.minLength = 4,
    this.maxLength = 8,
    this.errorText,
  });

  final String title;
  final String subtitle;
  final int minLength;
  final int maxLength;

  /// Optional error to show immediately (e.g. "Incorrect PIN").
  final String? errorText;

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  String _entry = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _error = widget.errorText;
  }

  void _tap(String d) {
    if (_entry.length >= widget.maxLength) return;
    HapticFeedback.selectionClick();
    setState(() {
      _entry += d;
      _error = null;
    });
  }

  void _backspace() {
    if (_entry.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _entry = _entry.substring(0, _entry.length - 1));
  }

  void _submit() {
    if (_entry.length < widget.minLength) {
      setState(() => _error = 'Enter at least ${widget.minLength} digits');
      return;
    }
    Navigator.of(context).pop<String>(_entry);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.lock_outline, size: 48),
            const SizedBox(height: 16),
            if (widget.subtitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            const SizedBox(height: 20),
            _Dots(count: _entry.length, max: widget.maxLength),
            const SizedBox(height: 12),
            SizedBox(
              height: 20,
              child: Text(
                _error ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.error,
                ),
              ),
            ),
            const Spacer(),
            _Keypad(
              onDigit: _tap,
              onBackspace: _backspace,
              onSubmit: _submit,
              submitEnabled: _entry.isNotEmpty,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.max});
  final int count;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(max, (i) {
        final filled = i < count;
        return Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: filled ? AppTheme.blue : Colors.transparent,
            border: Border.all(color: AppTheme.border),
          ),
        );
      }),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onBackspace,
    required this.onSubmit,
    required this.submitEnabled,
  });

  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;
  final bool submitEnabled;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final row in const [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
            ])
              Row(
                children: [
                  for (final d in row) _Key(label: d, onTap: () => onDigit(d)),
                ],
              ),
            Row(
              children: [
                _Key(
                  icon: Icons.backspace_outlined,
                  onTap: onBackspace,
                  semanticLabel: 'Delete',
                ),
                _Key(label: '0', onTap: () => onDigit('0')),
                _Key(
                  icon: Icons.check,
                  onTap: submitEnabled ? onSubmit : null,
                  semanticLabel: 'Submit',
                  accent: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    this.label,
    this.icon,
    required this.onTap,
    this.semanticLabel,
    this.accent = false,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = onTap == null;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Semantics(
          button: true,
          label: semanticLabel ?? label,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              child: Container(
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  border: Border.all(
                    color: accent ? AppTheme.blue : AppTheme.border,
                  ),
                ),
                child: icon != null
                    ? Icon(
                        icon,
                        color: disabled
                            ? theme.disabledColor
                            : (accent ? AppTheme.blue : null),
                      )
                    : Text(label ?? '', style: theme.textTheme.headlineSmall),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
