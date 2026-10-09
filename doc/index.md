# Dynamic Island — Component Reference

Reference documentation for the Quickshell dynamic-island configuration. Each
entry links to the component's reference page. Base pixel values live in
`IslandConfig` and are multiplied by each screen's `uiScale` (height / 1080).

## Entry and windows

| Component | Description |
|-----------|-------------|
| [shell](shell.md) | Application entry point; declares the per-screen top exclusion strip, island and workspace panel. |
| [Island](Island.md) | The dynamic island window: collapsed/expanded state machine, overlays, view registry. |
| [Workspaces](Workspaces.md) | Top-left workspace-switcher notch, one per monitor. |

## Singletons

| Component | Description |
|-----------|-------------|
| [IslandConfig](IslandConfig.md) | Central configuration: sizes, spacing, colours, motion tokens and power actions. |
| [Time](Time.md) | Current time and date strings from a `SystemClock`. |
| [Notifications](Notifications.md) | Notification daemon, sidebar/toast models, grouping, dismissal and do-not-disturb. |

## Collapsed island

| Component | Description |
|-----------|-------------|
| [CollapsedBar](CollapsedBar.md) | Collapsed bar: clock/workspace face beside the hover chip strip. |
| [BubbleChip](BubbleChip.md) | One clickable chip of the collapsed bar. |

## Expanded island

| Component | Description |
|-----------|-------------|
| [ExpandedIsland](ExpandedIsland.md) | Expanded island: title, active view, side navigation. |
| [ClockView](ClockView.md) | Expanded view: time and date. |
| [MediaView](MediaView.md) | Expanded view: MPRIS media controls. |

## Popups and notifications

| Component | Description |
|-----------|-------------|
| [TrayPopup](TrayPopup.md) | System tray item popup opened from the tray chip. |
| [PowerPopup](PowerPopup.md) | Session/power action popup opened from the power chip. |
| [NotificationCard](NotificationCard.md) | One notification rendered as a card; shared by sidebar and toasts. |
| [NotificationSidebar](NotificationSidebar.md) | Full-height grouped notification panel with collapsing piles. |
| [NotificationToasts](NotificationToasts.md) | Transient top-right toast stack. |
