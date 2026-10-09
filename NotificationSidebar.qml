// NotificationSidebar.qml
// Full-height panel that slides in from the right edge showing tracked
// notifications grouped by app. Backed by Notifications.display, a stable
// ListModel, so rows animate in/out instead of the view rebuilding. Groups
// collapse into a card pile; expanding fans the members downward.
pragma ComponentBehavior: Bound

import QtQuick

Item {
  id: root

  required property real uiScale
  required property bool open

  signal closed()

  readonly property real widthPx: Math.round(IslandConfig.notifSidebarWidth * root.uiScale)
  readonly property real pad: Math.round(IslandConfig.notifSidebarPadding * root.uiScale)
  readonly property real gap: Math.round(IslandConfig.notifCardSpacing * root.uiScale)

  // Suppresses the slide animation on the first real geometry pass, so the
  // panel doesn't sweep across the screen when the window is first sized.
  property bool ready: false
  onWidthChanged: if (!root.ready && width > 0) Qt.callLater(() => root.ready = true)

  Rectangle {
    id: panel

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: root.widthPx
    x: root.open ? root.width - width : root.width
    Behavior on x {
      enabled: root.ready
      NumberAnimation {
        duration: IslandConfig.motionDuration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: IslandConfig.easeDrawer
      }
    }

    color: IslandConfig.background
    radius: 0
    topLeftRadius: Math.round(IslandConfig.notifSidebarRadius * root.uiScale)
    bottomLeftRadius: Math.round(IslandConfig.notifSidebarRadius * root.uiScale)

    Loader {
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
        spacing: Math.round(IslandConfig.spacingSm * root.uiScale)

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
            visible: Notifications.count > 0

            Accessible.role: Accessible.Button
            Accessible.name: qsTr("Clear all notifications")

            MouseArea {
              id: clearHover
              anchors.fill: parent
              anchors.margins: -Math.round(IslandConfig.spacingXs * root.uiScale)
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
        spacing: 0
        model: Notifications.display
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
          // Keep the departing row above the one that replaces it.
          PropertyAction { property: "z"; value: 1 }
          NumberAnimation {
            property: "x"; to: list.width
            duration: IslandConfig.motionDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: IslandConfig.easeOut
          }
          NumberAnimation {
            property: "opacity"; to: 0
            duration: IslandConfig.animationDuration
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

        delegate: Item {
          id: row

          required property int key
          required property string appName
          required property string appIcon
          required property bool header
          required property bool isStart
          required property int groupSize
          required property int groupIndex
          required property int index

          readonly property var notification: row.header ? null : Notifications.objectFor(key)
          readonly property bool multi: row.groupSize > 1
          readonly property bool expanded: Notifications.isExpanded(row.appName)
          // Members of a collapsed group are tucked away; fanning them out is
          // the expand transition below. Header rows never tuck.
          readonly property bool tucked: !row.header && row.multi && !row.isStart && !row.expanded
          // Explicit per-row gap replaces ListView.spacing, so a group header
          // hugs its first card instead of paying two gaps at every boundary.
          readonly property real topGap: row.header
            ? (row.index === 0 ? 0 : root.gap)
            : ((row.isStart && row.multi) || row.index === 0 ? 0 : root.gap)

          width: list.width
          clip: true
          height: content.implicitHeight + row.topGap
          opacity: 1

          states: State {
            name: "tucked"
            when: row.tucked
            PropertyChanges { row.height: 0; row.opacity: 0 }
          }

          // Collapsing is instant (no per-row animation); expanding fans the
          // members out one by one.
          transitions: [
            Transition {
              from: "tucked"; to: ""
              // A member promoted to group head by a dismissal must appear
              // instantly; only a real expand fans it out.
              enabled: row.expanded
              NumberAnimation {
                property: "height"
                duration: IslandConfig.motionDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: IslandConfig.easeInOut
              }
              SequentialAnimation {
                PauseAnimation {
                  duration: IslandConfig.reduceMotion
                    ? 0 : Math.min(row.groupIndex, 5) * IslandConfig.notifAnimStagger
                }
                NumberAnimation {
                  property: "opacity"
                  duration: IslandConfig.animationDuration
                  easing.type: Easing.BezierSpline
                  easing.bezierCurve: IslandConfig.easeInOut
                }
              }
            }
          ]

          Item {
            id: content

            width: row.width
            y: row.topGap
            implicitHeight: row.header ? headerItem.height : body.implicitHeight

            // Group header row; it is its own model row so it never moves when
            // the group's first card is dismissed.
            Item {
              id: headerItem

              width: row.width
              height: Math.max(groupIcon.visible ? groupIcon.height : 0, chevron.height, groupClear.height, groupToggle.height)
              visible: row.header

              Text {
                id: chevron
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: Math.round(IslandConfig.spacingLg * root.uiScale)
                // text: "▸"
                rotation: row.expanded ? 90 : 0
                Behavior on rotation {
                  NumberAnimation {
                    duration: IslandConfig.motionDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: IslandConfig.easeOut
                  }
                }
                color: IslandConfig.foreground
                opacity: 0.6
                font.pixelSize: Math.round(IslandConfig.notifAppNameSize * root.uiScale)
                Accessible.ignored: true
              }

              Image {
                id: groupIcon
                anchors.left: chevron.right
                anchors.verticalCenter: parent.verticalCenter
                height: Math.round(IslandConfig.notifIconSize * root.uiScale)
                width: height
                source: row.appIcon
                sourceSize: Qt.size(width, height)
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                visible: source !== ""
                Accessible.ignored: true
              }

              Text {
                anchors.left: groupIcon.visible ? groupIcon.right : chevron.right
                anchors.leftMargin: groupIcon.visible ? Math.round(IslandConfig.spacingSm * root.uiScale) : 0
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - x - groupCount.width - groupClear.width
                  - (row.expanded ? groupToggle.width + Math.round(IslandConfig.spacingSm * root.uiScale) : 0)
                  - 2 * Math.round(IslandConfig.spacingSm * root.uiScale)
                elide: Text.ElideRight
                text: row.appName
                color: IslandConfig.foreground
                opacity: 0.7
                font.pixelSize: Math.round(IslandConfig.notifAppNameSize * root.uiScale)
              }

              Text {
                id: groupCount
                anchors.right: row.expanded ? groupToggle.left : groupClear.left
                anchors.rightMargin: Math.round(IslandConfig.spacingSm * root.uiScale)
                anchors.verticalCenter: parent.verticalCenter
                text: row.groupSize
                color: IslandConfig.foreground
                opacity: 0.5
                font.pixelSize: Math.round(IslandConfig.notifAppNameSize * root.uiScale)
              }

              Text {
                id: groupToggle
                anchors.right: groupClear.left
                anchors.rightMargin: Math.round(IslandConfig.spacingSm * root.uiScale)
                anchors.verticalCenter: parent.verticalCenter
                visible: row.expanded
                text: qsTr("Group")
                color: IslandConfig.foreground
                opacity: groupToggleHover.containsMouse ? 1 : 0.6
                font.pixelSize: Math.round(IslandConfig.notifBodySize * root.uiScale)

                Accessible.role: Accessible.Button
                Accessible.name: qsTr("Group notifications")

                MouseArea {
                  id: groupToggleHover
                  anchors.fill: parent
                  anchors.margins: -Math.round(IslandConfig.spacingXs * root.uiScale)
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: Notifications.toggleGroup(row.appName)
                }
              }

              Text {
                id: groupClear
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Clear")
                color: IslandConfig.foreground
                opacity: groupClearHover.containsMouse ? 1 : 0.6
                font.pixelSize: Math.round(IslandConfig.notifBodySize * root.uiScale)

                Accessible.role: Accessible.Button
                Accessible.name: qsTr("Clear group")

                MouseArea {
                  id: groupClearHover
                  anchors.fill: parent
                  anchors.margins: -Math.round(IslandConfig.spacingXs * root.uiScale)
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: Notifications.dismissGroup(row.appName)
                }
              }
            }

            // Card body; the group's first card also shows the pile's back
            // cards while collapsed.
            Item {
              id: body

              visible: !row.header
              width: row.width
              readonly property bool shellsVisible: row.multi && row.isStart && !row.expanded
              readonly property int shown: Math.min(row.groupSize, IslandConfig.notifPileMax)
              readonly property real peek: Math.round(IslandConfig.notifPilePeek * root.uiScale)
              readonly property real inset: Math.round(IslandConfig.notifPileInset * root.uiScale)
              implicitHeight: frontCard.implicitHeight
                + (shellsVisible ? (shown - 1) * peek : 0)
              Behavior on implicitHeight {
                // Only a real expand/collapse may grow the pile; a front card
                // promoted by a dismissal appears at its final size.
                enabled: row.expanded
                NumberAnimation {
                  duration: IslandConfig.motionDuration
                  easing.type: Easing.BezierSpline
                  easing.bezierCurve: IslandConfig.easeOut
                }
              }

              Repeater {
                model: (row.multi && row.isStart) ? Math.min(row.groupSize, IslandConfig.notifPileMax) - 1 : 0

                delegate: Rectangle {
                  required property int index

                  z: -index - 1
                  y: (index + 1) * body.peek
                  x: (index + 1) * body.inset
                  width: body.width - 2 * (index + 1) * body.inset
                  height: frontCard.implicitHeight
                  radius: Math.round(IslandConfig.notifCardRadius * root.uiScale)
                  color: IslandConfig.notifCardSurface
                  border.color: IslandConfig.notifCardBorder
                  border.width: 1
                  opacity: body.shellsVisible ? 1 : 0
                  visible: opacity > 0
                  Behavior on opacity {
                    NumberAnimation {
                      duration: IslandConfig.animationDuration
                      easing.type: Easing.BezierSpline
                      easing.bezierCurve: IslandConfig.easeOut
                    }
                  }
                }
              }

              NotificationCard {
                id: frontCard

                width: body.width
                uiScale: root.uiScale
                showAppName: !row.multi
                showClose: !row.multi || row.expanded
                collapsed: row.multi && !row.expanded
                notification: row.notification
                onExpandRequested: Notifications.toggleGroup(row.appName)
              }
            }
          }
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
        visible: Notifications.count === 0
      }
    }
  }
}
