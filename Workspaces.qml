// Workspaces.qml
// One workspace notch per monitor: a wide, shallow panel that drops from the
// top-left corner when the pointer reaches it, listing workspaces 1-10 in a
// row. The pointer catch and the panel are input-bounded by `mask`, so while
// hidden the window only listens at the top-left band. Every slot is clickable
// (empty ones create the workspace); the active one carries a sliding accent
// highlight. Sized from IslandConfig.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland

PanelWindow {
  id: root

  required property ShellScreen monitor
  required property real uiScale

  readonly property HyprlandMonitor hyprMonitor: Hyprland.monitorFor(root.monitor)
  readonly property var slots: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  readonly property int pad: Math.round(IslandConfig.wsPadding * root.uiScale)
  readonly property int itemW: Math.round(IslandConfig.wsItemSize * root.uiScale)
  readonly property int gap: Math.round(IslandConfig.wsItemSpacing * root.uiScale)
  readonly property real notchTop: Math.round(IslandConfig.wsNotchTopRadius * root.uiScale)
  readonly property real notchBottom: Math.round(IslandConfig.wsNotchBottomRadius * root.uiScale)
  readonly property real listWidth: 10 * root.pad
    + root.slots.length * root.itemW
    + (root.slots.length - 1) * root.gap
  readonly property real listHeight: 2 * root.pad + root.itemW

  // Workspaces living on this monitor, keyed by id. Reading `.values` keeps
  // the binding reactive to Hyprland workspace events.
  readonly property var byId: {
    const result = {}
    const name = root.hyprMonitor?.name
    const list = Hyprland.workspaces.values
    for (let i = 0; i < list.length; i++) {
      const ws = list[i]
      if (ws.monitor?.name === name)
        result[ws.id] = ws
    }
    return result
  }
  // The workspace currently shown on this monitor, and its slot in the panel.
  readonly property int activeId: root.hyprMonitor?.activeWorkspace?.id ?? -1
  readonly property int activeIndex: root.activeId >= 1 && root.activeId <= root.slots.length
    ? root.activeId - 1 : -1

  property bool hovered: false
  readonly property bool shown: IslandConfig.wsAlwaysShow || root.hovered

  // Keeps the panel up briefly after the pointer leaves, so travelling between
  // numbers doesn't retract it.
  Timer {
    id: release
    interval: IslandConfig.bubbleHoverLatch
    onTriggered: root.hovered = false
  }

  screen: root.monitor
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  aboveWindows: true
  focusable: false
  anchors.top: true
  anchors.left: true
  implicitWidth: Math.round(root.listWidth)
  implicitHeight: Math.round(root.listHeight)

  // Hidden: only the top-left band accepts input. Shown: the whole panel does,
  // so the pointer can travel along the numbers.
  mask: root.shown ? panelRegion : hoverRegion
  Region { id: hoverRegion; item: hoverBand }
  Region { id: panelRegion; item: panel }

  Item {
    id: hoverBand
    anchors.top: parent.top
    anchors.left: parent.left
    width: root.width
    height: Math.round(IslandConfig.wsHoverHeight * root.uiScale)
  }

  Item {
    id: panel

    width: parent.width
    height: Math.round(root.listHeight)
    y: root.shown ? 0 : -height
    Behavior on y {
      NumberAnimation {
        duration: IslandConfig.motionDuration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: IslandConfig.easeOut
      }
    }

    // Bathtub notch: flat top flush to the screen edge, concave fillets that
    // pinch inward, straight sides, convex bottom corners, long flat base.
    Shape {
      anchors.fill: parent
      antialiasing: true
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        fillColor: IslandConfig.background
        strokeWidth: 0
        startX: 0
        startY: 0
        PathLine { x: panel.width; y: 0 }
        PathArc {
          x: panel.width - root.notchTop; y: root.notchTop
          radiusX: root.notchTop; radiusY: root.notchTop
          direction: PathArc.Counterclockwise
        }
        PathLine { x: panel.width - root.notchTop; y: panel.height - root.notchBottom }
        PathArc {
          x: panel.width - root.notchTop - root.notchBottom; y: panel.height
          radiusX: root.notchBottom; radiusY: root.notchBottom
        }
        PathLine { x: root.notchTop + root.notchBottom; y: panel.height }
        PathArc {
          x: root.notchTop; y: panel.height - root.notchBottom
          radiusX: root.notchBottom; radiusY: root.notchBottom
        }
        PathLine { x: root.notchTop; y: root.notchTop }
        PathArc {
          x: 0; y: 0
          radiusX: root.notchTop; radiusY: root.notchTop
          direction: PathArc.Counterclockwise
        }
      }
    }

    // Active-slot highlight; slides along the row to whichever workspace is
    // active, like an old telephone dial.
    Rectangle {
      id: indicator

      y: root.pad
      width: root.itemW
      height: root.itemW
      x: (root.pad * 5) + Math.max(0, root.activeIndex) * (root.itemW + root.gap)
      radius: Math.round(IslandConfig.wsRadius * root.uiScale / 2)
      color: IslandConfig.accent
      opacity: root.activeIndex >= 0 ? 1 : 0
      Accessible.ignored: true
      Behavior on x {
        NumberAnimation {
          duration: IslandConfig.motionDuration
          easing.type: Easing.InOutQuad
        }
      }
      Behavior on opacity {
        NumberAnimation {
          duration: IslandConfig.motionDuration
          easing.type: Easing.BezierSpline
          easing.bezierCurve: IslandConfig.easeOut
        }
      }
    }

    Row {
      anchors.top: parent.top
      anchors.topMargin: root.pad
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: root.gap

      Repeater {
        model: root.slots

        delegate: Text {
          id: cell

          required property int modelData

          readonly property var ws: root.byId[modelData] ?? null
          readonly property bool current: cell.ws !== null && cell.ws.id === root.activeId

          width: root.itemW
          height: root.itemW
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          text: cell.modelData
          color: cell.ws !== null ? IslandConfig.foreground : IslandConfig.darkerForeground
          opacity: cell.current ? 1 : cell.ws !== null ? 0.7 : 0.4
          font.bold: cell.current
          font.pixelSize: Math.round(IslandConfig.wsFontSize * root.uiScale)

          Accessible.role: Accessible.Button
          Accessible.name: qsTr("Workspace %1").arg(cell.modelData)

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: cell.ws ? cell.ws.activate()
              : Hyprland.dispatch("workspace " + cell.modelData)
          }
        }
      }
    }
  }

  // Hover catch, above everything. The mask bounds where it can trigger, so it
  // never sees the pointer outside the band / panel.
  Item {
    anchors.fill: parent

    HoverHandler {
      onHoveredChanged: {
        if (hovered) {
          release.stop()
          root.hovered = true
        } else {
          release.restart()
        }
      }
    }
  }
}
