// NotificationSidebar.qml
// Full-height panel that slides in from the right edge showing tracked
// notifications grouped by app. Backed by Notifications.display, a stable
// ListModel, so rows animate in/out instead of the view rebuilding. Groups
// collapse into a card pile; expanding fans the members downward.
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
    Behavior on x { enabled: root.ready; NumberAnimation { duration: IslandConfig.animationDuration; easing.type: Easing.OutCubic } }

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
            visible: Notifications.count > 0

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
        spacing: root.gap
        model: Notifications.display
        boundsBehavior: Flickable.StopAtBounds

        add: Transition {
          NumberAnimation { property: "x"; from: list.width; to: 0; duration: IslandConfig.animationDuration; easing.type: Easing.OutCubic }
        }

        remove: Transition {
          NumberAnimation { property: "x"; to: list.width; duration: IslandConfig.animationDuration; easing.type: Easing.InCubic }
          NumberAnimation { property: "opacity"; to: 0; duration: IslandConfig.animationDuration; easing.type: Easing.InCubic }
        }

        displaced: Transition {
          NumberAnimation { property: "y"; duration: IslandConfig.animationDuration; easing.type: Easing.OutCubic }
        }

        delegate: Item {
          id: row

          required property int key
          required property string appName
          required property string appIcon
          required property bool isStart
          required property int groupSize
          required property int groupIndex

          readonly property var notification: Notifications.objectFor(key)
          readonly property bool multi: row.groupSize > 1
          readonly property bool expanded: Notifications.isExpanded(row.appName)
          // Members of a collapsed group are tucked away; fanning them out is
          // the expand transition below.
          readonly property bool tucked: row.multi && !row.isStart && !row.expanded

          width: list.width
          clip: true
          height: content.implicitHeight
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
              NumberAnimation { property: "height"; duration: IslandConfig.animationDuration; easing.type: Easing.InOutCubic }
              SequentialAnimation {
                PauseAnimation {
                  duration: row.groupIndex * IslandConfig.notifAnimStagger
                }
                NumberAnimation { property: "opacity"; duration: IslandConfig.animationDuration; easing.type: Easing.InOutCubic }
              }
            }
          ]

          Item {
            id: content

            width: row.width
            implicitHeight: (groupHeader.visible ? groupHeader.height + root.gap : 0) + body.implicitHeight

            // Group header, only on the group's first row.
            Item {
              id: groupHeader

              width: row.width
              height: Math.max(groupIcon.visible ? groupIcon.height : 0, chevron.height, groupClear.height)
              visible: row.multi && row.isStart

              MouseArea {
                id: groupToggle
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Notifications.toggleGroup(row.appName)
              }

              Text {
                id: chevron
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: Math.round(10 * root.uiScale)
                text: "▸"
                rotation: row.expanded ? 90 : 0
                Behavior on rotation { NumberAnimation { duration: IslandConfig.animationDuration; easing.type: Easing.OutCubic } }
                color: IslandConfig.foreground
                opacity: 0.6
                font.pixelSize: Math.round(IslandConfig.notifAppNameSize * root.uiScale)
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
                visible: source != ""
              }

              Text {
                id: groupName
                anchors.left: groupIcon.visible ? groupIcon.right : chevron.right
                anchors.leftMargin: groupIcon.visible ? Math.round(6 * root.uiScale) : 0
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - x - groupCount.width - groupClear.width
                  - 2 * Math.round(6 * root.uiScale)
                elide: Text.ElideRight
                text: row.appName
                color: IslandConfig.foreground
                opacity: 0.7
                font.pixelSize: Math.round(IslandConfig.notifAppNameSize * root.uiScale)
              }

              Text {
                id: groupCount
                anchors.right: groupClear.left
                anchors.rightMargin: Math.round(6 * root.uiScale)
                anchors.verticalCenter: parent.verticalCenter
                text: row.groupSize
                color: IslandConfig.foreground
                opacity: 0.5
                font.pixelSize: Math.round(IslandConfig.notifAppNameSize * root.uiScale)
              }

              Text {
                id: groupClear
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Clear")
                color: IslandConfig.foreground
                opacity: groupClearHover.containsMouse ? 1 : 0.6
                font.pixelSize: Math.round(IslandConfig.notifBodySize * root.uiScale)

                MouseArea {
                  id: groupClearHover
                  anchors.fill: parent
                  anchors.margins: -Math.round(4 * root.uiScale)
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: Notifications.dismissGroup(row.appName)
                }
              }
            }

            // Card body; the group's first row also shows the pile's back cards
            // while collapsed.
            Item {
              id: body

              y: groupHeader.visible ? groupHeader.height + root.gap : 0
              width: row.width
              readonly property bool shellsVisible: row.multi && row.isStart && !row.expanded
              readonly property int shown: Math.min(row.groupSize, IslandConfig.notifPileMax)
              readonly property real peek: Math.round(IslandConfig.notifPilePeek * root.uiScale)
              readonly property real inset: Math.round(IslandConfig.notifPileInset * root.uiScale)
              implicitHeight: frontCard.implicitHeight
                + (shellsVisible ? (shown - 1) * peek : 0)
              Behavior on implicitHeight { NumberAnimation { duration: IslandConfig.animationDuration; easing.type: Easing.OutCubic } }

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
                  Behavior on opacity { NumberAnimation { duration: IslandConfig.animationDuration } }
                }
              }

              NotificationCard {
                id: frontCard

                width: body.width
                uiScale: root.uiScale
                showAppName: !row.multi
                notification: row.notification
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
