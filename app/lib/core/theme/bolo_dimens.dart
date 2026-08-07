import 'package:flutter/material.dart';
import 'bolo_colors.dart';

/// Radii, shadows, and layout constants from Design System v0.2.
class BoloRadius {
  BoloRadius._();
  static const sm  = Radius.circular(8);
  static const md  = Radius.circular(16);
  static const lg  = Radius.circular(24);
  static const xl  = Radius.circular(32);
  static const pill = Radius.circular(999);

  static const smAll  = BorderRadius.all(sm);
  static const mdAll  = BorderRadius.all(md);
  static const lgAll  = BorderRadius.all(lg);
  static const xlAll  = BorderRadius.all(xl);
  static const pillAll = BorderRadius.all(pill);
}

class BoloShadow {
  BoloShadow._();

  /// Card resting — subtle warm shadow.
  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x141C0E06), blurRadius: 20, offset: Offset(0, 6)),
    BoxShadow(color: Color(0x0A1C0E06), blurRadius: 2,  offset: Offset(0, 1)),
  ];

  /// Lifted / hero — used behind the word card and phone frames.
  static const lift = <BoxShadow>[
    BoxShadow(color: Color(0x2E1C0E06), blurRadius: 48, offset: Offset(0, 20)),
    BoxShadow(color: Color(0x0F1C0E06), blurRadius: 8,  offset: Offset(0, 4)),
  ];

  /// Saffron-tinted glow behind the active word card.
  static const wordCard = <BoxShadow>[
    BoxShadow(color: Color(0x2EF55D00), blurRadius: 32, offset: Offset(0, 12)),
  ];
}

/// Layout tokens.
class BoloLayout {
  BoloLayout._();

  /// Content width cap on tablet/desktop; phone gets full-bleed.
  static const contentMaxWidth = 480.0;

  /// Minimum tap target — WCAG kids guideline.
  static const minTap = 80.0;

  /// Word-card minimum size.
  static const wordCardMin = 280.0;
}

/// Curated colour aliases for the app scaffold so `MaterialApp` doesn't
/// have to import every colour by name.
class BoloScheme {
  BoloScheme._();

  static const surface       = BoloColors.paper;
  static const surfaceRaised = BoloColors.paper2;
  static const primary       = BoloColors.saffron;
  static const onPrimary     = Colors.white;
}
