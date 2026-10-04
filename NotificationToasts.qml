// NotificationToasts.qml
// Transient stack of new notifications in the top-right corner. Backed by a
// ListModel so adding or removing one toast animates only that toast. Each
// auto-expires after the notification's own timeout (unless it never expires or
// the pointer is resting on it). Lives inside the island's overlay.
import QtQuick

Item {
  id: root

  required property real uiScale

  readonly property real widthPx: Math.round(IslandConfig.notifToastWidth * root.uiScale)

  ListView {
    id: list
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: Math.round(IslandConfig.notifToastTopMargin * root.uiScale)
    anchors.rightMargin: Math.round(IslandConfig.notifToastRightMargin * root.uiScale)
    width: root.widthPx
    height: parent.height
    spacing: Math.round(IslandConfig.notifToastGap * root.uiScale)
    model: Notifications.toasts
    interactive: false
    boundsBehavior: Flickable.StopAtBounds

    add: Transition {
      NumberAnimation { property: "opacity"; from: 0; to: 1; duration: IslandConfig.animationDuration }
      NumberAnimation { property: "scale"; from: 0.92; to: 1; duration: IslandConfig.animationDuration; easing.type: Easing.OutCubic }
    }

    remove: Transition {
      NumberAnimation { property: "opacity"; to: 0; duration: IslandConfig.animationDuration; easing.type: Easing.InCubic }
      NumberAnimation { property: "scale"; to: 0.92; duration: IslandConfig.animationDuration; easing.type: Easing.InCubic }
    }

    displaced: Transition {
      NumberAnimation { property: "y"; duration: IslandConfig.animationDuration; easing.type: Easing.OutCubic }
    }

    delegate: NotificationCard {
      required property int key
      width: list.width
      uiScale: root.uiScale
      allowReply: false
      notification: Notifications.objectFor(key)

      onClosed: Notifications.removeToast(notification)

      Connections {
        target: notification
        function onClosed() { Notifications.removeToast(notification) }
      }

      // Auto-expire. A non-positive timeout means "never".
      Timer {
        id: expireTimer
        running: notification.expireTimeout > 0
        interval: Math.max(1, notification.expireTimeout * 1000)
        onTriggered: notification.expire()
      }

      HoverHandler {
        onHoveredChanged: {
          if (!expireTimer.running) return
          hovered ? expireTimer.stop() : expireTimer.restart()
        }
      }
    }
  }
}
