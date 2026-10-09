# Workspaces

## 1. Component Overview

`Workspaces` draws one workspace-switcher notch per monitor: a wide, shallow
panel that drops from the top-left corner when the pointer reaches it. It lists
workspaces 1–10 in a row; every slot is clickable (empty ones create the
workspace) and the active one carries a sliding accent highlight.

A developer reaches for this component to change how workspaces are presented or
activated. Its main job is to resolve each numbered slot against the actual
Hyprland workspaces on any monitor so a number stays clickable even when it
lives on another monitor or has no windows.

## 2. Project Structure and Dependencies

- Instantiated by `shell.qml`, once per screen.
- Imports `QtQuick`, `QtQuick.Shapes`, `Quickshell` and `Quickshell.Hyprland`.
- Reads the `IslandConfig` singleton for all metrics and uses
  `Hyprland.monitorFor`, `Hyprland.workspaces`, `Hyprland.focusedWorkspace` and
  `Hyprland.dispatch`.
- No build system; loaded directly by Quickshell.

## 3. Component Hierarchy and Role

Root is `PanelWindow`. It adds: per-monitor workspace state, the hover show/hide
state machine with an input `mask`, the notch `Shape`, a sliding active-slot
`indicator`, and a `Repeater` of clickable number cells. The `mask` bounds input
to the hover band while hidden and to the whole panel while shown.

## 4. Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `monitor` | `ShellScreen` | — | Yes | The screen this panel belongs to. |
| `uiScale` | real | — | Yes | Screen scale applied to all metrics. |
| `hyprMonitor` | `HyprlandMonitor` | derived | No (readonly) | Hyprland monitor for this screen. |
| `slots` | var | `[1..10]` | No (readonly) | The workspace numbers listed. |
| `pad` | int | derived | No (readonly) | Scaled vertical padding (`wsPaddingY`). |
| `padX` | int | derived | No (readonly) | Scaled horizontal padding (`wsPaddingX`). |
| `itemW` | int | derived | No (readonly) | Scaled slot size (`wsItemSize`). |
| `gap` | int | derived | No (readonly) | Scaled slot spacing (`wsItemSpacing`). |
| `notchTop` | real | derived | No (readonly) | Scaled top fillet radius. |
| `notchBottom` | real | derived | No (readonly) | Scaled bottom corner radius. |
| `pitch` | real | derived | No (readonly) | Distance between left edges of adjacent slots (`itemW + gap`). |
| `contentWidth` | real | derived | No (readonly) | Width of the number row. |
| `listWidth` | real | derived | No (readonly) | Width including horizontal padding. |
| `listHeight` | real | derived | No (readonly) | Height including vertical padding. |
| `wsById` | var | derived | No (readonly) | Map of workspace id to workspace for every workspace on any monitor. |
| `activeId` | int | derived | No (readonly) | Id of the workspace active on this monitor, or `-1`. |
| `activeIndex` | int | derived | No (readonly) | Slot index of the active workspace, or `-1`. |
| `hovered` | bool | `false` | No | Whether the pointer is over the hover band/panel. |
| `shown` | bool | derived | No (readonly) | `IslandConfig.wsAlwaysShow || hovered`. |

## 5. Signals

None declared.

## 6. Methods

#### activateSlot(n) : void
Switches this monitor to slot `n`. If a workspace with that id exists anywhere it
is activated; otherwise the monitor is focused first (via
`Hyprland.dispatch("focusmonitor " + name)`) and then the workspace is created
with `Hyprland.dispatch("workspace " + n)`. No return value.

## 7. Inter-Component Interactions

- `shell.qml` sets `monitor` and `uiScale`.
- Reads Hyprland state reactively (`Hyprland.workspaces.values`,
  `hyprMonitor.activeWorkspace`), so slots and the indicator update on
  workspace events.
- The hover catch and a `Timer` using `IslandConfig.bubbleHoverLatch` keep the
  panel up briefly after the pointer leaves.
- The sliding indicator uses `IslandConfig.motionDuration`/`easeOut`; the panel
  slide uses `IslandConfig.motionDuration`/`easeOut`.

## 8. Usage Example

Omitted: this is a top-level `PanelWindow`, not an embeddable component.
