# IslandConfig

## 1. Component Overview

This project is a Quickshell desktop "dynamic island" for the Hyprland Wayland
compositor: a top-of-screen pill/notch that shows a clock, workspace number,
notification tray, power menu, media controls and a notification sidebar.

`IslandConfig` is the project's single configuration singleton. It holds every
metric, colour and motion token used by the island, its collapsed bar, the
expanded views, the tray/power popups and the notification UI. Components never
hardcode sizes or colours; they read base-pixel values from `IslandConfig` and
multiply by their per-screen `uiScale`. Editing this file is how a developer
re-themes or re-sizes the whole shell.

## 2. Project Structure and Dependencies

- Declared with `pragma Singleton`, so it is accessed directly by name
  (`IslandConfig.widthCollapsed`), not instantiated.
- Imports `QtQuick` and `Quickshell`.
- Read by essentially every other file: `Island.qml`, `CollapsedBar.qml`,
  `BubbleChip.qml`, `ExpandedIsland.qml`, `ClockView.qml`, `MediaView.qml`,
  `Workspaces.qml`, `TrayPopup.qml`, `PowerPopup.qml`, `NotificationCard.qml`,
  `NotificationSidebar.qml`, `NotificationToasts.qml` and `Notifications.qml`.
- `pragma ComponentBehavior: Bound` is set.
- There is no build system (no `qmldir`, no CMake); Quickshell loads the QML
  files directly, so the singleton requires no registration step.

## 3. Component Hierarchy and Role

Root type is `Singleton` (a Quickshell/QML non-visual object). It contributes
only state: scalar tokens and two derived readonly values
(`motionDuration`, `pressDuration`). It holds no items and must never have QML
items parented to it.

Base pixels are defined for a 1080p screen; each component multiplies the value
it uses by `uiScale` (screen height / 1080), which is why values here are small
integers.

## 4. Properties

### Sizes

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `widthCollapsed` | int | 290 | No | Width of the island when collapsed. |
| `widthExpanded` | int | 400 | No | Width of the island when expanded. |
| `heightCollapsed` | int | 32 | No | Height of the collapsed bar. |
| `heightExpanded` | int | 200 | No | Minimum expanded height; the island grows to fit the active view. |
| `radiusCollapsed` | int | 16 | No | Corner radius when collapsed. |
| `radiusExpanded` | int | 26 | No | Corner radius when expanded. |
| `topMargin` | int | 2 | No | Gap above the island in pill (non-notch) mode. |

### Spacing scale

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `spacingXxs` | int | 2 | No | Smallest gap (e.g. clock line spacing). |
| `spacingXs` | int | 4 | No | Extra-small gap (tight margins, icon hit-area insets). |
| `spacingSm` | int | 6 | No | Small gap (row spacing, label margins). |
| `spacingMd` | int | 8 | No | Medium gap (icon offsets, action-button vertical padding). |
| `spacingLg` | int | 10 | No | Large gap (icon-to-label offsets, switch-row spacing). |
| `spacingXl` | int | 16 | No | Extra-large gap (action-button horizontal padding). |

### Notch background

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `islandNotch` | bool | true | No | Draws the flush "bathtub" notch silhouette instead of a floating pill. |
| `islandNotchTopRadius` | int | 22 | No | Concave fillet where the notch pinches off the top edge. |
| `islandNotchBottomRadius` | int | 18 | No | Convex rounding of the notch's bottom corners. |
| `expandedPaddingY` | int | 14 | No | Vertical inner padding of the expanded view. |

### Type

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `clockCollapsedSize` | int | 14 | No | Font size of the clock/workspace text in the collapsed bar. |
| `clockExpandedSize` | int | 30 | No | Font size of the clock in the expanded view. |
| `dateSize` | int | 12 | No | Font size of the date line. |
| `headerHeight` | int | 16 | No | Height reserved for a view's title header. |
| `headerSize` | int | 12 | No | Font size of the view title. |
| `arrowSize` | int | 22 | No | Base glyph size of the side navigation arrows. |

### Collapsed hover and chips

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `trayBubbleSide` | string | `"right"` | No | Side the tray chip sits on. Values: `"left"`, `"right"`. |
| `trayChipIcon` | string | `"assets/tray.svg"` | No | Icon path for the tray chip. |
| `notifBubbleSide` | string | `"right"` | No | Side the notification chip sits on. Values: `"left"`, `"right"`. |
| `notifChipIcon` | string | `"assets/bell.svg"` | No | Icon shown on the notification chip. |
| `notifChipIconMuted` | string | `"assets/bell-off.svg"` | No | Icon shown when do-not-disturb is on. |
| `hoverPillFraction` | real | 0.6 | No | Share of the collapsed width the clock keeps on hover; chips split the rest. |
| `bubbleIconSize` | int | 18 | No | Icon size inside a chip. |
| `bubbleRadius` | int | 16 | No | Corner radius of a chip. |
| `bubbleSegmentGap` | int | 6 | No | Gap between split segments. |
| `bubbleHoverMargin` | int | 8 | No | Inset of the split content from the pill edges on hover. |
| `bubbleHoverPadding` | int | 8 | No | Hover tolerance around the bar, in px. |
| `bubbleHoverLatch` | int | 240 | No | Milliseconds the hover state is kept after the cursor leaves. |

### Tray popup and tooltip

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `trayPopupGap` | int | 6 | No | Gap between the bar and the tray popup. |
| `trayPopupPadding` | int | 6 | No | Padding inside the tray popup. |
| `trayPopupRadius` | int | 14 | No | Corner radius of the tray popup. |
| `trayItemSize` | int | 24 | No | Size of a tray item. |
| `trayItemSpacing` | int | 6 | No | Spacing between tray items. |
| `trayPopupMaxHeight` | int | 260 | No | Maximum visible height before the tray list scrolls. |
| `tooltipGap` | int | 6 | No | Gap between the bar and the chip tooltip. |
| `tooltipPaddingX` | int | 7 | No | Horizontal tooltip padding. |
| `tooltipPaddingY` | int | 3 | No | Vertical tooltip padding. |
| `tooltipRadius` | int | 10 | No | Tooltip corner radius. |
| `tooltipSize` | int | 12 | No | Tooltip font size. |

### Power popup

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `powerBubbleSide` | string | `"left"` | No | Side the power chip sits on. Values: `"left"`, `"right"`. |
| `powerChipIcon` | string | `"assets/power.svg"` | No | Icon path for the power chip. |
| `powerPopupWidth` | int | 160 | No | Width of the power popup. |
| `powerConfirmWidth` | int | 72 | No | Width of each Cancel/Confirm button in the inline confirmation. |
| `powerRowHeight` | real | 30 | No | Height of a power action row. |
| `powerRowSpacing` | int | 2 | No | Spacing between power action rows. |
| `powerIconSize` | int | 16 | No | Size of a power action icon. |
| `powerLabelSize` | int | 12 | No | Font size of a power action label. |
| `powerActions` | var | see below | No | Array of power actions. |

`powerActions` is an array of objects with the shape
`{ label: string, icon: string, cmd: list<string>, confirm: bool }`. `cmd` is
the detached process command; `confirm` requests an inline confirmation before
running. The defaults are Lock (`hyprlock`), Log out (`uwsm stop`), Suspend,
Restart, and Shut down, all with `confirm: true`.

### Side navigation

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `navTargetWidth` | int | 80 | No | Width of each clickable side strip. |
| `navMargin` | int | 4 | No | Inset of the hover background from the pill edge. |
| `navGap` | int | 8 | No | Space between an arrow and the content. |
| `navFeedbackOpacity` | real | 0.12 | No | Opacity of the navigation feedback overlay. |
| `navSeparator` | bool | false | No | Draws divider lines between the navigation strips and the content. |
| `navSeparatorOpacity` | real | 0.2 | No | Opacity of those dividers. |

### Notification UI

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `notifSidebarWidth` | int | 340 | No | Width of the notification sidebar. |
| `notifSidebarPadding` | int | 12 | No | Inner padding of the sidebar. |
| `notifSidebarRadius` | int | 20 | No | Corner radius of the sidebar. |
| `notifTitleSize` | int | 16 | No | Sidebar title font size. |
| `notifIconSize` | int | 20 | No | Group icon size. |
| `notifAppNameSize` | int | 11 | No | App-name font size. |
| `notifSummarySize` | int | 13 | No | Notification summary font size. |
| `notifBodySize` | int | 12 | No | Notification body font size. |
| `notifCloseSize` | int | 13 | No | Close-button glyph size. |
| `notifBodyMaxLines` | int | 6 | No | Maximum body lines before eliding. |
| `notifThumbSize` | int | 44 | No | Thumbnail size on a card. |
| `notifPilePeek` | int | 6 | No | Vertical offset of each collapsed pile layer. |
| `notifPileInset` | int | 6 | No | Horizontal inset of each collapsed pile layer. |
| `notifPileMax` | int | 3 | No | Maximum cards shown in a collapsed pile. |
| `notifAnimStagger` | int | 40 | No | Milliseconds between staggered rows when fanning/dismissing. |
| `notifCardPadding` | int | 10 | No | Inner padding of a notification card. |
| `notifCardSpacing` | int | 8 | No | Spacing between card children. |
| `notifCardRadius` | int | 14 | No | Notification card corner radius. |
| `notifToastWidth` | int | 320 | No | Width of a toast. |
| `notifToastGap` | int | 8 | No | Gap between toasts. |
| `notifToastTopMargin` | int | 48 | No | Top margin of the toast stack. |
| `notifToastRightMargin` | int | 12 | No | Right margin of the toast stack. |
| `notifToastMax` | int | 5 | No | Maximum simultaneous toasts. |
| `notifToastDuration` | int | 3100 | No | Milliseconds before a toast expires (restarts on unhover). |
| `notifCardSurface` | color | `darkBackground` | No | Card background. |
| `notifCardBorder` | color | `darkerForeground` | No | Card border. |
| `notifCardHoverSurface` | color | `lighterBackground2` | No | Card background on hover/press. |
| `notifCardHoverBorder` | color | `darkerForeground` | No | Card border on hover/press. |

### Media view

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `mediaArtSize` | int | 48 | No | Album-art size. |
| `mediaTitleSize` | int | 14 | No | Track title font size. |
| `mediaArtistSize` | int | 11 | No | Artist font size. |
| `mediaControlSize` | int | 16 | No | Media control glyph size. |
| `mediaControlSpacing` | int | 16 | No | Spacing between media controls. |
| `mediaSpacing` | int | 6 | No | Vertical spacing in the media view. |
| `mediaAutoPriority` | bool | true | No | Jumps to the media view when something starts playing. |

### Motion

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `animationDuration` | int | 240 | No | Base duration in ms for movement/height/opacity animations. |
| `hoverDuration` | int | 160 | No | Duration in ms for colour/opacity hover fades. |
| `reduceMotion` | bool | false | No | When true, movement animations collapse to 0 while opacity/colour fades keep `animationDuration`. Manual equivalent of a reduced-motion preference. |
| `motionDuration` | int | derived | No (readonly) | `reduceMotion ? 0 : animationDuration`. Use for movement animations. |
| `pressDuration` | int | derived | No (readonly) | `reduceMotion ? 0 : 160`. Use for press feedback. |
| `easeOut` | var | `[0.23, 1, 0.32, 1, 1, 1]` | No | Bezier control points for entering/exiting motion. |
| `easeInOut` | var | `[0.77, 0, 0.175, 1, 1, 1]` | No | Bezier control points for on-screen movement. |
| `easeDrawer` | var | `[0.32, 0.72, 0, 1, 1, 1]` | No | Bezier control points for panel slides (Ionic). |
| `workspaceDisplayDuration` | int | 1000 | No | Milliseconds the workspace number is held before swapping back to the clock. |

### Workspaces widget

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `wsAlwaysShow` | bool | false | No | Keeps the workspace panel open without hovering. |
| `wsHoverHeight` | int | 24 | No | Height of the top-left hover band that drops the panel. |
| `wsNotchTopRadius` | int | 19 | No | Concave fillet where the notch pinches off the top edge. |
| `wsNotchBottomRadius` | int | 19 | No | Convex rounding of the notch's bottom corners. |
| `wsPaddingY` | int | 6 | No | Vertical padding above/below the number row. |
| `wsPaddingX` | int | 30 | No | Horizontal breathing room around the number row. |
| `wsItemSize` | int | 20 | No | Size of a workspace slot. |
| `wsItemSpacing` | int | 9 | No | Spacing between workspace slots. |
| `wsFontSize` | int | 12 | No | Workspace number font size. |
| `wsRadius` | int | 8 | No | Corner radius of the active-slot highlight. |

### Colours

The palette follows the Kanagawa scheme.

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `background` | color | `#1F1F28` | No | Default background (`sumiInk1`). |
| `darkBackground` | color | `#16161D` | No | Dark background (`sumiInk0`). |
| `lighterBackground1` | color | `#2A2A37` | No | Lighter background (`sumiInk2`). |
| `lighterBackground2` | color | `#363646` | No | Lighter background (`sumiInk3`). |
| `darkForeground` | color | `#C8C093` | No | Dark foreground (`oldWhite`). |
| `foreground` | color | `#DCD7BA` | No | Default foreground (`fujiWhite`). |
| `darkerForeground` | color | `#54546D` | No | Borders and dimmed text (`sumiInk4`). |
| `accent` | color | `#223249` | No | Accent/highlight colour (`waveBlue1`). |

A commented reference table of the full Kanagawa palette is included at the end
of the file.

## 5. Signals

None.

## 6. Methods

None.

## 7. Inter-Component Interactions

- Every component reads its sizes, colours and motion tokens from this
  singleton. Typical access is `Math.round(IslandConfig.<token> * uiScale)`.
- `motionDuration` and `pressDuration` are the values components use so that
  `reduceMotion` applies consistently across the shell.
- `powerActions` is bound directly by `PowerPopup` as its action model.
- `notifCardSurface`/`notifCardBorder`/`notifCardHoverSurface`/
  `notifCardHoverBorder` are consumed by `NotificationCard` and the collapsed
  pile shells in `NotificationSidebar`.
- Changing a value here re-themes/re-sizes every component with no other edit.

## 8. Usage Example

Omitted: this is a singleton, not instantiated by callers.
