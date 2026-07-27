import QtQuick
import QtQuick.Layouts
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

            // ── Left: workspace dots ──────────────────────────────────
            Row {
                anchors {
                    left: parent.left
                    leftMargin: 8
                    verticalCenter: parent.verticalCenter
                }
                spacing: 14

                Repeater {
                    model: 4

                    Item {
                        width:  dotLabel.implicitWidth + 6
                        height: 24

                        Text {
                            id: dotLabel
                            readonly property int  wsNum:  index + 1
                            readonly property bool active: wsNum === bar.activeWs
                            anchors.centerIn: parent
                            text:  active ? "*" : "."
                            color: active ? "#94F7C5" : "#ffffff"
                            font.family:    "Fairfax HD"
                            font.pixelSize: 11
                            renderType:     Text.NativeRendering
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape:  Qt.PointingHandCursor
                            onClicked: {
                                bar.activeWs = dotLabel.wsNum
                                if (!wsSwitcher.running) {
                                    wsSwitcher.targetWs = dotLabel.wsNum
                                    wsSwitcher.running  = true
                                }
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

                text:  h12 + ":" + mins + " " + ampm + "  " + Qt.formatDate(clock.date, "dd MMM yyyy")
                color: "#6b93c2"
                font.family:    "Fairfax HD"
                font.pixelSize: 11
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
                    width:  volLabel.implicitWidth + 12
                    height: 24

                    Text {
                        id: volLabel
                        anchors.centerIn: parent
                        text:  "vol " + bar.volume
                        color: "#aaaaaa"
                        font.family:    "Fairfax HD"
                        font.pixelSize: 11
                        renderType:     Text.NativeRendering
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    if (!pavuProc.running) pavuProc.running = true
                    }
                }
            }
        }
    }
}
