import 'package:flutter/material.dart';

/// Type scale from `DESIGN.md` (Inter throughout).
abstract final class AppTextStyles {
  static const String _fontFamily = 'Inter';

  /// font size: 32
  /// font weight: 700
  /// line height: 40
  static const TextStyle display = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 40 / 32,
  );

  /// font size: 24
  /// font weight: 600
  /// line height: 32
  static const TextStyle headline = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
  );

  /// font size: 18
  /// font weight: 600
  /// line height: 26
  static const TextStyle title = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 26 / 18,
  );

  /// font size: 16
  /// font weight: 400
  /// line height: 24
  static const TextStyle body = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
  );

  /// font size: 14
  /// font weight: 400
  /// line height: 20
  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
  );

  /// font size: 12
  /// font weight: 400
  /// line height: 16
  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
  );

  /// font size: 14
  /// font weight: 600
  /// line height: 20
  static const TextStyle label = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
  );

  /// font size: 12
  /// font weight: 600
  /// line height: 16
  static const TextStyle labelSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
  );

  /// font size: 15
  /// font weight: 600
  /// line height: 20
  static const TextStyle numeric = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 20 / 15,
  );
}
