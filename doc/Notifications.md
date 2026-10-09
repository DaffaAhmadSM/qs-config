# Notifications

## 1. Component Overview

`Notifications` is the singleton that owns the notification daemon and all
notification display state for the shell. It runs a Quickshell
`NotificationServer`, tracks incoming notifications, and maintains two
`ListModel`s that the UI binds to:

- `display` — the sidebar's model, in display order, one row per notification
  (or per group header), newest first.
- `toasts` — the transient corner popups, one row per toast, newest first.

It also holds do-not-disturb state (persisted across reloads) and provides the
functions the sidebar, toast stack and collapsed chip call to dismiss, group and
clear notifications.

Reach for `Notifications` whenever a component needs the notification list,
wants to dismiss/clear notifications, or needs to read/toggle do-not-disturb.

## 2. Project Structure and Dependencies

- Declared with `pragma Singleton`; accessed by name (`Notifications.display`).
- Imports `QtQuick`, `Quickshell` and
  `Quickshell.Services.Notifications` (for `NotificationServer`).
- Consumed by `NotificationSidebar.qml` (sidebar list and group controls),
  `NotificationToasts.qml` (toast list and expiry), `NotificationCard.qml`
  (reads notification objects), `CollapsedBar.qml` (muted chip state) and
  `Island.qml` (right-click on the chip toggles do-not-disturb).
- Maintains a `PersistentProperties` child so do-not-disturb survives hot
  reloads (`reloadableId: "notifications"`).
- No build system; loaded directly by Quickshell.

## 3. Component Hierarchy and Role

Root type is `Singleton`. It contains two non-visual models (`displayModel`,
`toastModel`), a `NotificationServer`, a `PersistentProperties`, and two
`Timer`s (`pruneTimer`, `staggerTimer`). No QML items are parented to it.

Because `ListModel` cannot hold `QObject`s in Qt 6, the actual `Notification`
objects live in the `objectMap` keyed by an integer, and each model row stores
only that key plus display metadata.

## 4. Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `doNotDisturb` | bool | `false` | No (readonly) | Mirrors the persisted do-not-disturb flag. When true, new notifications still reach the sidebar but no toast is shown. |
| `server` | `NotificationServer` | — | No (readonly) | The notification daemon. Configured to support inline reply, actions and images, and to keep notifications across reloads. |
| `display` | `ListModel` | empty | No (readonly alias) | Sidebar model (`displayModel`). Roles: `header` (bool), `key` (int), `nid` (string), `appName` (string), `appIcon` (string), `isStart` (bool), `groupSize` (int), `groupIndex` (int). |
| `toasts` | `ListModel` | empty | No (readonly alias) | Toast model (`toastModel`). Role: `key` (int), newest first. |
| `count` | int | 0 | No | Number of tracked notifications; kept in sync by `reconcile()`. |
| `objectMap` | var | `{}` | No | Map of `key` to `Notification`. Reassigned (not mutated) so bindings re-evaluate. |
| `nidToKey` | var | `{}` | No | Map of notification id (`appName` + NUL + `id`) to `key`. |
| `nextKey` | int | 1 | No | Monotonic counter used to allocate stable keys. |
| `expandedGroups` | var | `{}` | No | Map of app name to expanded (bool). Reassigned on toggle so bindings re-evaluate. |
| `dismissQueue` | var | `[]` | No | Pending notifications to dismiss one-by-one by the stagger timer. |

### Model role reference (`display`)

| Role | Type | Meaning |
|------|------|---------|
| `header` | bool | True for a group header row. |
| `key` | int | Key into `objectMap`; `-1` for header rows. |
| `nid` | string | Notification id for the row; empty for header rows. |
| `appName` | string | Owning app name (empty string if unnamed). |
| `appIcon` | string | Group icon source. |
| `isStart` | bool | True for the first card of a group. |
| `groupSize` | int | Number of cards in the group. |
| `groupIndex` | int | Position of the card within its group. |

## 5. Signals

None declared.

## 6. Methods

#### toggleDnd() : void
Flips the persisted do-not-disturb flag. Called from the collapsed chip's
right-click.

#### nidOf(notification) : string
Returns the composite id `appName + "\u0000" + id` used internally to identify a
notification across model rows.

#### keyOf(notification) : int
Returns the stable integer key for a notification, allocating a new one from
`nextKey` on first sight, and updating `objectMap` (reassigning it so bindings
on `objectFor()` re-evaluate, including when a key is reused by a replacement
notification while pruning lags).

#### objectFor(key) : var
Returns the `Notification` for `key`, or `null` if absent.

#### rowIndexFor(nid) : int
Linear scan of `display` returning the first row whose `nid` matches, or `-1`.

#### liveList() : var
Returns a plain JS-array copy of the server's tracked notifications (its
`.values` is array-like rather than a JS array).

#### reconcile() : void
Rebuilds `display` incrementally: removes card rows whose notification is gone,
inserts rows for new notifications at the start of their group (newest first),
then calls `refreshGroups()`, updates `count`, and restarts `pruneTimer`.
Marked as O(notifications × display rows); sufficient for a few hundred.

#### prune() : void
Drops `nidToKey`/`objectMap` entries for notifications that are gone and have no
live toast. Runs after exit animations (via `pruneTimer`) so departing cards
keep their content.

#### setRowIf(index, role, value) : void
Sets a model role only when it differs, avoiding needless view churn.

#### refreshGroups() : void
Recomputes card roles and maintains exactly one header row at the start of every
group with two or more notifications, inserting/removing headers as group sizes
cross the threshold.

#### pushToast(notification) : void
Inserts a toast for the notification at the top of `toasts` and trims the stack
to `IslandConfig.notifToastMax`.

#### dropAt(index) : void
Removes the toast at `index`.

#### dropKey(key) : void
Removes the toast with the given key, if present.

#### isExpanded(appName) : bool
Returns whether the named group is expanded.

#### toggleGroup(appName) : void
Flips the expanded state of the named group (reassigning `expandedGroups`).

#### dismissStaggered(items) : void
Appends notifications to `dismissQueue` and starts the stagger timer, so each is
dismissed one at a time and animates out individually.

#### dismissGroup(appName) : void
Dismisses all currently tracked notifications belonging to `appName`.

#### clearAll() : void
Dismisses every tracked notification and empties `toasts`.

## 7. Inter-Component Interactions

- The `NotificationServer.onNotification` handler marks each notification
  tracked and pushes a toast unless it arrived over a reload
  (`lastGeneration`) or do-not-disturb is on.
- A `Connections` block on `server.trackedNotifications.valuesChanged` re-runs
  `reconcile()`.
- `NotificationSidebar` binds its `ListView.model` to `display`, reads `count`,
  and calls `isExpanded`, `toggleGroup`, `dismissGroup`, `clearAll` and
  `objectFor`.
- `NotificationToasts` binds its `ListView.model` to `toasts`, calls
  `objectFor(key)` and `dropKey(key)`.
- `CollapsedBar` reads `doNotDisturb` to pick the chip label/icon.
- `Island` calls `toggleDnd()` on notification-chip right-click.
- `pruneTimer` uses `IslandConfig.animationDuration + 50`; `staggerTimer` uses
  `IslandConfig.notifAnimStagger`.

## 8. Usage Example

Omitted: singleton, not instantiated by callers.
