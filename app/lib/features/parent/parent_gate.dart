import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/bolo_colors.dart';
import '../../core/theme/bolo_dimens.dart';
import '../../core/theme/bolo_typography.dart';

/// Kids-Category compliant parent gate.
///
/// Presents a small mental-arithmetic challenge that toddlers cannot solve
/// but any literate adult solves in a few seconds. On success the caller
/// receives an in-memory unlock token that lasts 5 minutes — never
/// persisted — so a parent who just solved the gate can bounce between
/// Settings and Progress without solving it again.
///
/// Usage:
/// ```dart
/// final ok = await ParentGate.ensure(ref, context);
/// if (ok) { /* navigate to protected screen */ }
/// ```

// ── Unlock-token provider ─────────────────────────────────────────

class ParentUnlock {
  final DateTime expiresAt;
  const ParentUnlock(this.expiresAt);
  bool get isValid => DateTime.now().isBefore(expiresAt);
}

final parentUnlockProvider =
    StateProvider<ParentUnlock?>((ref) => null);

// ── Public API ────────────────────────────────────────────────────

class ParentGate {
  static const _tokenDuration = Duration(minutes: 5);

  /// Returns `true` if the caller may proceed to a parent-only screen.
  /// Reuses the in-memory unlock token if valid; otherwise shows the gate
  /// dialog and, on success, mints a new 5-minute token.
  static Future<bool> ensure(WidgetRef ref, BuildContext context) async {
    final existing = ref.read(parentUnlockProvider);
    if (existing != null && existing.isValid) return true;

    final passed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ParentGateDialog(),
    );
    if (passed == true) {
      ref.read(parentUnlockProvider.notifier).state =
          ParentUnlock(DateTime.now().add(_tokenDuration));
      return true;
    }
    return false;
  }
}

// ── Dialog widget ─────────────────────────────────────────────────

class _ParentGateDialog extends StatefulWidget {
  const _ParentGateDialog();

  @override
  State<_ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<_ParentGateDialog> {
  late final int _a;
  late final int _b;
  late final int _c;
  final _controller = TextEditingController();
  bool _wrong = false;

  int get _answer => _a + _b + _c;

  @override
  void initState() {
    super.initState();
    // Use plain math on small integers so the answer is always 1-2 digits.
    final rng = Random();
    _a = 2 + rng.nextInt(6);   // 2..7
    _b = 2 + rng.nextInt(6);   // 2..7
    _c = 1 + rng.nextInt(4);   // 1..4
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _check() {
    final entered = int.tryParse(_controller.text.trim());
    if (entered == _answer) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _wrong = true);
    _controller.clear();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _wrong = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BoloRadius.lgAll),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'For grown-ups',
              style: GoogleFonts.merriweather(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: BoloColors.ink3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'What is $_a + $_b + $_c ?',
              style: GoogleFonts.merriweather(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: BoloColors.ink,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 140,
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                textAlign: TextAlign.center,
                autofocus: true,
                onSubmitted: (_) => _check(),
                style: GoogleFonts.merriweather(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: BoloColors.paper,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _wrong ? BoloColors.alert : BoloColors.paper3,
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _wrong ? BoloColors.alert : BoloColors.saffron,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 18,
              child: _wrong
                  ? Text(
                      'Try again',
                      style: BoloTypography.utilityLabel(color: BoloColors.alert),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Cancel',
                      style: BoloTypography.utilityLabel(color: BoloColors.ink3),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _check,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BoloColors.saffron,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BoloRadius.pillAll,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Enter',
                      style: BoloTypography.utilityLabel(color: Colors.white)
                          .copyWith(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
