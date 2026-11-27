# Phase 4 — OCR & Assisted Data Entry

**Status:** not started

**Source:** `ROADMAP.md` §9, `DATA_MODEL.md`, `DESIGN.md`, `ARCHITECTURE.md`, `AGENTS.md`

**Objective:** Reduce manual data entry by extracting product/warranty information from receipt or document photos/scans (OCR), while keeping the user fully in control to review and edit before saving.

**Completion criteria (from ROADMAP §9):**

- [ ] OCR meaningfully reduces manual data entry while keeping the user in control of the final information.

---

## Prerequisites

- [ ] Phase 3 marked done in plans (done)
- [ ] Confirm scope for first iteration (what sources: photo from camera/gallery, PDF pages/images already attached? Or only new capture flow?)
- [ ] Decide OCR approach (on-device vs cloud) and document tradeoffs (privacy, cost, offline behavior). **Must be approved before adding dependencies/services.**
- [ ] Confirm target platforms for OCR in this phase (Android/iOS; desktop/web out of scope unless stated)

---

## 1) Scope Decisions (proposed — approve before implementation)

1. **Entry points (first iteration):** from **Add/Edit Product** form allow “Scan receipt/document” that captures an image (camera) or picks an image (gallery). Optional: run OCR on an already attached image document later (defer if heavy).
2. **Supported inputs (first iteration):** common image types used for receipts/photos (`jpg`, `png`, `heic` where platform supports). PDF OCR is optional/future unless required.
3. **Extracted fields (initial target):** `name`, `brand`, `model`, `store`, `purchaseDate`, `price`, `currency`, `serialNumber` (same as ROADMAP). Mapping to existing `Product` fields only; no new required DB fields.
4. **UX flow (mandatory):** after OCR → show a **review screen/step** listing detected fields with confidence/flags where available → user edits any field → user taps Save (existing form save). **Never auto-save from OCR.**
5. **Offline behavior:** if OCR is cloud-based, the feature must degrade gracefully (show message, allow manual entry). If on-device, prefer offline-first. Decision required in §2.
6. **Privacy:** do not send documents to third parties without explicit user action and clear disclosure; avoid logging extracted sensitive text in production logs.
7. **Non-goals (initial iteration):** full document layout understanding, multi-page invoice parsing beyond best effort, warranty end date auto-calculation from OCR unless rules are obvious (prefer manual/warranty duration UI).

---

## 2) OCR Approach (decision required)

Choose one primary approach for v1 and record rationale:

- **Option A — On-device (e.g. ML Kit / platform text recognition):** better privacy/offline, may vary by language/quality.
- **Option B — Cloud OCR API:** often better quality, costs money, requires network and privacy review.
- **Option C — Hybrid:** try on-device first, optional cloud fallback (more complexity).

**Tasks:**
- [ ] Compare options against: accuracy on receipts, languages (en/es if relevant), offline, cost, maintenance, package/licensing.
- [ ] Pick approach and list approved dependencies (AGENTS.md §18: no silent deps). Get approval before adding packages.
- [ ] Define data flow: image bytes/file → OCR service → normalized draft model → form prefill.

---

## 3) Domain / Application Layer

- [ ] Define a small use case/service contract (e.g. `ExtractProductDraftFromImage`) returning a **draft** (nullable/optional fields), not a persisted entity.
- [ ] Define parsing/normalization utilities (pure Dart where possible):
  - [ ] Date parsing candidates → map to app date rules (timezone/calendar safe, align with `DATA_RULES.md` / existing patterns).
  - [ ] Price/currency parsing → align with `Product`/form validation rules.
  - [ ] Text cleanup (whitespace, common OCR artifacts) without over-aggressive changes.
- [ ] Unit tests for parsers/normalizers (dates, prices, currency hints) and for “no fields extracted” cases.

---

## 4) Data / Infrastructure Layer

- [ ] Implement OCR adapter behind the contract from §3 (on-device or cloud).
- [ ] Handle errors explicitly: no text found, low quality, network failure (if cloud), unsupported image.
- [ ] Ensure temporary image handling is safe (use existing temp/cache patterns if any; avoid leaking files unnecessarily).
- [ ] If cloud: document API keys/config strategy (no secrets in repo; env/config approach approved).

---

## 5) Presentation Layer (UI/UX)

- [ ] Add “Scan / OCR” entry point(s) in Product create/edit flow (buttons/icons consistent with `DESIGN.md`).
- [ ] Show loading state during OCR.
- [ ] **Review step/screen:** list detected fields, allow user to accept/edit each; indicate optional “not detected” state clearly.
- [ ] Prefill `ProductFormCubit` / form state from reviewed draft (do not bypass existing validation).
- [ ] Localize all user-facing strings (`easy_localization`).
- [ ] Error states: user-friendly messages (no raw exception text). Offer retry or “continue manually”.

---

## 6) Integration with Existing Flows

- [ ] Integrate with `ProductFormCubit` / existing form validation (purchase date, warranty fields remain under user control).
- [ ] Decide whether OCR can also suggest documents to attach (optional). If yes, keep it explicit and user-approved.
- [ ] Ensure no regression to manual product create/edit (Phase 1) and document attach flows (Phase 2).

---

## 7) Testing

- [ ] Unit tests: draft extraction mapping, date/price parsers, edge cases (empty input, garbled text).
- [ ] Widget tests: review UI states (loading, empty detection, partial detection, validation errors).
- [ ] Integration test (optional, best effort): only if a deterministic fake OCR service is injected; avoid requiring real camera/OCR in CI unless designed for it.
- [ ] Manual QA checklist (devices): camera permission, gallery pick, poor lighting sample, non-receipt image, localization (en/es if supported).

---

## 8) Quality & Verification

- [ ] `dart format .`
- [ ] `flutter analyze` (0 issues)
- [ ] `flutter test` (relevant suites)
- [ ] Verify privacy: no sensitive extracted data logged; network calls documented if cloud.

---

## 9) Documentation

- [ ] Update `DATA_MODEL.md` only if new persisted fields are introduced (likely not). Otherwise note “OCR is transient draft only.”
- [ ] Update `ARCHITECTURE.md` with new feature module pieces (`features/ocr/` or equivalent) and data flow.
- [ ] Update `DESIGN.md` if new UI patterns (scan button, review cards) are added.
- [ ] Update `ROADMAP.md` Phase 4 status when implementation progresses/completes.
- [ ] Update `docs/plans/README.md` when starting/finishing Phase 4.

---

## 10) Implementation Steps (one approval per step, AGENTS.md §28)

1. **Decisions + docs stub** — confirm §1–§2 choices, approved deps, then scaffold plan checkboxes updates only if needed.
2. **Domain + parsers** — draft model, use case contract, normalization + unit tests.
3. **Infrastructure (OCR adapter)** — implement chosen provider behind contract + error handling.
4. **Presentation** — scan entry points, review UI, prefill form, localization, widget tests.
5. **Integration + manual QA** — wire end-to-end, run verification commands, update docs.

---

## Decisions & Open Questions

- OCR engine (on-device vs cloud vs hybrid): _TBD_
- Languages supported in v1: _TBD_ (e.g. English only vs en/es)
- Whether to OCR already-attached documents in this phase: _TBD (proposed defer)_
- Any cost/budget constraints for cloud APIs: _TBD_
