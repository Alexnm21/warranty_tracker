# Warranty Tracker — Initial Implementation Scope

## 1. Purpose

The initial implementation of Warranty Tracker must remain intentionally small.

The goal of the first implementation is to build a **solid local-first MVP** around the core use case:

> The user can create, view, edit, delete, search, and manage products together with their purchase and warranty information.

The initial implementation must establish the project's architecture and persistence foundation without implementing future functionality prematurely.

---

# 2. Initial MVP

The initial MVP consists of:

```text
Products
├── Create product
├── View products
├── View product details
├── Edit product
├── Delete product
├── Search products
└── Calculate warranty status
```

All product data is stored locally using:

```text
Drift
  ↓
SQLite
```

The application must work without an internet connection.

---

# 3. Product Data

The initial implementation must support the following product fields:

```text
Product
├── id
├── name
├── brand
├── model
├── store
├── purchaseDate
├── price
├── currency
├── serialNumber
├── warrantyStartDate
├── warrantyEndDate
├── notes
├── createdAt
└── updatedAt
```

Required fields:

```text
id
name
purchaseDate
currency
warrantyStartDate
warrantyEndDate
createdAt
updatedAt
```

Optional fields:

```text
brand
model
store
price
serialNumber
notes
```

---

# 4. Product CRUD

The initial implementation must provide complete CRUD functionality.

## Create

The user can create a new product through a product form.

The form must allow the user to enter:

* Product name
* Brand
* Model
* Store
* Purchase date
* Price
* Currency
* Serial number
* Warranty start date
* Warranty end date
* Notes

Validation must be performed before saving.

---

## Read

The user must be able to:

* View a list of products.
* Open a product.
* View all relevant product information.
* See the current warranty status.

---

## Update

The user must be able to edit an existing product.

Updating a product must:

* Preserve its `id`.
* Preserve `createdAt`.
* Update `updatedAt`.
* Persist the modified values.

---

## Delete

The user must be able to delete a product.

Deletion must remove the product from the local database.

Since documents are not part of the initial implementation, there are no document files to clean up at this stage.

---

# 5. Warranty Status

Warranty status is part of the initial MVP.

The status is derived from:

```text
warrantyStartDate
warrantyEndDate
current date
```

Initial statuses:

```text
Future
Active
Expired
```

The application must not persist the status itself.

Example:

```text
Today < warrantyStartDate
    → Future

warrantyStartDate <= Today <= warrantyEndDate
    → Active

Today > warrantyEndDate
    → Expired
```

The exact date comparison logic must be centralized in the domain layer.

It must not be duplicated across widgets, pages, or BLoCs.

---

# 6. Product List

The initial product list must support:

* Displaying saved products.
* Opening product details.
* Showing basic warranty status.
* Showing an appropriate empty state when there are no products.

The list should use lazy rendering where appropriate.

The UI must remain responsive with a reasonably large number of products.

---

# 7. Search

The initial MVP must support basic product search.

Searchable fields:

```text
name
brand
model
store
serialNumber
```

Search should be case-insensitive from the user's perspective.

The search implementation should use the database when appropriate rather than loading the complete dataset into memory unnecessarily.

Advanced filtering is not part of the initial scope.

---

# 8. Sorting

Basic sorting may be implemented if required by the initial UI.

Supported sorting options should remain limited to useful product-level options such as:

```text
Recently added
Name
Warranty expiration
Purchase date
```

Do not implement a complex sorting/filtering system during the initial MVP.

---

# 9. Database

The initial database contains only the product table:

```text
products
```

No additional tables are required for the first implementation.

The database must use:

```text
Drift + SQLite
```

The architecture must include:

```text
ProductDao
ProductRepository
ProductRepositoryImpl
```

where appropriate.

The initial persistence flow is:

```text
UI
 ↓
BLoC/Cubit
 ↓
ProductRepository
 ↓
ProductDao
 ↓
Drift
 ↓
SQLite
```

---

# 10. Architecture Scope

The initial implementation must establish the agreed architecture:

```text
Presentation
    ↓
Domain
    ↓
Data
    ↓
Drift
    ↓
SQLite
```

The implementation must include:

### Presentation

* Product pages.
* Product widgets.
* Product BLoC/Cubit.

### Domain

* `Product` entity.
* Product repository contract.
* Warranty status business logic.

### Data

* Product repository implementation.
* Product DAO.
* Drift database.

Do not introduce additional architectural layers unless there is a concrete reason.

---

# 11. Navigation

The initial application must include navigation for the core product flow.

Minimum navigation:

```text
Product List
     ↓
Product Detail
     ↓
Edit Product
```

And:

```text
Product List
     ↓
Create Product
```

Use:

```text
go_router
```

for navigation.

---

# 12. Dependency Injection

The initial implementation must use:

```text
get_it
```

Dependencies should be registered approximately in this order:

```text
AppDatabase
    ↓
ProductDao
    ↓
ProductRepository
    ↓
Product Cubit/BLoC
```

The exact registration strategy should follow `ARCHITECTURE.md`.

---

# 13. Localization

All user-facing text must use:

```text
easy_localization
```

The initial MVP must include localization for all implemented UI text.

At minimum, the initial language should support the project's chosen default language.

The architecture must allow additional languages to be added later.

---

# 14. UI Scope

The initial UI must follow `DESIGN.md`.

The MVP should provide at least:

```text
Product List Screen
Product Detail Screen
Product Create/Edit Screen
```

Each important screen should handle:

```text
Loading
Success
Empty
Error
```

where applicable.

The initial implementation should prioritize usability and consistency over adding visual effects or unnecessary animations.

---

# 15. Testing Scope

The initial implementation must include tests for important business behavior.

Minimum testing scope:

### Unit tests

Test:

* Warranty status calculation.
* Product validation.
* Repository error handling.

### BLoC/Cubit tests

Test important product state transitions such as:

```text
Initial
Loading
Loaded
Error
```

and relevant create/update/delete flows.

### Widget tests

Test important product UI behavior where appropriate.

Examples:

* Product list empty state.
* Product form validation.
* Product detail rendering.

No arbitrary coverage percentage is required.

---

# 16. Error Handling

The initial MVP must handle at least:

* Database errors.
* Invalid product data.
* Failed create/update/delete operations.
* Empty product collections.

Technical exceptions must not be displayed directly to users.

The application should present understandable error states and messages.

---

# 17. Explicitly Out of Scope

The following functionality must **not** be implemented during the initial MVP unless explicitly requested:

### Documents

Not included:

* Receipt uploads.
* Invoice uploads.
* Warranty document uploads.
* PDF storage.
* Image storage.
* Document previews.
* Document management.

---

### OCR

Not included:

* Receipt scanning.
* OCR processing.
* Automatic product extraction.
* Automatic warranty extraction.

---

### Notifications

Not included:

* Local notifications.
* Warranty expiration reminders.
* Scheduled notifications.
* Push notifications.

---

### Cloud

Not included:

* User accounts.
* Authentication.
* Cloud synchronization.
* Cloud backup.
* Remote database.
* Multi-device synchronization.

---

### Premium

Not included:

* Subscription system.
* In-app purchases.
* Premium limits.
* Premium-only functionality.

---

### Advanced Features

Not included initially:

* Advanced analytics.
* Spending statistics.
* Warranty statistics.
* Advanced filters.
* Product categories.
* Tags.
* Store entities.
* Multiple users.
* Shared products.
* Export/import.
* Automatic backups.

These may be considered later.

---

# 18. Features Reserved for Later

The architecture should leave room for future features without implementing them now.

Potential future phases include:

```text
Phase 1
Core Product Management
        ↓
Phase 2
Documents & Attachments
        ↓
Phase 3
Notifications
        ↓
Phase 4
OCR
        ↓
Phase 5
Cloud Sync / Backup
        ↓
Phase 6
Premium Features
```

The exact order will be defined in `ROADMAP.md`.

---

# 19. Initial Definition of Done

The initial implementation is complete when the user can:

1. Launch the application.
2. See an empty product state when no products exist.
3. Create a product.
4. Save the product locally.
5. See the product in the product list.
6. Open the product details.
7. See its warranty status.
8. Edit the product.
9. Delete the product.
10. Search for products.
11. Close and reopen the application while retaining the products.
12. Use the application without an internet connection.

The implementation must also:

* Follow `AGENTS.md`.
* Follow `ARCHITECTURE.md`.
* Follow `DATA_MODEL.md`.
* Follow `DESIGN.md`.
* Use the agreed technology stack.
* Pass relevant tests.
* Have no relevant analyzer errors.
* Avoid unnecessary dependencies.
* Avoid implementing out-of-scope functionality.

---

# 20. Scope Rule for the Coding Agent

During the initial implementation, the coding agent must follow this rule:

> **Implement the smallest complete version of the core product and warranty management experience.**

If a requested change belongs to a future feature, the agent should not implement the future feature automatically.

Instead, it should explain:

```text
This belongs to a future scope area.

Current scope:
Core Product Management

Requested functionality:
Document attachments

Recommendation:
Add this to the Documents phase rather than implementing it now.
```

The agent may suggest future work but must not silently expand the MVP.

---

# 21. Scope Expansion

If a feature outside the initial scope is explicitly requested, the agent should first identify:

1. Which future scope area it belongs to.
2. Which architecture changes are required.
3. Which data-model changes are required.
4. Which dependencies, if any, are required.
5. Which documentation must be updated.

Only then should implementation begin.

This prevents accidental scope creep.

---

# 22. Initial Implementation Principle

The first version should prove that the fundamental architecture works:

```text
User
 ↓
Flutter UI
 ↓
BLoC/Cubit
 ↓
Repository
 ↓
DAO
 ↓
Drift
 ↓
SQLite
```

with:

```text
Product
Warranty rules
Local persistence
Search
CRUD
```

Everything else can be added incrementally.

The initial goal is **not to build the complete future Warranty Tracker**.

The goal is to build a small, reliable foundation that can evolve without unnecessary complexity.
