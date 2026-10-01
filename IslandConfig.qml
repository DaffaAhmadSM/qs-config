// IslandConfig.qml
// All island knobs in one place. Values are base pixels at 1080p and get
// multiplied by each screen's scale factor inside Island.qml.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
  // Sizes (px)
  property int widthCollapsed: 84
  property int widthExpanded: 230
  property int heightCollapsed: 32
  property int heightExpanded: 128 // minimum; expanded height auto-sizes to the view
  property int radiusCollapsed: 16
  property int radiusExpanded: 26
  property int topMargin: 7

  // Inner padding of the expanded view
  property int expandedPaddingX: 16
  property int expandedPaddingY: 14

  // Type (px)
  property int clockCollapsedSize: 14
  property int clockExpandedSize: 30
  property int dateSize: 12

  // Motion (ms)
  property int animationDuration: 400
  property int workspaceDisplayDuration: 1000 // hold the workspace number before swapping back to the clock

  // Colours
  property color background: "#0d0d0d"
  property color foreground: "#f2f2f2"
  property real dateOpacity: 0.65
}
