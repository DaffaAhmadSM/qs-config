# Time

## 1. Component Overview

`Time` is a small singleton that exposes the current time and a short date
string, both derived from a Quickshell `SystemClock`. It is the shared clock
source for the shell: the collapsed island and the expanded clock view both read
it, so the time string is formatted once and stays consistent.

Reach for `Time` whenever a component needs the current time or date; do not
create another `SystemClock`.

## 2. Project Structure and Dependencies

- Declared with `pragma Singleton`; accessed by name (`Time.time`,
  `Time.date`).
- Imports `Quickshell` (for `SystemClock`) and `QtQuick` (for
  `Qt.formatDateTime`).
- Read by `CollapsedBar.qml` (collapsed clock face) and `ClockView.qml`
  (expanded clock view).
- No build system: Quickshell loads the files directly, so no registration is
  required.

## 3. Component Hierarchy and Role

Root type is `Singleton`. It contains one child, a `SystemClock` with
`precision: SystemClock.Minutes`, whose `date` property drives both readonly
strings. The clock updates once per minute.

## 4. Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `time` | string | derived | No (readonly) | Current time formatted as `hh:mm` (24-hour). |
| `date` | string | derived | No (readonly) | Current date formatted as `ddd d MMM` (e.g. `Mon 9 Oct`). |

Both values are recomputed automatically when the internal `SystemClock` ticks.

## 5. Signals

None.

## 6. Methods

None.

## 7. Inter-Component Interactions

- `CollapsedBar` binds its clock/workspace face text to `Time.time`.
- `ClockView` binds its large time and date labels to `Time.time` and
  `Time.date`.
- No component writes to `Time`; it is read-only from the outside.

## 8. Usage Example

Omitted: singleton, not instantiated by callers.
