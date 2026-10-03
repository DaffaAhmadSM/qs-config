// Island.qml
// One dynamic island per monitor. Visible only on the compositor's focused
// monitor. A single content node is swapped between the collapsed bar (clock /
// workspace, with the hover split chips) and the expanded island (nav + view),
// so only one is ever instantiated. All sizing/colours come from IslandConfig.
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

  // ---- Layout metrics ----
  readonly property real headerHeight: Math.round(IslandConfig.headerHeight * root.uiScale)
  // View width, leaving room for the side navigation strips.
  readonly property real contentWidth: Math.round(
    (IslandConfig.widthExpanded - 2 * IslandConfig.navTargetWidth) * root.uiScale)
  // Reported by the expanded content while it is loaded.
  property real expandedViewHeight: 0
  readonly property real expandedContentHeight: Math.max(
    IslandConfig.heightExpanded * root.uiScale,
    root.headerHeight
      + Math.round(IslandConfig.mediaSpacing * root.uiScale)
      + root.expandedViewHeight
      + 2 * Math.round(IslandConfig.expandedPaddingY * root.uiScale)
  )

  // ---- Collapsed bar split ----
  readonly property bool trayLeft: IslandConfig.trayBubbleSide === "left"
  readonly property bool notifLeft: IslandConfig.notifBubbleSide === "left"
  readonly property real collapsedW: Math.round(IslandConfig.widthCollapsed * root.uiScale)
  readonly property real segGap: Math.round(IslandConfig.bubbleSegmentGap * root.uiScale)
  readonly property int chipCount: 2
  readonly property int leftCount: (root.trayLeft ? 1 : 0) + (root.notifLeft ? 1 : 0)
  readonly property int rightCount: root.chipCount - root.leftCount

  // Full-hover geometry (split = 1); the live properties below scale them by
  // the animated `split` so hover *and* unhover interpolate smoothly instead
  // of snapping on the collapsedHovered boolean.
  readonly property real chipW0: Math.round((root.collapsedW - root.chipCount * root.segGap) * IslandConfig.hoverBubbleFraction)
  readonly property real leftPanelW0: root.leftCount * (root.chipW0 + root.segGap)
  readonly property real rightPanelW0: root.rightCount * (root.chipW0 + root.segGap)
  readonly property real clockW: root.collapsedW - root.leftPanelW0 - root.rightPanelW0

  readonly property real chipW: root.chipW0 * root.split
  readonly property real leftPanelW: root.leftPanelW0 * root.split
  readonly property real rightPanelW: root.rightPanelW0 * root.split

  // While true the island is mid open/close morph; the hover split is deferred
  // until it settles so the split layout never overlaps the morph.
  property bool morphing: false

  // Whether the bar *should* be in its hovered (split) state. The state itself
  // is debounced on unhover so it doesn't snap back instantly.
  readonly property bool hoverWanted: !root.expanded && !root.morphing && (barHover.hovered || root.trayOpen)
  property bool collapsedHovered: false

  // Animated 0..1 factor for the hover split: the clock box interpolates
  // between the pill geometry (0) and the split geometry (1).
  property real split: root.collapsedHovered ? 1 : 0
  Behavior on split { NumberAnimation { duration: IslandConfig.animationDuration; easing.type: Easing.OutCubic } }

  // Set by the collapsed content, used by the tray tooltip.
  property bool trayHovered: false
  property real trayChipCenterX: 0

  onHoverWantedChanged: {
    if (root.hoverWanted) {
      root.collapsedHovered = true
      hoverRelease.stop()
    } else {
      hoverRelease.restart()
    }
  }

  function nextView(): void {
    activeView = (activeView + 1) % root.viewComponents.length
  }

  function prevView(): void {
    activeView = (activeView - 1 + root.viewComponents.length) % root.viewComponents.length
  }

  Component.onCompleted: root.lastWorkspace = Hyprland.focusedWorkspace

  onExpandedChanged: {
    root.morphing = true
    morphDone.restart()
    if (root.expanded) {
      root.collapsedHovered = false
      root.trayOpen = false
      root.trayHovered = false
      if (IslandConfig.mediaAutoPriority && root.mediaPlaying)
        root.activeView = root.mediaIndex
      return
    }
    root.trayHovered = false
    if (!IslandConfig.mediaAutoPriority || !root.mediaPlaying)
      root.activeView = 0
    else
      root.activeView = root.mediaIndex
  }

  // Clears the morph guard once the open/close animation has settled.
  Timer {
    id: morphDone
    interval: IslandConfig.animationDuration
    onTriggered: root.morphing = false
  }

  // Delay before the hovered bar retracts after the cursor leaves / the tray
  // closes, so crossing a gap doesn't collapse it mid-move.
  Timer {
    id: hoverRelease
    interval: IslandConfig.bubbleHoverLatch
    onTriggered: root.collapsedHovered = false
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
    enabled: shown
    opacity: shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: IslandConfig.animationDuration } }

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

  // ---- Swappable content: exactly one of these is instantiated ----

  // Collapsed bar.
  Component {
    id: collapsedContent

    Item {
      id: collapsedRoot
      anchors.fill: parent

      // Expose the tray chip position for the tooltip.
      Binding { target: root; property: "trayChipCenterX"; value: trayChip.x + trayChip.width / 2 }

      // Clock segment. Idle (split 0) it is exactly the pill; on hover (split
      // 1) it shrinks to clockW and the chips appear.
      Rectangle {
          id: clockSegment
          x: root.leftPanelW
          width: parent.width + (root.clockW - parent.width) * root.split
          height: parent.height
        radius: pill.radius + (Math.round(IslandConfig.radiusCollapsed * root.uiScale) - pill.radius) * root.split
        color: IslandConfig.background
        clip: true

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
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onContainsMouseChanged: root.trayHovered = containsMouse
          onClicked: root.trayOpen = true
        }
      }
    }
  }

  // Expanded island.
  Component {
    id: expandedContent

    Item {
      id: expandedRoot
      anchors.fill: parent

      property bool frontIsA: true
      readonly property var activeLoader: expandedRoot.frontIsA ? loaderA : loaderB
      readonly property var inactiveLoader: expandedRoot.frontIsA ? loaderB : loaderA
      readonly property real viewHeight: expandedRoot.activeLoader.implicitHeight

      function applyView(animate) {
        const target = root.viewComponents[root.activeView]
        if (!animate) {
          expandedRoot.activeLoader.sourceComponent = target
          expandedRoot.activeLoader.opacity = 1
          expandedRoot.inactiveLoader.sourceComponent = null
          return
        }
        const incoming = expandedRoot.inactiveLoader
        const outgoing = expandedRoot.activeLoader
        incoming.sourceComponent = target
        incoming.opacity = 1
        outgoing.opacity = 0
        expandedRoot.frontIsA = !expandedRoot.frontIsA
        swapDone.restart()
      }

      Component.onCompleted: expandedRoot.applyView(false)

      Connections {
        target: root
        function onActiveViewChanged(): void { expandedRoot.applyView(true) }
      }

      // Report our height so the pill can size itself.
      Binding { target: root; property: "expandedViewHeight"; value: expandedRoot.viewHeight }

      Timer {
        id: swapDone
        interval: IslandConfig.animationDuration
        onTriggered: expandedRoot.inactiveLoader.sourceComponent = null
      }

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
          height: expandedRoot.viewHeight

          Loader {
            id: loaderA
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: parent.width
            opacity: 0
            Behavior on opacity { NumberAnimation { duration: IslandConfig.animationDuration } }
          }

          Loader {
            id: loaderB
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: parent.width
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
    width: Math.max(root.collapsedW, pill.width) + 2 * pad
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

    Behavior on width { NumberAnimation { duration: IslandConfig.animationDuration; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: IslandConfig.animationDuration; easing.type: Easing.OutCubic } }
    Behavior on radius { NumberAnimation { duration: IslandConfig.animationDuration } }
    Behavior on color { ColorAnimation { duration: IslandConfig.animationDuration } }

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

      // Single content node: exactly one of collapsed/expanded is instantiated.
      Loader {
        id: contentLoader
        anchors.fill: parent
        sourceComponent: root.expanded ? expandedContent : collapsedContent
      }
    }
  }

  // Tray chip tooltip.
  Rectangle {
    id: trayTooltip
    opacity: root.trayHovered && !root.expanded && !root.trayOpen && root.collapsedHovered ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: IslandConfig.animationDuration } }
    x: pill.x + root.trayChipCenterX - width / 2
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
