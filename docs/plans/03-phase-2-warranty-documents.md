# Phase 2 — Warranty Documents

**Status:** done

**Source:** `ROADMAP.md` §7, `DATA_MODEL.md` §3, `DESIGN.md` (Documents &
Warranty Evidence), `ARCHITECTURE.md`, `AGENTS.md`

**Objective:** Allow users to keep documents associated with a warranty
together with the corresponding product.

**Completion criteria (from ROADMAP §7):**

- [x] Users can keep relevant warranty evidence with the corresponding
      product and retrieve it when needed.

---

## Prerequisites

- [x] Phase 1 (products, warranty status) implemented and tested
- [x] Drift schema versioning in place (`schemaVersion` migration strategy)

---

## 1) Dependencies

Added for document capture and viewing (AGENTS.md §18 — each one is justified
by a concrete requirement, none is replaceable with Flutter/Dart built-ins):

- [x] `cunning_document_scanner` — native document scanning (multi-page → PDF)
- [x] `image_picker` — take a photo with the camera
- [x] `file_selector` — pick existing files (PDF/images)
- [x] `path_provider` — resolve the application documents directory
- [x] `open_filex` — open a stored document with the system viewer

No network, cloud or analytics dependency was introduced. Documents stay
on-device (offline-first).

---

## 2) Domain Layer — Documents

- [x] **Entity: `WarrantyDocument`**  
      `id`, `productId`, `fileName`, `filePath`, `mimeType`, `sizeBytes`,
      `source`, `createdAt`. `id`/`productId` are `null` while staged in the
      form. `isPersisted` and `isImage` helpers.
- [x] **Enum: `DocumentSource`** — `scan`, `photo`, `file`.
- [x] **Controlled failures** — `DocumentImportException` /
      `DocumentOpenException` with `DocumentImportFailure` /
      `DocumentOpenFailure` enums and an internal `cause` that is never shown
      to the user.
- [x] **Repository contract: `DocumentRepository`** — `getByProduct`, `add`,
      `delete`, `deleteStoredFilesForProduct`.

## 3) Data Layer — Documents (Drift + file storage)

- [x] **Drift table: `product_documents`**  
      `lib/core/database/tables/product_documents_table.dart` (shared tables
      live in `core/database/`, per `ARCHITECTURE.md` §21).
      `@DataClassName('ProductDocumentRow')`; `productId` references
      `products.id` with `ON DELETE CASCADE`.
- [x] **Migration** — `schemaVersion = 3`; `from < 3` creates the table;
      `PRAGMA foreign_keys = ON` in `beforeOpen` for the cascade.
- [x] **DAO** — `document_dao.dart`: `getByProduct` (ordered by `createdAt`,
      `id`), `insertDocument`, `deleteById`.
- [x] **Mapper** — `document_mapper.dart` (`ProductDocumentRow` ↔ entity,
      `toInsertCompanion`, safe `DocumentSource` parsing).
- [x] **File storage** — `document_file_storage.dart`: staging folder,
      `persist(productId) → relative path`, `absolutePath`,
      `deleteFile`, `deleteProductDirectory`, sanitized unique names,
      cross-filesystem move fallback.
- [x] **Importer** — `document_importer.dart`: scan / photo / file selection,
      validation (empty file, 25 MB limit, supported types PDF/JPG/JPEG/PNG/
      HEIC/WEBP), plugin error mapping, staging, `discard`.
- [x] **Opener** — `document_opener.dart`: `OpenFilex` + `OpenResult` mapping
      to controlled failures.
- [x] **Repository implementation** — `document_repository_impl.dart`:
      metadata in SQLite, files outside; file deleted when metadata insert
      fails; delete removes metadata + file; staged file must exist.
- [x] **DI** — `DocumentDao`, `DocumentFileStorage`, `DocumentRepository`,
      `DocumentImporter`, `DocumentOpener` registered in
      `lib/app/di/injection.dart`.

## 4) Presentation

- [x] **Product form — documents section**  
      `widgets/product_documents_section.dart`,
      `widgets/warranty_document_tile.dart`. Scan / upload / photo actions,
      importing state, empty state, staged ("Pending save") vs persisted
      documents, open and remove with confirmation dialog.
- [x] **Form state/cubit** — `ProductFormState.documents`,
      `removedDocuments`, `isImporting`, `documentError`. Staged files are
      persisted on save; removed persisted documents are deleted only on save
      (so cancelling keeps them); staged files are discarded on close.
- [x] **Product detail — documents section**  
      `widgets/product_documents_list.dart`: loading, empty, load-error +
      retry, open-error inline message, open action.
- [x] **Detail state/cubit** — `ProductDetailCubit` loads documents after the
      product (documents error does not hide the product) and opens documents.
- [x] **Localization** — `products.detail.documents.*`,
      `products.form.documents.*` (actions, pending, remove dialog, errors) in
      `en.json` and `es.json`; failure → key mapping in
      `presentation/utils/document_error_keys.dart`.
- [x] **Design** — compact tile with file/PDF icon, name, open action; error
      colors and spacing from the design tokens.
- [x] **Delete a document from the detail screen** — the document list now
      shows a delete action per tile with a confirmation dialog; the
      `ProductDetailCubit.deleteDocument` removes metadata + file through
      `DocumentRepository.delete` and drops the row from the state. The
      confirmation dialog was extracted to
      `widgets/confirm_document_removal.dart` and is shared with the form, so
      both screens use the same behavior.
- [ ] **(Deferred)** **Richer metadata** (size, type, date) in the tile —
      DESIGN says items "may contain" them; not required by the completion
      criteria.

## 5) Integration

- [x] **Metadata cascade** — deleting a product removes its document rows
      (FK + `PRAGMA foreign_keys`), covered by `app_database_test`.
- [x] **Staging lifecycle** — files staged while editing are discarded when
      the form is closed without saving.
- [x] **Stored file cleanup on product deletion** — fixed in this step:
      `ProductRepositoryImpl.delete` now removes the product row first (FK
      cascade drops the metadata) and then calls
      `DocumentRepository.deleteStoredFilesForProduct`. If the file cleanup
      fails, the error is logged and the deletion still completes, so the user
      never sees a failed delete for a product that was already removed. This
      keeps the invariant in the data layer, so every current or future caller
      of `ProductRepository.delete` cleans up files without duplicating logic
      in the cubits. Covered by
      `test/features/products/data/repositories/product_repository_impl_test.dart`.
- [ ] **(Deferred, optional)** **Orphaned staging files** — staged files can
      remain if the process is killed mid-edit; optional startup cleanup (not
      required for the phase).

## 6) Testing

- [x] DAO tests (`document_dao_test.dart`)
- [x] Mapper tests (`document_mapper_test.dart`)
- [x] Repository tests (`document_repository_impl_test.dart`)
- [x] File storage tests (`document_file_storage_test.dart`)
- [x] Importer tests (`document_importer_test.dart`)
- [x] Opener tests (`document_opener_test.dart`)
- [x] Product form cubit document tests (staging, remove, save, errors)
- [x] Product detail cubit document tests (load, open errors)
- [x] Widget test `product_documents_section_test.dart`
- [x] DB tests: documents table creation, product-delete cascade,
      v2 → v3 migration preserves products
- [x] Integration test covering documents (attach → detail → delete):
      `integration_test/document_flow_test.dart` stages a real PDF through the
      form, saves it, verifies the persisted document on the detail screen and
      deletes it, asserting that both the metadata and the stored file are
      gone.
- [x] Regression test for stored-file cleanup on product deletion
      (`product_repository_impl_test.dart`).

## 7) Quality & Verification

- [x] `dart format .`
- [x] `flutter analyze` — 0 issues (verified at end of Phase 1)
- [x] `flutter test` — 160 unit/widget tests pass
- [x] `flutter test integration_test` on the iOS simulator — passes: product
      flow plus documents flow (attach → detail → delete)
- [x] Device smoke test for scan / camera / file picker — accepted without
      exhaustive verification, to be revisited if issues are reported. The
      scanner was verified on a physical Android device: it works, but ML Kit's
      default `full` mode leaves the PDF visibly bright. Left as-is after
      review; switching to `AndroidScannerMode.base` is the one-line change if
      it is revisited. Camera and file picker were not checked individually.
- [x] Verify upgrade from an existing v2 database: on the iOS simulator with a
      real installed app, a v2 database was seeded at
      `Documents/warranty_tracker.sqlite` and the current build opened it,
      resulting in `user_version = 3`, the product preserved, and the
      `product_documents` table created. It exercises the same
      `drift_flutter` + `path_provider` path a physical install uses.
- [x] Update plan/README statuses and any affected source-of-truth docs

---

## Decisions & Deviations

- **Separate `features/documents` feature** for domain/data/services, while
  document UI lives in the product presentation layer. Documents have no
  standalone screen yet, so a separate presentation layer would be empty; the
  entity/repository are still reusable later (e.g. a global document list).
- **Files are copied into a staging folder while editing** and moved into
  `<app documents>/warranty_documents/<productId>/` only on save. This keeps
  cancelled edits from leaving files behind and avoids writing to the product
  folder before the product has an id.
- **Only the relative path is persisted**; the absolute path is resolved at
  runtime (iOS app container paths change between installs/updates).
- **Persisted document deletion is deferred until save** inside the form, so
  cancelling an edit never destroys data. Staged (unsaved) files are discarded
  immediately. From the detail screen, deletion is immediate (with a
  confirmation dialog) because there is no edit session to defer to.
- **Deletion order is metadata first, then file (best-effort).** SQLite and the
  filesystem cannot be atomic, so a cleanup failure is logged and does not fail
  the operation: leaving an invisible orphan file is preferable to showing an
  entry whose file no longer exists. The same rule applies to product deletion.
- **Import validation happens before staging** (non-empty, ≤ 25 MB, supported
  type). The 25 MB limit and type list are documented in `DATA_MODEL.md` §3.2.
- **Metadata insert is rolled back on failure** by deleting the already-moved
  file, so a failed insert cannot leave an unreferenced file.
- **The scanner produces a PDF** (`CunningDocumentScanner.getPictures(asPdf:
  true)`), matching the "PDF support" roadmap improvement and keeping one file
  per scan.
- **No in-app preview**: documents open in the system viewer via `open_filex`.
  Previews are a roadmap "possible future improvement".
- **`DocumentImporter`, `DocumentFileStorage` and `DocumentOpener` expose
  injectable callbacks** (`scanner`, `camera`, `fileSelector`, `openFile`,
  `baseDirectory`) so tests do not need plugin mocks or `mockito` (AGENTS.md
  §18).
- **Known gap resolved:** product deletion now also removes stored document
  files (see §5). The cleanup lives in `ProductRepositoryImpl.delete`
  (cross-feature dependency on the `DocumentRepository` contract) rather than
  in each cubit, so the invariant cannot be forgotten by a new caller.
  `DATA_MODEL.md` §3.2 now describes the actual behavior.
- **Integration tests reuse the injectable seams instead of mocking plugins:**
  `document_flow_test.dart` re-registers `DocumentFileStorage` with a temporary
  `baseDirectory` and `DocumentImporter` with a fixed `fileSelector`, so the
  real validation, staging and persistence code runs without driving the
  native picker. Its helpers live in `integration_test/helpers.dart` and are
  shared with `product_flow_test.dart`.
- **No plan existed while the feature was implemented** (the work landed in
  commits `3b45d10`, `16791ab`, `91141b9`, `044aa1c`, `b51291e`). This plan
  reconstructs it from the code, the roadmap and the data model.

---

## Remaining Work

1. ~~Fix stored-file cleanup on product deletion~~ — done (see §5).
2. ~~Decide detail-screen document deletion~~ — done: immediate deletion with
   confirmation (see §4).
3. ~~Add integration coverage for documents~~ — done:
   `integration_test/document_flow_test.dart` covers attach → detail → delete
   and verifies metadata + file cleanup.
4. ~~Verify camera and file picker on a physical device~~ — accepted without
   exhaustive verification; revisit if issues appear. The scanner was verified
   on Android (works; bright PDF with ML Kit's default `full` mode, left as-is).
5. ~~Update statuses/docs~~ — done: Phase 2 is `done` in
   `docs/plans/README.md` and `ROADMAP.md` §18 now points to Phase 3.
6. Deferred backlog (not required for phase completion): richer tile metadata
   and startup cleanup of orphaned staging files.
