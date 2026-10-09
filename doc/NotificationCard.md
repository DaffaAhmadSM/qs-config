# NotificationCard

## 1. Component Overview

`NotificationCard` renders one notification as a card: a left thumbnail (the
notification image or the app icon) beside a stacked column of app name,
summary, body, inline reply and action buttons, with a close button. It is
shared by the sidebar and the transient toasts, which is why several aspects
(app name, close button, reply, collapsed behaviour) are switchable.

A developer reaches for `NotificationCard` when changing how a single
notification looks; the list containers decide which parts are shown.

## 2. Project Structure and Dependencies

- Instantiated by `NotificationSidebar.qml` (list rows and collapsed piles) and
  `NotificationToasts.qml` (toast delegates).
- Imports `QtQuick` and `QtQuick.Controls.Basic` (the card customises a
  `TextField` background, so it selects the Basic style explicitly).
- Reads the `IslandConfig` singleton for metrics and colours.
- No build system; loaded directly by Quickshell.

## 3. Component Hierarchy and Role

Root is `Rectangle` (the card surface, with hover/press styling). It adds: a
`HoverHandler` and a body `MouseArea`, a `Row` containing the thumbnail and a
content `Column` (app-name row with close button, summary, body, reply
`TextField`, action `Flow`), and the action-data split.

## 4. Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `uiScale` | real | — | Yes | Screen scale applied to all metrics. |
| `notification` | var | — | Yes | The notification object to render. |
| `allowReply` | bool | `true` | No | Whether the inline reply field may be shown (toasts keep it off so they never steal keyboard focus). |
| `showAppName` | bool | `true` | No | Whether the app name is shown (grouped cards hide it; the header carries it). |
| `showClose` | bool | `true` | No | Whether the per-card close button is shown (hidden on collapsed piles). |
| `collapsed` | bool | `false` | No | Collapsed pile cards expand their group instead of firing the default action on click. |
| `pad` | real | derived | No (readonly) | Scaled card padding. |
| `gap` | real | derived | No (readonly) | Scaled child spacing. |
| `thumbSize` | real | derived | No (readonly) | Scaled thumbnail size. |
| `thumbSource` | string | derived | No (readonly) | Thumbnail source: the notification image, else the app icon, else empty. |
| `actionData` | var | derived | No (readonly) | `{ list, defaultAction }` split of the notification's actions. |
| `actionList` | var | derived | No (readonly) | Non-default actions, rendered as buttons. |
| `defaultAction` | var | derived | No (readonly) | The action whose identifier is `"default"`, fired by clicking the body. |

## 5. Signals

#### closed()
Emitted when the close button is clicked, after the notification is dismissed.
Let the container remove the row/toast.

#### expandRequested()
Emitted when a collapsed pile card is clicked, asking its group to expand.

## 6. Methods

None.

## 7. Inter-Component Interactions

- Created by `NotificationSidebar` (with `showAppName`/`showClose`/`collapsed`
  tuned per row and pile state) and by `NotificationToasts` (with `allowReply:
  false` and `notification: Notifications.objectFor(key)`).
- Calls `notification.dismiss()`, `notification.sendInlineReply(text)` and
  `action.invoke()` directly on the notification object.
- Reads `IslandConfig` card/typography/thickness/colour tokens (including
  `notifCardSurface`, `notifCardBorder`, `notifCardHoverSurface`,
  `notifCardHoverBorder`, `spacing*`, `hoverDuration`).

## 8. Usage Example

```qml
NotificationCard {
  width: list.width
  uiScale: root.uiScale
  notification: Notifications.objectFor(key)
  onClosed: Notifications.dropKey(key)
}
```
