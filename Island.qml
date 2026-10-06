// Island.qml
// One dynamic island per monitor. Visible only on the compositor's focused
// monitor. A single content node is swapped between the collapsed bar and the
// expanded island, so only one is ever instantiated. All sizing/colours come
// from IslandConfig.
//
// Adding an expanded view: create <Name>View.qml with a `required property
// real uiScale` and a natural implicitHeight, then add an entry to `views`.
pragma ComponentBehavior: Bound

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

  // Overlay state.
  property bool expanded: false
  property bool trayOpen: false
  property bool powerOpen: false
  property bool notificationsOpen: false

  // Collapsed island briefly swaps the clock for the workspace number.
  property bool showingWorkspace: false
  property var lastWorkspace: null

  // ---- View registry ----
  // `views` is the single source of truth for the expanded views; array order is
  // the navigation order.
  readonly property var views: [
    { name: "CLOCK", component: clockView },
    { name: "MEDIA", component: mediaView }
  ]
  property int activeView: 0
  readonly property int mediaIndex: root.views.findIndex(v => v.name === "MEDIA")
  readonly property string activeViewName: root.views[root.activeView]?.name ?? ""
  readonly property var activeViewComponent: root.views[root.activeView]?.component ?? null

  readonly property Component clockView: Component {
    ClockView { uiScale: root.uiScale }
  }
  readonly property Component mediaView: Component {
    MediaView { uiScale: root.uiScale; player: root.activePlayer }
  }

  // ---- MPRIS ----
  // The playing player, else the first one. Both are reactive.
  readonly property var players: Mpris.players.values
  readonly property var activePlayer: root.players.find(p => p.isPlaying) ?? root.players[0] ?? null
  readonly property bool mediaPlaying: root.activePlayer?.isPlaying ?? false

  // ---- Layout metrics ----
  readonly property real collapsedW: Math.round(IslandConfig.widthCollapsed * root.uiScale)
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

  // While true the island is mid open/close morph; the hover split is deferred
  // until it settles so the split layout never overlaps the morph.
  property bool morphing: false

  // True while a collapsed-bar popup (tray or power) is open.
  readonly property bool chipPopupOpen: root.trayOpen || root.powerOpen

  // True while any overlay that needs the full-screen dismiss catcher is open.
  readonly property bool overlaysOpen: root.expanded || root.chipPopupOpen || root.notificationsOpen

  // Whether the bar *should* be in its hovered (split) state. The state itself
  // is debounced on unhover so it doesn't snap back instantly.
  readonly property bool hoverWanted: !root.expanded && !root.morphing && (barHover.hovered || root.chipPopupOpen)
  property bool collapsedHovered: false

  // Animated 0..1 factor for the hover split: the clock box interpolates
  // between the pill geometry (0) and the split geometry (1).
  property real split: root.collapsedHovered ? 1 : 0
  Behavior on split { NumberAnimation { duration: IslandConfig.animationDuration; easing.type: Easing.OutCubic } }

  // Set by the collapsed bar, used by the shared chip tooltip.
  property string hoveredChipLabel: ""
  property real hoveredChipCenterX: 0
  // Center of the chip that opened the current popup.
  property real chipAnchorX: 0

  onHoverWantedChanged: {
    if (root.hoverWanted) {
      root.collapsedHovered = true
      hoverRelease.stop()
    } else {
      hoverRelease.restart()
    }
  }

  function nextView(): void {
    activeView = (activeView + 1) % root.views.length
  }

  function prevView(): void {
    activeView = (activeView - 1 + root.views.length) % root.views.length
  }

  Component.onCompleted: root.lastWorkspace = Hyprland.focusedWorkspace

  onExpandedChanged: {
    root.morphing = true
    morphDone.restart()
    if (root.expanded) {
      root.collapsedHovered = false
      root.trayOpen = false
      root.powerOpen = false
      root.notificationsOpen = false
      root.hoveredChipLabel = ""
      if (IslandConfig.mediaAutoPriority && root.mediaPlaying)
        root.activeView = root.mediaIndex
      return
    }
    root.hoveredChipLabel = ""
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

  // ---- Swappable content: exactly one of these is instantiated ----

  Component {
    id: collapsedComponent

    CollapsedBar {
      anchors.fill: parent
      uiScale: root.uiScale
      split: root.split
      collapsedW: root.collapsedW
      pillRadius: pill.radius
      showingWorkspace: root.showingWorkspace
      chipsShown: root.collapsedHovered

      onChipClicked: (kind, centerX) => {
        root.chipAnchorX = centerX
        root.trayOpen = kind === "tray"
        root.powerOpen = kind === "power"
        root.notificationsOpen = kind === "notif"
      }
      onChipHovered: (label, centerX) => {
        root.hoveredChipLabel = label
        root.hoveredChipCenterX = centerX
      }
      onChipUnhovered: (label) => {
        if (root.hoveredChipLabel === label)
          root.hoveredChipLabel = ""
      }
    }
  }

  Component {
    id: expandedComponent

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
  focusable: root.overlaysOpen

  // Collapsed: only the pill and the live toast stack are clickable; an open
  // overlay uses the full-screen dismiss catcher.
  mask: root.overlaysOpen ? dismissRegion : collapsedRegion
  Region { id: collapsedRegion
    Region { item: barHitbox }
    Region { item: notifToasts.area }
  }
  Region { id: dismissRegion; item: dismissCatcher }

  Shortcut {
    sequence: "Escape"
    enabled: root.overlaysOpen
    onActivated: {
      if (root.notificationsOpen)
        root.notificationsOpen = false
      else if (root.trayOpen)
        root.trayOpen = false
      else if (root.powerOpen)
        root.powerOpen = false
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
    enabled: root.overlaysOpen
    onClicked: {
      if (root.expanded)
        root.expanded = false
      else if (root.notificationsOpen)
        root.notificationsOpen = false
      else if (root.trayOpen)
        root.trayOpen = false
      else if (root.powerOpen)
        root.powerOpen = false
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
        anchors.fill: parent
        sourceComponent: root.expanded ? expandedComponent : collapsedComponent
      }
    }
  }

  // Shared chip tooltip.
  Rectangle {
    opacity: root.hoveredChipLabel !== "" && !root.expanded && !root.chipPopupOpen && root.collapsedHovered ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: IslandConfig.animationDuration } }
    x: pill.x + root.hoveredChipCenterX - width / 2
    y: pill.y + pill.height + Math.round(IslandConfig.tooltipGap * root.uiScale)
    width: tooltipLabel.implicitWidth + 2 * Math.round(IslandConfig.tooltipPaddingX * root.uiScale)
    height: tooltipLabel.implicitHeight + 2 * Math.round(IslandConfig.tooltipPaddingY * root.uiScale)
    radius: Math.round(IslandConfig.tooltipRadius * root.uiScale)
    color: IslandConfig.background

    Text {
      id: tooltipLabel
      anchors.centerIn: parent
      text: root.hoveredChipLabel
      color: IslandConfig.foreground
      font.pixelSize: Math.round(IslandConfig.tooltipSize * root.uiScale)
    }
  }

  TrayPopup {
    anchor.window: root
    bar: pill
    anchorCenterX: root.chipAnchorX
    open: root.trayOpen
    uiScale: root.uiScale
    onClosed: root.trayOpen = false
    onDismissed: root.trayOpen = false
  }

  PowerPopup {
    anchor.window: root
    bar: pill
    anchorCenterX: root.chipAnchorX
    open: root.powerOpen
    uiScale: root.uiScale
    onClosed: root.powerOpen = false
    onDismissed: root.powerOpen = false
  }

  NotificationToasts {
    id: notifToasts
    anchors.fill: parent
    uiScale: root.uiScale
    hidden: root.notificationsOpen
  }

  NotificationSidebar {
    anchors.fill: parent
    uiScale: root.uiScale
    open: root.notificationsOpen
    onClosed: root.notificationsOpen = false
  }
}
