# shell

## 1. Component Overview

`shell.qml` is the entry point of the Quickshell configuration. It declares the
root and wires up the per-screen top-level surfaces; it contains no business
logic of its own.

For every screen it creates:

- a thin top exclusion strip that reserves space so windows do not overlap the
  bar,
- one `Island` (the dynamic island),
- one `Workspaces` panel (the top-left workspace notch).

A developer editing this file is configuring which top-level surfaces exist and
how they are distributed across monitors.

## 2. Project Structure and Dependencies

- Root type is `ShellRoot` from `Quickshell`.
- Imports `Quickshell` only.
- Instantiates `Island` and `Workspaces` (sibling QML files) and plain
  `PanelWindow`s for the exclusion strip.
- Every surface is created through `Variants { model: Quickshell.screens }` so
  one instance exists per monitor; `modelData` is the `ShellScreen`, and
  `uiScale` is computed as `height / 1080`.
- `//@ pragma UseQApplication` and `pragma ComponentBehavior: Bound` are set at
  the top.
- No build system: Quickshell loads `shell.qml` directly.

## 3. Component Hierarchy and Role

Root is `ShellRoot` (a non-visual root that hosts windows). It adds no visual
content; it contains three `Variants` blocks, each producing one window per
screen. The exclusion strip is a `PanelWindow` with `ExclusionMode.Normal` and
`exclusiveZone` equal to its height; the island and workspace panels manage
their own input and visibility.

## 4. Properties

None declared.

## 5. Signals

None.

## 6. Methods

None.

## 7. Inter-Component Interactions

- Drives `Island.monitor` and `Island.uiScale`, and
  `Workspaces.monitor`/`Workspaces.uiScale`, from each screen's
  `ShellScreen` data.
- The exclusion strip reserves `32 * s` pixels (where `s` is the screen's
  `height / 1080` scale) at the top of every monitor.

## 8. Usage Example

Omitted: this is the application entry point, not an embeddable component.
