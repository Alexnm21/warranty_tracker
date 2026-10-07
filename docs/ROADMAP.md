# Warranty Tracker — Roadmap

## 1. Purpose

This document defines the planned evolution of Warranty Tracker after the initial project setup.

It establishes:

* The order in which major capabilities should be developed.
* Dependencies between phases.
* The intended product evolution.
* Completion criteria for each phase.

The current implementation scope is defined in:

`docs/INITIAL_SCOPE.md`

This roadmap represents the intended direction of the project and may evolve as requirements and priorities change.

---

# 2. Product Vision

Warranty Tracker is intended to become a simple and reliable application for managing purchased products and their warranties.

The long-term direction is:

1. Store products and warranty information.
2. Keep warranty-related documents associated with each product.
3. Help users avoid missing warranty deadlines.
4. Reduce manual data entry through OCR and assisted data extraction.
5. Provide reliable backup and synchronization.
6. Offer optional premium functionality.

The product should remain focused on its main purpose:

> Know what you bought, when you bought it, how long it is covered, and have the necessary information available when you need to use the warranty.

---

# 3. Roadmap Principles

### 3.1 Build the core first

The basic product and warranty management experience must be solid before adding advanced functionality.

### 3.2 Add complexity only when justified

New features should provide clear user value and justify their additional complexity.

### 3.3 Keep the application local-first

The application should work correctly without requiring an account or an internet connection whenever possible.

### 3.4 Introduce external services progressively

Cloud services, OCR, notifications and synchronization should only be introduced when their use cases are clearly defined.

### 3.5 Avoid premature monetization

Premium functionality should be introduced only after the core product provides enough value to justify it.

### 3.6 Keep each phase usable

Each phase should result in a stable and usable version of the application.

---

# 4. Phase Overview

```text
Phase 0
Project Foundation
        ↓
Phase 1
Core Product & Warranty Management
        ↓
Phase 2
Warranty Documents
        ↓
Phase 3
Notifications & Reminders
        ↓
Phase 4
OCR & Assisted Data Entry
        ↓
Phase 5
Backup & Cloud Synchronization
        ↓
Phase 6
Premium & Advanced Features
```

Not every future phase is guaranteed to be implemented.

---

# 5. Phase 0 — Project Foundation

## Objective

Establish the technical foundation of the application before implementing the main product functionality.

## Scope

* Flutter project configuration.
* Project structure.
* Clean Architecture structure.
* Feature-first organization.
* Material 3 configuration.
* Theme configuration.
* Localization setup.
* Dependency injection setup.
* Routing setup.
* Drift and SQLite setup.
* Linting and formatting.
* Basic testing infrastructure.
* Initial documentation.

## Completion Criteria

* Application starts successfully.
* Architecture is established.
* Navigation works.
* Dependency injection works.
* Local database can be initialized.
* Localization works.
* Theme follows `DESIGN.md`.
* Tests can be executed successfully.
* Project follows `AGENTS.md`.

---

# 6. Phase 1 — Core Product & Warranty Management

## Objective

Implement the minimum useful version of Warranty Tracker.

This phase corresponds to the scope defined in:

`docs/INITIAL_SCOPE.md`

## Scope

### Products

Users can:

* Create products.
* View products.
* Edit products.
* Delete products.
* Search products.
* View product details.

### Product Information

Products can contain:

* Name.
* Brand.
* Model.
* Store.
* Purchase date.
* Price.
* Currency.
* Serial number.
* Warranty start date.
* Warranty end date.
* Notes.

### Warranty

The application calculates warranty status from the warranty dates:

* Future.
* Active.
* Expired.

Warranty status must remain derived rather than persisted.

### UI

Implement:

* Product list.
* Empty state.
* Product detail.
* Create product.
* Edit product.
* Delete confirmation.
* Search.
* Basic sorting if required by the final UX.

## Completion Criteria

The application allows users to manage their products and understand their current warranty status without requiring an internet connection.

Core flow:

```text
Create product
      ↓
Save locally
      ↓
View product
      ↓
See warranty status
      ↓
Edit / delete product
      ↓
Search product
```

---

# 7. Phase 2 — Warranty Documents

## Objective

Allow users to keep documents associated with a warranty together with the corresponding product.

## Scope

Potential document types:

* Purchase receipt.
* Invoice.
* Warranty document.
* Product manual.
* Other supporting documents.

Users should be able to:

* Add a document to a product.
* View document metadata.
* Open a document.
* Delete a document.
* Associate multiple documents with one product.

## Storage

Document metadata should be stored in the database.

Document files should be stored separately from the database.

Large binary files should not be stored directly in SQLite.

## Possible Future Improvements

* PDF support.
* Image documents.
* Document preview.
* Camera capture.
* File picker.
* Document categories.
* Document naming.
* Document sharing.

## Completion Criteria

Users can keep relevant warranty evidence with the corresponding product and retrieve it when needed.

---

# 8. Phase 3 — Notifications & Reminders

## Objective

Help users avoid forgetting important warranty-related dates.

## Scope

Potential reminders:

* Warranty expiration approaching.
* Warranty expiration.
* Optional custom reminder.

Example:

```text
Your iPhone 17 warranty expires in 30 days.
```

## Requirements

The notification system should:

* Respect user permissions.
* Allow notifications to be enabled or disabled.
* Avoid duplicate notifications.
* Correctly handle changes to warranty dates.
* Correctly handle deleted products.
* Work consistently across supported platforms.

## Completion Criteria

Users who enable reminders receive useful notifications without unnecessary duplication or stale reminders.

---

# 9. Phase 4 — OCR & Assisted Data Entry

## Objective

Reduce the amount of manual information users need to enter.

A major use case is taking a photo of a receipt or warranty document and extracting useful information from it.

## Possible Extracted Information

* Product name.
* Brand.
* Model.
* Store.
* Purchase date.
* Price.
* Currency.
* Serial number.

## User Flow

```text
Add product
    ↓
Scan receipt / document
    ↓
OCR processing
    ↓
Extract information
    ↓
Show detected fields
    ↓
User reviews and corrects
    ↓
Save product
```

## Important Rule

OCR results must never be treated as automatically correct.

The user must be able to review and modify extracted information before saving it.

## Completion Criteria

OCR meaningfully reduces manual data entry while keeping the user in control of the final information.

---

# 10. Phase 5 — Backup & Cloud Synchronization

## Objective

Protect user data and allow access to warranty information across devices.

This phase introduces external services and therefore represents a significant increase in complexity.

## Possible Functionality

### Account

* Optional user account.
* Sign in.
* Sign out.
* Account management.

### Backup

* Cloud backup.
* Restore from backup.
* Manual backup if appropriate.

### Synchronization

* Synchronize products.
* Synchronize warranty information.
* Synchronize document metadata.
* Synchronize documents where technically appropriate.

## Important Considerations

Before implementing synchronization, define:

* Authentication strategy.
* Backend technology.
* Data ownership.
* Conflict resolution.
* Offline changes.
* Synchronization states.
* Failure handling.
* Document storage.
* Privacy requirements.
* Data deletion.

## Local-First Behavior

Local data should remain usable when the network is unavailable.

Cloud functionality must not become a requirement for the basic functionality of the application.

## Completion Criteria

Users can safely back up their data and, where supported, access synchronized information from another device without losing local functionality.

---

# 11. Phase 6 — Premium & Advanced Features

## Objective

Introduce optional features that can support monetization while keeping the core application useful.

Premium functionality should only be introduced after the core product has demonstrated sufficient value.

## Possible Premium Features

Potential examples include:

* Unlimited products.
* Advanced document storage.
* Cloud synchronization.
* Automatic backups.
* Advanced OCR.
* Advanced reminders.
* Multiple-device synchronization.
* Export functionality.
* Advanced search and filtering.
* Statistics and analytics.
* Additional customization.

These are possibilities, not confirmed requirements.

## Free vs Premium

The exact free/premium boundary should be decided based on:

* User value.
* Operating costs.
* Cloud and storage costs.
* OCR costs.
* User feedback.
* Usage patterns.
* Competitor landscape.

The free version should remain genuinely useful.

---

# 12. Features Not Currently Planned

The following features are not part of the current roadmap unless a clear need emerges:

* Social functionality.
* Sharing products publicly.
* Multi-user household management.
* Complex inventory management.
* Accounting functionality.
* E-commerce functionality.
* Product price tracking.
* Product recommendations.
* Advertising-heavy UI.
* Unrelated productivity features.

The application should remain focused on warranty management.

---

# 13. Phase Dependencies

Preferred progression:

```text
Foundation
    ↓
Products & Warranties
    ↓
Documents
    ↓
Notifications
    ↓
OCR
    ↓
Cloud / Synchronization
    ↓
Premium
```

This order is preferred but not immutable.

For example:

* Notifications may be implemented before documents if they provide greater immediate value.
* OCR may initially support receipt images without cloud synchronization.
* Backup may be introduced before full multi-device synchronization.

---

# 14. Version Strategy

### v0.x — Development

Focus:

* Architecture.
* Database.
* Product management.
* Warranty logic.
* UI.
* Testing.

### v1.0 — Core Warranty Tracker

First stable version.

Includes:

* Product management.
* Warranty information.
* Warranty status.
* Search.
* Local persistence.
* Core UX.

### v1.x — Documents & Reminders

Adds:

* Warranty documents.
* Notifications.
* Reminders.

### v2.x — Assisted Management

Adds:

* OCR.
* Improved document handling.
* More automation.

### v3.x — Cloud

Adds:

* Accounts.
* Backup.
* Synchronization.

### v4.x+ — Premium & Advanced Features

Adds selected premium and advanced functionality based on product validation.

Version numbers are indicative and may change.

---

# 15. Roadmap Review

The roadmap should be reviewed when:

* A major phase is completed.
* A new important product requirement appears.
* A feature has significantly higher or lower value than expected.
* A technical limitation changes the implementation strategy.
* User feedback suggests a different priority.
* A planned feature becomes unnecessary.

The roadmap should not be updated for minor implementation details.

---

# 16. Adding New Features

Before adding a feature that is not part of the current phase, consider:

1. Does it solve an important user problem?
2. Does it belong to Warranty Tracker's core purpose?
3. Is it necessary for the current phase?
4. Does it introduce significant complexity?
5. Does it require a new dependency or external service?
6. Does it affect the data model?
7. Does it affect the architecture?
8. Can it be postponed to a later phase?

If the feature is not necessary for the current milestone, prefer adding it to the roadmap or backlog rather than implementing it immediately.

---

# 17. Definition of a Completed Phase

A roadmap phase is considered complete when:

* Its intended functionality is implemented.
* The functionality follows `AGENTS.md`.
* Architecture remains consistent with `ARCHITECTURE.md`.
* Data changes follow `DATA_MODEL.md`.
* UI follows `DESIGN.md`.
* Relevant tests are implemented.
* Known errors are handled appropriately.
* No unnecessary dependencies have been introduced.
* The application remains usable.
* Documentation is updated when the phase introduces important architectural or product decisions.

---

# 18. Current Priority

The current priority is:

> Complete Phase 0 and Phase 1 before implementing future-phase functionality.

The initial goal is not to build the complete long-term product immediately.

The initial goal is to build a small, reliable and well-structured warranty management application that provides real value.

Future complexity should be earned by actual product needs.

---

# 19. Final Roadmap Principle

Warranty Tracker should grow progressively:

```text
Simple
  ↓
Useful
  ↓
Reliable
  ↓
Automated
  ↓
Connected
  ↓
Sustainable
```

The application should never sacrifice simplicity and reliability merely to implement more features.
