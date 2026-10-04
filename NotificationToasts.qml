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

  // The clickable extent of the toast stack, used by the island's input mask so
  // toasts never block the rest of the screen.
  readonly property alias area: list

  ListView {
    id: list
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: Math.round(IslandConfig.notifToastTopMargin * root.uiScale)
    anchors.rightMargin: Math.round(IslandConfig.notifToastRightMargin * root.uiScale)
    width: root.widthPx
    height: Math.max(contentHeight, 1)
    spacing: Math.round(IslandConfig.notifToastGap * root.uiScale)
    model: Notifications.toasts
    interactive: false
    boundsBehavior: Flickable.StopAtBounds

    add: Transition {
      NumberAnimation { property: "x"; from: list.width; to: 0; duration: IslandConfig.animationDuration; easing.type: Easing.OutCubic }
    }

    remove: Transition {
      NumberAnimation { property: "x"; to: list.width; duration: IslandConfig.animationDuration; easing.type: Easing.InCubic }
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

      onClosed: Notifications.dropKey(key)

      // Fixed short timeout, paused while hovered and restarted from 0 on
      // unhover. Only hides the toast; the notification stays in the sidebar
      // until dismissed.
      Timer {
        id: expireTimer
        running: true
        interval: IslandConfig.notifToastDuration
        onTriggered: Notifications.dropKey(key)
      }

      HoverHandler {
        onHoveredChanged: hovered ? expireTimer.stop() : expireTimer.restart()
      }
    }
  }
}
