// NotificationCard.qml
// One notification rendered as a card: a left thumbnail (the notification image
// or the app icon) beside a stacked column of app name, summary, body, inline
// reply and action buttons, with a close button. Shared by the sidebar and the
// transient toasts.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic

Rectangle {
  id: root

  required property real uiScale
  required property var notification // Notification
  // Whether the inline reply field may be shown (toasts keep it off so they
  // never need to steal keyboard focus).
  property bool allowReply: true
  // Grouped cards hide the app name; the group header carries it.
  property bool showAppName: true

  signal closed()

  readonly property real pad: Math.round(IslandConfig.notifCardPadding * root.uiScale)
  readonly property real gap: Math.round(IslandConfig.notifCardSpacing * root.uiScale)
  readonly property real thumbSize: Math.round(IslandConfig.notifThumbSize * root.uiScale)
  readonly property string thumbSource:
    root.notification
      ? (root.notification.image || root.notification.appIcon || "")
      : ""

  // One pass over the actions: everything except the spec's "default" one,
  // which is instead triggered by clicking the card body.
  readonly property var actionData: {
    const result = { list: [], defaultAction: null }
    const acts = root.notification ? root.notification.actions : []
    for (let i = 0; i < acts.length; i++) {
      if (acts[i].identifier === "default")
        result.defaultAction = acts[i]
      else
        result.list.push(acts[i])
    }
    return result
  }
  readonly property var actionList: root.actionData.list
  readonly property var defaultAction: root.actionData.defaultAction

  radius: Math.round(IslandConfig.notifCardRadius * root.uiScale)
  color: bodyPress.pressed || cardHover.hovered
    ? IslandConfig.notifCardHoverSurface : IslandConfig.notifCardSurface
  border.color: bodyPress.pressed || cardHover.hovered
    ? IslandConfig.notifCardHoverBorder : IslandConfig.notifCardBorder
  border.width: 1
  Behavior on color { ColorAnimation { duration: IslandConfig.animationDuration } }
  Behavior on border.color { ColorAnimation { duration: IslandConfig.animationDuration } }

  implicitHeight: row.implicitHeight + 2 * root.pad

  HoverHandler { id: cardHover }

  // Body click fires the default action (when there is one).
  MouseArea {
    id: bodyPress
    anchors.fill: parent
    onClicked: if (root.defaultAction) root.defaultAction.invoke()
  }

  Row {
    id: row
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: root.pad
    spacing: root.gap

    // Left thumbnail.
    Rectangle {
      id: thumbFrame
      visible: root.thumbSource !== ""
      width: root.thumbSize
      height: root.thumbSize
      radius: Math.round(IslandConfig.notifCardRadius * root.uiScale / 2)
      color: "transparent"
      clip: true

      Image {
        anchors.fill: parent
        source: root.thumbSource
        sourceSize: Qt.size(root.thumbSize, root.thumbSize)
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
      }
    }

    Column {
      id: column
      width: row.width - (thumbFrame.visible ? thumbFrame.width + row.spacing : 0)
      spacing: root.gap

      Row {
        width: parent.width

        Text {
          width: parent.width - closeBtn.width
          visible: root.showAppName
          elide: Text.ElideRight
          text: root.notification ? root.notification.appName : ""
          color: IslandConfig.foreground
          opacity: 0.7
          font.pixelSize: Math.round(IslandConfig.notifAppNameSize * root.uiScale)
        }

        Text {
          id: closeBtn
          text: "✕"
          color: IslandConfig.foreground
          opacity: closeHover.containsMouse ? 1 : 0.55
          font.pixelSize: Math.round(IslandConfig.notifCloseSize * root.uiScale)

          Accessible.role: Accessible.Button
          Accessible.name: qsTr("Dismiss notification")

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

      // Inline reply.
      TextField {
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

            Accessible.role: Accessible.Button
            Accessible.name: actionBtn.modelData.text

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
}
