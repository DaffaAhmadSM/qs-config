# BubbleChip

## 1. Component Overview

`BubbleChip` is one chip of the collapsed bar: a rounded, clickable icon slot
that owns its own hover feedback and click handling, emitting events for the bar
to route. It draws an icon, a system-icon path, or a placeholder when no icon is
set.

A developer reaches for `BubbleChip` to add a new action to the collapsed bar;
the chip itself is action-agnostic — the parent decides what a click means.

## 2. Project Structure and Dependencies

- Instantiated inside `CollapsedBar.qml` as the delegate of its chip `Repeater`.
- Imports `QtQuick` and `QtQuick.Effects` (for `MultiEffect` icon tinting).
- Reads the `IslandConfig` singleton for radius, icon size and colours.
- No build system; loaded directly by Quickshell.

## 3. Component Hierarchy and Role

Root is `Rectangle`. It adds: the hover/click `MouseArea`, the placeholder and
system-icon children, a `MultiEffect` that recolours the icon to the foreground,
and accessibility metadata. Its visibility and interactivity follow `shown`.

## 4. Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `uiScale` | real | — | Yes | Screen scale applied to all metrics. |
| `shown` | bool | `false` | No | Controls opacity and whether the chip accepts input. |
| `notch` | bool | `false` | No | Notch mode: the chip stays clear because the island paints the background. |
| `icon` | string | `""` | No | Icon source. When empty, a placeholder is drawn instead. |
| `label` | string | `""` | No | Human-readable label, emitted with hover signals and used as the accessible name. |

## 5. Signals

#### clicked()
Emitted on a left click. The parent routes it to the chip's action.

#### rightClicked()
Emitted on a right click. The parent routes it to the chip's secondary action
(for the notification chip, toggling do-not-disturb).

#### hovered(string label, real centerX)
Emitted when the pointer enters. `centerX` is the chip centre in bar
coordinates, used to place the shared tooltip.

#### unhovered(string label)
Emitted when the pointer leaves. The parent clears the tooltip when the label
matches.

## 6. Methods

None.

## 7. Inter-Component Interactions

- Created by `CollapsedBar`'s `Repeater`, which sets `uiScale`, `width`,
  `shown`, `notch`, `label`, `icon` and `x`, and re-emits the chip's signals.
- Reads `IslandConfig.bubbleIconSize`, `bubbleRadius`, `foreground`.
- Publishes `Accessible.role: Accessible.Button` and its `label` as the
  accessible name; decorative children are marked ignored.

## 8. Usage Example

```qml
BubbleChip {
  uiScale: root.uiScale
  shown: root.chipsShown
  notch: root.notch
  icon: "assets/bell.svg"
  label: qsTr("Notifications")
  onClicked: root.openNotifications()
}
```
