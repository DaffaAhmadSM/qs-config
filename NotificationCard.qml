// NotificationCard.qml
// One notification rendered as a card: app icon/name, summary, body, optional
// image, action buttons, a close button and — when the sender provided one — an
// inline reply field. Used by both the sidebar list and the transient toasts.
import QtQuick
import QtQuick.Controls.Basic

Rectangle {
  id: root

  required property real uiScale
  required property var notification // Notification
  // Whether the inline reply field may be shown (toasts keep it off so they
  // never need to steal keyboard focus).
  property bool allowReply: true

  signal closed()

  readonly property real pad: Math.round(IslandConfig.notifCardPadding * root.uiScale)
  readonly property real iconSize: Math.round(IslandConfig.notifIconSize * root.uiScale)

  // All actions except the spec's "default" one, which is instead triggered by
  // clicking the card body.
  readonly property var actionList: {
    const acts = root.notification ? root.notification.actions : []
    return acts.filter(a => a.identifier !== "default")
  }
  readonly property var defaultAction: {
    const acts = root.notification ? root.notification.actions : []
    return acts.find(a => a.identifier === "default") ?? null
  }

  radius: Math.round(IslandConfig.notifCardRadius * root.uiScale)
  color: IslandConfig.notifCardSurface
  border.color: IslandConfig.notifCardBorder
  border.width: 1

  implicitHeight: column.implicitHeight + 2 * root.pad

  // Body click fires the default action (when there is one).
  MouseArea {
    anchors.fill: parent
    onClicked: if (root.defaultAction) root.defaultAction.invoke()
  }

  Column {
    id: column
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: root.pad
    spacing: Math.round(IslandConfig.notifCardSpacing * root.uiScale)

    // Header: icon, app name, close.
    Row {
      width: parent.width
      spacing: Math.round(6 * root.uiScale)

      Image {
        anchors.verticalCenter: parent.verticalCenter
        width: root.iconSize
        height: root.iconSize
        source: root.notification && root.notification.appIcon ? root.notification.appIcon : ""
        sourceSize: Qt.size(root.iconSize, root.iconSize)
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        visible: source != ""
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - root.iconSize - closeBtn.width - 2 * parent.spacing
        elide: Text.ElideRight
        text: root.notification ? root.notification.appName : ""
        color: IslandConfig.foreground
        opacity: 0.7
        font.pixelSize: Math.round(IslandConfig.notifAppNameSize * root.uiScale)
      }

      Text {
        id: closeBtn
        anchors.verticalCenter: parent.verticalCenter
        text: "✕"
        color: IslandConfig.foreground
        opacity: closeHover.containsMouse ? 1 : 0.55
        font.pixelSize: Math.round(IslandConfig.notifCloseSize * root.uiScale)

        MouseArea {
          id: closeHover
          anchors.fill: parent
          anchors.margins: -Math.round(4 * root.uiScale)
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (root.notification) root.notification.dismiss()
            root.closed()
          }
        }
      }
    }

    Text {
      width: parent.width
      visible: text !== ""
      wrapMode: Text.Wrap
      textFormat: Text.PlainText
      text: root.notification ? root.notification.summary : ""
      color: IslandConfig.foreground
      font.bold: true
      font.pixelSize: Math.round(IslandConfig.notifSummarySize * root.uiScale)
    }

    Text {
      width: parent.width
      visible: text !== ""
      wrapMode: Text.Wrap
      textFormat: Text.PlainText
      maximumLineCount: IslandConfig.notifBodyMaxLines
      elide: Text.ElideRight
      text: root.notification ? root.notification.body : ""
      color: IslandConfig.foreground
      opacity: 0.8
      font.pixelSize: Math.round(IslandConfig.notifBodySize * root.uiScale)
    }

    Image {
      width: parent.width
      height: IslandConfig.notifImageHeight * root.uiScale
      source: root.notification && root.notification.image ? root.notification.image : ""
      sourceSize: Qt.size(width, height)
      asynchronous: true
      fillMode: Image.PreserveAspectFit
      visible: source != "" && status === Image.Ready
    }

    // Inline reply.
    TextField {
      id: replyField
      width: parent.width
      visible: root.allowReply && (root.notification ? root.notification.hasInlineReply : false)
      placeholderText: root.notification && root.notification.inlineReplyPlaceholder
        ? root.notification.inlineReplyPlaceholder : qsTr("Reply…")
      color: IslandConfig.foreground
      font.pixelSize: Math.round(IslandConfig.notifBodySize * root.uiScale)
      background: Rectangle {
        color: "transparent"
        border.color: IslandConfig.foreground
        border.width: 1
        opacity: 0.4
        radius: Math.round(IslandConfig.notifCardRadius * root.uiScale / 2)
      }
      onAccepted: {
        if (text.length > 0 && root.notification) {
          root.notification.sendInlineReply(text)
          text = ""
        }
      }
    }

    // Action buttons.
    Flow {
      width: parent.width
      spacing: Math.round(6 * root.uiScale)
      visible: root.actionList.length > 0

      Repeater {
        model: root.actionList

        delegate: Rectangle {
          id: actionBtn

          required property var modelData

          radius: Math.round(IslandConfig.notifCardRadius * root.uiScale / 2)
          color: IslandConfig.foreground
          opacity: actionHover.containsMouse ? 0.2 : 0.1
          implicitWidth: actionLabel.implicitWidth + Math.round(16 * root.uiScale)
          implicitHeight: actionLabel.implicitHeight + Math.round(8 * root.uiScale)
          Behavior on opacity { NumberAnimation { duration: IslandConfig.animationDuration } }

          Text {
            id: actionLabel
            anchors.centerIn: parent
            text: actionBtn.modelData.text
            color: IslandConfig.foreground
            font.pixelSize: Math.round(IslandConfig.notifBodySize * root.uiScale)
          }

          MouseArea {
            id: actionHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: actionBtn.modelData.invoke()
          }
        }
      }
    }
  }
}
