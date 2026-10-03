// PowerPopup.qml
// A small popup listing session/power actions with bundled icons and labels.
// Opened from the collapsed island's power chip. The body is only built while
// open. Every action shows an inline confirmation before running.
import QtQuick
import Quickshell

PopupWindow {
  id: root

  required property var parentWindow
  required property Item bar
  required property real anchorCenterX
  required property bool open
  required property real uiScale

  signal dismissed()

  readonly property real pad: Math.round(IslandConfig.trayPopupPadding * root.uiScale)
  readonly property real popupW: Math.round(IslandConfig.powerPopupWidth * root.uiScale)
  readonly property real rowH: Math.round(IslandConfig.powerRowHeight * root.uiScale)
  readonly property real rowGap: Math.round(IslandConfig.powerRowSpacing * root.uiScale)
  readonly property var actions: IslandConfig.powerActions

  // null = list; otherwise the action awaiting confirmation.
  property var confirming: null

  readonly property real listH: root.actions.length * root.rowH
    + Math.max(0, root.actions.length - 1) * root.rowGap + 2 * root.pad
  readonly property real confirmH: 2 * root.rowH + root.rowGap + 2 * root.pad

  anchor.window: root.parentWindow
  anchor.rect.x: Math.max(0, Math.min(root.parentWindow.width - root.implicitWidth,
    root.bar.x + root.anchorCenterX - root.implicitWidth / 2))
  anchor.rect.y: root.bar.y + root.bar.height + Math.round(IslandConfig.trayPopupGap * root.uiScale)

  visible: root.open
  color: "transparent"

  implicitWidth: root.popupW
  implicitHeight: Math.max(1, loader.item ? loader.item.implicitHeight : 0)

  onOpenChanged: {
    if (!root.open) {
      closeTimer.restart()
      root.confirming = null
    }
  }

  Timer {
    id: closeTimer
    interval: 50
  }

  Component {
    id: powerBody

    Rectangle {
      anchors.fill: parent
      implicitHeight: root.confirming === null ? root.listH : root.confirmH
      radius: Math.round(IslandConfig.trayPopupRadius * root.uiScale)
      color: IslandConfig.background

      // Action list.
      Column {
        anchors.centerIn: parent
        spacing: root.rowGap
        visible: root.confirming === null

        Repeater {
          model: root.actions

          delegate: Item {
            id: row

            required property var modelData

            width: root.popupW - 2 * root.pad
            height: root.rowH

            // Hover highlight sits behind the content so it can't dim it.
            Rectangle {
              anchors.fill: parent
              radius: Math.round(IslandConfig.trayPopupRadius * root.uiScale / 2)
              color: IslandConfig.foreground
              opacity: rowHover.containsMouse ? 0.1 : 0
              Behavior on opacity { NumberAnimation { duration: IslandConfig.animationDuration } }
            }

            Image {
              id: rowIcon
              anchors.left: parent.left
              anchors.leftMargin: Math.round(8 * root.uiScale)
              anchors.verticalCenter: parent.verticalCenter
              source: row.modelData.icon
              sourceSize: Qt.size(Math.round(IslandConfig.powerIconSize * root.uiScale),
                                  Math.round(IslandConfig.powerIconSize * root.uiScale))
              asynchronous: true
              fillMode: Image.PreserveAspectFit
            }

            Text {
              anchors.left: rowIcon.right
              anchors.leftMargin: Math.round(10 * root.uiScale)
              anchors.verticalCenter: parent.verticalCenter
              text: row.modelData.label
              color: IslandConfig.foreground
              font.pixelSize: Math.round(IslandConfig.powerLabelSize * root.uiScale)
            }

            MouseArea {
              id: rowHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (row.modelData.confirm) {
                  root.confirming = row.modelData
                } else {
                  Quickshell.execDetached(row.modelData.cmd)
                  root.dismissed()
                }
              }
            }
          }
        }
      }

      // Inline confirmation.
      Column {
        anchors.centerIn: parent
        spacing: root.rowGap
        visible: root.confirming !== null

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.confirming ? root.confirming.label + "?" : ""
          color: IslandConfig.foreground
          font.pixelSize: Math.round(IslandConfig.powerLabelSize * root.uiScale)
        }

        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: Math.round(10 * root.uiScale)

          Item {
            width: Math.round(72 * root.uiScale)
            height: root.rowH

            Rectangle {
              anchors.fill: parent
              radius: Math.round(IslandConfig.trayPopupRadius * root.uiScale / 2)
              color: IslandConfig.foreground
              opacity: cancelHover.containsMouse ? 0.18 : 0.08
              Behavior on opacity { NumberAnimation { duration: IslandConfig.animationDuration } }
            }

            Text {
              anchors.centerIn: parent
              text: qsTr("Cancel")
              color: IslandConfig.foreground
              font.pixelSize: Math.round(IslandConfig.powerLabelSize * root.uiScale)
            }

            MouseArea {
              id: cancelHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.confirming = null
            }
          }

          Item {
            width: Math.round(72 * root.uiScale)
            height: root.rowH

            Rectangle {
              anchors.fill: parent
              radius: Math.round(IslandConfig.trayPopupRadius * root.uiScale / 2)
              color: IslandConfig.foreground
              opacity: confirmHover.containsMouse ? 0.18 : 0.08
              Behavior on opacity { NumberAnimation { duration: IslandConfig.animationDuration } }
            }

            Text {
              anchors.centerIn: parent
              text: qsTr("Confirm")
              color: IslandConfig.foreground
              font.pixelSize: Math.round(IslandConfig.powerLabelSize * root.uiScale)
            }

            MouseArea {
              id: confirmHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (root.confirming)
                  Quickshell.execDetached(root.confirming.cmd)
                root.dismissed()
              }
            }
          }
        }
      }
    }
  }

  Loader {
    id: loader
    anchors.fill: parent
    active: root.open || closeTimer.running
    sourceComponent: powerBody
  }
}
