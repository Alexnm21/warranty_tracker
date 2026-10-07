# Warranty Tracker

An offline-first Flutter application for managing purchased products, their purchase information, and their warranties — so you always know what you bought, when you bought it, how long it is covered, and where the receipt is.

## Features

* Register products with purchase details (date, price, store, brand).
* Track warranty periods and expiration status.
* Keep receipts and warranty documents attached to each product.
* Full CRUD with search and filtering.
* Works completely offline — no account or internet connection required.

## Tech Stack

| Area | Technology |
| ---- | ---------- |
| Framework | Flutter (Material 3) |
| Language | Dart |
| Architecture | Clean Architecture, feature-first |
| State management | BLoC / Cubit |
| Navigation | go_router |
| Dependency injection | get_it |
| Local database | Drift + SQLite |
| Localization | easy_localization |
| Linting | flutter_lints |

## Architecture

```text
Presentation (Pages / BLoC)
         ↓
      Domain (Entities / Repository contracts / Business rules)
         ↓
        Data (Repository implementations / DAOs / Drift)
```

The domain layer never depends on infrastructure. Repositories are consumed through their abstractions, and Drift DAOs stay inside the data layer.

Full details live in the project documentation:

* [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — architectural structure and dependency rules
* [`docs/DATA_MODEL.md`](docs/DATA_MODEL.md) — entities, relationships, and business data
* [`docs/DATA_RULES.md`](docs/DATA_RULES.md) — business data rules
* [`docs/FIELD_REQUIREMENTS.md`](docs/FIELD_REQUIREMENTS.md) — field-level requirements
* [`docs/WARRANTY_END_DATE_RULE.md`](docs/WARRANTY_END_DATE_RULE.md) — warranty end date calculation rule
* [`docs/DESIGN.md`](docs/DESIGN.md) — visual design system
* [`docs/INITIAL_SCOPE.md`](docs/INITIAL_SCOPE.md) — current implementation scope
* [`docs/ROADMAP.md`](docs/ROADMAP.md) — planned functionality and phases
* [`AGENTS.md`](AGENTS.md) — development rules

## Project Structure

```text
lib/
├── app/        # Root widget, theme, routing, dependency injection
├── core/       # Shared constants, errors, utils, database, widgets
└── features/   # Feature modules (data / domain / presentation)
```

## Getting Started

### Prerequisites

* Flutter SDK (^3.x)
* A connected device or emulator

### Setup

```bash
flutter pub get
flutter run
```

### Tests

```bash
flutter test
```

### Analysis

```bash
flutter analyze
```

## Status

In early development. The architecture and initial product scope are defined in [`docs/`](docs/); features are being implemented phase by phase according to the roadmap.

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE).
