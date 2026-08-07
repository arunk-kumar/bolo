import 'package:flutter/material.dart';

/// Bolo palette — mirrors the design spec at
/// `~/my-workshop/bolo/design/bolo-uiux-spec.html` (Design System v0.2).
///
/// Rule of one bold: only *one* saturated colour per screen. Everywhere
/// else stays on the mango / brown neutrals. `alert` exists only for
/// parent-facing warnings — never for wrong-answer feedback.
class BoloColors {
  BoloColors._();

  // ── Ink (text) ────────────────────────────────────────────────
  /// Titles. Warm-brown-black, never pure black.
  static const ink       = Color(0xFF1C0E06);
  /// Body text on paper.
  static const ink2      = Color(0xFF4A2E1A);
  /// Secondary / muted.
  static const ink3      = Color(0xFF7A5A44);

  // ── Paper (surfaces) ──────────────────────────────────────────
  /// App surface — the page the child taps on.
  static const paper     = Color(0xFFFFF4E6);
  /// Card fill, subtle rows, chip background.
  static const paper2    = Color(0xFFFFEBCC);
  /// Dividers, borders.
  static const paper3    = Color(0xFFFFD9A3);

  // ── Accents ───────────────────────────────────────────────────
  /// Primary. CTAs, headings, active state, word label.
  static const saffron   = Color(0xFFF55D00);
  /// Pressed variant of saffron.
  static const saffronD  = Color(0xFFC43F00);
  /// Highlight. Stars, current-step, reward burst.
  static const turmeric  = Color(0xFFFFB700);

  // ── Semantic ──────────────────────────────────────────────────
  /// Success only. Streak days, mastered words.
  static const sage      = Color(0xFF2A7A4B);
  /// Info. Hints, phrases-game scene sky.
  static const sky       = Color(0xFF0284C7);
  /// Parent-facing alert *only*. Never wrong-answer feedback.
  static const alert     = Color(0xFFE11D48);
}
