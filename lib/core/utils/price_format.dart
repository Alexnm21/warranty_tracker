import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Formats a price stored in minor units (e.g. cents) for display.
///
/// Prices are persisted as an integer in the currency's minor unit
/// (`899.99 EUR` -> `89999`). This renders it with the active locale's grouping
/// and always two decimals, appending the currency code when provided.
/// `NumberFormat` comes from `intl`, re-exported by `easy_localization`.
String formatPrice(BuildContext context, int minorUnits, String? currency) {
  final format = NumberFormat.decimalPattern(context.locale.toString())
    ..minimumFractionDigits = 2
    ..maximumFractionDigits = 2;

  final amount = format.format(minorUnits / 100);
  final code = currency?.trim();

  if (code == null || code.isEmpty) {
    return amount;
  }
  return '$amount $code';
}

/// Parses a user-entered price in major units (e.g. `899.99`) into minor units
/// (`89999`).
///
/// Accepts either `.` or `,` as the decimal separator. Returns `null` when
/// [text] is blank (meaning "no price") as well as for invalid or negative
/// input, so callers must handle the blank case separately when they need to
/// distinguish "empty" from "invalid".
int? parsePrice(String text) {
  final normalized = text.trim().replaceAll(',', '.');
  if (normalized.isEmpty) {
    return null;
  }

  final value = double.tryParse(normalized);
  if (value == null || value.isNaN || value.isInfinite || value < 0) {
    return null;
  }
  return (value * 100).round();
}
