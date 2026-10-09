// MediaView.qml
// Expanded island view: MPRIS media controls for the active player.
pragma ComponentBehavior: Bound

import QtQuick

Column {
  id: root

  required property real uiScale
  required property var player // MprisPlayer or null

  spacing: Math.round(IslandConfig.mediaSpacing * root.uiScale)

  // Reusable control glyph with an optional click target.
  component Control: Text {
    id: control

    property bool available: true
    property string accessibleName: ""
    signal activated()

    color: IslandConfig.foreground
    opacity: available ? 1 : 0.3
    font.pixelSize: Math.round(IslandConfig.mediaControlSize * root.uiScale)

    Accessible.role: Accessible.Button
    Accessible.name: control.accessibleName

    MouseArea {
      anchors.fill: parent
      anchors.margins: -Math.round(IslandConfig.spacingSm * root.uiScale)
      enabled: control.available
      cursorShape: control.available ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: control.activated()
    }
  }

  Image {
    anchors.horizontalCenter: parent.horizontalCenter

    readonly property int artSize: Math.round(IslandConfig.mediaArtSize * root.uiScale)

    width: artSize
    height: artSize
    source: root.player && root.player.trackArtUrl ? root.player.trackArtUrl : ""
    sourceSize: Qt.size(artSize, artSize)
    asynchronous: true
    fillMode: Image.PreserveAspectCrop
    visible: status === Image.Ready
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    width: root.width
    horizontalAlignment: Text.AlignHCenter
    elide: Text.ElideRight
    text: root.player ? (root.player.trackTitle || qsTr("Unknown Title")) : qsTr("No media")
    color: IslandConfig.foreground
    font.bold: true
    font.pixelSize: Math.round(IslandConfig.mediaTitleSize * root.uiScale)
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    width: root.width
    horizontalAlignment: Text.AlignHCenter
    elide: Text.ElideRight
    text: root.player ? root.player.trackArtist : ""
    color: IslandConfig.foreground
    opacity: 0.7
    visible: root.player !== null
    font.pixelSize: Math.round(IslandConfig.mediaArtistSize * root.uiScale)
  }

  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: Math.round(IslandConfig.mediaControlSpacing * root.uiScale)
    visible: root.player !== null

    Control {
      text: "⏮"
      accessibleName: qsTr("Previous track")
      available: root.player ? root.player.canGoPrevious : false
      onActivated: if (root.player) root.player.previous()
    }

    Control {
      text: root.player && root.player.isPlaying ? "⏸" : "⏵"
      accessibleName: root.player && root.player.isPlaying ? qsTr("Pause") : qsTr("Play")
      available: root.player ? root.player.canTogglePlaying : false
      onActivated: if (root.player) root.player.togglePlaying()
    }

    Control {
      text: "⏭"
      accessibleName: qsTr("Next track")
      available: root.player ? root.player.canGoNext : false
      onActivated: if (root.player) root.player.next()
    }
  }
}
