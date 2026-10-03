// Island.qml
// One dynamic island per monitor. Visible only on the compositor's focused
// monitor. Collapsed it shows the clock (or the workspace briefly); clicking
// zooms it open to the active view. Views are cross-faded by two Loaders and
// both unload when collapsed. All sizing/colours come from IslandConfig.
//
// Adding an expanded view: create <Name>View.qml with a `required property
// real uiScale` and a natural implicitHeight, then add a Component, a name and
// a registry slot below.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris

PanelWindow {
  id: root

  required property ShellScreen monitor
  required property real uiScale

  // Hyprland's focused monitor. Falls back to showing on every monitor when
  // there is no focus information (e.g. not running Hyprland).
  readonly property HyprlandMonitor hyprMonitor: Hyprland.monitorFor(root.monitor)
  readonly property bool focused: !Hyprland.focusedMonitor || root.hyprMonitor === Hyprland.focusedMonitor

  property bool expanded: false

  // Collapsed island briefly swaps the clock for the workspace number.
  property bool showingWorkspace: false
  property var lastWorkspace: null

  // ---- View registry ----
  property int activeView: 0
  readonly property int mediaIndex: 1
  readonly property var viewNames: ["CLOCK", "MEDIA"]
  readonly property string activeViewName: root.viewNames[root.activeView] ?? ""

  readonly property var viewComponents: [clockView, mediaView]
  readonly property Component clockView: Component {
    ClockView { uiScale: root.uiScale }
  }
  readonly property Component mediaView: Component {
    MediaView { uiScale: root.uiScale; player: root.activePlayer }
  }

  // ---- MPRIS ----
  // The playing player, else the first one. Both are reactive.
  readonly property var activePlayer: {
    const players = Mpris.players.values
    return players.find(p => p.isPlaying) ?? players[0] ?? null
  }
  readonly property bool mediaPlaying: Mpris.players.values.some(p => p.isPlaying)

  // ---- Cross-fade host ----
  // One loader shows the current view while the other fades in the incoming
  // one; the outgoing loader is unloaded once the fade finishes.
  property bool frontIsA: true
  readonly property var activeLoader: root.frontIsA ? loaderA : loaderB
  readonly property var inactiveLoader: root.frontIsA ? loaderB : loaderA

  readonly property real viewHeight: root.activeLoader.implicitHeight
  readonly property real headerHeight: Math.round(IslandConfig.headerHeight * root.uiScale)
  // View width, leaving room for the side navigation strips.
  readonly property real contentWidth: Math.round(
    (IslandConfig.widthExpanded - 2 * IslandConfig.navTargetWidth) * root.uiScale)
  readonly property real expandedContentHeight: Math.max(
    IslandConfig.heightExpanded * root.uiScale,
    root.headerHeight
      + Math.round(IslandConfig.mediaSpacing * root.uiScale)
      + root.viewHeight
      + 2 * Math.round(IslandConfig.expandedPaddingY * root.uiScale)
  )

  function nextView(): void {
    activeView = (activeView + 1) % root.viewComponents.length
  }

  function prevView(): void {
    activeView = (activeView - 1 + root.viewComponents.length) % root.viewComponents.length
  }

  function applyView(animate: bool): void {
    const target = root.viewComponents[root.activeView]
    if (!animate || !root.expanded) {
      root.activeLoader.sourceComponent = target
      root.activeLoader.opacity = 1
      root.inactiveLoader.sourceComponent = null
      return
    }
    const incoming = root.inactiveLoader
    const outgoing = root.activeLoader
    incoming.sourceComponent = target
    incoming.opacity = 1
    outgoing.opacity = 0
    root.frontIsA = !root.frontIsA
    swapDone.restart()
  }

  Component.onCompleted: {
    root.lastWorkspace = Hyprland.focusedWorkspace
    root.activeLoader.sourceComponent = root.viewComponents[root.activeView]
    root.activeLoader.opacity = 1
  }

  onActiveViewChanged: root.applyView(true)

  onExpandedChanged: {
    if (!root.expanded) {
        if (!IslandConfig.mediaAutoPriority || !root.mediaPlaying)
            root.activeView = 0
        else
            root.activeView = root.mediaIndex
      return
    }
    root.applyView(false)
    if (IslandConfig.mediaAutoPriority && root.mediaPlaying){
      root.activeView = root.mediaIndex
    }
  }

  Timer {
    id: swapDone
    interval: IslandConfig.animationDuration
    onTriggered: root.inactiveLoader.sourceComponent = null
  }

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

  screen: root.monitor
  visible: root.focused
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  aboveWindows: true

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  // Grab the keyboard only while open, so Escape/arrows work.
  focusable: root.expanded

  // Collapsed: only the pill is clickable. Expanded: the whole surface is, so an
  // outside click closes the island (and blocks apps underneath while open).
  mask: root.expanded ? dismissRegion : pillRegion
  Region { id: pillRegion; item: pill }
  Region { id: dismissRegion; item: dismissCatcher }

  Shortcut {
    sequence: "Escape"
    enabled: root.expanded
    onActivated: root.expanded = false
  }

  Shortcut {
    sequence: "Left"
    enabled: root.expanded
    onActivated: root.prevView()
  }

  Shortcut {
    sequence: "Right"
    enabled: root.expanded
    onActivated: root.nextView()
  }

  MouseArea {
    id: dismissCatcher
    anchors.fill: parent
    enabled: root.expanded
    onClicked: root.expanded = false
  }

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

    // Open only; closing is done by clicking outside or pressing Escape. Sits
    // above the dismiss catcher so a pill click never closes the island.
    MouseArea {
      anchors.fill: parent
      onClicked: root.expanded = true
    }

    WheelHandler {
      enabled: root.expanded
      onWheel: (event) => event.angleDelta.y < 0 ? root.nextView() : root.prevView()
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

      // Expanded layer: navigation header + cross-faded view host.
      Item {
        id: expandedLayer
        anchors.fill: parent
        enabled: root.expanded
        opacity: root.expanded ? 1 : 0

        // Content block: title above the active view.
        Item {
          id: viewColumn
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.top
          anchors.topMargin: Math.round(IslandConfig.expandedPaddingY * root.uiScale)
          width: root.contentWidth
          height: viewTitle.height + viewHost.height + Math.round(IslandConfig.mediaSpacing * root.uiScale)

          Text {
            id: viewTitle
            width: parent.width
            height: root.headerHeight
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            text: root.activeViewName
            color: IslandConfig.foreground
            font.bold: true
            font.pixelSize: Math.round(IslandConfig.headerSize * root.uiScale)
          }

          Item {
            id: viewHost
            anchors.top: viewTitle.bottom
            anchors.topMargin: Math.round(IslandConfig.mediaSpacing * root.uiScale)
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            height: root.viewHeight

            Loader {
              id: loaderA
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.top: parent.top
              width: parent.width
              active: root.expanded
              opacity: 0
              Behavior on opacity { NumberAnimation { duration: IslandConfig.animationDuration } }
            }

            Loader {
              id: loaderB
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.top: parent.top
              width: parent.width
              active: root.expanded
              opacity: 0
              Behavior on opacity { NumberAnimation { duration: IslandConfig.animationDuration } }
            }
          }
        }

        // Side navigation: full-height clickable strips.
        Item {
          id: prevTarget
          anchors.left: parent.left
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          width: Math.round(IslandConfig.navTargetWidth * root.uiScale)

          Rectangle {
            anchors.fill: parent
            anchors.margins: Math.round(IslandConfig.navMargin * root.uiScale)
            radius: Math.round(IslandConfig.radiusCollapsed * root.uiScale)
            color: IslandConfig.foreground
            opacity: prevHover.pressed ? 0.18
              : prevHover.containsMouse ? IslandConfig.navFeedbackOpacity : 0
            Behavior on opacity { NumberAnimation { duration: IslandConfig.animationDuration } }
          }

          Text {
            anchors.centerIn: parent
            text: "❮"
            color: IslandConfig.foreground
            font.pixelSize: Math.round(IslandConfig.arrowSize * root.uiScale)
          }

          MouseArea {
            id: prevHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.prevView()
          }
        }

        Item {
          id: nextTarget
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          width: Math.round(IslandConfig.navTargetWidth * root.uiScale)

          Rectangle {
            anchors.fill: parent
            anchors.margins: Math.round(IslandConfig.navMargin * root.uiScale)
            radius: Math.round(IslandConfig.radiusCollapsed * root.uiScale)
            color: IslandConfig.foreground
            opacity: nextHover.pressed ? 0.18
              : nextHover.containsMouse ? IslandConfig.navFeedbackOpacity : 0
            Behavior on opacity { NumberAnimation { duration: IslandConfig.animationDuration } }
          }

          Text {
            anchors.centerIn: parent
            text: "❯"
            color: IslandConfig.foreground
            font.pixelSize: Math.round(IslandConfig.arrowSize * root.uiScale)
          }

          MouseArea {
            id: nextHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.nextView()
          }
        }

        // Optional dividers between each strip and the content block.
        Rectangle {
          visible: IslandConfig.navSeparator
          anchors.left: prevTarget.right
          anchors.leftMargin: Math.round(IslandConfig.navGap / 2 * root.uiScale)
          anchors.verticalCenter: parent.verticalCenter
          width: 1
          height: viewColumn.height
          color: IslandConfig.foreground
          opacity: IslandConfig.navSeparatorOpacity
        }

        Rectangle {
          visible: IslandConfig.navSeparator
          anchors.right: nextTarget.left
          anchors.rightMargin: Math.round(IslandConfig.navGap / 2 * root.uiScale)
          anchors.verticalCenter: parent.verticalCenter
          width: 1
          height: viewColumn.height
          color: IslandConfig.foreground
          opacity: IslandConfig.navSeparatorOpacity
        }
      }
    }
  }
}
