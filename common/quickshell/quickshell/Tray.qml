import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Item {
    id: root

    required property var barWindow

    property var openItem: null

    readonly property int iconSize: 14

    width: trayRow.implicitWidth
    height: 24
    visible: (SystemTray.items.values ?? []).length > 0

    Row {
        id: trayRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Repeater {
            model: SystemTray.items

            delegate: Item {
                id: trayIcon

                required property var modelData

                width: root.iconSize
                height: root.iconSize
                anchors.verticalCenter: parent.verticalCenter

                readonly property string resolvedIcon: {
                    const raw = trayIcon.modelData.icon
                    if (!raw || !raw.includes("?path="))
                        return raw || ""
                    const parts = raw.split("?path=")
                    const name = parts[0]
                    const path = parts[1]
                    return Qt.resolvedUrl(path + "/" + name.slice(name.lastIndexOf("/") + 1))
                }

                Image {
                    id: iconImage
                    anchors.fill: parent
                    source: trayIcon.resolvedIcon
                    sourceSize: Qt.size(root.iconSize * 2, root.iconSize * 2)
                    fillMode: Image.PreserveAspectFit
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    visible: iconImage.status !== Image.Ready
                    text: ""
                    font.family: "Font Awesome 6 Free"
                    font.weight: Font.Black
                    font.pixelSize: root.iconSize - 2
                    color: "#aaaaaa"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (trayIcon.modelData.hasMenu) {
                            root.openItem = (root.openItem === trayIcon.modelData) ? null : trayIcon.modelData
                        } else if (mouse.button === Qt.LeftButton) {
                            trayIcon.modelData.activate()
                        }
                    }
                }
            }
        }
    }

    QsMenuOpener {
        id: menuOpener
        menu: root.openItem && root.openItem.hasMenu ? root.openItem.menu : null
    }

    PopupWindow {
        id: trayMenu

        visible: root.openItem !== null
        color: "transparent"
        implicitWidth: 180
        // Fixed size, same reasoning as NotificationCenter's historyPopup:
        // a menu whose contents arrive asynchronously item-by-item (Steam's
        // DBusMenu fetch, see the log - 16 separate layout updates) would
        // otherwise resize this mapped Wayland popup surface on every single
        // item, which corrupts the rendered buffer instead of resizing
        // cleanly. Content scrolls inside a Flickable instead.
        implicitHeight: 300

        anchor {
            window: root.barWindow
            item: root
            edges: Edges.Bottom | Edges.Left
            gravity: Edges.Bottom | Edges.Right
            margins { top: 6 }
        }

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: "#0b0c0e"
            border.width: 1
            border.color: "#22262c"

            Flickable {
                anchors.fill: parent
                anchors.margins: 4
                contentWidth: width
                contentHeight: menuColumn.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: menuColumn
                    width: parent.width

                    Repeater {
                        model: menuOpener.children

                        delegate: Item {
                            id: entryDelegate

                            required property var modelData

                            width: menuColumn.width
                            height: modelData.isSeparator ? 9 : (entryLabel.implicitHeight + 10)
                            visible: !modelData.hasChildren

                            Rectangle {
                                visible: entryDelegate.modelData.isSeparator
                                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 8 }
                                height: 1
                                color: "#22262c"
                            }

                            Text {
                                id: entryLabel
                                visible: !entryDelegate.modelData.isSeparator
                                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 8; rightMargin: 8 }
                                text: entryDelegate.modelData.text
                                color: entryDelegate.modelData.enabled ? "#e8e8e8" : "#555555"
                                font.family: "Fairfax HD"
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }

                            MouseArea {
                                visible: !entryDelegate.modelData.isSeparator && entryDelegate.modelData.enabled
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    entryDelegate.modelData.triggered()
                                    root.openItem = null
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
