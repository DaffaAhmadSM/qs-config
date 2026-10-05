// ExpandedIsland.qml
// The expanded island: a title above the active view, with clickable side strips
// to step between views. Reports its natural height so the pill can size itself.
pragma ComponentBehavior: Bound

import QtQuick

Item {
  id: root

  required property real uiScale
  required property real contentWidth
  required property real headerHeight
  required property string viewName
  required property Component viewComponent

  signal next()
  signal prev()

  property bool frontIsA: true
  readonly property var activeLoader: root.frontIsA ? loaderA : loaderB
  readonly property var inactiveLoader: root.frontIsA ? loaderB : loaderA
  readonly property real viewHeight: root.activeLoader.implicitHeight

  // Set once the loaders exist, so the view swap only animates on later changes.
  property bool ready: false

  function applyView(animate): void {
    const target = root.viewComponent
    if (!target)
      return
    if (!animate) {
      root.activeLoader.sourceComponent = target
      root.activeLoader.opacity = 1
      root.inactiveLoader.sourceComponent = null
      return
    }
    const incoming = root.inactiveLoader
    const outgoing = root.activeLoader
    incoming.sourceComponent = target
    incoming.opacity = 1
    outgoing.opacity = 0
    root.frontIsA = !root.frontIsA
    swapDone.restart()
  }

  Component.onCompleted: {
    root.ready = true
    root.applyView(false)
  }
  onViewComponentChanged: if (root.ready) root.applyView(true)

  Timer {
    id: swapDone
    interval: IslandConfig.animationDuration
    onTriggered: root.inactiveLoader.sourceComponent = null
  }
//
//   Item {
//       id: viewTitleBlock
//       anchors.top: parent.top
//       anchors.horizontalCenter: parent.horizontalCenter
//       anchors.topMargin: Math.round(IslandConfig.expandedPaddingY * root.uiScale)
//       Text {
//         anchors.top: parent.top
//         id: viewTitle
//         width: parent.width
//         height: root.headerHeight
//         verticalAlignment: Text.AlignVCenter
//         horizontalAlignment: Text.AlignHCenter
//         text: root.viewName
//         color: IslandConfig.foreground
//         font.bold: true
//         font.pixelSize: Math.round(IslandConfig.headerSize * root.uiScale)
//       }
//   }

  // Content block: title above the active view.
  Item {
    id: viewColumn
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    // anchors.top: parent.top
    anchors.topMargin: Math.round(IslandConfig.expandedPaddingY * root.uiScale)
    width: root.contentWidth
    height: viewTitle.height + viewHost.height + Math.round(IslandConfig.mediaSpacing * root.uiScale)

    Text {
      anchors.top: parent.top
      id: viewTitle
      width: parent.width
      height: root.headerHeight
      verticalAlignment: Text.AlignVCenter
      horizontalAlignment: Text.AlignHCenter
      text: root.viewName
      color: IslandConfig.foreground
      font.bold: true
      font.pixelSize: Math.round(IslandConfig.headerSize * root.uiScale)
    }

    Item {
      id: viewHost
      anchors.top: viewTitle.bottom
      anchors.topMargin: Math.round(IslandConfig.mediaSpacing * root.uiScale)
      anchors.horizontalCenter: parent.horizontalCenter
      width: parent.width
      height: root.viewHeight

      Loader {
        id: loaderA
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: parent.width
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: IslandConfig.animationDuration } }
      }

      Loader {
        id: loaderB
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: parent.width
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: IslandConfig.animationDuration } }
      }
    }
  }

  // Side navigation: full-height clickable strips.
  Item {
    id: prevTarget
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: Math.round(IslandConfig.navTargetWidth * root.uiScale)

    Accessible.role: Accessible.Button
    Accessible.name: qsTr("Previous view")

    Text {
      anchors.centerIn: parent

      text: "❮"
      color: IslandConfig.foreground
      opacity: prevHover.pressed ? 1
        : prevHover.containsMouse ? 1 : 0.5
      font.pointSize: prevHover.pressed ? Math.round(IslandConfig.arrowSize * 1.2 * root.uiScale)
        : prevHover.containsMouse ? Math.round(IslandConfig.arrowSize * root.uiScale)
        : Math.round(IslandConfig.arrowSize * 0.8 * root.uiScale)
      Behavior on opacity { NumberAnimation { duration: IslandConfig.animationDuration } }
      Behavior on font.pointSize { NumberAnimation { duration: IslandConfig.animationDuration * 0.4 } }
      Accessible.ignored: true
    }

    MouseArea {
      id: prevHover
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.prev()
    }
  }

  Item {
    id: nextTarget
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: Math.round(IslandConfig.navTargetWidth * root.uiScale)

    Accessible.role: Accessible.Button
    Accessible.name: qsTr("Next view")

    Text {
      anchors.centerIn: parent
      text: "❯"
      color: IslandConfig.foreground
      opacity: nextHover.pressed ? 1
        : nextHover.containsMouse ? 1 : 0.5
        font.pointSize: nextHover.pressed ? Math.round(IslandConfig.arrowSize * 1.2 * root.uiScale)
        : nextHover.containsMouse ? Math.round(IslandConfig.arrowSize * root.uiScale)
        : Math.round(IslandConfig.arrowSize * 0.8 * root.uiScale)
      Behavior on opacity { NumberAnimation { duration: IslandConfig.animationDuration } }
      Behavior on font.pointSize { NumberAnimation { duration: IslandConfig.animationDuration * 0.4 } }
      Accessible.ignored: true
    }

    MouseArea {
      id: nextHover
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.next()
    }
  }

  // Optional dividers between each strip and the content block.
  Rectangle {
    visible: IslandConfig.navSeparator
    anchors.left: prevTarget.right
    anchors.leftMargin: Math.round(IslandConfig.navGap / 2 * root.uiScale)
    anchors.verticalCenter: parent.verticalCenter
    width: 1
    height: viewColumn.height
    color: IslandConfig.foreground
    opacity: IslandConfig.navSeparatorOpacity
    Accessible.ignored: true
  }

  Rectangle {
    visible: IslandConfig.navSeparator
    anchors.right: nextTarget.left
    anchors.rightMargin: Math.round(IslandConfig.navGap / 2 * root.uiScale)
    anchors.verticalCenter: parent.verticalCenter
    width: 1
    height: viewColumn.height
    color: IslandConfig.foreground
    opacity: IslandConfig.navSeparatorOpacity
    Accessible.ignored: true
  }
}
