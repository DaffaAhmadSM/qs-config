# CollapsedBar

## 1. Component Overview

`CollapsedBar` is the collapsed state of the dynamic island: a clock (or
workspace number) face beside a strip of chips that appear on hover. It owns its
own chip layout and emits events upward, so `Island` only has to feed it state
and route the events.

The hover behaviour is the interesting part: the bar "splits" from a single pill
into `[clock][chips]`. A `split` factor from the parent animates the clock box
and chip widths between the two geometries.

## 2. Project Structure and Dependencies

- Instantiated inside `Island.qml` as the collapsed content node (wrapped in a
  `Component` and loaded by a `Loader`).
- Imports `QtQuick` and `Quickshell.Hyprland`.
- Uses the `IslandConfig` and `Notifications` singletons and the custom type
  `BubbleChip`.
- No build system; loaded directly by Quickshell.

## 3. Component Hierarchy and Role

Root is `Item`. It contains a clock `Rectangle` (with a clock face and a
workspace face that slide/fade against each other) and a `Repeater` of
`BubbleChip`s. It adds the chip list computation, the split geometry, and the
hover/margin math.

## 4. Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `uiScale` | real | — | Yes | Screen scale applied to all metrics. |
| `split` | real | — | Yes | Animated 0..1 hover-split factor from the parent. |
| `collapsedW` | real | — | Yes | Collapsed bar width. |
| `pillRadius` | real | — | Yes | Corner radius of the bar. |
| `showingWorkspace` | bool | — | Yes | Shows the workspace number face instead of the clock. |
| `chipsShown` | bool | — | Yes | Whether the chips are visible/enabled. |
| `notch` | bool | `false` | No | Notch mode: the island paints one background, so segments stay clear. |
| `inset` | real | `0` | No | Inset keeping content clear of the notch's pinched corners. |
| `chips` | var | derived | No (readonly) | Chip definitions, one per entry, ordered outwards from the clock. Each is `{ kind, label, side, icon, slot }`. |
| `leftCount` | int | derived | No (readonly) | Number of chips on the left side. |
| `rightCount` | int | derived | No (readonly) | Number of chips on the right side. |
| `segGap` | real | derived | No (readonly) | Scaled gap between segments (`bubbleSegmentGap`). |
| `hoverMargin` | real | derived | No (readonly) | Split inset from the bar edges, scaled by `split`. |
| `contentInset` | real | derived | No (readonly) | `inset + hoverMargin`. |
| `barW` | real | derived | No (readonly) | Usable bar span once the inset is removed. |
| `chipW0` | real | derived | No (readonly) | Full-hover chip width. |
| `chipW` | real | derived | No (readonly) | Live chip width (`chipW0 * split`). |
| `leftPanelW` | real | derived | No (readonly) | Animated width of the left chip panel. |
| `rightPanelW` | real | derived | No (readonly) | Animated width of the right chip panel. |
| `clockW` | real | derived | No (readonly) | Width the clock box shrinks to when fully hovered. |

## 5. Signals

#### chipClicked(string kind, real centerX)
Emitted when a chip is left-clicked. `kind` is the chip's kind
(`"notif"`, `"tray"` or `"power"`); `centerX` is the chip centre in bar
coordinates. The parent opens the matching popup and records the anchor.

#### chipRightClicked(string kind)
Emitted when a chip is right-clicked. The parent toggles do-not-disturb for the
notification chip.

#### chipHovered(string label, real centerX)
Emitted when the pointer enters a chip. The parent shows the shared tooltip at
`centerX`.

#### chipUnhovered(string label)
Emitted when the pointer leaves a chip. The parent clears the tooltip if the
label matches.

## 6. Methods

#### chipX(chip) : real
Returns the X position of a chip within the bar, laid out outwards from the
clock. `chip` is a `chips` entry. No side effects.

## 7. Inter-Component Interactions

- Driven by `Island`: `uiScale`, `split`, `collapsedW`, `pillRadius`, `notch`,
  `inset`, `showingWorkspace`, `chipsShown`.
- Emits the chip signals listed above, which `Island` handles to open overlays,
  toggle do-not-disturb and drive the tooltip.
- Reads `IslandConfig` for chip sides, icons, gap and hover metrics, and the
  `Notifications` singleton for the muted chip label/icon.
- Each chip delegate is a `BubbleChip`, fed `uiScale`, `width`, `shown`,
  `notch`, `label`, `icon` and `x`, and whose signals are re-emitted.

## 8. Usage Example

A minimal instantiation setting every required property.

```qml
CollapsedBar {
  anchors.fill: parent
  uiScale: root.uiScale
  split: root.split
  collapsedW: root.collapsedW
  pillRadius: 16 * root.uiScale
  showingWorkspace: root.showingWorkspace
  chipsShown: root.collapsedHovered
  onChipClicked: (kind, centerX) => root.openChip(kind, centerX)
}
```
