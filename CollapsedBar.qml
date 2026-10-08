// CollapsedBar.qml
// The collapsed island: a clock/workspace face beside a hover chip strip. Owns
// its chip list and layout so the parent only feeds state and receives events.
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Hyprland

Item {
  id: root

  required property real uiScale
  required property real split
  required property real collapsedW
  required property real pillRadius
  required property bool showingWorkspace
  required property bool chipsShown
  // Notch mode: the island paints one bathtub background, so the clock/chips
  // stop painting their own. `inset` keeps them clear of the pinched corners.
  property bool notch: false
  property real inset: 0

  signal chipClicked(string kind, real centerX)
  signal chipRightClicked(string kind)
  signal chipHovered(string label, real centerX)
  signal chipUnhovered(string label)

  // Chip definitions: one uniform chip per entry, ordered outwards from the
  // clock. `slot` is its 0-based position among same-side chips.
  readonly property var chips: {
    const defs = [
      { kind: "notif", label: qsTr("Notifications"), side: IslandConfig.notifBubbleSide, icon: IslandConfig.notifChipIcon },
      { kind: "tray", label: qsTr("Tray"), side: IslandConfig.trayBubbleSide, icon: IslandConfig.trayChipIcon },
      { kind: "power", label: qsTr("Power"), side: IslandConfig.powerBubbleSide, icon: IslandConfig.powerChipIcon }
    ]
    let left = 0, right = 0
    return defs.map(c => ({
      kind: c.kind,
      label: c.label,
      side: c.side,
      icon: c.icon,
      slot: c.side === "left" ? left++ : right++
    }))
  }
  readonly property int leftCount: root.chips.filter(c => c.side === "left").length
  readonly property int rightCount: root.chips.length - root.leftCount

  readonly property real segGap: Math.round(IslandConfig.bubbleSegmentGap * root.uiScale)
  // The split content is pulled in from the pill edges as the hover progresses.
  readonly property real hoverMargin: Math.round(IslandConfig.bubbleHoverMargin * root.uiScale) * root.split
  readonly property real contentInset: root.inset + root.hoverMargin
  // Usable bar span once the inset is removed.
  readonly property real barW: root.collapsedW - 2 * root.contentInset
  // Full-hover chip width; the live width scales it by the animated `split`.
  readonly property real chipW0: Math.max(0, Math.round(
    (root.barW * (1 - IslandConfig.hoverPillFraction) - root.chips.length * root.segGap) / root.chips.length))
  readonly property real chipW: root.chipW0 * root.split
  readonly property real leftPanelW: root.leftCount * (root.chipW0 + root.segGap) * root.split
  readonly property real rightPanelW: root.rightCount * (root.chipW0 + root.segGap) * root.split
  readonly property real clockW: root.barW - root.chips.length * (root.chipW0 + root.segGap)

  // X of a chip within the bar, laid out outwards from the clock.
  function chipX(chip): real {
    return chip.side === "left"
      ? root.contentInset + root.leftPanelW - root.segGap - root.chipW - chip.slot * (root.chipW + root.segGap)
      : root.contentInset + root.barW - root.rightPanelW + chip.slot * (root.chipW + root.segGap) + root.segGap
  }

  // Clock segment. Idle (split 0) it is exactly the pill; on hover (split 1) it
  // shrinks to clockW and the chips appear.
  Rectangle {
    x: root.contentInset + root.leftPanelW
    width: root.barW + (root.clockW - root.barW) * root.split
    height: parent.height
    radius: root.pillRadius
    color: root.notch ? "transparent" : IslandConfig.background
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

  // Chip strip.
  Repeater {
    model: root.chips

    delegate: BubbleChip {
      required property var modelData

      uiScale: root.uiScale
      width: root.chipW
      shown: root.chipsShown
      notch: root.notch
      label: modelData.kind === "notif" && Notifications.doNotDisturb
        ? qsTr("Notifications muted") : modelData.label
      icon: modelData.kind === "notif" && Notifications.doNotDisturb
        ? IslandConfig.notifChipIconMuted : (modelData.icon ?? "")
      x: root.chipX(modelData)

      onClicked: root.chipClicked(modelData.kind, x + width / 2)
      onRightClicked: root.chipRightClicked(modelData.kind)
      onHovered: (label, centerX) => root.chipHovered(label, centerX)
      onUnhovered: (label) => root.chipUnhovered(label)
    }
  }
}
