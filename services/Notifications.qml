pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications

/**
 * Provides extra features not in Quickshell.Services.Notifications:
 *  - Persistent storage
 *  - Popup notifications, with timeout
 *  - Notification groups by app
 */
Singleton {
	id: root
    component Notif: QtObject {
        id: wrapper
        required property int notificationId // Could just be `id` but it conflicts with the default prop in QtObject
        property Notification notification
        property list<var> actions: notification?.actions.map((action) => ({
            "identifier": action.identifier,
            "text": action.text,
        })) ?? []
        property bool popup: false
        property bool isTransient: notification?.hints.transient ?? false
        property string appIcon: notification?.appIcon ?? ""
        property string appName: notification?.appName ?? ""
        property string desktopEntry: notification?.desktopEntry ?? ""
        property string body: notification?.body ?? ""
        property string image: notification?.image ?? ""
        property string summary: notification?.summary ?? ""
        property double time
        property string urgency: notification?.urgency.toString() ?? "normal"
        property Timer timer
        property bool popupPresented: false
        property double popupStartedAt: 0

        onNotificationChanged: {
            if (notification === null) {
                root.discardNotification(notificationId);
            }
        }
    }

    function notifToJSON(notif) {
        return {
            "notificationId": notif.notificationId,
            "actions": notif.actions,
            "appIcon": notif.appIcon,
            "appName": notif.appName,
            "desktopEntry": notif.desktopEntry,
            "body": notif.body,
            "image": notif.image,
            "summary": notif.summary,
            "time": notif.time,
            "urgency": notif.urgency,
        }
    }
    function notifToString(notif) {
        return JSON.stringify(notifToJSON(notif), null, 2);
    }

    component NotifTimer: Timer {
        required property int notificationId
        property int requestedTimeout: -1
        interval: requestedTimeout < 0 ? Config.options.notifications.timeout : requestedTimeout
        running: !root.bubbleMode
        onIntervalChanged: {
            const notification = root.list.find(notif => notif.notificationId === notificationId);
            if (running && notification) notification.popupStartedAt = Date.now();
        }
        onTriggered: () => {
            const index = root.list.findIndex((notif) => notif.notificationId === notificationId);
            // Already dismissed or discarded while the timer was running
            if (index === -1) {
                destroy();
                return;
            }
            const notifObject = root.list[index];
            print("[Notifications] Notification timer triggered for ID: " + notificationId + ", transient: " + notifObject?.isTransient);
            if (notifObject.isTransient) root.discardNotification(notificationId);
            else root.timeoutNotification(notificationId);
            destroy()
        }
    }

    property bool silent: false
    readonly property bool bubbleMode: Config.options.notifications.style === "bubble" && !Config.options.bar.vertical
    readonly property string popupPosition: {
        const value = Config.options.notifications.position;
        if (value === "top") return "top_right";
        if (value === "bottom") return "bottom_right";
        return ["top_left", "top_center", "top_right", "bottom_left", "bottom_center", "bottom_right"].includes(value) ? value : "top_right";
    }
    readonly property bool bubbleFromBar: bubbleMode && popupPosition === (Config.options.bar.bottom ? "bottom_center" : "top_center")
    property int unread: 0
    property var filePath: Directories.notificationsPath
    property list<Notif> list: []
    property var popupList: list.filter((notif) => notif.popup);
    property bool popupInhibited: (GlobalStates?.sidebarRightOpen ?? false) || silent
    property var latestTimeForApp: ({})
    onBubbleModeChanged: {
        for (const notification of popupList) {
            notification.popupPresented = false;
            if (bubbleMode) notification.timer?.stop();
            else restartPopupTimeout(notification.notificationId);
        }
    }
    Component {
        id: notifComponent
        Notif {}
    }
    Component {
        id: notifTimerComponent
        NotifTimer {}
    }

    function stringifyList(list) {
        return JSON.stringify(list.map((notif) => notifToJSON(notif)), null, 2);
    }
    
    onListChanged: {
        // Update latest time for each app
        root.list.forEach((notif) => {
            if (!root.latestTimeForApp[notif.appName] || notif.time > root.latestTimeForApp[notif.appName]) {
                root.latestTimeForApp[notif.appName] = Math.max(root.latestTimeForApp[notif.appName] || 0, notif.time);
            }
        });
        // Remove apps that no longer have notifications
        Object.keys(root.latestTimeForApp).forEach((appName) => {
            if (!root.list.some((notif) => notif.appName === appName)) {
                delete root.latestTimeForApp[appName];
            }
        });
    }

    function appNameListForGroups(groups) {
        return Object.keys(groups).sort((a, b) => {
            // Sort by time, descending
            return groups[b].time - groups[a].time;
        });
    }

    function groupsForList(list) {
        const groups = {};
        list.forEach((notif) => {
            if (!groups[notif.appName]) {
                groups[notif.appName] = {
                    appName: notif.appName,
                    appIcon: notif.appIcon,
                    notifications: [],
                    time: 0
                };
            }
            groups[notif.appName].notifications.push(notif);
            // Always set to the latest time in the group
            groups[notif.appName].time = latestTimeForApp[notif.appName] || notif.time;
        });
        return groups;
    }

    property var groupsByAppName: groupsForList(root.list)
    property var popupGroupsByAppName: groupsForList(root.popupList)
    property list<string> appNameList: appNameListForGroups(root.groupsByAppName)
    property list<string> popupAppNameList: appNameListForGroups(root.popupGroupsByAppName)

    // Quickshell's notification IDs starts at 1 on each run, while saved notifications
    // can already contain higher IDs. This is for avoiding id collisions
    property int idOffset
    signal initDone();
    signal notify(notification: var);
    signal discard(id: int);
    signal discardAll();
    signal timeout(id: var);

	NotificationServer {
        id: notifServer
        // actionIconsSupported: true
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        bodySupported: true
        imageSupported: true
        keepOnReload: false
        persistenceSupported: true

        onNotification: (notification) => {
            notification.tracked = true
            const newNotifObject = notifComponent.createObject(root, {
                "notificationId": notification.id + root.idOffset,
                "notification": notification,
                "time": Date.now(),
            });
			root.list = [...root.list, newNotifObject];

            // Popup
            if (!root.popupInhibited) {
                newNotifObject.popup = true;
                if (notification.expireTimeout != 0) {
                    newNotifObject.timer = notifTimerComponent.createObject(root, {
                        "notificationId": newNotifObject.notificationId,
                        "requestedTimeout": notification.expireTimeout,
                    });
                    newNotifObject.popupStartedAt = Date.now();
                }
                root.unread++;
            }
            root.notify(newNotifObject);
            // console.log(notifToString(newNotifObject));
            notifFileView.setText(stringifyList(root.list));
        }
    }

    function markAllRead() {
        root.unread = 0;
    }

    function discardNotification(id) {
        root.discardNotifications([id]);
    }

    function discardNotifications(ids) {
        console.log("[Notifications] Discarding notifications with IDs: " + ids.join(", "));
        const idSet = new Set(ids);
        root.list.filter(notif => idSet.has(notif.notificationId)).forEach(notif => {
            notif.timer?.stop();
            notif.timer?.destroy();
            notif.timer = null;
        });
        // Assign a new array instead of splicing: on a list<> property, splice()
        // shifts the following elements one by one and emits listChanged for each,
        // re-running the grouping and every model bound to the list each time.
        const remaining = root.list.filter((notif) => !idSet.has(notif.notificationId));
        if (remaining.length !== root.list.length) {
            root.list = remaining;
            notifFileView.setText(stringifyList(root.list));
        }
        notifServer.trackedNotifications.values
            .filter((notif) => idSet.has(notif.id + root.idOffset))
            .forEach((notif) => notif.dismiss());
        ids.forEach((id) => root.discard(id)); // Emit signal
    }

    function discardAllNotifications() {
        root.list.forEach(notif => { notif.timer?.stop(); notif.timer?.destroy(); notif.timer = null; });
        root.list = []
        triggerListChange()
        notifFileView.setText(stringifyList(root.list));
        notifServer.trackedNotifications.values.forEach((notif) => {
            notif.dismiss()
        })
        root.discardAll();
    }

    function cancelTimeout(id) {
        const index = root.list.findIndex((notif) => notif.notificationId === id);
        if (root.list[index] != null && root.list[index].timer != null)
            root.list[index].timer.stop();
    }

    function restartPopupTimeout(id) {
        const notification = root.list.find(notif => notif.notificationId === id);
        if (!notification?.popup || !notification.timer) return;
        notification.popupStartedAt = Date.now();
        notification.timer.restart();
    }

    function presentPopup(id) {
        const notification = root.list.find(notif => notif.notificationId === id);
        if (!notification?.popup || notification.popupPresented) return;
        notification.popupPresented = true;
        restartPopupTimeout(id);
    }

    function suspendPopup(id) {
        const notification = root.list.find(notif => notif.notificationId === id);
        if (!notification) return;
        notification.popupPresented = false;
        if (root.bubbleMode) notification.timer?.stop();
    }

    function activateNotification(id) {
        const notification = root.list.find(notif => notif.notificationId === id);
        if (!notification) return false;
        const hasDefaultAction = notification.actions.some(action => action.identifier === "default");
        const normalize = value => (value ?? "").toLowerCase().replace(/\.desktop$/, "").replace(/[ _-]/g, "");
        const desktopId = notification.desktopEntry.replace(/\.desktop$/, "");
        const entry = (desktopId ? DesktopEntries.byId(desktopId) : null)
            ?? DesktopEntries.applications.values.find(app => normalize(app.name) === normalize(notification.appName));
        const names = [desktopId, notification.appName, entry?.id, entry?.startupClass, entry?.name].filter(Boolean).map(normalize);
        const toplevels = ToplevelManager.toplevels.values.filter(win => names.includes(normalize(win.appId)));
        const toplevel = toplevels.find(win => win.activated) ?? toplevels[0];
        const window = WM.windowList.find(win => names.includes(normalize(win.appId)));
        // Default actions can select a tab/document but cannot always raise their app on Wayland.
        if (toplevel) toplevel.activate();
        else if (window) WM.focusWindow(window.id);
        if (hasDefaultAction && root.attemptInvokeAction(id, "default")) return true;
        if (!toplevel && !window) {
            if (!entry) return false;
            entry.execute();
        }
        root.timeoutNotification(id);
        return true;
    }

    function timeoutNotification(id) {
        const index = root.list.findIndex((notif) => notif.notificationId === id);
        if (root.list[index] != null)
        {
            root.list[index].popup = false;
            root.list[index].timer?.stop();
        }
        root.timeout(id);
    }

    function timeoutAll() {
        root.popupList.forEach((notif) => {
            root.timeout(notif.notificationId);
        })
        root.popupList.forEach((notif) => {
            notif.timer?.stop();
            notif.popup = false;
        });
    }

    function attemptInvokeAction(id, notifIdentifier) {
        console.log("[Notifications] Attempting to invoke action with identifier: " + notifIdentifier + " for notification ID: " + id);
        const notifServerIndex = notifServer.trackedNotifications.values.findIndex((notif) => notif.id + root.idOffset === id);
        console.log("Notification server index: " + notifServerIndex);
        if (notifServerIndex !== -1) {
            const notifServerNotif = notifServer.trackedNotifications.values[notifServerIndex];
            const action = notifServerNotif.actions.find((action) => action.identifier === notifIdentifier);
            // console.log("Action found: " + JSON.stringify(action));
            if (action) {
                action.invoke();
                root.discardNotification(id);
                return true;
            } else {
                console.warn("[Notifications] Action not found:", notifIdentifier);
            }
        } 
        else {
            console.log("Notification not found in server: " + id)
        }
        return false;
    }

    function triggerListChange() {
        root.list = root.list.slice(0)
    }

    function refresh() {
        notifFileView.reload()
    }

    Component.onCompleted: {
        refresh()
    }

    FileView {
        id: notifFileView
        path: Qt.resolvedUrl(filePath)
        onLoaded: {
            try {
                const fileContents = notifFileView.text()
                root.list = JSON.parse(fileContents).map((notif) => {
                    return notifComponent.createObject(root, {
                        "notificationId": notif.notificationId,
                        "actions": [], // Notification actions are meaningless if they're not tracked by the server or the sender is dead
                        "appIcon": notif.appIcon,
                        "appName": notif.appName,
                        "desktopEntry": notif.desktopEntry ?? "",
                        "body": notif.body,
                        "image": notif.image,
                        "summary": notif.summary,
                        "time": notif.time,
                        "urgency": notif.urgency,
                    });
                });
                // Find largest notificationId
                let maxId = 0
                root.list.forEach((notif) => {
                    maxId = Math.max(maxId, notif.notificationId)
                })

                root.idOffset = maxId
                root.initDone()
            } catch (e) {
                console.error("[Notifications] Failed to parse notifications file, resetting:", e)
                root.list = []
                notifFileView.setText(stringifyList(root.list))
                root.idOffset = 0
                root.initDone()
            }
        }
        onLoadFailed: (error) => {
            if(error == FileViewError.FileNotFound) {
                console.log("[Notifications] File not found, creating new file.")
                root.list = []
                notifFileView.setText(stringifyList(root.list));
            } else {
                console.log("[Notifications] Error loading file: " + error)
            }
        }
    }
}
