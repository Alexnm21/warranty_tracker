# Phase 3 — Notifications & Reminders

**Status:** planned

**Source:** `ROADMAP.md` §8, `ARCHITECTURE.md` §32, `DATA_MODEL.md`,
`DESIGN.md`, `AGENTS.md`

**Objective:** Help users avoid forgetting important warranty-related dates by
sending local notifications before and on the warranty end date, with explicit
user control and no duplicates or stale reminders.

**Completion criteria (from ROADMAP §8):**

- [ ] Users who enable reminders receive useful notifications without
      unnecessary duplication or stale reminders.

---

## Prerequisites

- [x] Phase 1 (products, warranty status) implemented and tested
- [x] Phase 2 (documents) implemented, tested and merged
- [ ] Dependencies and scope decisions below approved
- [ ] Confirm supported platforms for this phase: Android and iOS
      (the project currently ships only those two targets)

---

## 1) Dependencies

Every dependency must be justified (AGENTS.md §18). None of these is
replaceable with Flutter/Dart built-ins.

- [ ] `flutter_local_notifications` **^22.3.3** — schedules local
      notifications on Android/iOS, including the platform permission flows.
      Pinned to 22.x on purpose: 23.x requires Flutter >= 3.44 and Dart
      ^3.12, while the project uses Flutter 3.41.7 / Dart 3.11.5.
- [ ] `timezone` **^0.11.2** — required by `zonedSchedule` to represent the
      device's local calendar correctly (DST included).
- [ ] `flutter_timezone` **^5.1.1** — resolves the device timezone name so
      `timezone`'s `tz.local` is the real local zone instead of UTC.
- [x] `shared_preferences` — already in `pubspec.yaml` (currently unused).
      Reminder settings are simple key/value data, so no new dependency and
      no database migration are needed.

No network, cloud, push-notification or analytics dependency is introduced.
Everything stays on-device (offline-first).

---

## 2) Scope Decisions (proposed)

These keep the phase small while satisfying the ROADMAP completion criteria.
Any change requires explicit approval before implementation.

1. **Global settings, not per-product reminders.** The user chooses whether
   reminders are enabled and how many days before expiration to be notified.
   The ROADMAP lists "optional custom reminder" as a *potential* reminder, not
   a requirement, so per-product custom reminders are deferred.
2. **Two reminder events per product** when enabled:
   * "approaching" at `warrantyEndDate - leadDays`, at 09:00 local time;
   * "expires today" at `warrantyEndDate`, at 09:00 local time.
   Events whose date/time is already in the past are not scheduled.
3. **Lead time options:** 1, 3, 7, 14, 30, 60 days. **Default: 30 days**
   (matches the ROADMAP example "expires in 30 days").
4. **Reminder time is fixed at 09:00 local time** for this phase. A
   configurable time adds UI and scheduling complexity without being required.
5. **Inexact Android scheduling** (`AndroidScheduleMode.inexactAllowWhileIdle`)
   so the app does not need `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`.
   Warranty reminders do not require minute-level precision.
6. **Resync instead of bookkeeping.** The scheduler derives the desired
   notifications from the current products and settings, cancels the app's
   scheduled reminders, and schedules the new plan. This makes deleted
   products, edited dates and changed settings correct by construction.
7. **No deep link from the notification** in this phase. Tapping opens the
   app normally (the notification payload still carries the `productId` so a
   future phase can add routing without changing what is scheduled).
8. **Permission is requested only from an explicit user action** (enabling
   reminders in Settings), never on app start.

---

## 3) Domain Layer — Reminders

- [ ] **Entity: `ReminderSettings`**
      `enabled` (bool), `leadDays` (int). Defaults: `false`, `30`.
      Validation: `leadDays` must be one of the supported options; unknown
      stored values fall back to the default.
- [ ] **Enum: `ReminderType`** — `approaching`, `expiration`.
- [ ] **Entity: `WarrantyReminder`** — `notificationId`, `productId`,
      `productName`, `scheduledAt`, `type`.
- [ ] **Repository contract: `ReminderSettingsRepository`** —
      `Future<ReminderSettings> load()`, `Future<void> save(ReminderSettings)`.
- [ ] **Service contract: `ReminderScheduler`** —
      `Future<void> sync()`; implemented in the data layer.
- [ ] **Planner: `WarrantyReminderPlanner`** (pure Dart, no Flutter)
      `List<WarrantyReminder> plan({products, settings, now})`:
  - skip when `settings.enabled` is false;
  - skip products with a null `warrantyEndDate`;
  - use `DateTime(y, m, d, 9)` local calendar values, consistent with
    `DATA_RULES.md` and `WARRANTY_END_DATE_RULE.md`;
  - skip events at or before `now`;
  - stable deterministic IDs from `productId` + `ReminderType`, so a resync
    never leaves duplicates;
  - if `leadDays == 0` is ever stored, do not emit two events on the same day;
  - cap the plan to the **soonest 60 events** so the iOS limit of 64 pending
    notifications is never hit (leave a small buffer for other app
    notifications).
- [ ] Unit tests for the planner: approaching + expiration, end date today,
      past end date, null end date, disabled settings, boundaries at 09:00,
      deterministic IDs, duplicate-free output and the 60-event cap.

---

## 4) Data Layer — Settings, Gateway and Scheduler

- [ ] **Settings repository** — `reminder_settings_repository_impl.dart` using
      `SharedPreferences` keys `reminders.enabled` and `reminders.lead_days`.
      It is the only place that knows the storage format.
- [ ] **Notification gateway** — `warranty_notification_gateway.dart`
      wrapping `FlutterLocalNotificationsPlugin`:
  - `initialize()`: plugin init plus timezone bootstrap (device timezone);
  - `requestPermission()` / `permissionStatus()` for Android 13+ and iOS;
  - `cancelAll()` and `schedule(WarrantyReminder, title, body)` using
    `zonedSchedule` with inexact Android mode;
  - `openSystemNotificationSettings()` for the denied-permission case;
  - exposes injectable seams (plugin instance / clock / timezone) so tests do
    not need native platform mocks, following the Phase 2 pattern.
- [ ] **Scheduler** — `warranty_reminder_scheduler.dart` implements
      `ReminderScheduler.sync()`:
  1. load settings;
  2. always cancel the app's warranty reminders first;
  3. if disabled or permission is not granted, stop (no scheduling);
  4. read the current products through `ProductDao`;
  5. build the plan with `WarrantyReminderPlanner`;
  6. schedule each reminder with localized title/body.
  Scheduling failures are caught and logged: a product create/update/delete
  must never fail because of notifications.
- [ ] **Notification messages** — add `reminders.notification.*` keys to
      `en.json` and `es.json` (one title/body per `ReminderType`, with the
      product name and days as parameters). Text is composed when scheduling,
      so a language change is applied on the next sync.
- [ ] **DI** — register `ReminderSettingsRepository`,
      `WarrantyNotificationGateway`, `WarrantyReminderScheduler` and the
      settings cubit in `lib/app/di/injection.dart`.

---

## 5) Integration — Keeping Reminders Correct

- [ ] **Startup sync**: after DI and plugin initialization, call
      `sync()` once. It must not request permission and must be safe when no
      products exist or reminders are disabled.
- [ ] **Product lifecycle hooks**: `ProductRepositoryImpl` calls
      `ReminderScheduler.sync()` after `create`, `update` and `delete`.
      Failures are logged, never propagated (same rule as stored-file cleanup
      in Phase 2).
- [ ] **Settings changes**: saving the settings triggers a sync, so enabling,
      disabling or changing the lead time takes effect immediately.
- [ ] **Deleted products / changed dates**: covered by the resync derived from
      the database; the planner only sees current rows.
- [ ] **Android reboot**: add the boot receiver so the plugin reschedules after
      a reboot.
- [ ] **App resume (optional, only if needed)**: if permission or timezone
      changes are not reflected, resync when the settings screen becomes
      current (`ModalRoute.isCurrentOf`), per AGENTS.md §7.

---

## 6) Presentation — Settings

- [ ] Replace the placeholder `SettingsView` with a real settings page:
  - **Reminders section** with an enable/disable switch;
  - lead-time selector (1/3/7/14/30/60 days), reused via the existing
    `OptionSelectorRow` where it fits;
  - short helper text explaining what will be notified;
  - permission-denied state with an "Open system settings" action;
  - loading and error states for settings persistence.
- [ ] **Cubit: `ReminderSettingsCubit`** with immutable states
      (loading, ready, saving, permission-blocked, error):
  - load settings + permission status on creation;
  - enabling requests permission; store `enabled = true` only when granted;
  - disabling saves and cancels scheduled reminders;
  - changing the lead time saving + syncing;
  - permission check on screen re-entry (AGENTS.md §7 refresh rule).
- [ ] **Localization** — `settings.reminders.*` keys in `en.json` and
      `es.json`. No hard-coded user-facing strings.
- [ ] **Design** — use existing tokens (`AppColors`, `AppSpacing`,
      `AppTextStyles`) and Material 3 components. If the settings page
      introduces a new visual pattern, document it in `DESIGN.md` first.

---

## 7) Platform Configuration

### Android

- [ ] `android/app/build.gradle.kts`: enable core library desugaring
      (`isCoreLibraryDesugaringEnabled = true`), `multiDexEnabled = true`,
      and add `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`.
      The project already uses AGP 8.11.1, the minimum required by the plugin.
- [ ] Ensure `compileSdk` is >= 35 (Flutter 3.41 already resolves a supported
      value; verify after adding the plugin).
- [ ] `AndroidManifest.xml`: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`,
      `ScheduledNotificationReceiver`, and
      `ScheduledNotificationBootReceiver` with the boot/replace intent
      filters. No exact-alarm permission (inexact scheduling).
- [ ] Add a monochrome notification icon drawable and pass it to
      `AndroidInitializationSettings` (avoid using the launcher icon).
- [ ] Verify notification channels are created with the desired importance;
      changing sound/importance later requires a new channel id.

### iOS

- [ ] `ios/Runner/AppDelegate.swift`: set
      `UNUserNotificationCenter.current().delegate` (the project uses the
      UIScene lifecycle via `FlutterImplicitEngineDelegate`, so confirm the
      correct hook) so foreground notifications and taps are delivered.
- [ ] No `Info.plist` entry is required for local notifications.
- [ ] Deployment target stays at iOS 13, which the plugin supports.

---

## 8) Testing

- [ ] Planner unit tests (see §3), including the iOS 64-limit cap.
- [ ] `ReminderSettingsRepositoryImpl` tests with
      `SharedPreferences.setMockInitialValues`, covering defaults, unknown
      values and round-trip persistence.
- [ ] Scheduler tests with fakes for settings, products and gateway:
      disabled → cancel only; permission denied → cancel only; enabled →
      deterministic schedule list; gateway failure → swallowed and logged.
- [ ] `ProductRepositoryImpl` tests updated: sync runs after create/update/
      delete and a sync failure does not fail the operation.
- [ ] `ReminderSettingsCubit` tests: load, toggle granted, toggle denied,
      lead-time change, save error, permission-blocked refresh.
- [ ] Widget test for the settings page: switch, options, denied message,
      loading and error states, localized strings.
- [ ] Integration test (best effort): enable reminders on the simulator, add
      a product whose end date falls inside the lead window, and assert that
      the expected pending notification exists. If simulator behavior proves
      unreliable, keep the coverage at the scheduler/unit level and document
      why.
- [ ] Manual device verification checklist:
  - permission prompt appears only when enabling;
  - a reminder scheduled one minute ahead is delivered;
  - editing the end date reschedules the reminder;
  - deleting the product removes its pending reminder;
  - disabling reminders removes all pending reminders;
  - device reboot keeps Android notifications scheduled.

---

## 9) Quality & Verification

- [ ] `dart format .`
- [ ] `flutter analyze` — 0 issues
- [ ] `flutter test` — all unit/widget tests pass
- [ ] `flutter test integration_test` on the iOS simulator
- [ ] Android smoke test (permission, scheduling, reboot)
- [ ] iOS smoke test (permission, foreground/background delivery)
- [ ] No database migration expected: settings live in `SharedPreferences`,
      so `schemaVersion` stays at 3. Verify upgrading an existing install with
      data still works.

---

## 10) Documentation

- [ ] `DATA_MODEL.md`: add a short "Reminder Settings" section stating that
      reminder preferences are device-local settings persisted in
      `SharedPreferences` and are **not** part of the product data model or
      the database schema.
- [ ] `ARCHITECTURE.md`: add `features/reminders/` (domain/data) and describe
      the notification integration (resync from current products, scheduler
      as a data-layer service).
- [ ] `DESIGN.md`: document the settings page if it introduces new patterns.
- [ ] `ROADMAP.md`: mark Phase 3 as done and move the current priority to
      Phase 4 only when the completion criteria are met.
- [ ] `docs/plans/README.md`: keep the Phase 3 status current.

---

## 11) Implementation Steps (one approval per step, AGENTS.md §28)

1. **Dependencies + platform configuration** — `pubspec.yaml`,
   `android/app/build.gradle.kts`, `AndroidManifest.xml`, notification icon,
   `ios/Runner/AppDelegate.swift`; `flutter pub get`; verify builds.
2. **Domain** — `reminder_settings.dart`, `reminder_type.dart`,
   `warranty_reminder.dart`, `reminder_settings_repository.dart`,
   `reminder_scheduler.dart`, `warranty_reminder_planner.dart` + planner
   tests.
3. **Data** — settings repository, notification gateway, scheduler and their
   tests; DI registrations.
4. **Integration** — startup sync and product lifecycle hooks in
   `ProductRepositoryImpl`; repository tests updated.
5. **Presentation** — `ReminderSettingsCubit`, real `SettingsView`, reminder
   widgets, translations and widget/cubit tests.
6. **Verification** — integration test, iOS/Android smoke tests, docs updates
   and plan checkboxes.

---

## Decisions & Open Questions

- **Reminder time configurable?** Proposed no (fixed 09:00). Revisit only if
  users ask for it.
- **Per-product custom reminders?** Deferred (not required by the completion
  criteria).
- **Should the approaching reminder be user-toggleable independently from the
  expiration-day reminder?** Proposed no for this phase.
- **What happens if permission is later revoked in system settings?** The
  settings screen shows a blocked state and offers to open system settings;
  scheduled notifications are cancelled on the next sync.
- **Notifications and app language:** messages are built when scheduled; after
  a language change they are updated on the next sync (startup, product
  change or settings change). This limitation will be documented.
- **Two products expiring the same day** produce two notifications. The OS
  may group them; the app does not deduplicate across products because each
  reminder belongs to a different product.

---

## Risks

- **iOS pending-notification limit (64).** Mitigated by capping the plan to
  the soonest 60 events.
- **Android OEM background restrictions** can delay or block scheduled
  notifications on some devices; this is an OS limitation and is documented
  for users if it becomes a recurring support issue.
- **Timezone/DST** is handled by `timezone` + `flutter_timezone`; the plan
  uses calendar dates at 09:00 local time.
- **Permission denial** must never break product management: scheduling is
  best-effort and failures are logged, not surfaced as product errors.
- **Plugin upgrade path**: 22.x is the last line compatible with the current
  Flutter SDK; upgrading Flutter may allow 23.x later. Revisit then.
