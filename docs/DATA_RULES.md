# Warranty Tracker — Date Relationship Rules

## 1. Purpose

This document defines the rules governing the relationship between product purchase dates and warranty dates.

These rules apply to:

* Product creation.
* Product editing.
* Domain validation.
* Warranty status calculation.
* Date-related business logic.

The data model is defined in:

`docs/DATA_MODEL.md`

Field requirements are defined in:

`docs/FIELD_REQUIREMENTS.md`

---

# 2. Product Dates

The current product model contains three relevant dates:

* `purchaseDate`
* `warrantyStartDate`
* `warrantyEndDate`

They represent different concepts and must not be treated as interchangeable.

---

# 3. Purchase Date

`purchaseDate` represents the calendar date on which the product was purchased.

Rules:

* It is required.
* It represents a calendar date.
* Time of day is not relevant.
* It must not be automatically changed when warranty dates change.
* It does not define whether the warranty is active, future, or expired.

The purchase date is informational.

---

# 4. Warranty Start Date

`warrantyStartDate` represents the first calendar date on which the warranty is considered active.

Rules:

* It is required.
* It represents a calendar date.
* It must be on or before `warrantyEndDate`.
* It may be before, equal to, or after `purchaseDate`.

The application must not assume that the warranty always starts on the purchase date.

Example:

```text
purchaseDate      = 2026-01-10
warrantyStartDate = 2026-01-15
```

This is valid.

---

# 5. Warranty End Date

`warrantyEndDate` represents the last calendar date on which the warranty is covered.

Rules:

* It is required.
* It represents a calendar date.
* It must be on or after `warrantyStartDate`.
* It is inclusive.

Invalid:

```text
warrantyStartDate = 2026-01-10
warrantyEndDate   = 2026-01-09
```

Valid:

```text
warrantyStartDate = 2026-01-10
warrantyEndDate   = 2026-01-10
```

A warranty whose start and end dates are equal is valid.

---

# 6. Relationship Between Purchase and Warranty Dates

The **only mandatory relationship between these three dates** is:

```text
warrantyStartDate <= warrantyEndDate
```

There is intentionally no required relationship between `purchaseDate` and the warranty range.

Therefore, all of the following are valid:

### Normal case

```text
purchaseDate      = 2026-01-10
warrantyStartDate = 2026-01-10
warrantyEndDate   = 2028-01-10
```

### Warranty starts after purchase

```text
purchaseDate      = 2026-01-10
warrantyStartDate = 2026-01-15
warrantyEndDate   = 2027-01-15
```

### Warranty starts before purchase

```text
purchaseDate      = 2026-01-10
warrantyStartDate = 2026-01-01
warrantyEndDate   = 2027-01-01
```

### Warranty ends before purchase

```text
purchaseDate      = 2026-01-10
warrantyStartDate = 2025-01-01
warrantyEndDate   = 2025-12-31
```

The last case is unusual, but it is **not invalid according to the current product rules**.

The application must not reject it unless a future product decision explicitly introduces such a restriction.

---

# 7. Normal Date Order

The most common scenario will normally look like:

```text
purchaseDate
      ↓
warrantyStartDate
      ↓
warrantyEndDate
```

For example:

```text
purchaseDate      = 2026-01-10
warrantyStartDate = 2026-01-10
warrantyEndDate   = 2028-01-10
```

However, this is a **typical scenario, not a validation rule**.

The implementation must not assume that the dates always follow this order.

---

# 8. Warranty Status

Warranty status is derived from:

* `warrantyStartDate`
* `warrantyEndDate`
* The current calendar date.

It must not be persisted.

The supported statuses are:

* `future`
* `active`
* `expired`

The `purchaseDate` does not participate in the warranty status calculation.

---

# 9. Status Rules

Use calendar-date comparison rather than time-of-day comparison.

## Future

A warranty is `future` when:

```text
today < warrantyStartDate
```

Example:

```text
today             = 2026-01-10
warrantyStartDate = 2026-01-15
warrantyEndDate   = 2027-01-15

status = future
```

---

## Active

A warranty is `active` when:

```text
warrantyStartDate <= today <= warrantyEndDate
```

Example:

```text
today             = 2026-06-10
warrantyStartDate = 2026-01-15
warrantyEndDate   = 2027-01-15

status = active
```

The start and end dates are inclusive.

Therefore:

```text
today == warrantyStartDate
```

is `active`.

And:

```text
today == warrantyEndDate
```

is also `active`.

---

## Expired

A warranty is `expired` when:

```text
today > warrantyEndDate
```

Example:

```text
today             = 2028-01-16
warrantyStartDate = 2026-01-15
warrantyEndDate   = 2028-01-15

status = expired
```

---

# 10. Status Decision Order

Warranty status should conceptually follow:

```text
if today < warrantyStartDate
    → future

else if today <= warrantyEndDate
    → active

else
    → expired
```

This logic belongs in the domain/business layer.

The UI must not independently calculate warranty status.

---

# 11. Calendar Date Semantics

For warranty and purchase calculations, dates represent calendar days.

The implementation should avoid accidental differences caused by:

* Time zones.
* Local time.
* UTC conversion.
* Time-of-day values.
* Daylight saving changes.

A product purchased on a given calendar date should remain associated with that calendar date regardless of the time at which the record is viewed.

---

# 12. Date Input

The product form should allow users to enter:

* Purchase date.
* Warranty start date.
* Warranty end date.

Date pickers should be preferred over free-form date text where appropriate.

The UI should clearly distinguish the three dates.

---

# 13. Validation

The minimum required validation is:

```text
purchaseDate != null
warrantyStartDate != null
warrantyEndDate != null

warrantyStartDate <= warrantyEndDate
```

There is intentionally **no validation rule** requiring:

```text
purchaseDate <= warrantyStartDate
```

or:

```text
purchaseDate <= warrantyEndDate
```

These relationships may be unusual in some cases, but they are not invalid under the current business rules.

If `warrantyStartDate > warrantyEndDate`, the product must not be saved.

The application should provide a clear validation message to the user.

---

# 14. Editing Dates

When a product is edited:

* Changing `purchaseDate` must not automatically change warranty dates.
* Changing `warrantyStartDate` must not automatically change `purchaseDate`.
* Changing `warrantyEndDate` must not automatically change `purchaseDate`.
* Changing warranty dates must cause the derived warranty status to update.

The application must not silently modify one date because another date changed.

---

# 15. Warranty Duration

Warranty duration is derived from:

```text
warrantyStartDate
warrantyEndDate
```

It must not be stored separately.

Changing either warranty date changes the derived duration automatically.

`purchaseDate` does not determine warranty duration.

---

# 16. Invalid Date Relationships

The following relationship is invalid:

```text
warrantyStartDate > warrantyEndDate
```

The following relationships are valid under the current rules:

```text
purchaseDate > warrantyStartDate
purchaseDate > warrantyEndDate
warrantyStartDate > purchaseDate
```

They may be unusual, but the application must not reject them without an explicit product requirement.

The only invalid ordering rule between the three dates is:

```text
warrantyStartDate > warrantyEndDate
```

---

# 17. Source of Truth

The source of truth for the purchase date is:

```text
purchaseDate
```

The source of truth for warranty status is:

```text
warrantyStartDate
warrantyEndDate
current calendar date
```

The purchase date is **not** part of the warranty status calculation.

No derived warranty status or duration should be persisted as independent data.

---

# 18. Testing Requirements

Date-related business logic should have tests covering at least:

### Normal purchase and warranty dates

```text
purchaseDate = 2026-01-10
start        = 2026-01-10
end          = 2028-01-10

→ valid
```

### Warranty starts after purchase

```text
purchaseDate = 2026-01-10
start        = 2026-01-15
end          = 2027-01-15

→ valid
```

### Warranty starts before purchase

```text
purchaseDate = 2026-01-10
start        = 2026-01-01
end          = 2027-01-01

→ valid
```

### Warranty ends before purchase

```text
purchaseDate = 2026-01-10
start        = 2025-01-01
end          = 2025-12-31

→ valid
```

This is unusual but intentionally allowed by the current rules.

### Future

```text
today < start
```

### Active at start

```text
today == start
```

### Active in the middle

```text
start < today < end
```

### Active at end

```text
today == end
```

### Expired

```text
today > end
```

### Same-day warranty

```text
start == end
```

### Invalid range

```text
start > end
```

This is the only invalid date-order relationship.

---

# 19. Current Date Rule

Warranty status must always be calculated using the current calendar date at the time the status is requested.

The application must not permanently store the calculated status.

This ensures that an `active` warranty automatically becomes `expired` when the relevant date passes without requiring a database update.

---

# 20. Final Rule

The purchase date and warranty dates represent independent concepts.

The only required ordering rule is:

```text
warrantyStartDate <= warrantyEndDate
```

The purchase date may occur:

* Before the warranty starts.
* On the warranty start date.
* During the warranty period.
* After the warranty ends.

These cases are all valid under the current data model.

Warranty status is derived exclusively from the warranty dates and the current calendar date:

```text
today < start
    → future

start <= today <= end
    → active

today > end
    → expired
```

The end date is inclusive.

These rules are the single source of truth for date-related warranty behavior.
