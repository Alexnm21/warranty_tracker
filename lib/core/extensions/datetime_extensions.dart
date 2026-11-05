extension DatetimeExtensions on DateTime {
  static const _shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Formats the date as `12 Mar 2028` (day, 3-letter month, year).
  String get dateString => '$day ${_shortMonths[month - 1]} $year';
}
