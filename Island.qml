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
import QtQuick.Shapes
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
  property bool trayOpen: false

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

  // ---- Collapsed bar split ----
  // The bar keeps a fixed widthCollapsed; hovering redistributes it into a
  // shrinking clock segment plus notif/tray chips, so there is never a gap
  // boundary to lose the hover.
  property bool hoverLatch: false
  readonly property bool collapsedHovered: !root.expanded && (barHover.hovered || root.hoverLatch || root.trayOpen)

  readonly property real collapsedW: Math.round(IslandConfig.widthCollapsed * root.uiScale)
  readonly property real segGap: Math.round(IslandConfig.bubbleSegmentGap * root.uiScale)
  readonly property int chipCount: 2
  readonly property real gapTotal: root.collapsedHovered ? root.chipCount * root.segGap : 0
  readonly property real avail: root.collapsedW - root.gapTotal
  readonly property real chipW: root.collapsedHovered
    ? Math.round(root.avail * IslandConfig.hoverBubbleFraction) : 0

  readonly property bool trayLeft: IslandConfig.trayBubbleSide === "left"
  readonly property bool notifLeft: IslandConfig.notifBubbleSide === "left"
  readonly property int leftCount: (root.trayLeft ? 1 : 0) + (root.notifLeft ? 1 : 0)
  readonly property int rightCount: root.chipCount - root.leftCount
  readonly property real leftPanelW: root.collapsedHovered ? root.leftCount * (root.chipW + root.segGap) : 0
  readonly property real rightPanelW: root.collapsedHovered ? root.rightCount * (root.chipW + root.segGap) : 0
  readonly property real clockW: root.collapsedW - root.leftPanelW - root.rightPanelW

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
    if (root.expanded)
      root.trayOpen = false
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

  // Keep the bar open briefly after the cursor leaves, so crossing a segment
  // gap can't collapse it mid-move.
  Timer {
    id: hoverRelease
    interval: IslandConfig.bubbleHoverLatch
    onTriggered: root.hoverLatch = false
  }

  Connections {
    target: barHover
    function onHoveredChanged(): void {
      if (barHover.hovered) {
        root.hoverLatch = true
        hoverRelease.stop()
      } else {
        hoverRelease.restart()
      }
    }
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

  // Simple drawn tray glyph (shelf + down arrow), scales with its size.
  component TrayGlyph: Shape {
    id: glyph

    ShapePath {
      strokeColor: IslandConfig.foreground
      strokeWidth: Math.max(1, glyph.width * 0.09)
      fillColor: "transparent"
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin

      startX: glyph.width * 0.2
      startY: glyph.height * 0.62
      PathLine { x: glyph.width * 0.2; y: glyph.height * 0.82 }
      PathLine { x: glyph.width * 0.8; y: glyph.height * 0.82 }
      PathLine { x: glyph.width * 0.8; y: glyph.height * 0.62 }

      PathMove { x: glyph.width * 0.5; y: glyph.height * 0.15 }
      PathLine { x: glyph.width * 0.5; y: glyph.height * 0.52 }

      PathMove { x: glyph.width * 0.34; y: glyph.height * 0.37 }
      PathLine { x: glyph.width * 0.5; y: glyph.height * 0.53 }
      PathLine { x: glyph.width * 0.66; y: glyph.height * 0.37 }
    }
  }

  // One chip of the collapsed bar (same look as the pill). `tray` swaps the
  // placeholder for the tray glyph.
  component BubbleChip: Rectangle {
    id: chip

    property bool shown: false
    property bool tray: false

    height: parent ? parent.height : 0
    radius: Math.round(IslandConfig.bubbleRadius * root.uiScale)
    color: IslandConfig.background
    clip: true
    visible: shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: IslandConfig.animationDuration } }
    Behavior on width { NumberAnimation { duration: IslandConfig.animationDuration; easing.type: Easing.OutCubic } }
    Behavior on x { NumberAnimation { duration: IslandConfig.animationDuration; easing.type: Easing.OutCubic } }

    // Placeholder icon.
    Rectangle {
      visible: !chip.tray
      anchors.centerIn: parent
      width: Math.round(IslandConfig.bubbleIconSize * root.uiScale)
      height: width
      radius: Math.round(width * 0.3)
      color: IslandConfig.foreground
      opacity: 0.55
    }

    // Tray icon.
    TrayGlyph {
      visible: chip.tray
      anchors.centerIn: parent
      width: Math.round(IslandConfig.bubbleIconSize * root.uiScale)
      height: width
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
  focusable: root.expanded || root.trayOpen

  // Collapsed: only the pill is clickable. Expanded or tray-open: the whole
  // surface is, so an outside click closes it (and blocks apps underneath).
  mask: root.expanded || root.trayOpen ? dismissRegion : pillRegion
  Region { id: pillRegion; item: barHitbox }
  Region { id: dismissRegion; item: dismissCatcher }

  Shortcut {
    sequence: "Escape"
    enabled: root.expanded || root.trayOpen
    onActivated: {
      if (root.trayOpen)
        root.trayOpen = false
      else
        root.expanded = false
    }
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
    enabled: root.expanded || root.trayOpen
    onClicked: {
      if (root.expanded)
        root.expanded = false
      else if (root.trayOpen)
        root.trayOpen = false
    }
  }

  // Solid input region spanning the whole collapsed bar (plus hover padding),
  // so the gaps between the split segments never drop cursor events.
  Rectangle {
    id: barHitbox
    color: "transparent"
    readonly property real pad: Math.round(IslandConfig.bubbleHoverPadding * root.uiScale)
    x: pill.x - pad
    y: pill.y - pad
    width: root.collapsedW + 2 * pad
    height: pill.height + 2 * pad
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
    // Collapsed segments paint their own backgrounds (so gaps show through);
    // the expanded island paints it here.
    color: root.expanded ? IslandConfig.background : "transparent"

    Behavior on width { NumberAnimation { duration: IslandConfig.animationDuration; easing.type: Easing.OutBack } }
    Behavior on height { NumberAnimation { duration: IslandConfig.animationDuration; easing.type: Easing.OutBack } }
    Behavior on radius { NumberAnimation { duration: IslandConfig.animationDuration } }

    // Open only; closing is done by clicking outside or pressing Escape. Sits
    // above the dismiss catcher so a pill click never closes the island.
    MouseArea {
      anchors.fill: parent
      onClicked: root.expanded = true
    }

    // Hover over the whole bar regardless of the segment/child stack.
    HoverHandler {
      id: barHover
      margin: Math.round(IslandConfig.bubbleHoverPadding * root.uiScale)
    }

    WheelHandler {
      enabled: root.expanded
      onWheel: (event) => event.angleDelta.y < 0 ? root.nextView() : root.prevView()
    }

    Item {
      id: content
      anchors.fill: parent
      clip: true

      // Collapsed layer: fixed-width bar that splits into [clock][notif][tray]
      // on hover. Each part paints its own background.
      Item {
        id: collapsedLayer
        anchors.fill: parent
        enabled: !root.expanded
        opacity: root.expanded ? 0 : 1

        // Clock segment (the "pill" when idle: full width).
        Rectangle {
          id: clockSegment
          x: root.leftPanelW
          width: root.clockW
          height: parent.height
          radius: Math.round(IslandConfig.radiusCollapsed * root.uiScale)
          color: IslandConfig.background
          clip: true
          Behavior on x { NumberAnimation { duration: IslandConfig.animationDuration; easing.type: Easing.OutCubic } }
          Behavior on width { NumberAnimation { duration: IslandConfig.animationDuration; easing.type: Easing.OutCubic } }

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

        // Notification chip
        BubbleChip {
          id: notifChip
          width: root.chipW
          shown: root.collapsedHovered
          x: root.notifLeft
            ? root.leftPanelW - root.chipW - root.segGap
            : root.collapsedW - root.rightPanelW + root.segGap
        }

        // Tray chip
        BubbleChip {
          id: trayChip
          width: root.chipW
          shown: root.collapsedHovered
          tray: true

          readonly property int order: root.trayLeft === root.notifLeft ? 1 : 0

          x: root.trayLeft
            ? root.leftPanelW - (order + 1) * (root.chipW + root.segGap)
            : root.collapsedW - root.rightPanelW + order * (root.chipW + root.segGap) + root.segGap

          MouseArea {
            id: trayHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.trayOpen = true
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

  // Tray chip tooltip.
  Rectangle {
    id: trayTooltip
    opacity: trayHover.containsMouse && !root.expanded && !root.trayOpen && trayChip.shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: IslandConfig.animationDuration } }
    x: pill.x + trayChip.x + (trayChip.width - width) / 2
    y: pill.y + pill.height + Math.round(IslandConfig.tooltipGap * root.uiScale)
    width: tooltipLabel.implicitWidth + 2 * Math.round(IslandConfig.tooltipPaddingX * root.uiScale)
    height: tooltipLabel.implicitHeight + 2 * Math.round(IslandConfig.tooltipPaddingY * root.uiScale)
    radius: Math.round(IslandConfig.tooltipRadius * root.uiScale)
    color: IslandConfig.background

    Text {
      id: tooltipLabel
      anchors.centerIn: parent
      text: qsTr("Tray")
      color: IslandConfig.foreground
      font.pixelSize: Math.round(IslandConfig.tooltipSize * root.uiScale)
    }
  }

  TrayPopup {
    id: trayPopup
    parentWindow: root
    bar: pill
    side: IslandConfig.trayBubbleSide
    open: root.trayOpen
    uiScale: root.uiScale
    onClosed: root.trayOpen = false
    onDismissed: root.trayOpen = false
  }
}
