// IslandConfig.qml
// All island knobs in one place. Values are base pixels at 1080p and get
// multiplied by each screen's scale factor inside Island.qml.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
  // Sizes (px)
  property int widthCollapsed: 200
  property int widthExpanded: 400
  property int heightCollapsed: 32
  property int heightExpanded: 128 // minimum; expanded height auto-sizes to the view
  property int radiusCollapsed: 16
  property int radiusExpanded: 26
  property int topMargin: 2

  // Inner padding of the expanded view
  property int expandedPaddingX: 16
  property int expandedPaddingY: 14

  // Type (px)
  property int clockCollapsedSize: 14
  property int clockExpandedSize: 30
  property int dateSize: 12

  // View navigation header
  property int headerHeight: 16
  property int headerSize: 12
  property int headerSpacing: 12
  property int arrowSize: 22

  // Collapsed hover: the bar splits into [clock][chips] within widthCollapsed.
  property string trayBubbleSide: "right"  // "left" | "right"
  property string notifBubbleSide: "right" // "left" | "right"
  property real hoverPillFraction: 0.6
  property real hoverBubbleFraction: 0.2
  property int bubbleIconSize: 18
  property int bubbleRadius: 16
  property int bubbleSegmentGap: 6
  property int bubbleHoverPadding: 8 // hover tolerance around the bar (px)
  property int bubbleHoverLatch: 150 // ms to keep hover after the cursor leaves

  // Tray popup + tooltip
  property int trayPopupGap: 6
  property int trayPopupPadding: 6
  property int trayPopupRadius: 14
  property int trayItemSize: 24
  property int trayItemSpacing: 6
  property int trayPopupMaxHeight: 260
  property int tooltipGap: 6
  property int tooltipPaddingX: 7
  property int tooltipPaddingY: 3
  property int tooltipRadius: 10
  property int tooltipSize: 12

  // Side navigation
  property int navTargetWidth: 30 // width of each clickable side strip
  property int navMargin: 4       // inset of the hover background from the pill edge
  property int navGap: 8          // space between an arrow and the content
  property real navFeedbackOpacity: 0.12
  property bool navSeparator: false
  property real navSeparatorOpacity: 0.2

  // Media view
  property int mediaArtSize: 48
  property int mediaTitleSize: 14
  property int mediaArtistSize: 11
  property int mediaControlSize: 16
  property int mediaControlSpacing: 16
  property int mediaSpacing: 6
  property bool mediaAutoPriority: true // jump to MEDIA when something starts playing

  // Motion (ms)
  property int animationDuration: 245
  property int workspaceDisplayDuration: 1000 // hold the workspace number before swapping back to the clock

  // Colours
  property color background: "#0d0d0d"
  property color foreground: "#f2f2f2"
  property real dateOpacity: 0.65
}
