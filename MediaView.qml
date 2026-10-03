// MediaView.qml
// Expanded island view: MPRIS media controls for the active player.
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
    signal activated()

    color: IslandConfig.foreground
    opacity: available ? 1 : 0.3
    font.pixelSize: Math.round(IslandConfig.mediaControlSize * root.uiScale)

    MouseArea {
      anchors.fill: parent
      anchors.margins: -Math.round(6 * root.uiScale)
      enabled: control.available
      onClicked: control.activated()
    }
  }

  Image {
    id: art

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
      available: root.player ? root.player.canGoPrevious : false
      onActivated: if (root.player) root.player.previous()
    }

    Control {
      text: root.player && root.player.isPlaying ? "⏸" : "⏵"
      available: root.player ? root.player.canTogglePlaying : false
      onActivated: if (root.player) root.player.togglePlaying()
    }

    Control {
      text: "⏭"
      available: root.player ? root.player.canGoNext : false
      onActivated: if (root.player) root.player.next()
    }
  }
}
