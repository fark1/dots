import QtQuick

Rectangle {
    id: card

    required property var entry
    property bool showActions: true

    signal dismissRequested()
    signal actionRequested(int index)

    readonly property var actions: entry ? JSON.parse(entry.actionsJson || "[]") : []
    readonly property bool critical: entry && entry.urgency === 2

    implicitHeight: content.implicitHeight + 16
    radius: 6
    color: "#0f1114"
    border.width: 1
    border.color: critical ? "#c0596b" : "#22262c"

    Column {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
        spacing: 4

        Row {
            width: parent.width

            Text {
                text: card.entry ? card.entry.appName : ""
                color: "#6b93c2"
                font.family: "Fairfax HD"
                font.pixelSize: 10
                elide: Text.ElideRight
                width: parent.width - closeIcon.width - 6
            }

            Item {
                width: 6
                height: 1
            }

            Text {
                id: closeIcon
                text: ""
                font.family: "Font Awesome 6 Free"
                font.weight: Font.Black
                font.pixelSize: 10
                color: closeArea.containsMouse ? "#e8e8e8" : "#888888"

                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.dismissRequested()
                }
            }
        }

        Text {
            text: card.entry ? card.entry.summary : ""
            color: "#e8e8e8"
            font.family: "Fairfax HD"
            font.pixelSize: 11
            wrapMode: Text.Wrap
            width: parent.width
        }

        Text {
            visible: card.entry && card.entry.body.length > 0
            text: card.entry ? card.entry.body : ""
            color: "#aaaaaa"
            font.family: "Fairfax HD"
            font.pixelSize: 10
            wrapMode: Text.Wrap
            width: parent.width
            maximumLineCount: 3
            elide: Text.ElideRight
        }

        Row {
            visible: card.showActions && card.actions.length > 0
            spacing: 6

            Repeater {
                model: card.actions

                Rectangle {
                    required property var modelData

                    radius: 4
                    color: "#1b1e24"
                    height: actionLabel.implicitHeight + 6
                    width: actionLabel.implicitWidth + 12

                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: parent.modelData.text
                        color: "#94F7C5"
                        font.family: "Fairfax HD"
                        font.pixelSize: 10
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.actionRequested(parent.modelData.index)
                    }
                }
            }
        }
    }
}
