# ClockView

## 1. Component Overview

`ClockView` is an expanded island view: the current time with the date beneath
it. It is one of the entries in `Island`'s `views` registry (the `"CLOCK"`
view).

A developer reaches for `ClockView` when adding or rearranging expanded views;
it is a self-contained view that only needs the screen scale.

## 2. Project Structure and Dependencies

- Wrapped by a `Component` in `Island.qml` (`clockView`) and rendered by
  `ExpandedIsland`'s loader.
- Imports `QtQuick`.
- Reads the `Time` and `IslandConfig` singletons.
- No build system; loaded directly by Quickshell.

## 3. Component Hierarchy and Role

Root is `Column`. It adds two horizontally centred `Text` labels — the time and
the date — spaced by `IslandConfig.spacingXxs`.

## 4. Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `uiScale` | real | — | Yes | Screen scale applied to the font sizes. |

Typography: the time uses `IslandConfig.clockExpandedSize`, the date uses
`IslandConfig.dateSize`.

## 5. Signals

None.

## 6. Methods

None.

## 7. Inter-Component Interactions

- Instantiated by `Island`'s `clockView` component with `uiScale`.
- Binds its labels to `Time.time` and `Time.date`.
- Reads `IslandConfig.foreground`, `clockExpandedSize`, `dateSize`,
  `spacingXxs`.
- Exposes a natural `implicitHeight` (via its `Column` root) that
  `ExpandedIsland` reports back to `Island`.

## 8. Usage Example

```qml
ClockView { uiScale: root.uiScale }
```
