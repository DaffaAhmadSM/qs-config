// IslandConfig.qml
// All island knobs in one place. Values are base pixels at 1080p and get
// multiplied by each screen's scale factor inside Island.qml.
pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
  // Sizes (px)
  property int widthCollapsed:290
  property int widthExpanded: 400
  property int heightCollapsed: 32
  property int heightExpanded: 200 // minimum; expanded height auto-sizes to the view
  property int radiusCollapsed: 16
  property int radiusExpanded: 26
  property int topMargin: 2

  // Island notch (bathtub) background instead of the floating pill
  property bool islandNotch: true
  property int islandNotchTopRadius: 22 // concave fillet where the notch pinches off the top edge
  property int islandNotchBottomRadius: 18 // convex rounding of the notch's bottom corners

  // Inner padding of the expanded view
  property int expandedPaddingY: 14

  // Type (px)
  property int clockCollapsedSize: 14
  property int clockExpandedSize: 30
  property int dateSize: 12

  // View navigation header
  property int headerHeight: 16
  property int headerSize: 12
  property int arrowSize: 22

  // Collapsed hover: the bar splits into [clock][chips] within widthCollapsed.
  property string trayBubbleSide: "right"  // "left" | "right"
  property string trayChipIcon: "assets/tray.svg"
  property string notifBubbleSide: "right" // "left" | "right"
  property real hoverPillFraction: 0.6 // clock share; chips split the rest
  property int bubbleIconSize: 18
  property int bubbleRadius: 16
  property int bubbleSegmentGap: 6
  property int bubbleHoverMargin: 8 // inset of the split content from the pill edges on hover
  property int bubbleHoverPadding: 8 // hover tolerance around the bar (px)
  property int bubbleHoverLatch: 240 // ms to keep hover after the cursor leaves

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

  // Power chip + menu
  property string powerBubbleSide: "left" // "left" | "right"
  property string powerChipIcon: "assets/power.svg"
  property int powerPopupWidth: 160
  property real powerRowHeight: 30
  property int powerRowSpacing: 2
  property int powerIconSize: 16
  property int powerLabelSize: 12
  property var powerActions: [
    { label: "Lock",      icon: "assets/lock.svg",    cmd: ["hyprlock"],             confirm: true },
    { label: "Log out",   icon: "assets/logout.svg",  cmd: ["uwsm", "stop"],         confirm: true },
    { label: "Suspend",   icon: "assets/suspend.svg", cmd: ["systemctl", "suspend"], confirm: true },
    { label: "Restart",   icon: "assets/restart.svg", cmd: ["systemctl", "reboot"],  confirm: true },
    { label: "Shut down", icon: "assets/power.svg",   cmd: ["systemctl", "poweroff"], confirm: true }
  ]

  // Side navigation
  property int navTargetWidth: 80 // width of each clickable side strip
  property int navMargin: 4       // inset of the hover background from the pill edge
  property int navGap: 8          // space between an arrow and the content
  property real navFeedbackOpacity: 0.12
  property bool navSeparator: false
  property real navSeparatorOpacity: 0.2

  // Notifications
  property int notifSidebarWidth: 340
  property int notifSidebarPadding: 12
  property int notifSidebarRadius: 20
  property int notifTitleSize: 16
  property int notifIconSize: 20
  property int notifAppNameSize: 11
  property int notifSummarySize: 13
  property int notifBodySize: 12
  property int notifCloseSize: 13
  property int notifBodyMaxLines: 6
  property int notifThumbSize: 44
  property int notifPilePeek: 6
  property int notifPileInset: 6
  property int notifPileMax: 3
  property int notifAnimStagger: 40 // ms between staggered rows when fanning/staggering
  property int notifCardPadding: 10
  property int notifCardSpacing: 8
  property int notifCardRadius: 14
  property int notifToastWidth: 320
  property int notifToastGap: 8
  property int notifToastTopMargin: 48
  property int notifToastRightMargin: 12
  property int notifToastMax: 5
  property int notifToastDuration: 3100 // ms before a toast expires (restarts on unhover)
  property string notifChipIcon: "assets/bell.svg"
  property color notifCardSurface: darkBackground
  property color notifCardBorder: darkerForeground
  property color notifCardHoverSurface: lighterBackground2
  property color notifCardHoverBorder: darkerForeground

  // Media view
  property int mediaArtSize: 48
  property int mediaTitleSize: 14
  property int mediaArtistSize: 11
  property int mediaControlSize: 16
  property int mediaControlSpacing: 16
  property int mediaSpacing: 6
  property bool mediaAutoPriority: true // jump to MEDIA when something starts playing

  // Motion (ms)
  property int animationDuration: 240
  // Movement (slide / height / rotation / scale) collapses to 0 with reduceMotion;
  // opacity and colour fades keep animationDuration. Qt has no
  // prefers-reduced-motion query, this flag is the manual equivalent.
  property bool reduceMotion: false
  readonly property int motionDuration: reduceMotion ? 0 : animationDuration
  readonly property int pressDuration: reduceMotion ? 0 : 160

  // Strong UI curves for Easing.BezierSpline: control1, control2, end (last point 1,1).
  property var easeOut: [0.23, 1, 0.32, 1, 1, 1]     // entering / exiting
  property var easeInOut: [0.77, 0, 0.175, 1, 1, 1]  // moving on screen
  property var easeDrawer: [0.32, 0.72, 0, 1, 1, 1]  // panel slide (Ionic)

  property int workspaceDisplayDuration: 1000 // hold the workspace number before swapping back to the clock

  // Workspaces widget (top-left bathtub notch dropdown, one per monitor)
  property bool wsAlwaysShow: true // keep the panel open without hovering
  property int wsHoverHeight: 24 // top-left hover band that drops the panel
  property int wsNotchTopRadius: 19 // concave fillet where the notch pinches off the top edge
  property int wsNotchBottomRadius: 8 // convex rounding of the notch's bottom corners
  property int wsPaddingY: 6 // vertical padding above/below the number row
  property int wsPaddingX: 30 // horizontal breathing room around the number row
  property int wsItemSize: 16
  property int wsItemSpacing: 9
  property int wsFontSize: 12
  property int wsRadius: 8

  // Colours
  property color background: "#1F1F28"
  property color darkBackground: "#16161D"
  property color lighterBackground1: '#2A2A37'
  property color lighterBackground2: '#363646'
  property color darkForeground: "#C8C093"
  property color foreground: "#DCD7BA"
  property color darkerForeground: "#54546D"
  property color accent: "#223249"

  // kanagawa color scheme
  // https://github.com/rebelot/kanagawa.nvim
  //
  // | Name          |    Hex    | Usage                                                                             |
  // | :------------ | :-------: | :-------------------------------------------------------------------------------- |
  // | fujiWhite     | `#DCD7BA` | Default foreground                                                                |
  // | oldWhite      | `#C8C093` | Dark foreground (statuslines)                                                     |
  // | sumiInk0      | `#16161D` | Dark background (statuslines and floating windows)                                |
  // | sumiInk1      | `#1F1F28` | Default background                                                                |
  // | sumiInk2      | `#2A2A37` | Lighter background (colorcolumn, folds)                                           |
  // | sumiInk3      | `#363646` | Lighter background (cursorline)                                                   |
  // | sumiInk4      | `#54546D` | Darker foreground (line numbers, fold column, non-text characters), float borders |
  // | waveBlue1     | `#223249` | Popup background, visual selection background                                     |
  // | waveBlue2     | `#2D4F67` | Popup selection background, search background                                     |
  // | winterGreen   | `#2B3328` | Diff Add (background)                                                             |
  // | winterYellow  | `#49443C` | Diff Change (background)                                                          |
  // | winterRed     | `#43242B` | Diff Deleted (background)                                                         |
  // | winterBlue    | `#252535` | Diff Line (background)                                                            |
  // | autumnGreen   | `#76946A` | Git Add                                                                           |
  // | autumnRed     | `#C34043` | Git Delete                                                                        |
  // | autumnYellow  | `#DCA561` | Git Change                                                                        |
  // | samuraiRed    | `#E82424` | Diagnostic Error                                                                  |
  // | roninYellow   | `#FF9E3B` | Diagnostic Warning                                                                |
  // | waveAqua1     | `#6A9589` | Diagnostic Info                                                                   |
  // | dragonBlue    | `#658594` | Diagnostic Hint                                                                   |
  // | fujiGray      | `#727169` | Comments                                                                          |
  // | springViolet1 | `#938AA9` | Light foreground                                                                  |
  // | oniViolet     | `#957FB8` | Statements and Keywords                                                           |
  // | crystalBlue   | `#7E9CD8` | Functions and Titles                                                              |
  // | springViolet2 | `#9CABCA` | Brackets and punctuation                                                          |
  // | springBlue    | `#7FB4CA` | Specials and builtin functions                                                    |
  // | lightBlue     | `#A3D4D5` | Not used                                                                          |
  // | waveAqua2     | `#7AA89F` | Types                                                                             |
  // | springGreen   | `#98BB6C` | Strings                                                                           |
  // | boatYellow1   | `#938056` | Not used                                                                          |
  // | boatYellow2   | `#C0A36E` | Operators, RegEx                                                                  |
  // | carpYellow    | `#E6C384` | Identifiers                                                                       |
  // | sakuraPink    | `#D27E99` | Numbers                                                                           |
  // | waveRed       | `#E46876` | Standout specials 1 (builtin variables)                                           |
  // | peachRed      | `#FF5D62` | Standout specials 2 (exception handling, return)                                  |
  // | surimiOrange  | `#FFA066` | Constants, imports, booleans                                                      |
  // | katanaGray    | `#717C7C` | Deprecated                                                                        |
  //
}
