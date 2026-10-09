# NotificationSidebar

## 1. Component Overview

`NotificationSidebar` is the full-height panel that slides in from the right
edge showing tracked notifications grouped by app. It is backed by
`Notifications.display`, a stable `ListModel`, so rows animate in/out instead of
the whole view rebuilding. Groups collapse into a card pile; expanding fans the
members downward.

A developer reaches for this component to change how the notification list is
presented, grouped, or animated.

## 2. Project Structure and Dependencies

- Instantiated by `Island.qml` inside the island overlay, driven by
  `notificationsOpen`.
- Imports `QtQuick`.
- Uses the `Notifications` singleton (model and commands) and the
  `IslandConfig` and `NotificationCard` types.
- No build system; loaded directly by Quickshell.

## 3. Component Hierarchy and Role

Root is `Item`. Inside it a `Rectangle` (`panel`) slides in from the right; a
`Loader` (active while open or the close timer runs) builds an inline
`sidebarBody` component. The body contains a header `Column` (title + "Clear
all") and a `ListView` over `Notifications.display`. Each delegate is an `Item`
that renders either a group header row or a card row (with a collapsed pile of
back cards).

## 4. Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `uiScale` | real | — | Yes | Screen scale applied to all metrics. |
| `open` | bool | — | Yes | Whether the sidebar is shown. |
| `widthPx` | real | derived | No (readonly) | Scaled sidebar width (`notifSidebarWidth`). |
| `pad` | real | derived | No (readonly) | Scaled padding (`notifSidebarPadding`). |
| `gap` | real | derived | No (readonly) | Scaled gap (`notifCardSpacing`). |
| `ready` | bool | `false` | No | Suppresses the slide animation on the first real geometry pass. Set via `onWidthChanged`. |

### ListView delegate roles

Every delegate receives these required roles from `Notifications.display`:

| Role | Type | Meaning |
|------|------|---------|
| `key` | int | Key into `Notifications.objectFor`. |
| `appName` | string | Owning app name. |
| `appIcon` | string | Group icon source. |
| `header` | bool | True for a group header row. |
| `isStart` | bool | True for the first card of a group. |
| `groupSize` | int | Number of cards in the group. |
| `groupIndex` | int | Position within the group. |
| `index` | int | Row index in the view. |

Derived per-row values: `notification` (`objectFor(key)`, null for headers),
`multi` (`groupSize > 1`), `expanded` (`Notifications.isExpanded(appName)`),
`tucked` (a non-start member of a collapsed group) and `topGap` (explicit gap
replacing `ListView.spacing`).

## 5. Signals

#### closed()
Emitted when the sidebar asks to be closed. `Island` clears `notificationsOpen`.

## 6. Methods

None declared. Row behaviour lives in signals on `Notifications`
(`toggleGroup`, `dismissGroup`, `clearAll`).

## 7. Inter-Component Interactions

- `Island` supplies `uiScale` and `open` and handles `closed`.
- The `ListView.model` is `Notifications.display`; the panel calls
  `Notifications.clearAll()`, and each header row calls
  `Notifications.toggleGroup(appName)` / `Notifications.dismissGroup(appName)`.
- The empty-state `Text` is shown when `Notifications.count === 0`.
- The collapsed pile: a group's first card renders back "shell" `Rectangle`s
  (up to `notifPileMax`) and a `NotificationCard` whose `collapsed` flag makes a
  body click call `Notifications.toggleGroup` instead of firing the default
  action. Expanding animates each member's height/opacity with a stagger of
  `notifAnimStagger`; collapsing is instant.
- Row insert/remove/displaced transitions use `IslandConfig.motionDuration`
  with `easeOut`; the panel slide uses `easeDrawer`.
- Reads `IslandConfig` notification typography, pile, card and motion tokens.

## 8. Usage Example

```qml
NotificationSidebar {
  anchors.fill: parent
  uiScale: root.uiScale
  open: root.notificationsOpen
  onClosed: root.notificationsOpen = false
}
```
