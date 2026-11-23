import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Formats [date] as a localized short date (year/month/day).
///
/// Uses the app's active locale from [context] so the format matches the
/// current language. `DateFormat` comes from `intl`, re-exported by
/// `easy_localization`, so no extra import is needed.
String formatDate(BuildContext context, DateTime date) {
  return DateFormat.yMd(context.locale.toString()).format(date);
}
