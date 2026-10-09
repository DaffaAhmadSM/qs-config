# MediaView

## 1. Component Overview

`MediaView` is an expanded island view: MPRIS media controls for the active
player. It shows album art, track title and artist, and previous / play-pause /
next controls, disabled according to the player's capabilities. It is the
`"MEDIA"` entry in `Island`'s `views` registry.

A developer reaches for `MediaView` when changing the media presentation or the
controls; it takes the player object as a property, so it is decoupled from how
the player is selected.

## 2. Project Structure and Dependencies

- Wrapped by a `Component` in `Island.qml` (`mediaView`), which supplies
  `uiScale` and `Island.activePlayer`; rendered by `ExpandedIsland`'s loader.
- Imports `QtQuick`.
- Reads the `IslandConfig` singleton; the `player` property is an MPRIS player
  from `Quickshell.Services.Mpris` (`MprisPlayer` or `null`).
- No build system; loaded directly by Quickshell.

## 3. Component Hierarchy and Role

Root is `Column`. It adds: a centred album-art `Image`, title and artist
`Text`s, and a `Row` of three `Control` glyphs. It also declares the reusable
inline `Control` component (see below).

### Nested component: `Control`

An inline component based on `Text` — a clickable glyph with an optional click
target.

| Member | Type | Default | Description |
|--------|------|---------|-------------|
| `available` | bool | `true` | When false the glyph is dimmed and its click target disabled. |
| `accessibleName` | string | `""` | Accessible name for the glyph. |
| `activated` | signal | — | Emitted when the glyph is clicked. |

## 4. Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `uiScale` | real | — | Yes | Screen scale applied to all metrics. |
| `player` | var | — | Yes | The MPRIS player to control, or `null` when there is no media. |

## 5. Signals

None declared. The nested `Control` declares an `activated()` signal.

## 6. Methods

None.

## 7. Inter-Component Interactions

- Instantiated by `Island`'s `mediaView` component with `uiScale` and the
  active player.
- Reads the player's `trackArtUrl`, `trackTitle`, `trackArtist`, `isPlaying`,
  `canGoPrevious`, `canTogglePlaying`, `canGoNext` and calls `previous()`,
  `togglePlaying()`, `next()`.
- Reads `IslandConfig` for art/type/control sizes, spacing and foreground.
- Exposes a natural `implicitHeight` that `ExpandedIsland` reports back to
  `Island`.
- When no player is present, the artist row and controls hide and the title
  falls back to a "No media" string.

## 8. Usage Example

```qml
MediaView {
  uiScale: root.uiScale
  player: root.activePlayer
}
```
