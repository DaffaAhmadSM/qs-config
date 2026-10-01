// Island.qml
// One dynamic island per monitor. Visible only on the compositor's focused
// monitor. Collapsed it shows the clock; clicking zooms it open to reveal the
// active view. All sizing/colours come from IslandConfig.
//
// Adding an expanded view: create <Name>View.qml with a `required property
// real uiScale` and a natural implicitHeight, then add a Component below and
// append it to `viewComponents`.
import QtQuick
import Quickshell
import Quickshell.Hyprland

PanelWindow {
  id: root

  required property ShellScreen monitor
  required property real uiScale

  // Hyprland's focused monitor. Falls back to showing on every monitor when
  // there is no focus information (e.g. not running Hyprland).
  readonly property HyprlandMonitor hyprMonitor: Hyprland.monitorFor(root.monitor)
  readonly property bool focused: !Hyprland.focusedMonitor || root.hyprMonitor === Hyprland.focusedMonitor

  property bool expanded: false
  property int activeView: 0

  // Collapsed island briefly swaps the clock for the workspace number.
  property bool showingWorkspace: false
  property var lastWorkspace: null

  Component.onCompleted: root.lastWorkspace = Hyprland.focusedWorkspace

  Timer {
    id: workspaceTimer
    interval: IslandConfig.workspaceDisplayDuration
    onTriggered: root.showingWorkspace = false
  }

  // focusedWorkspace also changes when monitor focus moves between monitors.
  Connections {
    target: Hyprland
    function onFocusedWorkspaceChanged(): void {
      if (!root.focused || root.lastWorkspace === Hyprland.focusedWorkspace)
        return
      root.lastWorkspace = Hyprland.focusedWorkspace
      root.showingWorkspace = true
      workspaceTimer.restart()
    }
  }

  // Expanded views, in cycle order.
  readonly property var viewComponents: [clockView]
  readonly property Component clockView: Component {
    ClockView { uiScale: root.uiScale }
  }

  // Expanded height follows the active view, clamped to the configured minimum.
  readonly property real expandedContentHeight: Math.max(
    IslandConfig.heightExpanded * root.uiScale,
    viewLoader.implicitHeight + 2 * Math.round(IslandConfig.expandedPaddingY * root.uiScale)
  )

  function nextView(): void {
    activeView = (activeView + 1) % viewComponents.length
  }

  function prevView(): void {
    activeView = (activeView - 1 + viewComponents.length) % viewComponents.length
  }

  screen: root.monitor
  visible: root.focused
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  aboveWindows: true

  anchors {
    top: true
    left: true
    right: true
  }

  // Tall enough for the expanded state; transparent area is click-through.
  implicitHeight: Math.round(IslandConfig.topMargin * root.uiScale) + root.expandedContentHeight
  mask: Region { item: pill }

  Rectangle {
    id: pill
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: Math.round(IslandConfig.topMargin * root.uiScale)

    width: Math.round((root.expanded ? IslandConfig.widthExpanded : IslandConfig.widthCollapsed) * root.uiScale)
    height: root.expanded
      ? root.expandedContentHeight
      : Math.round(IslandConfig.heightCollapsed * root.uiScale)
    radius: Math.round((root.expanded ? IslandConfig.radiusExpanded : IslandConfig.radiusCollapsed) * root.uiScale)
    color: IslandConfig.background

    Behavior on width { NumberAnimation { duration: IslandConfig.animationDuration; easing.type: Easing.OutBack } }
    Behavior on height { NumberAnimation { duration: IslandConfig.animationDuration; easing.type: Easing.OutBack } }
    Behavior on radius { NumberAnimation { duration: IslandConfig.animationDuration } }

    // Declared first so future view controls sit above and win the click.
    MouseArea {
      anchors.fill: parent
      onClicked: root.expanded = !root.expanded
    }

    Item {
      id: content
      anchors.fill: parent
      clip: true

      // Collapsed layer: the clock alone, centered.
      Item {
        id: collapsedLayer
        anchors.fill: parent
        enabled: !root.expanded
        opacity: root.expanded ? 0 : 1
        // Behavior on opacity { NumberAnimation { duration: IslandConfig.animationDuration } }

        // Clock face; slides up and fades out while the workspace shows.
        Item {
          id: clockFace
          anchors.fill: parent
          opacity: root.showingWorkspace ? 0 : 1
          Behavior on opacity { NumberAnimation { duration: IslandConfig.animationDuration } }

          transform: Translate {
            y: root.showingWorkspace ? -clockFace.height : 0
            Behavior on y { NumberAnimation { duration: IslandConfig.animationDuration; easing.type: Easing.OutBack } }
          }

          Text {
            anchors.centerIn: parent
            text: Time.time
            color: IslandConfig.foreground
            font.bold: true
            font.pixelSize: Math.round(IslandConfig.clockCollapsedSize * root.uiScale)
          }
        }

        // Workspace face; slides in from below on workspace change.
        Item {
          id: workspaceFace
          anchors.fill: parent
          opacity: root.showingWorkspace ? 1 : 0
          Behavior on opacity { NumberAnimation { duration: IslandConfig.animationDuration } }

          transform: Translate {
            y: root.showingWorkspace ? 0 : workspaceFace.height
            Behavior on y { NumberAnimation { duration: IslandConfig.animationDuration; easing.type: Easing.OutBack } }
          }

          Text {
            anchors.centerIn: parent
            text: Hyprland.focusedWorkspace?.name ?? ""
            color: IslandConfig.foreground
            font.bold: true
            font.pixelSize: Math.round(IslandConfig.clockCollapsedSize * root.uiScale)
          }
        }
      }

      // Expanded layer: hosts the active view and cross-fades with the clock.
      Item {
        id: expandedLayer
        anchors.fill: parent
        enabled: root.expanded
        opacity: root.expanded ? 1 : 0
        // Behavior on opacity { NumberAnimation { duration: IslandConfig.animationDuration } }

        Loader {
          id: viewLoader
          anchors.centerIn: parent
          width: Math.round((IslandConfig.widthExpanded - 2 * IslandConfig.expandedPaddingX) * root.uiScale)
          sourceComponent: root.viewComponents[root.activeView]
        }
      }
    }
  }
}
