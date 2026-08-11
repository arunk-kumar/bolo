import 'package:flutter/material.dart';
import 'bolo_colors.dart';
import 'bolo_dimens.dart';

/// Assembles a Flutter [ThemeData] from Bolo tokens.
///
/// Everything visual in the app should read from these tokens rather than
/// hard-coded values — that way one change here ripples everywhere.
class BoloTheme {
  BoloTheme._();

  static ThemeData light() {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);

    return base.copyWith(
      scaffoldBackgroundColor: BoloColors.paper,
      colorScheme: base.colorScheme.copyWith(
        primary:       BoloColors.saffron,
        onPrimary:     Colors.white,
        secondary:     BoloColors.turmeric,
        onSecondary:   BoloColors.ink,
        surface:       BoloColors.paper,
        onSurface:     BoloColors.ink2,
        surfaceContainerHighest: BoloColors.paper2,
        error:         BoloColors.alert,
      ),
      textTheme: base.textTheme
          .apply(
            fontFamily: 'Nunito',
            bodyColor: BoloColors.ink2,
            displayColor: BoloColors.ink,
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: BoloColors.ink2),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BoloColors.saffron,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(BoloLayout.minTap),
          shape: const RoundedRectangleBorder(borderRadius: BoloRadius.pillAll),
          textStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
          elevation: 6,
          shadowColor: BoloColors.saffronD,
        ),
      ),
    );
  }
}
