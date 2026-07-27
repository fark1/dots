pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    readonly property int historyLimit: 50
    readonly property int toastDefaultDuration: 6000

    readonly property ListModel history: ListModel {}
    readonly property int count: history.count

    // ordered newest-first queue of notification ids currently shown as toasts.
    // a real ListModel (not a JS array) so Repeater can add/remove individual
    // delegates instead of rebuilding the whole toast list on every change.
    readonly property ListModel toastQueue: ListModel {}
    // id -> live Notification object, kept alive via notification.tracked
    property var liveNotifications: ({})

    NotificationServer {
        id: server

        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyImagesSupported: true
        imageSupported: true
        persistenceSupported: false

        onNotification: notification => root.addNotification(notification)
    }

    function entryForId(id) {
        for (let i = 0; i < history.count; i++) {
            if (history.get(i).notifId === id)
                return history.get(i)
        }
        return null
    }

    function removeHistoryEntry(id) {
        for (let i = 0; i < history.count; i++) {
            if (history.get(i).notifId === id) {
                history.remove(i, 1)
                return
            }
        }
    }

    function addNotification(notification) {
        notification.tracked = true
        if (liveNotifications[notification.id] !== notification)
            notification.closed.connect(reason => root.onNotificationClosed(notification.id))
        liveNotifications[notification.id] = notification

        const actionsArr = []
        for (let i = 0; i < notification.actions.length; i++) {
            actionsArr.push({
                identifier: notification.actions[i].identifier,
                text: notification.actions[i].text,
                index: i
            })
        }

        const entry = {
            notifId: notification.id,
            appName: notification.appName || "Unknown",
            summary: notification.summary || "",
            body: notification.body || "",
            appIcon: notification.appIcon || "",
            image: notification.image || "",
            urgency: notification.urgency,
            expireTimeout: notification.expireTimeout,
            actionsJson: JSON.stringify(actionsArr),
            timestamp: Date.now()
        }

        // a notification id can be reused by the sender to update it in place
        removeHistoryEntry(notification.id)
        history.insert(0, entry)
        while (history.count > historyLimit)
            history.remove(history.count - 1, 1)

        removeQueuedToast(notification.id)
        toastQueue.insert(0, { notifId: notification.id })
    }

    function queuedToastIndex(id) {
        for (let i = 0; i < toastQueue.count; i++) {
            if (toastQueue.get(i).notifId === id)
                return i
        }
        return -1
    }

    function removeQueuedToast(id) {
        const idx = queuedToastIndex(id)
        if (idx !== -1)
            toastQueue.remove(idx, 1)
    }

    function onNotificationClosed(id) {
        const notification = liveNotifications[id]
        if (!notification)
            return
        // remove from the live map before touching tracked: setting tracked
        // to false can synchronously re-emit closed on the same call stack,
        // and this guard stops that re-entrant call from looping forever
        delete liveNotifications[id]
        dismissToast(id)
        notification.tracked = false
    }

    function dismissToast(id) {
        removeQueuedToast(id)
    }

    function dismissAllToasts() {
        toastQueue.clear()
    }

    function invokeAction(id, actionIndex) {
        const notification = liveNotifications[id]
        dismissToast(id)
        if (notification && notification.actions[actionIndex])
            notification.actions[actionIndex].invoke()
    }

    function dismissNotification(id) {
        const notification = liveNotifications[id]
        dismissToast(id)
        removeHistoryEntry(id)
        if (notification)
            notification.dismiss()
    }

    function clearHistory() {
        for (let i = 0; i < history.count; i++) {
            const notification = liveNotifications[history.get(i).notifId]
            if (notification)
                notification.dismiss()
        }
        history.clear()
        toastQueue.clear()
    }
}
