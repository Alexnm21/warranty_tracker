# ARCHITECTURE.md

# Warranty Tracker — Architecture

This document defines the architectural structure and dependency rules of Warranty Tracker.

The project follows:

* **Clean Architecture**
* **Feature-first organization**
* **BLoC/Cubit for state management**
* **Repository pattern**
* **Drift + SQLite for local persistence**
* **get_it for dependency injection**
* **go_router for navigation**

The architecture should provide a clear separation between:

```text
Presentation
     ↓
  Domain
     ↓
    Data
```

Dependencies must always point inward.

---

# 1. Architectural Goals

The architecture should prioritize:

1. Maintainability
2. Testability
3. Clear separation of responsibilities
4. Low coupling
5. Reusability where it provides real value
6. Simple feature development
7. Offline-first behavior
8. Easy future expansion

The architecture must not become unnecessarily complex.

Do not introduce abstractions solely because Clean Architecture allows them.

Every abstraction should have a clear responsibility.

---

# 2. High-Level Architecture

The application is divided into three main layers:

```text
┌─────────────────────────────┐
│        PRESENTATION         │
│                             │
│ Pages / Widgets             │
│ BLoC / Cubit                │
└──────────────┬──────────────┘
               │
               ↓
┌─────────────────────────────┐
│           DOMAIN            │
│                             │
│ Entities                    │
│ Repository contracts        │
│ Use Cases (when needed)     │
│ Business rules              │
└──────────────┬──────────────┘
               │
               ↓
┌─────────────────────────────┐
│            DATA             │
│                             │
│ Repository implementations  │
│ DAOs                        │
│ Database                    │
│ DTOs / Models (when needed) │
│ Mappers (when needed)       │
└─────────────────────────────┘
```

The dependency direction is:

```text
Presentation → Domain ← Data
```

The domain layer must not depend on data or presentation.

---

# 3. Project Structure

The project follows a **feature-first** structure.

Recommended structure:

```text
lib/
├── app/
│   ├── app.dart
│   ├── router/
│   │   ├── app_router.dart
│   │   └── route_names.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   └── ...
│   └── di/
│       └── injection.dart
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── extensions/
│   ├── utils/
│   └── widgets/
│
├── features/
│   ├── products/
│   │   ├── data/
│   │   │   ├── daos/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   │
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   └── repositories/
│   │   │
│   │   └── presentation/
│   │       ├── bloc/
│   │       ├── pages/
│   │       └── widgets/
│   │
│   ├── warranties/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   └── settings/
│       ├── data/
│       ├── domain/
│       └── presentation/
│
└── main.dart
```

The exact feature list may evolve as the application grows.

`usecases/` and `mappers/` are **not created by default**. Add them only when complexity requires it (see §9 and §13).

---

# 4. `app/`

The `app` directory contains application-wide configuration.

It is responsible for things such as:

* Application root widget
* Theme configuration
* Routing
* Dependency injection
* Global application configuration

It must not contain feature-specific business logic.

---

# 5. `core/`

`core/` contains functionality that is genuinely shared across multiple features.

Examples:

```text
core/
├── constants/
├── database/
├── errors/
├── extensions/
├── utils/
└── widgets/
```

Only place code in `core/` when it is truly feature-independent.

Do not use `core/` as a dumping ground.

If a component is only relevant to warranties, it belongs inside the warranty feature.

If a utility is only relevant to products, it should remain inside the product feature.

---

# 6. Features

Each major application capability should be represented as a feature.

Examples:

```text
features/
├── products/
├── warranties/
├── documents/
├── settings/
└── ...
```

A feature owns its:

* UI
* State management
* Domain logic
* Data access

Features should be as independent as reasonably possible.

---

# 7. Domain Layer

The domain layer represents the business logic of a feature.

Example:

```text
products/
└── domain/
    ├── entities/
    └── repositories/
```

## 7.1 Entities

Entities represent business concepts.

Examples:

```text
Product
Warranty
Store
Document
Purchase
```

Entities must not contain infrastructure-specific implementation details.

Avoid coupling entities to:

* Drift
* SQLite
* Flutter
* BLoC
* JSON serialization
* Database rows

Example:

```dart
class Product {
  final String id;
  final String name;
  final String? brand;
  final DateTime purchaseDate;
  final double? price;

  const Product({
    required this.id,
    required this.name,
    this.brand,
    required this.purchaseDate,
    this.price,
  });
}
```

The actual fields depend on `DATA_MODEL.md`.

---

# 8. Repository Contracts

Repository interfaces belong in the domain layer.

Example:

```dart
abstract interface class ProductRepository {
  Future<List<Product>> getProducts();

  Future<Product?> getProductById(String id);

  Future<void> saveProduct(Product product);

  Future<void> deleteProduct(String id);
}
```

The domain only knows what the repository can do.

It does not know how the data is stored.

The repository implementation belongs to the data layer.

---

# 9. Use Cases

Use cases are **optional and not created by default**.

By default, BLoCs/Cubits call repository contracts directly:

```text
ProductCubit
     ↓
ProductRepository
```

A `usecases/` folder is added only when complexity requires it.

Create a use case when at least one of the following is true:

* It encapsulates a real business rule (e.g. `GetWarrantyStatus`).
* The same operation is needed from multiple places (e.g. several BLoCs).
* It coordinates more than one repository or source of data.
* It isolates logic that would otherwise be duplicated in BLoCs.

Do **not** create a use case that merely delegates to a repository method:

```dart
// Avoid: boilerplate with no added value
class CreateProduct {
  final ProductRepository repository;

  CreateProduct(this.repository);

  Future<void> call(Product product) {
    return repository.saveProduct(product);
  }
}
```

Use cases, when they exist, should remain independent from Flutter and infrastructure.

---

# 10. Data Layer

The data layer implements persistence and external data access.

Example:

```text
products/
└── data/
    ├── daos/
    ├── models/
    └── repositories/
```

DAOs belong to the feature that owns the data access (see §21).

`mappers/` is added only when domain entities and data representations actually differ (see §13).

---

# 11. DAOs

DAOs (Data Access Objects) are the direct interface between the data layer and Drift.

They encapsulate SQL queries and expose typed methods that repository implementations consume.

Example:

```text
ProductDao
WarrantyDao
```

A DAO should not contain presentation logic or UI concerns.

Example responsibility:

```text
ProductRepositoryImpl
        ↓
   ProductDao
        ↓
     Drift
        ↓
     SQLite
```

DAOs are infrastructure-specific and must remain inside the data layer.

Each feature owns its DAOs under `features/<feature>/data/daos/`. Shared database infrastructure (`AppDatabase`, table definitions) lives in `core/database/` (see §21).

---

# 12. Models / DTOs

Models are **not created by default**.

Use them only when the database representation actually differs from the domain entity:

```text
ProductEntity
     ↕ mapper
ProductModel
```

If the Drift row maps one-to-one to the domain entity, work directly with the entity and skip the model.

Do not expose Drift-generated database types throughout the application.

Keep database-specific representations inside the data layer.

---

# 13. Mappers

Mappers are **not created by default**. Create one only when:

* A model/entity pair actually exists (see §12), or
* The same non-trivial conversion would otherwise be duplicated in several repositories or BLoCs.

When a mapper exists, conversions go through it:

```text
ProductModel
      ↓
ProductMapper
      ↓
Product
```

And when saving:

```text
Product
   ↓
ProductMapper
   ↓
ProductModel
```

For simple cases, an inline conversion inside the repository is preferred over a dedicated mapper file. Avoid unnecessary boilerplate.

---

# 14. Repository Implementations

Repository implementations belong in the data layer.

Example:

```text
domain/
└── repositories/
    └── product_repository.dart

data/
└── repositories/
    └── product_repository_impl.dart
```

The implementation uses the appropriate DAO.

Example flow:

```text
ProductRepository
       ↑
       │ implements
       │
ProductRepositoryImpl
       │
       ↓
ProductDao
       │
       ↓
     Drift
       │
       ↓
    SQLite
```

The presentation and domain layers should depend on the repository abstraction, not its implementation.

A repository implementation can be small, but it should not become a dumb pass-through. Its value comes from:

* Translating infrastructure errors into domain/application errors.
* Composing data from multiple DAOs when a use case needs it.
* Mapping when the data representation differs from the entity (see §13).

If a repository does none of these, keep it anyway as the abstraction boundary, but do not add extra layers around it.

---

# 15. Presentation Layer

The presentation layer contains:

```text
presentation/
├── bloc/
├── pages/
└── widgets/
```

## BLoC/Cubit

BLoC/Cubit coordinates UI state and calls domain repository contracts directly (or use cases when they exist).

Example:

```text
ProductPage
     ↓
ProductCubit
     ↓
ProductRepository
     ↓
ProductDao
     ↓
Drift / SQLite
```

BLoCs and Cubits must not:

* Access Drift directly
* Execute SQL directly
* Instantiate repositories manually
* Contain large amounts of business logic
* Perform unrelated responsibilities

---

# 16. Pages

Pages represent complete screens/routes.

Examples:

```text
ProductsPage
ProductDetailPage
ProductFormPage
WarrantyDetailPage
SettingsPage
```

Pages should primarily:

* Build the screen
* Connect to the appropriate BLoC/Cubit
* React to state
* Trigger user actions

Avoid putting business logic directly in pages.

---

# 17. Widgets

Widgets should represent reusable UI components.

Examples:

```text
ProductCard
WarrantyStatusChip
ProductList
EmptyProductsView
```

Prefer small focused widgets.

If a widget becomes very large or contains multiple unrelated responsibilities, consider extracting smaller widgets.

Do not extract every few lines into a separate widget without a reason.

---

# 18. Dependency Rules

The following dependency rules must always be respected.

### Allowed

```text
Presentation → Domain
Data → Domain
App → Presentation / Domain / Data
Core → independent shared functionality
```

### Forbidden

```text
Domain → Presentation
Domain → Data
Domain → Flutter UI
Presentation → Data implementation
Presentation → Drift
Presentation → SQLite
```

The most important rule is:

> **The domain layer must never depend on infrastructure or presentation.**

---

# 19. Feature-to-Feature Dependencies

Features should remain independent whenever possible.

Avoid:

```text
products → warranties → products
```

Circular dependencies between features are forbidden.

If multiple features need the same business concept, consider:

1. Moving genuinely shared functionality to `core/`.
2. Creating a dedicated shared domain concept.
3. Reconsidering whether the features should actually be one feature.

Do not move feature-specific code to `core/` simply to solve an import problem.

---

# 20. Cross-Feature Communication

Features should communicate through well-defined interfaces.

Avoid directly accessing another feature's:

* BLoC
* Cubit
* Widgets
* DAOs
* Repository implementations

If one feature requires information from another feature, prefer using an appropriate domain-level abstraction.

Example:

```text
Warranty feature
       ↓
ProductRepository
```

rather than:

```text
Warranty feature
       ↓
ProductCubit
```

---

# 21. Database Architecture

The database is centralized but feature-specific data access should remain separated.

Shared infrastructure lives in `core/`:

```text
core/
└── database/
    ├── app_database.dart
    └── tables/
```

Each feature owns its DAOs:

```text
features/
└── <feature>/
    └── data/
        └── daos/
```

Feature repositories consume the database through their own feature's DAOs.

Example:

```text
ProductRepositoryImpl
        ↓
   ProductDao
        ↓
   AppDatabase
        ↓
     Drift
        ↓
     SQLite
```

The exact DAO organization may evolve as the database grows.

---

# 22. Dependency Injection Architecture

Dependency registration is centralized.

Example:

```text
app/
└── di/
    └── injection.dart
```

The dependency graph should approximately follow:

```text
Database
   ↓
DAOs
   ↓
Repository Implementations
   ↓
BLoCs / Cubits
```

If use cases exist for a feature, they sit between repositories and BLoCs/Cubits.

Example:

```dart
getIt.registerLazySingleton<AppDatabase>(
  () => AppDatabase(),
);

getIt.registerLazySingleton<ProductDao>(
  () => getIt<AppDatabase>().productDao,
);

getIt.registerLazySingleton<ProductRepository>(
  () => ProductRepositoryImpl(getIt<ProductDao>()),
);

getIt.registerFactory(
  () => ProductCubit(getIt<ProductRepository>()),
);
```

Dependencies should be injected through constructors with explicit types (`getIt<ProductDao>()`) rather than untyped `getIt()` calls, so each class's dependencies are visible from its constructor.

Prefer `registerLazySingleton` for long-lived services and repositories.

Prefer `registerFactory` for short-lived presentation objects such as BLoCs/Cubits when appropriate.

The exact registration strategy may vary according to lifecycle requirements.

---

# 23. Routing Architecture

Routing belongs in:

```text
app/router/
```

The router should know about application pages but should not contain business logic.

Example:

```text
GoRouter
   ↓
ProductsPage
   ↓
ProductCubit
```

Do not perform database operations directly from route definitions.

If route redirects require application state, expose the required state through an appropriate application-level mechanism.

---

# 24. State Flow

The standard flow for reading data is:

```text
User opens screen
       ↓
Page
       ↓
BLoC / Cubit
       ↓
Repository interface
       ↓
Repository implementation
       ↓
DAO
       ↓
Drift / SQLite
       ↓
DAO
       ↓
Repository
       ↓
BLoC / Cubit
       ↓
New State
       ↓
UI
```

The standard flow for writing data is:

```text
User action
     ↓
Page / Widget
     ↓
BLoC / Cubit
     ↓
Repository
     ↓
DAO
     ↓
Database
     ↓
Updated state
     ↓
UI
```

If use cases exist, they are invoked between the BLoC/Cubit and the repository.

---

# 25. Reactive Database Updates

For collections and lists, **Drift streams are the default**. Subscribe once and let the UI update automatically instead of manually refreshing after every write:

```text
SQLite
   ↓
Drift Stream
   ↓
Repository
   ↓
BLoC / Cubit
   ↓
UI
```

One-shot `Future` reads are appropriate for single records or operations where reactivity adds no value.

Do not mix both approaches for the same data without a concrete reason.

---

# 26. Business Logic Location

Business rules belong in the domain layer whenever practical.

For example:

```text
Warranty expiration calculation
Warranty status
Remaining warranty time
```

should not be implemented separately in:

```text
ProductPage
ProductCubit
WarrantyCard
WarrantyDetailPage
```

Instead, centralize the rule in an appropriate domain abstraction.

This prevents different parts of the application from calculating the same value differently.

---

# 27. Date and Warranty Logic

Warranty-related calculations must use a consistent approach.

Examples include:

* Warranty expiration
* Days remaining
* Expired status
* Expiring soon status

These rules should not be duplicated across UI components.

The exact business rules belong in `DATA_MODEL.md` and/or the relevant domain implementation.

---

# 28. When to Create an Abstraction

Create an abstraction when at least one of the following is true:

* It represents a meaningful domain concept.
* It isolates infrastructure.
* It is reused in multiple places.
* It improves testability.
* It protects the application from an implementation detail.
* It represents a stable contract.

Do not create abstractions solely to increase the number of classes.

For example, avoid creating:

```text
IProductNameFormatter
ProductNameFormatterImpl
```

if there is no meaningful reason for the abstraction.

---

# 29. When to Create a New Feature

Create a new feature when functionality represents a meaningful application capability with its own:

* Domain concepts
* UI
* State
* Business rules
* Data requirements

Do not create a feature for every individual screen.

For example:

```text
products/
    product_list
    product_detail
    product_form
```

is generally preferable to:

```text
product_list_feature/
product_detail_feature/
product_form_feature/
```

---

# 30. Refactoring Rules

Refactor when:

* Code duplication becomes meaningful.
* A class has too many responsibilities.
* A dependency boundary is being violated.
* A pattern is repeatedly implemented differently.
* A change would otherwise significantly increase technical debt.

Do not refactor unrelated parts of the application simply because they could be cleaner.

When a refactor affects architecture, document the decision when appropriate.

---

# 31. Testing Architecture

Testing should follow the same architectural boundaries.

### Domain

Prioritize unit tests for:

* Business rules
* Pure domain logic
* Use cases and mappers, when they exist

### Data

Test:

* Repository behavior where valuable
* Data transformations
* Database behavior when important

### Presentation

Test:

* BLoC/Cubit state transitions
* Important widgets
* Critical user flows

Tests should not require the entire application to be initialized unless they are intentionally integration tests.

---

# 32. Architecture Evolution

This architecture is not immutable.

As Warranty Tracker grows, the architecture may need to evolve.

Possible future requirements include:

* Cloud synchronization
* User accounts
* Backup
* Notifications
* OCR
* Premium features
* Multiple storage providers
* Remote APIs

When introducing such functionality:

1. Preserve existing boundaries where possible.
2. Avoid forcing future architecture into the current code prematurely.
3. Introduce new abstractions only when the requirement actually exists.
4. Update this document when a project-wide architectural decision changes.

---

# 33. Architectural Decision Rule

When multiple valid implementations exist:

1. Prefer the simplest implementation.
2. Prefer the existing project pattern.
3. Prefer fewer dependencies.
4. Prefer stronger separation of responsibilities.
5. Prefer testable business logic.
6. Prefer solutions that are easy for another developer to understand.

The architecture should serve the application, not the other way around.

---

# 34. Source of Truth

This document defines the project's architectural structure.

For related concerns, refer to:

* `AGENTS.md` → development rules and agent behavior
* `DESIGN.md` → UI and visual system
* `DATA_MODEL.md` → entities, relationships, and business data
* `ROADMAP.md` → project scope and development phases

If implementation and documentation disagree, identify the discrepancy and determine whether the code or documentation should be updated.

Do not silently establish a new architectural convention.
