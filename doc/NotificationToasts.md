# NotificationToasts

## 1. Component Overview

`NotificationToasts` is the transient stack of new notifications in the
top-right corner. It is backed by the `Notifications.toasts` `ListModel`, so
adding or removing one toast animates only that toast. Each toast auto-expires
after a fixed duration, unless it never expires or the pointer is resting on it.
It lives inside the island's overlay.

A developer reaches for this component to change toast behaviour (stacking,
expiry, hover pause) or presentation.

## 2. Project Structure and Dependencies

- Instantiated by `Island.qml` inside the island overlay, and its `area` is
  added to the island's collapsed input `mask`.
- Imports `QtQuick`.
- Uses the `Notifications` singleton and the `NotificationCard` type.
- No build system; loaded directly by Quickshell.

## 3. Component Hierarchy and Role

Root is `Item`, whose opacity follows `hidden`. It adds a `ListView` anchored to
the top-right, bound to `Notifications.toasts`, with add/remove/displaced
transitions, and whose delegate is a `NotificationCard` wrapped with an expiry
`Timer` and a `HoverHandler`.

## 4. Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `uiScale` | real | — | Yes | Screen scale applied to all metrics. |
| `hidden` | bool | `false` | No | Fades the whole stack out (used while the sidebar covers the toast corner). |
| `widthPx` | real | derived | No (readonly) | Scaled toast width (`notifToastWidth`). |
| `area` | `Item` | derived | No (readonly alias) | The clickable extent of the toast stack (aliases the `ListView`), used by the island's input mask. |

## 5. Signals

None declared.

## 6. Methods

None.

## 7. Inter-Component Interactions

- `Island` sets `uiScale` and `hidden` (`notificationsOpen`) and uses `area`
  in its `mask`.
- The `ListView.model` is `Notifications.toasts`; each delegate carries a `key`
  role and sets `notification: Notifications.objectFor(key)`.
- A toast's `onClosed` calls `Notifications.dropKey(key)`; an expiry `Timer`
  (interval `notifToastDuration`) also calls it, and is stopped while hovered
  and restarted on unhover.
- Toast transitions (`add`/`remove`/`displaced`) use `IslandConfig.motionDuration`
  with `easeOut`.
- Reads `IslandConfig.notifToast*`, `notifToastWidth` and motion tokens.

## 8. Usage Example

```qml
NotificationToasts {
  id: notifToasts
  anchors.fill: parent
  uiScale: root.uiScale
  hidden: root.notificationsOpen
}
```
