---
name: Warranty Tracker
colors:
  surface: '#f9f9ff'
  surface-dim: '#d3daef'
  surface-bright: '#f9f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f1f3ff'
  surface-container: '#e9edff'
  surface-container-high: '#e1e8fd'
  surface-container-highest: '#dce2f7'
  on-surface: '#141b2b'
  on-surface-variant: '#434655'
  inverse-surface: '#293040'
  inverse-on-surface: '#edf0ff'
  outline: '#747686'
  outline-variant: '#c4c5d7'
  surface-tint: '#1d4ed8'
  primary: '#1d4ed8'
  on-primary: '#ffffff'
  primary-container: '#dbeafe'
  on-primary-container: '#001551'
  inverse-primary: '#b7c4ff'
  secondary: '#006c4a'
  on-secondary: '#ffffff'
  secondary-container: '#82f5c1'
  on-secondary-container: '#00714e'
  tertiary: '#6b3700'
  on-tertiary: '#ffffff'
  tertiary-container: '#8d4b00'
  on-tertiary-container: '#ffcba3'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dce1ff'
  primary-fixed-dim: '#b7c4ff'
  on-primary-fixed: '#001551'
  on-primary-fixed-variant: '#0039b5'
  secondary-fixed: '#85f8c4'
  secondary-fixed-dim: '#68dba9'
  on-secondary-fixed: '#002114'
  on-secondary-fixed-variant: '#005137'
  tertiary-fixed: '#ffdcc3'
  tertiary-fixed-dim: '#ffb77d'
  on-tertiary-fixed: '#2f1500'
  on-tertiary-fixed-variant: '#6e3900'
  background: '#f9f9ff'
  on-background: '#141b2b'
  surface-variant: '#dce2f7'
typography:
  display:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
  headline:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  title:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 26px
  body:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-small:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  caption:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  label-small:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
  numeric:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: '600'
    lineHeight: 20px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  screen: 16px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
---

# Warranty Tracker Design System

## Purpose

Warranty Tracker is a clean, modern mobile application for managing products, purchase information, warranty coverage and related documents.

The interface should prioritize:

* **Clarity:** Users should immediately understand which products they own and the current state of their warranties.
* **Trust:** Warranty information should feel reliable and organized.
* **Simplicity:** Adding and checking a product should require minimal effort.
* **Visual calm:** Use whitespace, restrained colors and clear hierarchy instead of excessive decoration.
* **Useful information density:** Show important warranty information without making screens feel crowded.

The visual language is inspired by modern productivity and utility applications rather than financial dashboards.

---

# Brand & Visual Style

Warranty Tracker uses a modern, minimal and friendly utility aesthetic.

The interface should feel:

* Clean
* Reliable
* Organized
* Lightweight
* Modern
* Practical

Avoid:

* Excessive gradients
* Heavy shadows
* Excessive borders
* Large decorative illustrations
* Excessive use of accent colors
* Financial-dashboard aesthetics
* Visually dense layouts

The primary visual hierarchy should come from typography, spacing, surface elevation and status colors.

---

# Colors

## Primary

**Primary:** `#1D4ED8`

Used for:

* Primary actions
* Active navigation items
* Selected controls
* Important interactive elements
* Links
* Focused inputs
* FAB

Primary actions should be visually prominent but should not dominate the entire screen.

**Primary container:** `#DBEAFE`

Used for:

* Selected backgrounds
* Subtle primary highlights
* Informational elements associated with the primary action

---

## Warranty Status Colors

Warranty status must never rely only on color. Each status should also use an icon and explicit text.

### Active

* Background: `#ECFDF5`
* Text: `#047857`
* Icon: check-circle / shield-check
* Status: **Active**

Represents a currently valid warranty.

### Expiring Soon

* Background: `#FFFBEB`
* Text: `#B45309`
* Icon: clock / alert-triangle
* Status: **Expiring soon**

Used when a warranty is approaching its expiration date.

### Expired

* Background: `#FEF2F2`
* Text: `#B91C1C`
* Icon: calendar-x / x-circle
* Status: **Expired**

Used when warranty coverage has ended.

---

# Backgrounds & Surfaces

The application uses a very light neutral background:

**App background:** `#F9F9FF`

Cards and primary content surfaces use:

**Surface:** `#FFFFFF`

Secondary structural areas may use:

**Secondary surface:** `#F1F3FF`

Do not use large areas of saturated color as backgrounds.

---

# Text

### Primary text

`#141B2B`

Used for:

* Screen titles
* Product names
* Important values
* Primary information

### Secondary text

`#434655`

Used for:

* Dates
* Stores
* Categories
* Supporting information
* Metadata

### Tertiary text

`#747686`

Used for:

* Hints
* Disabled content
* Very low-priority metadata

Text hierarchy should primarily be created through size and weight rather than introducing many different colors.

---

# Typography

Use **Inter** throughout the application.

Typography should be clean and highly legible.

### Display

32px / 700

Used sparingly for large page-level information.

### Headline

24px / 600

Used for major screen titles and important sections.

### Title

18px / 600

Used for:

* Product names
* Card titles
* Section titles

### Body

16px / 400

Used for primary descriptive content.

### Body Small

14px / 400

Used for:

* Secondary information
* Dates
* Store names
* Supporting descriptions

### Caption

12px / 400

Used for low-priority metadata.

### Label

14px / 600

Used for:

* Buttons
* Interactive controls
* Status labels

### Label Small

12px / 600

Used for:

* Status pills
* Compact controls
* Small metadata labels

### Numeric

15px / 600

Used for:

* Remaining warranty time
* Prices
* Important dates
* Numeric values

Numerical information should remain visually stable and easy to scan.

---

# Spacing

The default screen horizontal margin is:

**16px**

Use the spacing scale consistently:

* `4px` — very small internal spacing
* `8px` — compact spacing
* `16px` — standard component spacing
* `24px` — section spacing
* `32px` — large section separation

Avoid arbitrary spacing values unless required by a specific component.

---

# Shapes & Border Radius

Warranty Tracker uses moderately rounded components.

### Cards

`16px`

### Buttons

`12px`

### Input fields

`12px`

### Small controls

`8px`

### Status pills

`9999px`

### FAB

Circular or fully rounded.

### Bottom sheets

`20px` top corners.

The overall design should feel rounded and approachable without becoming overly playful.

---

# Cards

Cards are one of the main visual components of Warranty Tracker.

### Card appearance

* Background: `#FFFFFF`
* Border: `1px solid #C4C5D7`
* Radius: `16px`
* Internal padding: `16px`

Use subtle elevation only when it improves hierarchy.

Cards should not have heavy shadows.

### Product / Warranty Card

A typical product card can contain:

**Top area**

* Product image or icon
* Product name
* Warranty status

**Main information**

* Warranty remaining time
* Warranty expiration date

**Secondary information**

* Purchase date
* Store
* Price
* Category

The most important information should remain visually dominant.

---

# Warranty Status Pills

Status pills communicate warranty state.

Every status pill must use:

1. A tinted background
2. A status icon
3. Explicit text
4. Appropriate text color

### Active

Green tint + check icon + "Active"

### Expiring Soon

Amber tint + clock/alert icon + "Expiring soon"

### Expired

Red tint + expired/calendar icon + "Expired"

Do not communicate warranty status using color alone.

---

# Buttons

## Primary Button

* Background: `#1D4ED8`
* Text: `#FFFFFF`
* Radius: `12px`
* Minimum height: `48px`
* Font: Inter 14px / 600

Used for the main action on a screen.

Examples:

* Add product
* Save product
* Continue
* Confirm

## Secondary Button

* Background: `#FFFFFF`
* Border: `1px solid #C4C5D7`
* Text: `#141B2B`
* Radius: `12px`
* Minimum height: `48px`

Used for secondary actions.

## Destructive Button

Use the error color only for destructive operations.

Examples:

* Delete product
* Remove document

Destructive actions should generally require confirmation.

---

# Floating Action Button

The FAB is used for the primary creation action when appropriate.

Typical use:

**Add product**

Properties:

* Diameter: `56px`
* Primary color: `#1D4ED8`
* White icon
* Fully rounded
* Subtle elevation
* Positioned with approximately `16px` horizontal inset

The FAB should not appear on screens where a prominent primary button already provides the same action.

---

# Input Fields

Input fields should be simple and highly readable.

### Default

* Background: `#FFFFFF`
* Border: `1px solid #C4C5D7`
* Radius: `12px`
* Horizontal padding: `16px`
* Minimum height: approximately `48px`

### Focused

* Border: `#1D4ED8`
* Use a subtle primary focus ring if necessary.

### Error

* Border: `#BA1A1A`
* Error message below the field
* Do not rely exclusively on the red border

Inputs may use contextual leading icons where they improve recognition.

Examples:

* Search
* Calendar
* Price
* Store

---

# Search

Search should feel lightweight and integrated into the interface.

Use:

* Search icon
* Clear input affordance when text exists
* Rounded input container
* Neutral background
* Primary focus state

Search results should prioritize product name and relevant warranty information.

---

# Filters

Filters should use compact controls such as:

* Segmented controls
* Chips
* Dropdowns
* Bottom sheets

Active filters should use the primary color or a subtle primary container.

Avoid visually heavy filter controls.

---

# Bottom Navigation

The application uses a simple bottom navigation structure.

Navigation should provide clear access to the main areas of the application.

Active navigation items use:

* Primary color `#1D4ED8`
* Stronger icon weight
* Clear active label

Inactive items use neutral gray.

The navigation bar should remain visually lightweight and should not compete with the page content.

---

# Empty States

Empty states should be friendly and informative.

They should contain:

1. A simple icon or illustration
2. A short title
3. A concise explanation
4. One clear primary action when appropriate

Example:

**No products yet**

"Add your first product to start tracking its warranty."

**Add product**

Avoid large decorative illustrations that consume excessive screen space.

---

# Loading States

Use subtle skeleton loading where content loading takes noticeable time.

Skeletons should:

* Match the shape of the real content
* Use neutral gray surfaces
* Avoid excessive animation
* Avoid bright colors

Do not show skeleton loaders when loading is effectively instantaneous.

---

# Dialogs & Bottom Sheets

Use dialogs for:

* Confirmation
* Destructive actions
* Short focused interactions

Use bottom sheets for:

* Filters
* Selection lists
* Secondary actions
* Multi-option controls

Bottom sheets should have:

* White background
* `20px` top corner radius
* Centered drag handle where appropriate
* Adequate horizontal padding
* Keyboard-aware behavior for text inputs

A dark translucent backdrop may be used behind modal content.

---

# Icons

Use a consistent outline icon style.

Preferred style:

* Lucide
* Material Symbols Outlined
* Similar modern outline icon sets

Icons should generally use neutral text colors unless they represent:

* Primary action
* Warranty status
* Destructive action

Do not mix multiple unrelated icon styles.

---

# Product Images

Product images should have a clean presentation.

When an actual product image exists:

* Display it prominently
* Preserve aspect ratio
* Use a neutral surface behind it
* Avoid aggressive cropping

When no image exists:

* Use a simple product/category icon
* Use a neutral background

Product images should support recognition without dominating the interface.

---

# Documents & Warranty Evidence

Warranty Tracker may store supporting documents such as:

* Receipts
* Invoices
* Warranty documents
* Photos of paper warranties
* Other purchase evidence

Documents should be presented as compact, recognizable list items.

Each document item may contain:

* File/photo icon or thumbnail
* Document name
* Document type
* Date when relevant
* Open/view action

The interface should make it obvious that documents belong to the selected product.

---

# Product Detail

The product detail screen should prioritize the warranty itself.

Recommended hierarchy:

1. Product identity
2. Warranty status
3. Warranty expiration / remaining time
4. Purchase information
5. Store information
6. Documents
7. Additional product information
8. Actions

The warranty status should be immediately understandable without requiring the user to read the entire screen.

---

# Add Product Flow

Adding a product should be a simple, guided process.

The flow should prioritize the minimum information required to create a useful warranty record.

Possible information:

* Product name
* Brand
* Category
* Store
* Purchase date
* Price
* Warranty duration / expiration date
* Product identifier
* Documents or receipt
* Product image

Do not overwhelm the user with all optional fields at once.

Optional information should remain secondary.

---

# Interactions

Interactions should feel predictable and responsive.

### Tap

Interactive components should provide clear visual feedback.

### Swipe

Use swipe actions only when they provide a clear benefit, such as deleting or archiving a product.

### Long press

Avoid requiring long press for important functionality.

### Navigation

Moving between screens should preserve the user's context whenever possible.

### Destructive actions

Deleting a product or important document should require confirmation.

---

# Accessibility

Accessibility is part of the design system.

* Do not rely exclusively on color.
* Statuses must include text and icons.
* Maintain sufficient contrast.
* Interactive elements should have comfortable touch targets.
* Text should remain readable at larger accessibility sizes.
* Icons that perform actions should have accessible labels.
* Important information should not be communicated only through visual position or color.

---

# Responsive Behaviour

The primary target is mobile.

The design should scale naturally to larger screens without introducing unnecessary complexity.

For larger screens:

* Increase available content width where appropriate.
* Keep comfortable margins.
* Avoid excessively wide cards.
* Preserve the same visual hierarchy.
* Use multi-column layouts only when they clearly improve usability.

Do not redesign the application into a desktop dashboard simply because additional horizontal space is available.

---

# Design Principles

When making a new screen or component, follow these principles in order:

1. **Clarity over decoration**
2. **Consistency over novelty**
3. **Useful information over visual density**
4. **Whitespace over unnecessary borders**
5. **Status should be immediately understandable**
6. **Primary actions should be obvious**
7. **Keep the interface visually calm**
8. **Reuse existing components whenever possible**

New components should visually belong to the existing Warranty Tracker design system.

---

# Source of Truth

This document is the visual source of truth for Warranty Tracker.

When implementing or modifying a screen:

* Follow these colors.
* Follow these typography rules.
* Follow these spacing values.
* Follow these corner radii.
* Reuse established component styles.
* Preserve the existing visual hierarchy.
* Do not introduce a new visual style without a clear reason.

When an existing approved screen conflicts with a generic rule in this document, prioritize the **established visual language of the approved Warranty Tracker screens** and update this document accordingly.

The goal is not to make every screen identical. The goal is to make every screen feel like the same application.