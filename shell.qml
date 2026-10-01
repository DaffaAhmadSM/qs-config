import Quickshell

ShellRoot {
  id: root

  // Reserve the top strip on every monitor so windows don't overlap the bar.
  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      readonly property real s: modelData ? modelData.height / 1080 : 1

      screen: modelData
      color: "transparent"
      exclusionMode: ExclusionMode.Normal
      exclusiveZone: 42 * s
      aboveWindows: true

      anchors {
        top: true
        left: true
        right: true
      }
      implicitHeight: 42 * s
    }
  }

  // Dynamic island: one window per monitor, shown only on the focused one.
  Variants {
    model: Quickshell.screens

    Island {
      required property var modelData
      monitor: modelData
      uiScale: modelData ? modelData.height / 1080 : 1
    }
  }
}
