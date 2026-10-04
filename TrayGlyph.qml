// TrayGlyph.qml
// Simple drawn tray glyph (shelf + down arrow); scales with its size.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes

Shape {
  id: glyph

  Accessible.ignored: true

  ShapePath {
    strokeColor: IslandConfig.foreground
    strokeWidth: Math.max(1, glyph.width * 0.09)
    fillColor: "transparent"
    capStyle: ShapePath.RoundCap
    joinStyle: ShapePath.RoundJoin

    startX: glyph.width * 0.2
    startY: glyph.height * 0.62
    PathLine { x: glyph.width * 0.2; y: glyph.height * 0.82 }
    PathLine { x: glyph.width * 0.8; y: glyph.height * 0.82 }
    PathLine { x: glyph.width * 0.8; y: glyph.height * 0.62 }

    PathMove { x: glyph.width * 0.5; y: glyph.height * 0.15 }
    PathLine { x: glyph.width * 0.5; y: glyph.height * 0.52 }

    PathMove { x: glyph.width * 0.34; y: glyph.height * 0.37 }
    PathLine { x: glyph.width * 0.5; y: glyph.height * 0.53 }
    PathLine { x: glyph.width * 0.66; y: glyph.height * 0.37 }
  }
}
