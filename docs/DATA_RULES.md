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

The current product model contains two relevant dates:

* `purchaseDate`
* `warrantyEndDate`

The purchase date is also the first calendar date on which the warranty is
covered, so no separate warranty start date exists.

---

# 3. Purchase Date

`purchaseDate` represents the calendar date on which the product was purchased.

Rules:

* It is required.
* It represents a calendar date.
* Time of day is not relevant.
* It is the first day of the warranty coverage.
* It must not be automatically changed when the warranty end date changes.

Example:

```text
purchaseDate    = 2026-01-10
warrantyEndDate = 2028-01-10
```

This means the warranty is covered from `2026-01-10` through `2028-01-10`.

---

# 4. Warranty Start Date

There is no separate warranty start date.

The warranty starts on the `purchaseDate`:

```text
warrantyStartDate = purchaseDate
```

The application must not add an extra field for it and must not assume that
the warranty starts on a different date than the purchase.

---

# 5. Warranty End Date

`warrantyEndDate` represents the last calendar date on which the warranty is covered.

Rules:

* It is required.
* It represents a calendar date.
* It must be on or after `purchaseDate`.
* It is inclusive.

Invalid:

```text
purchaseDate    = 2026-01-10
warrantyEndDate = 2026-01-09
```

Valid:

```text
purchaseDate    = 2026-01-10
warrantyEndDate = 2026-01-10
```

A warranty whose purchase and end dates are equal is valid.

---

# 6. Relationship Between Purchase and Warranty Dates

The **only mandatory relationship between these two dates** is:

```text
purchaseDate <= warrantyEndDate
```

A warranty that ends before the product was purchased is invalid and the
product must not be saved.

---

# 7. Normal Date Order

The most common scenario will normally look like:

```text
purchaseDate
      ↓
warrantyEndDate
```

For example:

```text
purchaseDate    = 2026-01-10
warrantyEndDate = 2028-01-10
```

However, this is a **typical scenario, not a validation rule**.

The implementation must not assume that the warranty always lasts a fixed
number of years.

---

# 8. Warranty Status

Warranty status is derived from:

* `purchaseDate`
* `warrantyEndDate`
* The current calendar date.

It must not be persisted.

The supported statuses are:

* `future`
* `active`
* `expired`

---

# 9. Status Rules

Use calendar-date comparison rather than time-of-day comparison.

## Future

A warranty is `future` when:

```text
today < purchaseDate
```

Example:

```text
today           = 2026-01-10
purchaseDate    = 2026-01-15
warrantyEndDate = 2027-01-15

status = future
```

---

## Active

A warranty is `active` when:

```text
purchaseDate <= today <= warrantyEndDate
```

Example:

```text
today           = 2026-06-10
purchaseDate    = 2026-01-15
warrantyEndDate = 2027-01-15

status = active
```

The purchase and end dates are inclusive.

Therefore:

```text
today == purchaseDate
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
today           = 2028-01-16
purchaseDate    = 2026-01-15
warrantyEndDate = 2028-01-15

status = expired
```

---

# 10. Status Decision Order

Warranty status should conceptually follow:

```text
if today < purchaseDate
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
* Warranty end date.

Date pickers should be preferred over free-form date text where appropriate.

The UI should clearly distinguish the two dates.

---

# 13. Validation

The minimum required validation is:

```text
purchaseDate != null
warrantyEndDate != null

purchaseDate <= warrantyEndDate
```

If `warrantyEndDate < purchaseDate`, the product must not be saved.

The application should provide a clear validation message to the user.

---

# 14. Editing Dates

When a product is edited:

* Changing `purchaseDate` must not automatically change the warranty end date.
* Changing `warrantyEndDate` must not automatically change `purchaseDate`.
* Changing warranty dates must cause the derived warranty status to update.

The application must not silently modify one date because another date changed.

---

# 15. Warranty Duration

Warranty duration is derived from:

```text
purchaseDate
warrantyEndDate
```

It must not be stored separately.

Changing either date changes the derived duration automatically.

---

# 16. Invalid Date Relationships

The following relationship is invalid:

```text
purchaseDate > warrantyEndDate
```

It is the only invalid date-order relationship.

---

# 17. Source of Truth

The source of truth for the purchase date is:

```text
purchaseDate
```

The source of truth for warranty status is:

```text
purchaseDate
warrantyEndDate
current calendar date
```

No derived warranty status or duration should be persisted as independent data.

---

# 18. Testing Requirements

Date-related business logic should have tests covering at least:

### Normal purchase and warranty dates

```text
purchaseDate    = 2026-01-10
end             = 2028-01-10

→ valid
```

### Same-day warranty

```text
purchaseDate    = 2026-01-10
end             = 2026-01-10

→ valid
```

### Future

```text
today < purchaseDate
```

### Active at purchase

```text
today == purchaseDate
```

### Active in the middle

```text
purchaseDate < today < end
```

### Active at end

```text
today == end
```

### Expired

```text
today > end
```

### Invalid range

```text
purchaseDate > end
```

This is the only invalid date-order relationship.

---

# 19. Current Date Rule

Warranty status must always be calculated using the current calendar date at the time the status is requested.

The application must not permanently store the calculated status.

This ensures that an `active` warranty automatically becomes `expired` when the relevant date passes without requiring a database update.

---

# 20. Final Rule

The purchase date is the start of the warranty coverage.

The only required ordering rule is:

```text
purchaseDate <= warrantyEndDate
```

Warranty status is derived exclusively from the purchase date, the warranty end date and the current calendar date:

```text
today < purchaseDate
    → future

purchaseDate <= today <= warrantyEndDate
    → active

today > warrantyEndDate
    → expired
```

The end date is inclusive.

These rules are the single source of truth for date-related warranty behavior.
