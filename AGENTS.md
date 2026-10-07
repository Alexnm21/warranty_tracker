# AGENTS.md

## 1. Project Overview

**Warranty Tracker** is a Flutter application for managing products, purchase information, warranties, receipts, invoices, and warranty-related documents.

The application should prioritize:

* Simplicity
* Reliability
* Maintainability
* Good UX
* Offline-first behavior
* Clean and consistent UI
* Strong type safety
* Minimal unnecessary dependencies

The project is intended to be maintainable over the long term. Avoid solutions that are unnecessarily complex for the current scope of the application.

---

## 2. Core Principles

Follow these principles when developing the application:

1. Prefer simple solutions over clever solutions.
2. Prefer Flutter/Dart built-in functionality before adding a dependency.
3. Do not introduce abstractions without a concrete reason.
4. Keep business logic independent from Flutter UI whenever possible.
5. Keep features isolated and easy to modify.
6. Avoid duplicated logic.
7. Reuse existing components, utilities, and patterns.
8. Follow the existing architecture instead of introducing alternative patterns.
9. Do not make architectural changes without a clear reason.
10. Do not add functionality that was not requested.
11. Do not modify unrelated code while implementing a feature.
12. Preserve existing behavior unless the requested change requires otherwise.

---

# 3. Technology Stack

The project uses the following technologies:

| Area                 | Technology                       |
| -------------------- | -------------------------------- |
| Framework            | Flutter                          |
| Language             | Dart                             |
| Architecture         | Clean Architecture               |
| Project organization | Feature-first                    |
| State management     | BLoC / Cubit                     |
| Navigation           | go_router                        |
| Dependency injection | get_it                           |
| Local database       | Drift + SQLite                   |
| Localization         | easy_localization                |
| Linting              | flutter_lints                    |
| Testing              | flutter_test + Dart test tooling |
| UI                   | Material 3                       |

Do not replace one of these technologies with another approach unless explicitly requested or there is a strong technical reason.

---

# 4. Architecture

The project follows **Clean Architecture with feature-first organization**.

The application should generally be organized around features rather than technical layers.

Example:

```text
lib/
├── app/
│   ├── router/
│   ├── theme/
│   └── di/
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── extensions/
│   ├── utils/
│   └── widgets/
│
└── features/
    ├── products/
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    │
    ├── warranties/
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    │
    └── settings/
        ├── data/
        ├── domain/
        └── presentation/
```

The exact structure may evolve as the project grows. Follow `ARCHITECTURE.md` for the detailed architecture rules.

---

# 5. Layer Responsibilities

## Domain

The domain layer contains application business logic and should be independent from Flutter and infrastructure whenever practical.

Typical contents:

* Entities
* Repository contracts
* Use cases
* Business rules

The domain layer should not depend on:

* Flutter widgets
* BLoC
* Drift
* go_router
* get_it
* UI-specific code

---

## Data

The data layer is responsible for obtaining and persisting data.

Typical contents:

* Repository implementations
* Data sources
* Database code
* DTOs/models
* Data mappers

Infrastructure-specific details must remain inside the data layer.

---

## Presentation

The presentation layer contains UI and presentation state.

Typical contents:

* Pages/screens
* Widgets
* BLoCs
* Cubits
* UI-specific models when necessary

Presentation code should not directly access the database.

---

# 6. State Management

Use **BLoC/Cubit** for state management.

Rules:

* Prefer `Cubit` for simple stateful features.
* Use `Bloc` when event-driven state management provides a clear benefit.
* Do not mix multiple state-management solutions.
* Do not introduce Provider, Riverpod, GetX, Redux, MobX, etc.
* Keep business logic out of widgets.
* Widgets should react to state rather than contain complex business logic.
* Avoid unnecessary states and events.
* State classes should be immutable whenever practical.

Do not create a BLoC/Cubit for trivial UI state that can naturally remain local to a widget.

---

# 7. Navigation

Use **go_router** for application navigation.

Rules:

* Do not navigate using custom routing systems.
* Keep route definitions centralized.
* Use named routes where appropriate.
* Route configuration must remain independent from individual widgets as much as practical.
* Do not place navigation logic throughout business/domain code.
* Authentication or other future route guards should be implemented through go_router mechanisms rather than ad-hoc checks.

---

# 8. Dependency Injection

Use **get_it** for dependency injection.

Rules:

* Dependencies should be registered in the application dependency-injection configuration.
* Do not instantiate repositories, services, databases, or other long-lived dependencies directly inside widgets.
* Avoid service locator access deep inside domain logic when constructor injection is practical.
* Prefer constructor injection for classes with dependencies.
* Keep dependency registration organized and predictable.

---

# 9. Database

Use **Drift + SQLite** for local persistence.

The database should be treated as an implementation detail of the data layer.

Rules:

* Do not access SQLite directly from presentation code.
* Database tables and queries belong to the data layer.
* Keep database-specific models separate from domain entities.
* Map database records to domain entities.
* Use Drift's generated code rather than manually duplicating database boilerplate.
* Database migrations must be handled explicitly.
* Never silently delete or recreate existing user data to solve a schema change.
* Destructive database changes require explicit consideration and migration handling.

The database should support the application's offline-first nature.

---

# 10. Localization

Use **easy_localization** for user-facing text.

Rules:

* Do not hard-code user-facing strings directly in widgets.
* Add translatable strings to the localization files.
* Translation keys should be descriptive and organized by feature.
* Do not use English text as a fallback directly inside UI code unless explicitly required.
* Technical logs and developer-only messages do not necessarily need localization.

Example:

```dart
Text('warranty.expiring_soon'.tr())
```

instead of:

```dart
Text('Expiring soon')
```

---

# 11. UI and Design

The application uses **Material 3**.

All visual decisions must follow `DESIGN.md`.

Rules:

* `DESIGN.md` is the source of truth for the visual system.
* Reuse existing design tokens and components.
* Do not invent arbitrary colors, spacing, typography, radii, or elevations.
* Prefer existing reusable widgets over creating visually equivalent duplicates.
* Keep UI consistent across features.
* Support appropriate loading, empty, error, and success states.
* Consider accessibility when implementing interactive components.
* Do not sacrifice usability merely to follow a visual design literally.

If `DESIGN.md` conflicts with a specific implementation requirement, identify the conflict before making a significant design deviation.

---

# 12. Reusable Components

Before creating a new reusable component:

1. Search the project for an existing component that could be reused.
2. Check whether the component can be reasonably extended.
3. Only create a new component when it represents a genuinely different responsibility or improves maintainability.

Avoid creating generic components that are only used once unless there is a clear reason.

Avoid "God widgets" that contain too many unrelated responsibilities.

---

# 13. Error Handling

Errors should be handled explicitly.

Rules:

* Do not silently swallow exceptions.
* Do not use empty `catch` blocks.
* Convert infrastructure-specific errors into appropriate application/domain errors when necessary.
* The UI should display meaningful user-facing error states.
* Do not expose technical exception messages directly to users.
* Logging should contain useful debugging information without exposing sensitive data.

---

# 14. Async Code

Use Dart's standard asynchronous mechanisms:

* `Future`
* `Stream`
* `async`
* `await`

Rules:

* Handle loading, success, and error states where appropriate.
* Avoid unnecessary nested asynchronous operations.
* Do not block the UI thread with expensive synchronous operations.
* Database and file operations should be asynchronous where appropriate.

---

# 15. Code Style

Follow standard Dart and Flutter conventions.

Use:

* `camelCase` for variables and methods.
* `PascalCase` for classes, enums, extensions, and widgets.
* `snake_case` for file names.
* `const` constructors and values whenever possible.
* Null safety.
* Small focused methods.
* Small focused classes.

Avoid:

* Unnecessary abbreviations.
* Extremely long methods.
* Extremely large widgets.
* Dead code.
* Commented-out code.
* Magic numbers and strings when a named constant improves clarity.

Comments should explain **why**, not simply describe what the code does.

---

# 16. Linting

Use **flutter_lints** and follow the project's configured analysis rules.

The project should remain free of analyzer errors.

Warnings should be treated seriously and resolved when practical.

Do not disable a lint merely to make the analyzer quiet.

If a lint must be disabled, keep the scope as small as possible and document the reason when it is not obvious.

---

# 17. Testing

Testing should focus on behavior and business logic rather than achieving an arbitrary coverage percentage.

Priorities:

### Unit tests

Use unit tests for:

* Business rules
* Use cases
* Mappers
* Important utility logic
* Warranty status calculations
* Date-related logic

### BLoC/Cubit tests

Test important state transitions and user flows.

### Widget tests

Use widget tests for important reusable components and critical screens.

### Integration tests

Use them only when they provide meaningful value for important end-to-end flows.

Do not create tests solely to increase coverage numbers.

When fixing a bug, consider adding a regression test when practical.

---

# 18. Dependencies

Dependencies should be kept to a minimum.

Before adding a package:

1. Check whether Flutter/Dart already provides the required functionality.
2. Check whether an existing project dependency can solve the problem.
3. Evaluate whether the package is actively maintained.
4. Consider package size and complexity.
5. Consider whether the dependency creates unnecessary architectural coupling.
6. Explain why the dependency is necessary.

Do not add a package merely because it makes a small task slightly easier.

The agent must **not silently add dependencies**.

---

# 19. Security and Privacy

The application may contain personal purchase information and documents.

Rules:

* Do not log sensitive user information.
* Do not expose personal documents unnecessarily.
* Do not hard-code secrets.
* Do not commit API keys, tokens, passwords, or credentials.
* Treat locally stored documents as user data.
* Ask before introducing external services that transmit user data.

---

# 20. Performance

Optimize when there is a real performance problem or a clearly identifiable risk.

Do not prematurely optimize code at the expense of readability.

Pay particular attention to:

* Large lists
* Images
* Document previews
* Database queries
* Unnecessary widget rebuilds
* Expensive operations on the UI isolate

Prefer Flutter's built-in lazy widgets such as `ListView.builder` for large collections.

---

# 21. File and Folder Rules

Keep files focused.

Prefer:

```text
product_card.dart
product_detail_page.dart
product_form.dart
```

over a single large file containing all product-related UI.

Do not create unnecessary folder nesting.

New folders should represent a meaningful architectural or domain boundary.

---

# 22. Feature Development Process

When implementing a new feature:

1. Understand the requested behavior.
2. Check `AGENTS.md`.
3. Check `ARCHITECTURE.md`.
4. Check `DATA_MODEL.md` when data is involved.
5. Check `DESIGN.md` for UI work.
6. Check `ROADMAP.md` to understand the current project scope.
7. Inspect existing code for reusable patterns.
8. Plan the required changes.
9. Implement the smallest complete solution.
10. Run formatting and analysis.
11. Run relevant tests.
12. Review the implementation for unnecessary complexity.
13. Report any architectural decisions or new dependencies.

Do not start by creating files blindly.

---

# 23. Modifying Existing Code

Before modifying existing code:

* Read enough surrounding code to understand its purpose.
* Preserve existing conventions.
* Reuse existing abstractions where appropriate.
* Avoid unrelated refactoring.
* Do not rewrite working code merely because another style is preferred.

If a larger refactor is clearly necessary, explain why before performing it.

---

# 24. Agent Autonomy

The agent is encouraged to make reasonable implementation decisions within the rules defined by this document.

The agent may:

* Choose implementation details.
* Refactor small pieces of code when necessary for the requested feature.
* Suggest improvements.
* Identify potential architectural problems.
* Suggest new reusable components.
* Suggest new tests.
* Suggest improvements to documentation.

The agent should **not**:

* Change the architecture without explaining why.
* Replace core technologies without approval.
* Add dependencies silently.
* Change the visual system without considering `DESIGN.md`.
* Implement unrequested features.
* Delete user data.
* Make destructive database changes without explicit consideration.

---

# 25. Improving AGENTS.md

`AGENTS.md` is a living document.

The agent should actively identify recurring patterns, repeated mistakes, ambiguities, or useful project-wide rules that could improve future development.

The agent should **suggest a new rule** when:

* The same mistake happens repeatedly.
* The same implementation decision has to be explained repeatedly.
* A project convention emerges across multiple features.
* A recurring architectural problem is identified.
* A new technology introduces an important project-wide convention.
* A rule would prevent future inconsistencies.
* A useful development workflow becomes established.

However:

> **The agent must not modify `AGENTS.md` automatically.**

When a potentially useful rule is identified, the agent should report it clearly, for example:

```text
AGENTS.md suggestion

Reason:
This pattern has appeared in several features.

Suggested rule:
"All date calculations related to warranty expiration should use
the shared WarrantyDateUtils instead of implementing date arithmetic
inside individual BLoCs."

Would you like me to add this rule to AGENTS.md?
```

Only add the rule after explicit approval.

Avoid adding rules for isolated or insignificant situations.

The goal is to keep `AGENTS.md` concise, useful, and based on actual project experience.

---

# 26. Documentation Consistency

The following documents are part of the project's source of truth:

* `AGENTS.md` — development rules and agent behavior.
* `ARCHITECTURE.md` — architectural decisions and project structure.
* `DATA_MODEL.md` — data entities and business data rules.
* `DESIGN.md` — visual design system and UI rules.
* `ROADMAP.md` — planned functionality and development phases.

If a change affects one of these documents, the agent should identify it.

Do not silently allow the documentation to become inconsistent with the implementation.

---

# 27. Definition of Done

A task is considered complete when:

* The requested functionality works.
* The implementation follows the project architecture.
* Existing functionality has not been unnecessarily affected.
* User-facing text uses localization.
* UI follows `DESIGN.md`.
* No unnecessary dependency was introduced.
* Code is formatted.
* There are no relevant analyzer errors.
* Relevant tests pass.
* Important new business logic has appropriate tests.
* Documentation is updated when the change affects project-wide rules or decisions.

Do not consider a task complete merely because the code compiles.

---

# 28. Final Rule

When in doubt:

> Prefer the simplest maintainable solution that fits the existing architecture and design system.

If an important decision cannot be made confidently from the existing project rules, **stop and ask rather than silently introducing a new convention**.
