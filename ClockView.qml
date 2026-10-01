// ClockView.qml
// Expanded island view: the current time with the date beneath it.
import QtQuick

Column {
  id: root

  required property real uiScale

  spacing: Math.round(2 * root.uiScale)

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    text: Time.time
    color: IslandConfig.foreground
    font.bold: true
    font.pixelSize: Math.round(IslandConfig.clockExpandedSize * root.uiScale)
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    text: Time.date
    color: IslandConfig.foreground
    font.pixelSize: Math.round(IslandConfig.dateSize * root.uiScale)
  }
}
