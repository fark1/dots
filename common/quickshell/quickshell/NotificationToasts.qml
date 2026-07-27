import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: toastWindow

    readonly property int toastWidth: 300

    anchors { top: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    implicitWidth: toastWidth + 20
    implicitHeight: screen ? screen.height : 1080
    visible: NotificationStore.toastQueue.count > 0
    mask: Region { item: toastColumn }

    Component.onCompleted: {
        if (WlrLayershell != null) {
            WlrLayershell.namespace = "quickshell-notifications"
            WlrLayershell.layer = WlrLayer.Overlay
        }
    }

    Column {
        id: toastColumn
        // 24px bar height + 8px gap, so toasts never overlap the bar
        anchors { top: parent.top; right: parent.right; topMargin: 32; rightMargin: 10 }
        spacing: 8
        width: toastWindow.toastWidth

        Repeater {
            model: NotificationStore.toastQueue

            delegate: Item {
                id: toastDelegate

                required property var modelData
                readonly property var entry: NotificationStore.entryForId(modelData.notifId)

                width: toastColumn.width
                height: entry ? card.implicitHeight : 0
                visible: entry !== null
                clip: true

                Behavior on height {
                    NumberAnimation { duration: 150; easing.type: Easing.InOutCubic }
                }

                NotificationCard {
                    id: card
                    width: parent.width
                    entry: toastDelegate.entry

                    onDismissRequested: NotificationStore.dismissToast(toastDelegate.modelData.notifId)
                    onActionRequested: index => NotificationStore.invokeAction(toastDelegate.modelData.notifId, index)
                }

                Timer {
                    running: toastDelegate.entry !== null && toastDelegate.entry.expireTimeout !== 0
                    interval: {
                        const entry = toastDelegate.entry
                        if (!entry)
                            return NotificationStore.toastDefaultDuration
                        return entry.expireTimeout > 0 ? entry.expireTimeout : NotificationStore.toastDefaultDuration
                    }
                    onTriggered: NotificationStore.dismissToast(toastDelegate.modelData.notifId)
                }
            }
        }
    }
}
