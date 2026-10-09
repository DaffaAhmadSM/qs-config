# Island

## 1. Component Overview

`Island` is the dynamic island itself: one `PanelWindow` per monitor, shown only
on the compositor's focused monitor. It is the orchestrator of the shell's main
surface — it decides whether the collapsed bar or the expanded island is shown,
owns the overlay flags (expanded, tray, power, notifications), and hosts the
tray/power popups, the toast stack and the notification sidebar.

A developer reaching for `Island` is usually adding a new expanded view,
changing how the collapsed/expanded swap works, or wiring a new overlay. The
view registry (`views`) makes adding an expanded view a data-only change.

## 2. Project Structure and Dependencies

- Instantiated by `shell.qml`, once per screen.
- Imports `QtQuick`, `QtQuick.Shapes`, `Quickshell`, `Quickshell.Hyprland` and
  `Quickshell.Services.Mpris`.
- Uses the `IslandConfig`, `Time` and `Notifications` singletons, and the
  custom types `CollapsedBar`, `ExpandedIsland`, `TrayPopup`, `PowerPopup`,
  `NotificationToasts`, `NotificationSidebar`, `ClockView` and `MediaView`.
- No build system; loaded directly by Quickshell.

## 3. Component Hierarchy and Role

Root is `PanelWindow`. It adds: monitor/focus derivation, the
collapsed/expanded state machine, the view registry, hover/split animation
state, the input mask and dismiss catcher, and the popup/overlay hosts.

Inside the window, a `Rectangle` (`pill`) draws the island background (or, in
notch mode, a `Shape` silhouette) and holds a `Loader` that instantiates
**exactly one** content node at a time — `collapsedComponent` (`CollapsedBar`)
or `expandedComponent` (`ExpandedIsland`).

## 4. Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `monitor` | `ShellScreen` | — | Yes | The screen this island belongs to. |
| `uiScale` | real | — | Yes | Screen scale (height / 1080) applied to all metrics. |
| `notch` | bool | `IslandConfig.islandNotch` | No (readonly) | Whether the flush notch silhouette is drawn. |
| `notchTop` | real | derived | No (readonly) | Scaled top fillet radius. |
| `notchBottom` | real | derived | No (readonly) | Scaled bottom corner radius. |
| `hyprMonitor` | `HyprlandMonitor` | derived | No (readonly) | Hyprland monitor for this screen. |
| `focused` | bool | derived | No (readonly) | True on the focused monitor, or on every monitor when no focus info exists. |
| `expanded` | bool | `false` | No | Whether the island is expanded. |
| `trayOpen` | bool | `false` | No | Whether the tray popup is open. |
| `powerOpen` | bool | `false` | No | Whether the power popup is open. |
| `notificationsOpen` | bool | `false` | No | Whether the notification sidebar is open. |
| `showingWorkspace` | bool | `false` | No | Briefly true to swap the collapsed clock for the workspace number. |
| `lastWorkspace` | var | `null` | No | Last seen focused workspace, used to detect changes. |
| `views` | var | `[CLOCK, MEDIA]` | No (readonly) | Registry of expanded views; array order is navigation order. Each entry is `{ name: string, component: Component }`. |
| `activeView` | int | `0` | No | Index into `views` of the active view. |
| `mediaIndex` | int | derived | No (readonly) | Index of the entry named `"MEDIA"`, or `-1`. |
| `activeViewName` | string | derived | No (readonly) | Name of the active view (empty if none). |
| `activeViewComponent` | `Component` | derived | No (readonly) | Component of the active view (null if none). |
| `collapsedW` | real | derived | No (readonly) | Scaled collapsed width. |
| `headerHeight` | real | derived | No (readonly) | Scaled header height. |
| `contentWidth` | real | derived | No (readonly) | Expanded view width, leaving room for the navigation strips. |
| `expandedViewHeight` | real | `0` | No | Height reported by the expanded content while loaded. |
| `expandedContentHeight` | real | derived | No (readonly) | Final expanded height: max of `heightExpanded` and header + spacing + view height + padding. |
| `morphing` | bool | `false` | No | True during the open/close morph; the hover split is deferred until it settles. |
| `chipPopupOpen` | bool | derived | No (readonly) | `trayOpen || powerOpen`. |
| `overlaysOpen` | bool | derived | No (readonly) | `expanded || chipPopupOpen || notificationsOpen`; controls the full-screen dismiss catcher. |
| `hoverWanted` | bool | derived | No (readonly) | Whether the bar should be in its hovered (split) state. |
| `collapsedHovered` | bool | `false` | No | Debounced hover state; the split factor follows it. |
| `split` | real | derived (0/1) | No | Animated hover-split factor: 0 = pill geometry, 1 = split geometry. |
| `hoveredChipLabel` | string | `""` | No | Label of the currently hovered chip, used by the shared tooltip. |
| `hoveredChipCenterX` | real | `0` | No | Center X (in island coordinates) of the hovered chip. |
| `chipAnchorX` | real | `0` | No | Center X of the chip that opened the current popup. |

### Internal components

| Name | Base | Description |
|------|------|-------------|
| `clockView` | `Component` | Wraps `ClockView` with `uiScale`. |
| `mediaView` | `Component` | Wraps `MediaView` with `uiScale` and the active MPRIS player. |
| `collapsedComponent` | `Component` | The collapsed content node (`CollapsedBar`), fed hover/split/notch state and emitting chip events. |
| `expandedComponent` | `Component` | The expanded content node (`ExpandedIsland`), fed the active view and navigation signals. |

## 5. Signals

None declared. The instance is wired to child signals:

- `CollapsedBar.onChipClicked(kind, centerX)` sets the matching overlay flag.
- `CollapsedBar.onChipRightClicked(kind)` toggles do-not-disturb for the
  notification chip.
- `CollapsedBar.onChipHovered/onChipUnhovered` drive the shared tooltip.
- `ExpandedIsland.onViewHeightChanged` updates `expandedViewHeight`;
  `onNext`/`onPrev` call `nextView()`/`prevView()`.

## 6. Methods

#### nextView() : void
Advances `activeView` to the next entry in `views`, wrapping around.

#### prevView() : void
Moves `activeView` to the previous entry in `views`, wrapping around.

## 7. Inter-Component Interactions

- `shell.qml` sets `monitor` and `uiScale`.
- Feeds `CollapsedBar` (`uiScale`, `split`, `collapsedW`, `pillRadius`,
  `notch`, `inset`, `showingWorkspace`, `chipsShown`).
- Feeds `ExpandedIsland` (`uiScale`, `contentWidth`, `headerHeight`,
  `viewName`, `viewComponent`) and receives its `viewHeight`, `next`, `prev`.
- Hosts `TrayPopup` and `PowerPopup`, passing `bar` (the `pill`), `anchorCenterX`
  (`chipAnchorX`), `open` and `uiScale`; both set `anchor.window` to the island.
- Hosts `NotificationToasts` (`hidden` when the sidebar is open) and
  `NotificationSidebar` (`open`, `onClosed`).
- Reads `IslandConfig` metrics and the `Notifications` singleton (chip
  right-click calls `Notifications.toggleDnd()`).
- `onExpandedChanged` resets the other overlays and selects the media view when
  `IslandConfig.mediaAutoPriority` is on and something is playing; a `Timer`
  clears `morphing` after `IslandConfig.animationDuration`.
- `Hyprland` workspace changes drive the brief workspace-number swap.

## 8. Usage Example

Omitted: this is a top-level `PanelWindow`, not an embeddable component.
