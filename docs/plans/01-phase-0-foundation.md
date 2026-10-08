# Phase 0 — Project Foundation

**Status:** done

**Source:** `ROADMAP.md` §5, `ARCHITECTURE.md`, `DESIGN.md`

**Objective:** Establish the technical foundation (structure, theme, routing,
DI, database, localization) before implementing product functionality.

**Completion criteria (from ROADMAP §5):**

- [ ] Application starts successfully with the new structure
- [ ] Architecture is established
- [ ] Navigation works
- [ ] Dependency injection works
- [ ] Local database can be initialized
- [ ] Localization works
- [ ] Theme follows `DESIGN.md`
- [ ] Tests can be executed successfully
- [ ] Project follows `AGENTS.md`

---

## Steps

### 1. Dependencies

Add to `pubspec.yaml`:

- [x] `get_it` — dependency injection
- [x] `go_router` — navigation
- [x] `flutter_bloc` — state management (used from Phase 1)
- [x] `drift` + `drift_flutter` — local database
- [x] `easy_localization` — user-facing strings
- [x] `build_runner` + `drift_dev` (dev) — Drift code generation

### 2. Project structure

- [x] Create `lib/app/` (`app.dart`, `router/`, `theme/`, `di/`, `shell_page.dart`)
- [x] Create `lib/core/` (`database/`, `widgets/` — only what is needed now)
- [x] Create `lib/features/` with placeholder views: `home`, `products`, `settings`
- [x] Remove the counter demo (widgets and its test)
- [x] Rewrite `lib/main.dart` as bootstrap: init DI → init localization → `runApp`
      (`WidgetsFlutterBinding.ensureInitialized()` +
      `await EasyLocalization.ensureInitialized()` + `setupInjection()` +
      `runApp(EasyLocalization(...))`)
- [x] `/` renders the shell: `NavigationBar` with 3 destinations over an
      `IndexedStack` of the three placeholder views

### 3. Theme (`app/theme/`)

- [x] `app_colors.dart` — Material 3 color tokens per **Decisions #1**
- [x] `app_text_styles.dart` — Inter type scale (display 32/700 → label-small 12/600)
- [x] `app_theme.dart` — `ThemeData` wired to the tokens (light theme)
- [x] Spacing constants: 4 / 8 / 16 / 24 / 32, screen margin 16
- [x] Radii constants: cards 16, buttons 12, inputs 12, small controls 8, bottom sheets 20
- [x] Bundle Inter TTF files in `assets/fonts/` (offline-first; do not fetch at
      runtime) — variable font (100–900) + `OFL.txt` license

### 4. Routing (`app/router/`)

- [x] `app_router.dart` with `GoRouter`
- [x] `route_names.dart` with named routes
- [x] Route `/` → shell page (bottom navigation: home, productList, settings)
      — implemented with `StatefulShellRoute.indexedStack` (Option A): one
      branch per tab (`/`, `/products`, `/settings`), independent stack per
      branch

### 5. Dependency injection (`app/di/`)

- [x] `injection.dart` with `setupInjection()`
- [x] Register `AppDatabase` (other registrations arrive in Phase 1)
- [x] Call from bootstrap in `main.dart`

### 6. Database (`core/database/`)

- [x] `AppDatabase` (Drift) with `schemaVersion: 1`
- [x] Explicit migration strategy (`onUpgrade` path documented even if empty for now)
- [x] Tables folder under `core/database/tables/` — deferred to Phase 1 together
      with the `products` table (an empty folder has no content to commit)
- [x] Verify DB initializes — covered by `test/core/database/app_database_test.dart`
      (in-memory open + query)
- [x] Note: `products` table is deferred to Phase 1 (tied to `DATA_MODEL.md`)

### 7. Localization

- [x] Initialize `easy_localization` in bootstrap (`ensureInitialized()` + widget
      wrapping in `runApp`; requires `main()` to be `async`)
- [x] Create `assets/translations/en.json` and `es.json` (**Decisions #2**)
- [x] Add translations folder to pubspec `assets`
- [x] Base keys: app name, common actions (save, cancel, delete, confirm)
- [x] No hard-coded user-facing strings in widgets (shell labels + placeholder
      views use `.tr()`; `MaterialApp` uses `onGenerateTitle` + delegates from
      context)
- [x] Replace temporary hard-coded shell labels (`Home`, `Products`, `Settings`)

### 8. Tests

- [x] Smoke test that boots the real app (DI + localization initialized)
- [x] Remove the old counter test
- [x] `flutter analyze`, `dart format`, `flutter test` all green (CI enforces this)

### 9. Validation

- [x] Compare result against ROADMAP §5 completion criteria — all 9 met
      (starts; architecture; navigation; DI; local DB; localization; theme
      follows `DESIGN.md`; tests green; follows `AGENTS.md`)
- [x] Check against `AGENTS.md` definition of done (§27) — met; no business
      logic in Phase 0 so logic-specific tests are N/A
- [x] Update this plan's status to `done`

---

## Decisions

1. **Color source discrepancy in `DESIGN.md`** — *resolved*
   - Authoritative values: primary `#1D4ED8`, app background `#F9F9FF`,
     primary text `#141B2B`.
   - `DESIGN.md` corrected: frontmatter (`primary`, `primary-container: #DBEAFE`,
     `on-primary-container: #001551`, `surface-tint`) and body narrative
     (background, secondary surface, primary/secondary/tertiary text, borders,
     error border) are now aligned.
   - Warranty status colors (active/expiring/expired) are a separate system and
     were left unchanged.
   - Note: `DESIGN.md` was generated with Stitch and may drift again; treat the
     frontmatter tokens as the source of truth for colors.

2. **Languages** — *resolved*
   - `en` + `es`.

3. **Main screen structure** — *resolved*
   - `/` is a shell with bottom navigation hosting 3 views:
     `home`, `productList`, `settings`.
   - The shell is application chrome (imports the three views), so it lives in
     `app/`; each view belongs to its feature.
   - Real product screens arrive in Phase 1; placeholders now.

---

## Notes

- **Page vs View convention:** a *Page* is a widget that represents a route
  (e.g. `ShellPage`, future `ProductDetailPage`); a *View* is a widget shown
  inside a Page (e.g. `HomeView`, `ProductListView`, `SettingsView`). Feature
  views live in `presentation/views/`.
- CI is already configured (`.github/workflows/ci.yml`): runs on PRs to `main`
  only (format, analyze, test, debug APK build).
- `drift_flutter` chosen over manual `sqlite3_flutter_libs` + `path_provider`
  wiring; revisit only if a concrete limitation appears.
- Inter must be bundled as assets, not downloaded at runtime
  (offline-first principle, §3.3 of `ROADMAP.md`).
- **`drift` is capped to `2.34.x`**: Flutter 3.41.7 pins `meta 1.17.0`, and
  `drift` 2.35 + `drift_dev` require `meta ^1.18.0` (via `analyzer`). Revisit
  after a `flutter upgrade`.
- Generated `*.g.dart` files are **committed** (CI does not run
  `build_runner`) and excluded from analysis in `analysis_options.yaml`.
- `shared_preferences` added as a direct dependency: required by
  `easy_localization` and by its `ensureInitialized()` in `main()` and in the
  widget test (mocked with `setMockInitialValues`).
