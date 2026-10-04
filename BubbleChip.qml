// BubbleChip.qml
// One chip of the collapsed bar (same look as the pill). `tray` draws the tray
// glyph; `icon` (a system icon path) draws an image instead. Owns its hover
// feedback and click, emitting events for the bar to route.
pragma ComponentBehavior: Bound

import QtQuick

Rectangle {
  id: chip

  required property real uiScale
  property bool shown: false
  property bool tray: false
  property string icon: ""
  property string label: ""

  signal clicked()
  signal hovered(string label, real centerX)
  signal unhovered(string label)

  Accessible.role: Accessible.Button
  Accessible.name: chip.label

  height: parent ? parent.height : 0
  radius: Math.round(IslandConfig.bubbleRadius * chip.uiScale)
  color: IslandConfig.background
  clip: true
  enabled: chip.shown
  opacity: chip.shown ? 1 : 0
  Behavior on opacity { NumberAnimation { duration: IslandConfig.animationDuration } }

  // Placeholder icon.
  Rectangle {
    visible: !chip.tray && chip.icon === ""
    anchors.centerIn: parent
    width: Math.round(IslandConfig.bubbleIconSize * chip.uiScale)
    height: width
    radius: Math.round(width * 0.3)
    color: IslandConfig.foreground
    opacity: 0.55
    Accessible.ignored: true
  }

  // Tray icon.
  TrayGlyph {
    visible: chip.tray && chip.icon === ""
    anchors.centerIn: parent
    width: Math.round(IslandConfig.bubbleIconSize * chip.uiScale)
    height: width
  }

  // System icon.
  Image {
    visible: chip.icon !== ""
    anchors.centerIn: parent
    source: chip.icon
    sourceSize: Qt.size(Math.round(IslandConfig.bubbleIconSize * chip.uiScale),
                        Math.round(IslandConfig.bubbleIconSize * chip.uiScale))
    asynchronous: true
    fillMode: Image.PreserveAspectFit
    Accessible.ignored: true
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onContainsMouseChanged: containsMouse
      ? chip.hovered(chip.label, chip.x + chip.width / 2)
      : chip.unhovered(chip.label)
    onClicked: chip.clicked()
  }
}
