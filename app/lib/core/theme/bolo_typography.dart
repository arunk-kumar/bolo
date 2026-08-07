import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bolo_colors.dart';

/// Bolo type scale — Nunito everywhere; weight and size do the hierarchy.
/// Sizes match Design System v0.2 (see design/bolo-uiux-spec.html §02).
///
/// Fetched via google_fonts at runtime for now; will be swapped to a
/// bundled font file in a follow-up commit so offline first-launch works.
class BoloTypography {
  BoloTypography._();

  /// Word display — the biggest thing the child sees.
  /// Nunito 900 · 56 / 56 · letter-spacing -1%.
  static TextStyle wordDisplay({Color color = BoloColors.saffron}) =>
      GoogleFonts.nunito(
        fontSize: 56,
        height: 1.0,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.56, // -1%
        color: color,
      );

  /// Hero / session-complete title. Nunito 900 · 42 / 44.
  static TextStyle hero({Color color = BoloColors.ink}) => GoogleFonts.nunito(
        fontSize: 42,
        height: 44 / 42,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.42,
        color: color,
      );

  /// Screen title — stage names, game headers. Nunito 900 · 28 / 32.
  static TextStyle screenTitle({Color color = BoloColors.ink}) =>
      GoogleFonts.nunito(
        fontSize: 28,
        height: 32 / 28,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.28,
        color: color,
      );

  /// Buttons, coaching prompts. Nunito 800 · 20 / 26.
  static TextStyle subhead({Color color = BoloColors.ink}) =>
      GoogleFonts.nunito(
        fontSize: 20,
        height: 26 / 20,
        fontWeight: FontWeight.w800,
        color: color,
      );

  /// Parent-facing body copy. Nunito 600 · 16 / 24.
  static TextStyle body({Color color = BoloColors.ink2}) => GoogleFonts.nunito(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w600,
        color: color,
      );

  /// Utility label — meta rows, status pills. Nunito 800 · 12 / 16 · +12% tracking · UPPERCASE.
  static TextStyle utilityLabel({Color color = BoloColors.ink3}) =>
      GoogleFonts.nunito(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.44, // +12%
        color: color,
      );

  /// Score pill, stat values — Nunito 900 tabular. Size passed by caller.
  static TextStyle numericDisplay({
    required double size,
    Color color = BoloColors.saffron,
  }) =>
      GoogleFonts.nunito(
        fontSize: size,
        height: 1.0,
        fontWeight: FontWeight.w900,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: color,
      );
}
