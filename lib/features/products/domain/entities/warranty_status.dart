enum WarrantyStatus {
  future,
  active,
  expired;

  static WarrantyStatus fromDates(
    DateTime? start,
    DateTime? end, [
    DateTime? now,
  ]) {
    if (end == null) {
      return WarrantyStatus.active;
    }

    final today = _dateOnly(now ?? DateTime.now());
    final endDate = _dateOnly(end);

    if (endDate.isBefore(today)) {
      return WarrantyStatus.expired;
    }

    if (start == null) {
      return WarrantyStatus.active;
    }

    final startDate = _dateOnly(start);
    if (startDate.isAfter(today)) {
      return WarrantyStatus.future;
    }

    return WarrantyStatus.active;
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
