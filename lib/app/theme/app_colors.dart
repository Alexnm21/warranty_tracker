import 'package:flutter/material.dart';

/// Design tokens from `DESIGN.md` (frontmatter).
abstract final class AppColors {
  // Primary
  static const Color primary = Color(0xFF1D4ED8);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFDBEAFE);
  static const Color onPrimaryContainer = Color(0xFF001551);
  static const Color inversePrimary = Color(0xFFB7C4FF);
  static const Color surfaceTint = Color(0xFF1D4ED8);

  // Secondary
  static const Color secondary = Color(0xFF006C4A);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF82F5C1);
  static const Color onSecondaryContainer = Color(0xFF00714E);

  // Tertiary
  static const Color tertiary = Color(0xFF6B3700);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF8D4B00);
  static const Color onTertiaryContainer = Color(0xFFFFCBA3);

  // Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Surfaces
  static const Color surface = Color(0xFFF9F9FF);
  static const Color background = surface;
  static const Color surfaceDim = Color(0xFFD3DAEF);
  static const Color surfaceBright = Color(0xFFF9F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF1F3FF);
  static const Color surfaceContainer = Color(0xFFE9EDFF);
  static const Color surfaceContainerHigh = Color(0xFFE1E8FD);
  static const Color surfaceContainerHighest = Color(0xFFDCE2F7);
  static const Color surfaceVariant = Color(0xFFDCE2F7);
  static const Color inverseSurface = Color(0xFF293040);
  static const Color inverseOnSurface = Color(0xFFEDF0FF);

  // On surfaces
  static const Color onSurface = Color(0xFF141B2B);
  static const Color onSurfaceVariant = Color(0xFF434655);
  static const Color onBackground = Color(0xFF141B2B);

  // Outline
  static const Color outline = Color(0xFF747686);
  static const Color outlineVariant = Color(0xFFC4C5D7);

  // Fixed primary
  static const Color primaryFixed = Color(0xFFDCE1FF);
  static const Color primaryFixedDim = Color(0xFFB7C4FF);
  static const Color onPrimaryFixed = Color(0xFF001551);
  static const Color onPrimaryFixedVariant = Color(0xFF0039B5);

  // Fixed secondary
  static const Color secondaryFixed = Color(0xFF85F8C4);
  static const Color secondaryFixedDim = Color(0xFF68DBA9);
  static const Color onSecondaryFixed = Color(0xFF002114);
  static const Color onSecondaryFixedVariant = Color(0xFF005137);

  // Fixed tertiary
  static const Color tertiaryFixed = Color(0xFFFFDCC3);
  static const Color tertiaryFixedDim = Color(0xFFFFB77D);
  static const Color onTertiaryFixed = Color(0xFF2F1500);
  static const Color onTertiaryFixedVariant = Color(0xFF6E3900);

  // Warranty status (from `DESIGN.md` status sections)
  static const Color statusActiveBackground = Color(0xFFECFDF5);
  static const Color statusActiveText = Color(0xFF047857);
  static const Color statusExpiringBackground = Color(0xFFFFFBEB);
  static const Color statusExpiringText = Color(0xFFB45309);
  static const Color statusExpiredBackground = Color(0xFFFEF2F2);
  static const Color statusExpiredText = Color(0xFFB91C1C);
}
