// NotificationToasts.qml
// Transient stack of new notifications in the top-right corner. Backed by a
// ListModel so adding or removing one toast animates only that toast. Each
// auto-expires after the notification's own timeout (unless it never expires or
// the pointer is resting on it). Lives inside the island's overlay.
pragma ComponentBehavior: Bound

import QtQuick

Item {
  id: root

  required property real uiScale

  // Faded out while the sidebar covers the toast corner, so toasts never
  // teleport in or out.
  property bool hidden: false
  opacity: hidden ? 0 : 1
  visible: opacity > 0
  Behavior on opacity {
    NumberAnimation {
      duration: IslandConfig.animationDuration
      easing.type: Easing.BezierSpline
      easing.bezierCurve: IslandConfig.easeOut
    }
  }

  Accessible.role: Accessible.Grouping
  Accessible.name: qsTr("Notifications")

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
      NumberAnimation {
        property: "x"; from: list.width; to: 0
        duration: IslandConfig.motionDuration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: IslandConfig.easeOut
      }
    }

    remove: Transition {
      NumberAnimation {
        property: "x"; to: list.width
        duration: IslandConfig.motionDuration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: IslandConfig.easeOut
      }
    }

    displaced: Transition {
      NumberAnimation {
        property: "y"
        duration: IslandConfig.motionDuration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: IslandConfig.easeOut
      }
    }

    delegate: NotificationCard {
      id: toastCard
      required property int key
      width: list.width
      uiScale: root.uiScale
      allowReply: false
      notification: Notifications.objectFor(key)

      onClosed: Notifications.dropKey(toastCard.key)

      // Fixed short timeout, paused while hovered and restarted from 0 on
      // unhover. Only hides the toast; the notification stays in the sidebar
      // until dismissed.
      Timer {
        id: expireTimer
        running: true
        interval: IslandConfig.notifToastDuration
        onTriggered: Notifications.dropKey(toastCard.key)
      }

      HoverHandler {
        id: toastHover
        onHoveredChanged: toastHover.hovered ? expireTimer.stop() : expireTimer.restart()
      }
    }
  }
}
