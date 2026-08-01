import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io

ShellRoot {

    // ── Notification toasts (top-right overlay, independent of the bar) ───
    NotificationToasts {}

    // ── Clock ────────────────────────────────────────────────────────────
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // ── Workspace switcher (dot clicks → ydotool Super+F1-4) ─────────────
    // KEY_LEFTMETA=125  KEY_F1=59 F2=60 F3=61 F4=62
    Process {
        id: wsSwitcher
        property int targetWs: 1
        property var fKeys: [59, 60, 61, 62]
        command: {
            var fk = fKeys[targetWs - 1]
            return ["bash", "-c",
                "YDOTOOL_SOCKET=/tmp/.ydotool_socket ydotool key 125:1 " + fk + ":1 " + fk + ":0 125:0"]
        }
    }

    // ── Volume poll (every 1s) ────────────────────────────────────────────
    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: { if (!volQuery.running) volQuery.running = true }
    }

    Process {
        id: volQuery
        command: ["pactl", "get-sink-volume", "@DEFAULT_SINK@"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                var m = data.match(/(\d+)%/)
                if (m) bar.volume = m[1] + "%"
            }
        }
    }

    // ── Volume adjust (Ctrl+Super+scroll over the volume widget) ──────────
    Process {
        id: volAdjust
        property string delta: "+5%"
        command: ["pactl", "set-sink-volume", "@DEFAULT_SINK@", delta]
    }

    // ── pavucontrol launcher ──────────────────────────────────────────────
    Process {
        id: pavuProc
        command: ["pavucontrol"]
    }

    // ── Bar IPC ───────────────────────────────────────────────────────────
    IpcHandler {
        target: "bar"

        function toggle(): void {
            if (bar.shown) {
                bar.shown = false
                hideTimer.start()
            } else {
                bar.exclusionMode  = ExclusionMode.Auto
                bar.implicitHeight = 24
                showTimer.start()
            }
        }

        function setWs(ws: string): void {
            var n = parseInt(ws)
            if (n >= 1 && n <= 4) bar.activeWs = n
        }

        function wsNext(): void {
            bar.activeWs = bar.activeWs < 4 ? bar.activeWs + 1 : 1
        }

        function wsPrev(): void {
            bar.activeWs = bar.activeWs > 1 ? bar.activeWs - 1 : 4
        }
    }

    // ── Bar ──────────────────────────────────────────────────────────────
    PanelWindow {
        id: bar

        anchors {
            top: true
            left: true
            right: true
        }

        property bool   shown:    true
        property int    activeWs: 1
        property string volume:   "–"

        implicitHeight: 24
        exclusionMode:  ExclusionMode.Auto
        color:          "transparent"

        Timer {
            id: hideTimer
            interval: 320
            onTriggered: {
                bar.exclusionMode  = ExclusionMode.Ignore
                bar.implicitHeight = 0
            }
        }

        Timer {
            id: showTimer
            interval: 16
            onTriggered: bar.shown = true
        }

        Item {
            id: content
            width:  parent.width
            height: 24

            y:       bar.shown ? 0 : -24
            opacity: bar.shown ? 1.0 : 0.0

            Behavior on y       { NumberAnimation { duration: 300; easing.type: Easing.InOutCubic } }
            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutCubic } }

            Rectangle {
                anchors.fill: parent
                color: "#07080a"
            }

            // ── Left: workspace shapes ──────────────────────────────────
            Row {
                anchors {
                    left: parent.left
                    leftMargin: 8
                    verticalCenter: parent.verticalCenter
                }
                spacing: 14

                Repeater {
                    model: ["triangle", "square", "hexagon", "pentagon"]

                    Item {
                        id: wsIcon

                        required property string modelData
                        required property int    index

                        readonly property int  wsNum:  index + 1
                        readonly property bool active: wsNum === bar.activeWs

                        // per-shape inactive color: triangle, square, hexagon, pentagon
                        readonly property var    inactiveColors: ["#e05f65", "#78dba9", "#f1cf8a", "#c68aee"]
                        readonly property string inactiveColor:  inactiveColors[index]

                        width:  20
                        height: 24

                        // Solid fill: the shape's own color when inactive, black
                        // when active - the outline layer below adds the accent
                        // color back on top so the selected icon isn't just a
                        // flat black blob.
                        Image {
                            id: shapeSource
                            anchors.centerIn: parent
                            width:  14
                            height: 14
                            source: Qt.resolvedUrl("icons/" + wsIcon.modelData + ".svg")
                            sourceSize: Qt.size(28, 28)
                            visible: false
                        }

                        MultiEffect {
                            id: shapeEffect
                            anchors.fill: shapeSource
                            source: shapeSource
                            colorization: 1.0
                            colorizationColor: wsIcon.active ? "#000000" : wsIcon.inactiveColor

                            Behavior on colorizationColor {
                                ColorAnimation { duration: 150 }
                            }

                            RotationAnimation {
                                id: spinAnim
                                target: shapeEffect
                                from: 0
                                to: 360
                                duration: 400
                                easing.type: Easing.OutBack
                            }
                        }

                        // Outline: only shown for the active workspace, drawn on
                        // top of the black fill in the shape's own accent color.
                        Image {
                            id: outlineSource
                            anchors.centerIn: parent
                            width:  14
                            height: 14
                            source: Qt.resolvedUrl("icons/" + wsIcon.modelData + "-outline.svg")
                            sourceSize: Qt.size(28, 28)
                            visible: false
                        }

                        MultiEffect {
                            id: outlineEffect
                            anchors.fill: outlineSource
                            source: outlineSource
                            colorization: 1.0
                            colorizationColor: wsIcon.inactiveColor
                            visible: wsIcon.active

                            RotationAnimation {
                                id: outlineSpinAnim
                                target: outlineEffect
                                from: 0
                                to: 360
                                duration: 400
                                easing.type: Easing.OutBack
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape:  Qt.PointingHandCursor
                            onClicked: {
                                bar.activeWs = wsIcon.wsNum
                                if (!wsSwitcher.running) {
                                    wsSwitcher.targetWs = wsIcon.wsNum
                                    wsSwitcher.running  = true
                                }
                                spinAnim.restart()
                                outlineSpinAnim.restart()
                            }
                        }
                    }
                }
            }

            // ── Center: clock ─────────────────────────────────────────
            Text {
                anchors.centerIn: parent

                readonly property int    h12:  { var h = clock.hours % 12; return h === 0 ? 12 : h }
                readonly property string ampm: clock.hours >= 12 ? "PM" : "AM"
                readonly property string mins: clock.minutes < 10 ? "0" + clock.minutes : "" + clock.minutes

                text:  h12 + ":" + mins + " " + ampm
                color: "#6b93c2"
                font.family:    "SF Pro Display"
                font.weight:    600
                font.pixelSize: 12
                renderType:     Text.NativeRendering
                height: 24
                verticalAlignment: Text.AlignVCenter
            }

            // ── Right: tray, notifications, volume ─────────────────────
            Row {
                anchors {
                    right: parent.right
                    rightMargin: 8
                    verticalCenter: parent.verticalCenter
                }
                spacing: 14

                Tray {
                    barWindow: bar
                }

                NotificationCenter {
                    barWindow: bar
                }

                Item {
                    id: volWidget

                    property bool hovered: false

                    // icon + left/right padding, plus the percentage label's
                    // width only when hover-revealed
                    width:  14 + 12 + (hovered ? volLabel.implicitWidth + 6 : 0)
                    height: 24

                    Behavior on width {
                        NumberAnimation { duration: 150; easing.type: Easing.InOutCubic }
                    }

                    Image {
                        id: volIconSource
                        anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
                        width:  14
                        height: 14
                        source: Qt.resolvedUrl("icons/volume.svg")
                        sourceSize: Qt.size(28, 28)
                        visible: false
                    }

                    MultiEffect {
                        id: volIconEffect
                        anchors.fill: volIconSource
                        source: volIconSource
                        colorization: 1.0
                        colorizationColor: "#aaaaaa"
                    }

                    Text {
                        id: volLabel
                        anchors { left: volIconEffect.right; leftMargin: 6; verticalCenter: parent.verticalCenter }
                        text:  bar.volume
                        color: "#aaaaaa"
                        font.family:    "Fairfax HD"
                        font.pixelSize: 11
                        renderType:     Text.NativeRendering
                        opacity: volWidget.hovered ? 1.0 : 0.0
                        visible: opacity > 0

                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape:  Qt.PointingHandCursor
                        hoverEnabled: true
                        onEntered: volWidget.hovered = true
                        onExited:  volWidget.hovered = false
                        onClicked: if (!pavuProc.running) pavuProc.running = true

                        onWheel: wheel => {
                            if (!(wheel.modifiers & Qt.ControlModifier) || !(wheel.modifiers & Qt.MetaModifier))
                                return
                            volAdjust.delta = wheel.angleDelta.y > 0 ? "+5%" : "-5%"
                            if (!volAdjust.running) volAdjust.running = true
                            if (!volQuery.running) volQuery.running = true
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text:  Qt.formatDate(clock.date, "ddd, dd MMM yyyy")
                    color: "#6b93c2"
                    font.family:    "SF Pro Display"
                    font.weight:    600
                    font.pixelSize: 12
                    renderType:     Text.NativeRendering
                }
            }
        }
    }
}
