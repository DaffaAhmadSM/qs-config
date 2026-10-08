// BubbleChip.qml
// One chip of the collapsed bar (same look as the pill): draws `icon`, a system
// icon path, or a placeholder when none is set. Owns its hover feedback and
// click, emitting events for the bar to route.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects


Rectangle {
  id: chip

  required property real uiScale
  property bool shown: false
  property bool notch: false
  property string icon: ""
  property string label: ""

  signal clicked()
  signal rightClicked()
  signal hovered(string label, real centerX)
  signal unhovered(string label)

  Accessible.role: Accessible.Button
  Accessible.name: chip.label

  height: parent ? parent.height : 0
  radius: Math.round(IslandConfig.bubbleRadius * chip.uiScale)
  // Notch mode: the island paints one bathtub background, so the chip stays clear.
  color: chip.notch ? "transparent" : IslandConfig.background
  clip: true
  enabled: chip.shown
  opacity: chip.shown ? 1 : 0
  Behavior on opacity { NumberAnimation { duration: IslandConfig.animationDuration } }

  // Placeholder icon.
  Rectangle {
    visible: chip.icon === ""
    anchors.centerIn: parent
    width: Math.round(IslandConfig.bubbleIconSize * chip.uiScale)
    height: width
    radius: Math.round(width * 0.3)
    color: IslandConfig.foreground
    opacity: 0.55
    Accessible.ignored: true
  }

  // System icon.
  Image {
    id: chipIcon
    anchors.centerIn: parent
    source: chip.icon
    sourceSize: Qt.size(Math.round(IslandConfig.bubbleIconSize * chip.uiScale),
                        Math.round(IslandConfig.bubbleIconSize * chip.uiScale))
    asynchronous: true
    fillMode: Image.PreserveAspectFit
    Accessible.ignored: true
    visible: false
  }


  MultiEffect {
    anchors.fill: chipIcon
    source: chipIcon
    visible: chip.icon !== ""
    colorizationColor: IslandConfig.foreground
    colorization: 1.0
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onContainsMouseChanged: containsMouse
      ? chip.hovered(chip.label, chip.x + chip.width / 2)
      : chip.unhovered(chip.label)
    onClicked: (mouse) => mouse.button === Qt.RightButton ? chip.rightClicked() : chip.clicked()
  }
}
