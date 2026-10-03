// TrayPopup.qml
// A small popup listing the system tray items as a vertical column of icons.
// Opened from the collapsed island's tray chip. The body (and the SystemTray
// reference) is only built while open, so nothing tray-related exists when the
// popup is closed.
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

PopupWindow {
  id: root

  required property var parentWindow
  required property Item bar
  required property string side
  required property bool open
  required property real uiScale

  signal dismissed()

  readonly property real pad: Math.round(IslandConfig.trayPopupPadding * root.uiScale)
  readonly property real itemPx: Math.round(IslandConfig.trayItemSize * root.uiScale)
  readonly property real maxList: Math.round(IslandConfig.trayPopupMaxHeight * root.uiScale)

  anchor.window: root.parentWindow
  anchor.rect.x: root.side === "left"
    ? root.bar.x
    : root.bar.x + root.bar.width - root.implicitWidth
  anchor.rect.y: root.bar.y + root.bar.height + Math.round(IslandConfig.trayPopupGap * root.uiScale)

  visible: root.open
  color: "transparent"

  // Keep a strictly positive size so the surface is never resized to 0 (which
  // the compositor rejects as an invalid size during hide).
  implicitWidth: root.itemPx + 2 * root.pad
  implicitHeight: Math.max(root.itemPx + 2 * root.pad, loader.item ? loader.item.implicitHeight : 0)

  // Unload the body only after the popup has hidden.
  onOpenChanged: if (!root.open) closeTimer.restart()

  Timer {
    id: closeTimer
    interval: 50
  }

  Component {
    id: trayBody

    Rectangle {
      anchors.fill: parent
      implicitHeight: Math.min(list.contentHeight, root.maxList) + 2 * root.pad
      radius: Math.round(IslandConfig.trayPopupRadius * root.uiScale)
      color: IslandConfig.background

      ListView {
        id: list
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.pad
        width: root.itemPx
        height: Math.min(list.contentHeight, root.maxList)
        clip: true
        spacing: Math.round(IslandConfig.trayItemSpacing * root.uiScale)
        model: SystemTray.items
        boundsBehavior: Flickable.StopAtBounds

        delegate: Item {
          id: entry

          required property var modelData

          width: list.width
          height: root.itemPx

          Image {
            anchors.centerIn: parent
            source: entry.modelData.icon
            sourceSize: Qt.size(entry.width, entry.height)
            asynchronous: true
            fillMode: Image.PreserveAspectFit
          }

          MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor

            onClicked: (mouse) => {
              const item = entry.modelData
              if (mouse.button === Qt.MiddleButton) {
                item.secondaryActivate()
              } else if (item.onlyMenu && item.hasMenu) {
                item.display(root, 0, 0)
              } else if (mouse.button === Qt.RightButton && item.hasMenu) {
                item.display(root, 50, 10)
              } else {
                item.activate()
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
    sourceComponent: trayBody
  }
}
