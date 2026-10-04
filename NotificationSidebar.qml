// NotificationSidebar.qml
// Full-height panel that slides in from the right edge showing the tracked
// notification list. Lives inside the island's full-screen overlay; only the
// panel body is built while open.
import QtQuick

Item {
  id: root

  required property real uiScale
  required property bool open

  signal closed()

  readonly property real widthPx: Math.round(IslandConfig.notifSidebarWidth * root.uiScale)
  readonly property real pad: Math.round(IslandConfig.notifSidebarPadding * root.uiScale)

  Rectangle {
    id: panel

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: root.widthPx
    x: root.open ? root.width - width : root.width
    Behavior on x { NumberAnimation { duration: IslandConfig.animationDuration; easing.type: Easing.OutCubic } }

    color: IslandConfig.background
    radius: 0
    topLeftRadius: Math.round(IslandConfig.notifSidebarRadius * root.uiScale)
    bottomLeftRadius: Math.round(IslandConfig.notifSidebarRadius * root.uiScale)

    Loader {
      id: loader
      anchors.fill: parent
      active: root.open || closeTimer.running
      sourceComponent: sidebarBody
    }
  }

  // Keep the body alive while it slides out.
  onOpenChanged: if (!root.open) closeTimer.restart()

  Timer {
    id: closeTimer
    interval: IslandConfig.animationDuration
  }

  Component {
    id: sidebarBody

    Item {
      anchors.fill: parent

      Column {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.pad
        spacing: Math.round(6 * root.uiScale)

        Row {
          width: parent.width

          Text {
            width: parent.width - clearBtn.width
            text: qsTr("Notifications")
            color: IslandConfig.foreground
            font.bold: true
            font.pixelSize: Math.round(IslandConfig.notifTitleSize * root.uiScale)
          }

          Text {
            id: clearBtn
            text: qsTr("Clear all")
            color: IslandConfig.foreground
            opacity: clearHover.containsMouse ? 1 : 0.6
            font.pixelSize: Math.round(IslandConfig.notifBodySize * root.uiScale)
            visible: Notifications.server.trackedNotifications.values.length > 0

            MouseArea {
              id: clearHover
              anchors.fill: parent
              anchors.margins: -Math.round(4 * root.uiScale)
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: Notifications.clearAll()
            }
          }
        }
      }

      ListView {
        id: list
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.margins: root.pad
        clip: true
        spacing: Math.round(IslandConfig.notifCardSpacing * root.uiScale)
        model: Notifications.server.trackedNotifications
        boundsBehavior: Flickable.StopAtBounds

        delegate: NotificationCard {
          required property var modelData
          width: list.width
          uiScale: root.uiScale
          notification: modelData
        }
      }

      Text {
        anchors.centerIn: parent
        width: parent.width - 2 * root.pad
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        text: qsTr("No notifications")
        color: IslandConfig.foreground
        opacity: 0.5
        font.pixelSize: Math.round(IslandConfig.notifBodySize * root.uiScale)
        visible: Notifications.server.trackedNotifications.values.length === 0
      }
    }
  }
}
