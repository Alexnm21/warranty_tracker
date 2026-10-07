# Warranty Tracker — Warranty End-Date Rule

## 1. Purpose

This document defines whether `warrantyEndDate` is included in the warranty coverage period.

This rule applies to:

* Warranty status calculation.
* Warranty expiration.
* Date validation.
* Tests.
* UI presentation.

---

# 2. End Date Is Inclusive

`warrantyEndDate` is an **inclusive** date.

This means the warranty remains active throughout the end date.

The warranty is considered active when:

```text
warrantyStartDate <= today <= warrantyEndDate
```

---

# 3. Status Rules

The warranty status is:

### Future

```text
today < warrantyStartDate
```

### Active

```text
warrantyStartDate <= today <= warrantyEndDate
```

### Expired

```text
today > warrantyEndDate
```

---

# 4. Example

Given:

```text
warrantyStartDate = 2026-01-01
warrantyEndDate   = 2026-12-31
```

The warranty is:

```text
2025-12-31 → future
2026-01-01 → active
2026-06-15 → active
2026-12-31 → active
2027-01-01 → expired
```

Therefore, **December 31, 2026 is the last covered day**.

---

# 5. Calendar-Date Semantics

Warranty dates represent calendar dates, not timestamps.

The application must not interpret `warrantyEndDate` as the beginning of that day.

For example:

```text
warrantyEndDate = 2026-12-31
```

means the entire calendar day of December 31 is covered.

Time-of-day must not cause the warranty to become expired during that date.

---

# 6. No Time-Based Expiration

The application must not use logic equivalent to:

```text
now > warrantyEndDate at 00:00
```

This would incorrectly make the warranty expire at the beginning of the end date.

Instead, compare calendar dates:

```text
today > warrantyEndDate
```

---

# 7. Same-Day Warranty

A warranty where:

```text
warrantyStartDate == warrantyEndDate
```

is valid.

On that date:

```text
status = active
```

Before that date:

```text
status = future
```

After that date:

```text
status = expired
```

Example:

```text
start = 2026-10-07
end   = 2026-10-07
```

Result:

```text
2026-10-06 → future
2026-10-07 → active
2026-10-08 → expired
```

---

# 8. Implementation Rule

The domain warranty-status logic must treat `warrantyEndDate` as inclusive.

The UI must use the same rule.

There must be a single source of truth for this behavior.

The application must not have different interpretations of the end date in different layers.

---

# 9. Testing Requirements

Tests must explicitly cover the boundary:

```text
today == warrantyEndDate
```

Expected result:

```text
active
```

Tests must also cover:

```text
today == warrantyEndDate + 1 day
```

Expected result:

```text
expired
```

---

# 10. Final Rule

The final covered day of a warranty is `warrantyEndDate`.

Therefore:

```text
today <= warrantyEndDate
```

means the warranty has not yet expired.

The warranty becomes expired only on the calendar day after `warrantyEndDate`.
