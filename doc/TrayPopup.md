# TrayPopup

## 1. Component Overview

`TrayPopup` is a small popup listing the system tray items as a vertical column
of icons. It is opened from the collapsed island's tray chip. Its body (and the
`SystemTray` reference) is only built while the popup is open, so nothing
tray-related exists when the popup is closed.

A developer reaches for `TrayPopup` to change how tray items are presented or
activated; it is instantiated by `Island`, not by general view code.

## 2. Project Structure and Dependencies

- Instantiated by `Island.qml`, which passes `bar`, `anchorCenterX`, `open` and
  `uiScale` and sets its `anchor.window`.
- Imports `QtQuick`, `Quickshell` and `Quickshell.Services.SystemTray`.
- Reads the `IslandConfig` singleton for padding, item size and popup metrics.
- No build system; loaded directly by Quickshell.

## 3. Component Hierarchy and Role

Root is `PopupWindow`. It adds: the anchor rect math (anchored to the bar and
horizontally centred on the chip), a positive implicit size, a `Loader` that
builds the body only while open (and while the close timer runs), and an inline
`trayBody` component containing the item `ListView`.

## 4. Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `bar` | Item | — | Yes | The collapsed bar item the popup is positioned against. |
| `anchorCenterX` | real | — | Yes | X centre of the chip that opened the popup, in bar coordinates. |
| `open` | bool | — | Yes | Whether the popup is shown. |
| `uiScale` | real | — | Yes | Screen scale applied to all metrics. |
| `pad` | real | derived | No (readonly) | Scaled padding (`trayPopupPadding`). |
| `itemPx` | real | derived | No (readonly) | Scaled tray item size (`trayItemSize`). |
| `maxList` | real | derived | No (readonly) | Scaled maximum list height (`trayPopupMaxHeight`). |

The caller also sets `anchor.window` (the `Island` panel) so the popup attaches
to it.

## 5. Signals

#### dismissed()
Emitted when a tray item is activated (a normal left click that is not handled
by a menu), telling the caller to close the popup.

## 6. Methods

None.

## 7. Inter-Component Interactions

- `Island` supplies `bar`, `anchorCenterX`, `open`, `uiScale`, `anchor.window`
  and handles `dismissed` (closing the popup).
- The body's `ListView.model` is `SystemTray.items`; each delegate renders the
  item icon and, on click, either shows the item menu (`display`) or calls
  `activate`/`secondaryActivate` and emits `dismissed`.
- The body is only built while open or the 50 ms close timer runs, so the tray
  binding is not created until needed.
- Reads `IslandConfig.trayPopup*` and `trayItem*` metrics plus `background`.

## 8. Usage Example

```qml
TrayPopup {
  anchor.window: island
  bar: pill
  anchorCenterX: chipCenterX
  open: root.trayOpen
  uiScale: root.uiScale
  onDismissed: root.trayOpen = false
}
```
