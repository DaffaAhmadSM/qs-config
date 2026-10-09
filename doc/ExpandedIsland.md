# ExpandedIsland

## 1. Component Overview

`ExpandedIsland` is the expanded state of the dynamic island: a title above the
active view, with clickable side strips to step between views. It reports its
natural height back to the parent so the island can size itself.

A developer reaches for this component when adding view navigation or changing
how views are titled/framed; the actual view content is supplied as a
`Component` (see `views` in `Island`).

## 2. Project Structure and Dependencies

- Instantiated inside `Island.qml` as the expanded content node.
- Imports `QtQuick`.
- Reads the `IslandConfig` singleton for padding, type sizes and motion.
- No build system; loaded directly by Quickshell.

## 3. Component Hierarchy and Role

Root is `Item`. It adds: a title `Text`, a `viewHost` containing two `Loader`s
used as a foreground/background pair for cross-fading between views, the
prev/next click strips, and optional separators. It adds the `applyView`
transition logic that swaps which loader is in front.

## 4. Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `uiScale` | real | — | Yes | Screen scale applied to all metrics. |
| `contentWidth` | real | — | Yes | Width available to the title and the view. |
| `headerHeight` | real | — | Yes | Height reserved for the title. |
| `viewName` | string | — | Yes | Title shown above the view. |
| `viewComponent` | `Component` | — | Yes | The active view's component. |
| `frontIsA` | bool | `true` | No | Which loader is currently in front. |
| `activeLoader` | var | derived | No (readonly) | The loader currently in front. |
| `inactiveLoader` | var | derived | No (readonly) | The loader currently behind (cross-fade target). |
| `viewHeight` | real | derived | No (readonly) | Natural height of the front loader's content. |
| `ready` | bool | `false` | No | Set once the loaders exist, so the first view doesn't animate in. |

## 5. Signals

#### next()
Emitted when the right navigation strip is clicked. The parent advances to the
next view.

#### prev()
Emitted when the left navigation strip is clicked. The parent moves to the
previous view.

## 6. Methods

#### applyView(animate) : void
Installs `viewComponent` into the appropriate loader. When `animate` is false,
the active loader is set and shown immediately and the inactive loader cleared.
When true, the incoming loader is loaded and faded in while the outgoing one
fades out, then `frontIsA` is flipped and a timer clears the outgoing component
after `IslandConfig.animationDuration`. Called on completion and whenever
`viewComponent` changes.

## 7. Inter-Component Interactions

- Driven by `Island`: `uiScale`, `contentWidth`, `headerHeight`, `viewName`,
  `viewComponent`; `Island` handles `next`/`prev` and reads `viewHeight` via
  `onViewHeightChanged`.
- Each loader instantiates the supplied view component, which is expected to
  expose a `required property real uiScale` and a natural `implicitHeight`
  (the `ClockView`/`MediaView` contract).
- Reads `IslandConfig` for `expandedPaddingY`, `headerSize`, `mediaSpacing`,
  `navTargetWidth`, `navGap`, `navSeparator`, `navSeparatorOpacity`, `arrowSize`
  and `animationDuration`.

## 8. Usage Example

```qml
ExpandedIsland {
  anchors.fill: parent
  uiScale: root.uiScale
  contentWidth: root.contentWidth
  headerHeight: root.headerHeight
  viewName: root.activeViewName
  viewComponent: root.activeViewComponent
  onViewHeightChanged: root.expandedViewHeight = viewHeight
  onNext: root.nextView()
  onPrev: root.prevView()
}
```
