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

- [x] **Product List**  
  - Page: `pages/product_list_page.dart`  
  - Cubit/Bloc: `bloc/product_list_cubit.dart` (or bloc). Load all, search, delete with confirmation.  
  - Widgets: `widgets/product_card.dart`, `widgets/empty_products.dart`, `widgets/warranty_status_pill.dart`
- [x] **Product Detail**  
  - Page: `pages/product_detail_page.dart`  
  - Cubit: `bloc/product_detail_cubit.dart` (loading/loaded/notFound/error)  
  - Shows all fields + derived `warrantyStatus` with clear visual state; edit/delete actions (delete confirmed). `_Section`/`_DetailRow` render only present fields.
- [x] **Product Form (Create/Edit)**  
  - Page: `pages/product_form_page.dart` (shared)  
  - Cubit: `bloc/product_form_cubit.dart` with validation  
  - Fields: name (required), brand, model, store, purchase date, price+currency, serial, warranty start/end, notes
- [x] **State classes**  
  Immutable states with `copyWith` (no `Equatable`; not a project dependency). `ProductListState` with `loading/loaded/error`.
- [x] **Localization**  
  Added `products.*` keys (44) to `assets/translations/en.json` and `es.json`: list, detail labels, form fields, validation messages, warranty status, delete dialog, and error messages. Existing `common.*` keys are reused.
- [x] **UI states**  
  Loading, empty, error, success. Follow DESIGN.md spacing/typography/components.

## 4) Navigation

- [x] **Routes**  
  Added nested routes in `lib/app/router/app_router.dart`: `/products` (list), `/products/new` (create), `/products/:id` (detail), `/products/:id/edit` (edit). Named routes via `RouteNames`; navigation uses `goNamed` with `pathParameters`. `RoutePaths` kept for top-level paths only (nested paths must be relative in go_router). Detail/Form are stubs pending Steps 5–6.
- [x] **Deep linking / params**  
  Product id passed via path param (`state.pathParameters['id']`), parsed with `int.tryParse`. No business logic in router.

## 5) Integration

- [x] **Wire to Shell**  
  Products branch points to `ProductListPage`; tab navigation works (existing `widget_test` still green).
- [x] **DI completeness**  
  `ProductListCubit` registered as a factory in `injection.dart`. No direct instantiation in widgets (`ProductListPage` reads it from `getIt`).
- [x] **Theme/Design**  
  Reused `AppColors`, `AppSpacing`, `AppRadii`, `AppTextStyles`. Follows DESIGN.md cards/pills/empty states/interactions (swipe-to-delete + confirm dialog).

## 6) Testing

Focus on behavior: business logic + important flows.

- [x] **Unit tests — WarrantyStatus**  
  Test `fromDates` for: future, active (today between), expired, boundary cases.
- [x] **Unit tests — Mappers**  
  Row <-> entity mapping (`toEntity`, `toRow`, `toInsertCompanion`).
- [x] **BLoC/Cubit tests**  
  ProductList, ProductDetail and ProductForm state transitions (valid/invalid, success/error) via a manual `FakeProductRepository`. Also `parsePrice` unit tests.
- [x] **Widget tests**  
  ProductCard, EmptyProducts (minimal but meaningful), using a `pumpLocalized` helper.
- [x] **Integration test**  
  `integration_test/product_flow_test.dart` runs the full flow on the iOS
  simulator (create → list → detail → edit → search → delete → empty) against an
  in-memory database. Added `integration_test` (Flutter SDK package, no
  third-party dependency). It also serves as the regression test for the
  list-refresh bug fixed in Step 7 (see Decisions).
- [x] **Regression**  
  Run existing tests: `flutter test` (57 tests pass).

## 7) Quality & Verification

- [x] **Format**: `dart format .`
- [x] **Analyze**: `flutter analyze` — 0 new errors/warnings unless justified
- [x] **Tests pass**: `flutter test` (57 unit/widget) + `flutter test integration_test` (1) on the iOS simulator
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
- **`setupInjection({AppDatabase? database})`** gained an optional database
  parameter so widget tests can inject `AppDatabase.forTesting(NativeDatabase.memory())`.
  The real `driftDatabase(...)` never opens under `flutter test`, which left the
  list cubit stuck in `loading` and made `pumpAndSettle` time out. Production
  behavior is unchanged (lazy, file-backed database).
- **Navigation uses named routes + `pathParameters`** (`context.goNamed`), not
  string paths. `RoutePaths` keeps only top-level absolute paths because nested
  go_router routes must declare relative `path` values (`new`, `:id`, `edit`).
- **List search field** uses `ValueListenableBuilder` on the `TextEditingController`
  so the clear button toggles without a full-page rebuild.
- **`products.noResults`** key (not `products.search.empty`): easy_localization
  resolves dotted keys by walking a nested map, so a `search` **string** and a
  `search.empty` sibling would conflict.
- **Relative-import lint fixes** in `lib/app/app.dart` and `lib/main.dart`
  (pre-existing `prefer_relative_imports` infos from Phase 0) are included.
  `flutter analyze` is now fully clean.
- **Detail/Form pages are stubs** in Step 4 (they render an empty `Scaffold`);
  Steps 5–6 implement them. The routes and DI are already wired.
- **`formatPrice` helper** (`core/utils/price_format.dart`) added in Step 5 to
  render minor-unit prices; the form (Step 6) will add the reverse parse there.
- **`ProductDetailCubit` uses `registerFactoryParam<ProductDetailCubit, int, void>`**
  in DI, so the page builds it with the route's product id (`getIt(param1: id)`).
- **New i18n keys** in Step 5: `common.edit`, `products.detail.warrantyStartDate`,
  `products.detail.warrantyEndDate` (en + es).
- **Form validation lives in the cubit** (`ProductFormCubit._validate`) instead
  of `Form`/`TextFormField` validators, so the business rules are unit-testable
  and there is a single source of truth. Error values in the state are i18n keys
  rendered as `InputDecoration.errorText`. Rules follow `FIELD_REQUIREMENTS.md`:
  name/purchase/warranty-start/warranty-end required, end >= start, price
  non-negative, currency required when price is set.
- **New products default to `EUR`** (`FIELD_REQUIREMENTS.md` §11).
- **After a successful save the form navigates to the product list** (rather than
  popping): it keeps the flow predictable and guarantees the list is showing
  fresh data.
- **Bug fixed in Step 7 — the product list did not refresh**: `/products/new`
  and `/products/:id` are nested routes, so `ProductListPage` and its
  `ProductListCubit` survive navigation and `BlocProvider(create:)` never
  re-ran (the list kept showing "No products yet" after a successful create).
  Fixed in `_ProductListContentState` with `ModalRoute.isCurrentOf(context)`,
  which reloads the cubit when the route becomes current again after a nested
  screen is popped. No reload on ordinary rebuilds (search typing, keyboard),
  and no new dependency. The integration test is the regression test: it fails
  without the fix.
- **`parsePrice`** added to `core/utils/price_format.dart` (reverse of
  `formatPrice`); accepts `.` or `,` decimals and returns minor units.
- **`ProductFormStatus` distinguishes `loadError` from `saveError`** so a failed
  save shows a snackbar instead of replacing the form (and losing input).
- **Suggest extraction**: the error/retry state is now duplicated as private
  widgets in the list, detail and form pages; it could become a shared
  `core/widgets/error_state.dart`. Left as-is to keep step scope minimal.
- **Testing uses a manual `FakeProductRepository`** (`test/.../fakes/`) instead
  of `mockito`/`bloc_test`, to avoid new dependencies (AGENTS.md §18). Cubits are
  exercised by driving them directly.
- **`pumpLocalized` test helper** (`test/helpers/`) wraps widgets in
  `EasyLocalization` + `MaterialApp` using the app's own
  `context.localizationDelegates`. Two gotchas: (1) the delegates must include
  `GlobalMaterialLocalizations`, otherwise `intl` date symbols for bare `en`/`es`
  are not initialized and `DateFormat` throws; (2) the pump must run inside
  `tester.runAsync` so the real async asset load completes (the fake-async zone
  does not drive it reliably across multiple tests).
  - No new dependency was needed: the app already passes
    `context.localizationDelegates`, so `formatDate` works at runtime.
- **`formatDate` requires `GlobalMaterialLocalizations`**: it formats with
  `context.locale.toString()` (`en`/`es`), which needs date symbols initialized
  by `flutter_localizations` (provided transparently by easy_localization's
  delegates). If Material localizations are ever removed, `DateFormat` will
  throw.
