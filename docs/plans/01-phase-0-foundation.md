# Phase 0 — Project Foundation

**Status:** pending

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

- [ ] `get_it` — dependency injection
- [ ] `go_router` — navigation
- [ ] `flutter_bloc` — state management (used from Phase 1)
- [ ] `drift` + `drift_flutter` — local database
- [ ] `easy_localization` — user-facing strings
- [ ] `build_runner` + `drift_dev` (dev) — Drift code generation

### 2. Project structure

- [ ] Create `lib/app/` (`app.dart`, `router/`, `theme/`, `di/`)
- [ ] Create `lib/core/` (`database/`, `widgets/` — only what is needed now)
- [ ] Create `lib/features/` skeleton (features stay empty until Phase 1)
- [ ] Remove the counter demo (widgets and its test)
- [ ] Rewrite `lib/main.dart` as bootstrap: init DI → init localization → `runApp`

### 3. Theme (`app/theme/`)

- [ ] `app_colors.dart` — Material 3 color tokens per **Decisions #1**
- [ ] `app_text_styles.dart` — Inter type scale (display 32/700 → label-small 12/600)
- [ ] `app_theme.dart` — `ThemeData` wired to the tokens (light theme)
- [ ] Spacing constants: 4 / 8 / 16 / 24 / 32, screen margin 16
- [ ] Radii constants: cards 16, buttons 12, inputs 12, small controls 8, bottom sheets 20
- [ ] Bundle Inter TTF files in `assets/fonts/` (offline-first; do not fetch at runtime)

### 4. Routing (`app/router/`)

- [ ] `app_router.dart` with `GoRouter`
- [ ] `route_names.dart` with named routes
- [ ] Route `/` → products placeholder page (no product logic yet)

### 5. Dependency injection (`app/di/`)

- [ ] `injection.dart` with `setupInjection()`
- [ ] Register `AppDatabase` (other registrations arrive in Phase 1)
- [ ] Call from bootstrap in `main.dart`

### 6. Database (`core/database/`)

- [ ] `AppDatabase` (Drift) with `schemaVersion: 1`
- [ ] Explicit migration strategy (`onUpgrade` path documented even if empty for now)
- [ ] Tables folder under `core/database/tables/`
- [ ] Verify DB initializes on app start
- [ ] Note: `products` table is deferred to Phase 1 (tied to `DATA_MODEL.md`)

### 7. Localization

- [ ] Initialize `easy_localization` in bootstrap
- [ ] Create `assets/translations/en.json` and `es.json` (**Decisions #2**)
- [ ] Add translations folder to pubspec `assets`
- [ ] Base keys: app name, common actions (save, cancel, delete, confirm)
- [ ] No hard-coded user-facing strings in widgets

### 8. Tests

- [ ] Smoke test that boots the real app (DI + localization initialized)
- [ ] Remove the old counter test
- [ ] `flutter analyze`, `dart format`, `flutter test` all green (CI enforces this)

### 9. Validation

- [ ] Compare result against ROADMAP §5 completion criteria
- [ ] Check against `AGENTS.md` definition of done (§27)
- [ ] Update this plan's status to `done`

---

## Decisions

1. **Color source discrepancy in `DESIGN.md`** — *open*
   - Frontmatter tokens: `primary: #0037b0`, `primary-container: #1d4ed8`,
     `background: #f9f9ff`, `on-surface: #141b2b`
   - Body text: `Primary: #1D4ED8`, `background: #F8F9FA`, text `#111827`
   - Frontmatter looks like a generated M3 palette; body is the narrative.
   - Pending: which one wins for `app_colors.dart`.

2. **Languages** — *open*
   - Proposal: `en` + `es`. Pending confirmation.

3. **Screens beyond the placeholder** — *open*
   - ROADMAP only requires that navigation works. Proposal: single placeholder
     page for now, real product screens in Phase 1.

---

## Notes

- CI is already configured (`.github/workflows/ci.yml`): runs on PRs to `main`
  only (format, analyze, test, debug APK build).
- `drift_flutter` chosen over manual `sqlite3_flutter_libs` + `path_provider`
  wiring; revisit only if a concrete limitation appears.
- Inter must be bundled as assets, not downloaded at runtime
  (offline-first principle, §3.3 of `ROADMAP.md`).
