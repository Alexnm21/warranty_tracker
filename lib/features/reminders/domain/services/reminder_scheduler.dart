/// Recomputes the app's pending reminders from the current products and
/// settings. Implemented in the data layer.
abstract class ReminderScheduler {
  Future<void> sync();
}
