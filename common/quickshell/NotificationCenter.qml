import QtQuick
import Quickshell

Item {
    id: root

    required property var barWindow

    readonly property int count: NotificationStore.count
    readonly property string badgeText: count > 9 ? "9+" : String(count)
    property bool open: false

    width: bellLabel.implicitWidth + 12
    height: 24

    Text {
        id: bellLabel
        anchors.centerIn: parent
        text: ""
        font.family: "Font Awesome 6 Free"
        font.weight: Font.Black
        font.pixelSize: 12
        color: root.count > 0 ? "#94F7C5" : "#ffffff"
    }

    Rectangle {
        visible: root.count > 0
        anchors { right: bellLabel.right; top: bellLabel.top; rightMargin: -7; topMargin: -5 }
        width: Math.max(badgeLabel.implicitWidth + 6, 12)
        height: 12
        radius: 6
        color: "#c0596b"

        Text {
            id: badgeLabel
            anchors.centerIn: parent
            text: root.badgeText
            color: "#ffffff"
            font.family: "Fairfax HD"
            font.pixelSize: 8
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.open = !root.open
            if (root.open)
                NotificationStore.dismissAllToasts()
        }
    }

    PopupWindow {
        id: historyPopup

        visible: root.open
        color: "transparent"
        implicitWidth: 300
        // fixed regardless of content: this is a real Wayland popup surface,
        // and resizing it every time a card is added/removed is what caused
        // the "warp" glitch (no animation smooths a native surface resize,
        // and its anchor position shifts with it). content scrolls inside
        // instead, same principle as the bar never animating its own
        // implicitHeight directly.
        implicitHeight: 220

        anchor {
            window: root.barWindow
            item: root
            edges: Edges.Bottom | Edges.Right
            gravity: Edges.Bottom | Edges.Left
            margins { top: 6 }
        }

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: "#0b0c0e"
            border.width: 1
            border.color: "#22262c"

            Column {
                id: headerColumn
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
                spacing: 6

                Row {
                    width: parent.width
                    height: 20

                    Text {
                        text: "Notifications"
                        color: "#e8e8e8"
                        font.family: "Fairfax HD"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - (clearLabel.visible ? clearLabel.implicitWidth + 8 : 0)
                    }

                    Text {
                        id: clearLabel
                        text: "clear all"
                        color: clearArea.containsMouse ? "#94F7C5" : "#888888"
                        font.family: "Fairfax HD"
                        font.pixelSize: 10
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.count >= 3

                        MouseArea {
                            id: clearArea
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NotificationStore.clearHistory()
                        }
                    }
                }

                Text {
                    visible: root.count === 0
                    text: "No notifications"
                    color: "#666666"
                    font.family: "Fairfax HD"
                    font.pixelSize: 10
                    width: parent.width
                }
            }

            Flickable {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: headerColumn.bottom
                    bottom: parent.bottom
                    leftMargin: 8
                    rightMargin: 8
                    topMargin: 6
                    bottomMargin: 8
                }
                contentWidth: width
                contentHeight: historyList.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: historyList
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: NotificationStore.history

                        delegate: NotificationCard {
                            id: historyCard

                            required property var modelData

                            width: historyList.width
                            showActions: true
                            entry: historyCard.modelData

                            onDismissRequested: NotificationStore.dismissNotification(historyCard.modelData.notifId)
                            onActionRequested: index => NotificationStore.invokeAction(historyCard.modelData.notifId, index)
                        }
                    }
                }
            }
        }
    }
}
