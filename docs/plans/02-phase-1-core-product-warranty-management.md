# Phase 1 — Core Product & Warranty Management

## Objective

Implement the minimum usable version of Warranty Tracker: manage products and understand warranty status. All data is stored locally (offline-first) using Drift.

This phase implements the scope defined in `docs/INITIAL_SCOPE.md` and `docs/ROADMAP.md` §6.

## References

- [ROADMAP.md](../ROADMAP.md#6-phase-1--core-product--warranty-management)
- [ARCHITECTURE.md](../ARCHITECTURE.md)
- [DATA_MODEL.md](../DATA_MODEL.md)
- [DESIGN.md](../DESIGN.md)
- [AGENTS.md](../../AGENTS.md)
- [INITIAL_SCOPE.md](../INITIAL_SCOPE.md)

## Prerequisites

- [x] Flutter project configured
- [x] Clean Architecture + feature-first structure present
- [x] go_router configured
- [x] get_it configured
- [x] easy_localization configured
- [x] Drift + SQLite configured (schema bootstrap exists)
- [x] Material 3 + theme following DESIGN.md
- [x] flutter_lints configured

## 1) Domain Layer — Products

Create `lib/features/products/domain/` following Clean Architecture.

- [x] **Entity: Product**  
  Created `entities/product.dart`. Fields: id, name, brand?, model?, store?, purchaseDate?, price?, currency?, serialNumber?, warrantyStartDate?, warrantyEndDate?, notes?, createdAt?, updatedAt?.  
  Derive `warrantyStatus` (enum: `future`, `active`, `expired`) from dates. Do **not** persist this field.
- [x] **Enum: WarrantyStatus**  
  Created `entities/warranty_status.dart` with values `future`, `active`, `expired` and helper `fromDates(start, end, now)`.
- [x] **Repository contract: ProductRepository**  
  Created `repositories/product_repository.dart` with methods: `getAll()`, `getById(id)`, `create(product)`, `update(product)`, `delete(id)`, `search(query)`. Keep minimal per INITIAL_SCOPE.

## 2) Data Layer — Products (Drift)

Create `lib/features/products/data/` with tables, DAOs, mappers, data sources, repository impl.

- [x] **Drift table: products**  
  Created `lib/core/database/tables/products_table.dart` (per `ARCHITECTURE.md` §21: shared tables live in `core/database/tables/`). Uses `@DataClassName('ProductRow')` to avoid colliding with the domain `Product`. `id` is auto-increment `IntColumn`; dates are `DateTimeColumn`; `price` is `IntColumn` (minor units). Required columns (`name`, dates, `createdAt`, `updatedAt`) are `NOT NULL`.
- [x] **DAO / data source**  
  Created `lib/features/products/data/daos/product_dao.dart` (`@DriftAccessor(tables: [Products])`): `getAll`, `getById`, `insertProduct`, `updateProduct`, `deleteById`, `search` (case-insensitive `LOWER(...) LIKE` over name/brand/model/store/serialNumber, ordered by `createdAt DESC`).
- [x] **DTO/Model mapping**  
  Created `lib/features/products/data/mappers/product_mapper.dart` mapping `ProductRow`/`ProductsCompanion` <-> domain `Product`. Drift-generated types stay inside the data layer.
- [x] **Repository implementation**  
  Created `lib/features/products/data/repositories/product_repository_impl.dart`. `create` sets `createdAt`/`updatedAt`; `update` preserves `id`/`createdAt` and refreshes `updatedAt`; empty search falls back to `getAll`. Infra exceptions propagate to be handled as UI error states in the presentation layer.
- [x] **Register in DI**  
  Registered `ProductDao` and `ProductRepository` in `lib/app/di/injection.dart`.

## 3) Presentation Layer — Products (BLoC/Cubit)

Create `lib/features/products/presentation/` with pages, widgets, blocs/cubits.

- [ ] **Product List**  
  - Page: `pages/product_list_page.dart`  
  - Cubit/Bloc: `bloc/product_list_cubit.dart` (or bloc). Load all, search, delete with confirmation.  
  - Widgets: `widgets/product_card.dart`, `widgets/empty_products.dart`
- [ ] **Product Detail**  
  - Page: `pages/product_detail_page.dart`  
  - Cubit: `bloc/product_detail_cubit.dart`  
  - Show all fields + derived `warrantyStatus` with clear visual state
- [ ] **Product Form (Create/Edit)**  
  - Page: `pages/product_form_page.dart` (shared)  
  - Cubit: `bloc/product_form_cubit.dart` with validation  
  - Fields: name (required), brand, model, store, purchase date, price+currency, serial, warranty start/end, notes
- [ ] **State classes**  
  Use immutable states with `Equatable` if present in project style; otherwise follow existing conventions.
- [ ] **Localization**  
  Add user-facing strings to `assets/translations/` (en/es as appropriate). Use `tr()`.  
  Keys: e.g. `products.title`, `products.empty`, `products.add`, `products.edit`, `products.delete`, `products.search`, `products.warranty.status.*`, etc.
- [ ] **UI states**  
  Loading, empty, error, success. Follow DESIGN.md spacing/typography/components.

## 4) Navigation

- [ ] **Routes**  
  Add routes for products in `lib/app/router/app_router.dart`:  
  - `/products` (list)  
  - `/products/new` (create)  
  - `/products/:id` (detail)  
  - `/products/:id/edit` (edit)  
  Use named routes where appropriate. Keep ShellPage integration in mind.
- [ ] **Deep linking / params**  
  Pass product id via route params. No business logic in router.

## 5) Integration

- [ ] **Wire to Shell**  
  Products tab should navigate to product list (already exists). Ensure navigation works.
- [ ] **DI completeness**  
  All new dependencies registered. No direct instantiation in widgets.
- [ ] **Theme/Design**  
  Reuse existing components from `core/widgets/`. Follow DESIGN.md.

## 6) Testing

Focus on behavior: business logic + important flows.

- [ ] **Unit tests — WarrantyStatus**  
  Test `fromDates` for: future, active (today between), expired, boundary cases.
- [ ] **Unit tests — Mappers**  
  Row <-> entity mapping.
- [ ] **BLoC/Cubit tests**  
  ProductList, ProductForm state transitions (valid/invalid, success/error).
- [ ] **Widget tests**  
  ProductCard, EmptyProducts (minimal but meaningful).
- [ ] **Regression**  
  Run existing tests: `flutter test`

## 7) Quality & Verification

- [ ] **Format**: `dart format .`
- [ ] **Analyze**: `flutter analyze` — 0 new errors/warnings unless justified
- [ ] **Tests pass**: `flutter test`
- [ ] **Manual smoke test**  
  Flow: create → list shows → detail → edit → delete → search → empty state
- [ ] **Offline check**  
  Works with airplane mode (no network). Confirm no external calls introduced.

## Completion Criteria (from ROADMAP)

Application allows managing products and understanding warranty status offline. Core flow works end-to-end. No unnecessary dependencies. Follows architecture, DESIGN.md, localization. Tests cover key business logic.

## Notes

- Warranty status is **derived**. Never store in DB.
- Keep domain pure (no Flutter/Drift).
- Minimal UI first; polish only if needed to satisfy UX.
- Avoid premature abstraction.
- Update this plan as you progress.

## Decisions & Deviations

- **Price is stored as `int` minor units** (`899.99 EUR` -> `89999`), per
  `FIELD_REQUIREMENTS.md` §10. The domain entity `Product.price` was changed
  from `double?` to `int?` before any data existed (no migration needed).
- **Table location**: `lib/core/database/tables/products_table.dart`
  (`ARCHITECTURE.md` §21), not inside the feature's `data/tables/` folder.
- **Mapper created despite `ARCHITECTURE.md` §13** ("not by default"): the
  Drift row (`ProductRow`) is a generated infrastructure type that the domain
  must not depend on, and the 14-field conversion is reused and unit-testable.
- **DI uses constructor injection** (`ProductDao(getIt<AppDatabase>())`)
  instead of the `getIt<AppDatabase>().productDao` example in
  `ARCHITECTURE.md` §22. Registering the DAO via `@DriftDatabase(daos: [...])`
  creates a cyclic import (`app_database.dart` <-> `product_dao.dart`) that
  breaks drift's annotation resolution. *(Consider aligning the
  `ARCHITECTURE.md` example with the constructor-injection form.)*
- **"Expiring soon" pill deferred**: `DESIGN.md` defines a 4th visual state,
  but the domain only has `future/active/expired` and no day-threshold rule
  exists in `DATA_RULES.md`. Phase 1 shows the 3 domain statuses only. *(A
  threshold would need to be defined in `DATA_RULES.md` first.)*
- **`docs/DATA_MODEL.md` populated** as part of this phase (it was empty).
  It notes that `FIELD_REQUIREMENTS.md` links to non-existent
  `docs/DATE_RULES.md` and `docs/INVALID_DATE_VALIDATION.md`; the actual docs
  are `DATA_RULES.md` and `WARRANTY_END_DATE_RULE.md`. *(Docs consistency to
  fix.)*
- **`injection_test.dart`** now asserts registration only (not resolving
  instances): resolving `AppDatabase` builds a `driftDatabase(...)` connection
  that calls `path_provider`, which requires a Flutter binding in tests.
