class ReminderSettings {
  static const int defaultLeadDays = 30;

  /// Options for the settings UI; keep in sync with the validation below.
  static const Set<int> leadDaysOptions = {1, 3, 7, 14, 30, 60};

  // A stored value may be unknown from an older build, so settings should
  // still load instead of failing the whole sync.
  ReminderSettings({this.enabled = false, int? leadDays})
    : leadDays = leadDays != null && leadDaysOptions.contains(leadDays)
          ? leadDays
          : defaultLeadDays;

  final bool enabled;
  final int leadDays;

  ReminderSettings copyWith({bool? enabled, int? leadDays}) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      leadDays: leadDays ?? this.leadDays,
    );
  }
}
