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

- [ ] **Drift table: products**  
  Create table in Drift (e.g. `products_table.dart` or inside database file). Include all fields from Product. Use `IntColumn` for id (auto-increment or uuid? follow existing DB conventions). Store dates as `DateTime` or `Text` consistently with existing schema.
- [ ] **DAO / data source**  
  Implement queries: all, byId, insert, update, delete, search (by name/brand/model/serial/store).  
  Keep DB-specific code inside data layer only.
- [ ] **DTO/Model mapping**  
  Create mapper `mappers/product_mapper.dart` to map DB row <-> domain entity.  
  Domain must not depend on Drift types.
- [ ] **Repository implementation**  
  Create `repositories/product_repository_impl.dart` implementing `ProductRepository`. Convert infra errors appropriately (follow existing error handling).
- [ ] **Register in DI**  
  Wire repository, data source, use cases in `lib/app/di/`.

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
