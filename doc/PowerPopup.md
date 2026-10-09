# PowerPopup

## 1. Component Overview

`PowerPopup` is a small popup listing session/power actions with bundled icons
and labels. It is opened from the collapsed island's power chip. Its body is
only built while the popup is open, and every action shows an inline
confirmation before running.

A developer reaches for `PowerPopup` to change the session actions; the action
list itself lives in `IslandConfig.powerActions`.

## 2. Project Structure and Dependencies

- Instantiated by `Island.qml`, which passes `bar`, `anchorCenterX`, `open` and
  `uiScale` and sets its `anchor.window`.
- Imports `QtQuick` and `Quickshell` (for `Quickshell.execDetached`).
- Reads the `IslandConfig` singleton for metrics and the `powerActions` model.
- No build system; loaded directly by Quickshell.

## 3. Component Hierarchy and Role

Root is `PopupWindow`. It adds: the anchored position, the confirmation state,
the `Loader`-gated body, and the inline `powerBody` component containing the
action `Column`/`Repeater` and the inline confirmation `Column`.

## 4. Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `bar` | Item | — | Yes | The collapsed bar item the popup is positioned against. |
| `anchorCenterX` | real | — | Yes | X centre of the power chip, in bar coordinates. |
| `open` | bool | — | Yes | Whether the popup is shown. |
| `uiScale` | real | — | Yes | Screen scale applied to all metrics. |
| `confirming` | var | `null` | No | The action awaiting confirmation (`null` shows the list). |
| `pad` | real | derived | No (readonly) | Scaled padding (`trayPopupPadding`). |
| `popupW` | real | derived | No (readonly) | Scaled popup width (`powerPopupWidth`). |
| `rowH` | real | derived | No (readonly) | Scaled row height (`powerRowHeight`). |
| `rowGap` | real | derived | No (readonly) | Scaled row spacing (`powerRowSpacing`). |
| `actions` | var | `IslandConfig.powerActions` | No (readonly) | The action list. Entries: `{ label, icon, cmd, confirm }`. |
| `listH` | real | derived | No (readonly) | Height of the action list state. |
| `confirmH` | real | derived | No (readonly) | Height of the confirmation state. |

The caller also sets `anchor.window` so the popup attaches to the `Island`
panel.

## 5. Signals

#### dismissed()
Emitted after an action runs (or is confirmed) to tell the caller to close the
popup.

## 6. Methods

None.

## 7. Inter-Component Interactions

- `Island` supplies `bar`, `anchorCenterX`, `open`, `uiScale`, `anchor.window`
  and handles `dismissed`.
- The action list is `IslandConfig.powerActions`. Clicking an action either sets
  `confirming` (when the entry's `confirm` is true) or runs
  `Quickshell.execDetached(cmd)` and emits `dismissed`.
- Confirming runs `Quickshell.execDetached(confirming.cmd)` and emits
  `dismissed`; Cancel clears `confirming`.
- The body is only built while open or the 50 ms close timer runs; closing also
  clears `confirming`.
- Reads `IslandConfig.power*`, `trayPopupPadding` and `trayPopupRadius`.

## 8. Usage Example

```qml
PowerPopup {
  anchor.window: island
  bar: pill
  anchorCenterX: chipCenterX
  open: root.powerOpen
  uiScale: root.uiScale
  onDismissed: root.powerOpen = false
}
```
