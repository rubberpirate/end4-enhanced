import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.services
import qs.modules.ii.notificationPopup
import qs.modules.ii.settings
import qs.modules.ii.bar

ShellRoot {
    id: root
    property bool failed: false
    property var stack: null
    property var standard: null
    function check(condition, message) {
        if (!condition) { failed = true; console.error("FAIL: " + message); }
    }
    NotificationPopup { id: popup }
    PanelWindow {
        id: barWindow
        anchors { top: true; left: true; right: true }
        implicitHeight: 380
        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        mask: Region { item: null }
        Loader { id: fixtureLoader; active: Config.ready; width: parent.width; sourceComponent: BarContent { id: barContent; height: 36 } }
    }
    DashboardSettingsCatalog { id: catalog }
    Connections {
        target: Notifications
        function onNotify(notification) {
            if (!["Bubble test"].includes(notification.appName)) {
                Notifications.discardNotification(notification.notificationId);
                return;
            }
            console.log("TEST NOTIFICATION", notification.notificationId, notification.summary);
        }
    }
    Process {
        id: sender
        stderr: StdioCollector { onStreamFinished: { if (text) console.log("SENDER:", text); } }
        property int expiry: 0
        command: ["gdbus", "call", "--session", "--dest", "org.freedesktop.Notifications", "--object-path", "/org/freedesktop/Notifications", "--method", "org.freedesktop.Notifications.Notify", "Bubble test", "0", "", "Deployed to staging", "v1.4.0 is live", '["view", "View"]', "{}", String(expiry)]
    }
    Timer {
        interval: 900; running: true
        onTriggered: {
            root.check(Config.ready, "configuration loaded");
            root.check(Config.options.notifications.style === "standard", "standard is the default");
            root.standard = popup.popupWindow;
            root.stack = fixtureLoader.item.notificationBubbles;
            root.check(root.standard !== null && root.stack !== null, "both popup styles instantiate");
            Config.options.bar.cornerStyle = 4;
            Config.options.bar.layouts.leftLayout = [];
            Config.options.bar.layouts.rightLayout = [];
            Config.options.bar.layouts.middleLayout = ["dynamicIsland"];
            root.check(GlobalStates.dynamicIslandEnabled, "dynamic island detected");
            catalog.custom["bar:Popup style"].set("bubble");
            sender.running = true;
        }
    }
    Timer {
        interval: 1900; running: true
        onTriggered: {
            root.check(Notifications.popupList.length === 1, "DBus notification delivered");
            root.check(root.stack.active && !root.standard.visible, "bubble displays with dynamic island enabled");
            root.check(root.stack.cards.length === 1, "service notification becomes a bubble card");
            const card = root.stack.cards[0];
            root.check(card.actions[0].text === "View", "DBus action label preserved");
            card.invoke(card.notificationId, "view");
            root.check(Notifications.list.length === 0, "bubble action invokes service and dismisses notification");
        }
    }
    Timer {
        interval: 3700; running: true
        onTriggered: {
            root.check(!root.stack.active, "window closes after final return");
            sender.running = true;
        }
    }
    Timer {
        interval: 4500; running: true
        onTriggered: {
            catalog.custom["bar:Popup style"].set("standard");
            root.check(!root.stack.active, "style switch clears hidden bubble animations");
            Config.options.bar.layouts.middleLayout = ["clockWidget"];
        }
    }
    Timer {
        interval: 4900; running: true
        onTriggered: {
            root.check(root.standard.visible, "standard popup still works");
            Config.options.notifications.style = "bubble";
        }
    }
    Timer {
        interval: 5700; running: true
        onTriggered: {
            root.check(root.stack.active && !root.standard.visible, "switching back restores bubble popup");
            root.check(root.stack.anchorItem === fixtureLoader.item.notificationAnchor, "uses the actual bar island");
            root.check(root.stack.anchorWidth === fixtureLoader.item.notificationAnchor.width, "drop follows the island width");
            root.check(root.stack.parent === fixtureLoader.item, "bubbles live inside the bar");
            GlobalStates.screenLocked = true;
            root.check(!root.stack.active, "locking clears visible bubble content");
            Notifications.timeoutAll();
            GlobalStates.screenLocked = false;
        }
    }
    Timer {
        interval: 6000; running: true
        onTriggered: {
            root.check(!root.stack.active, "expired notification does not reappear after unlocking");
            sender.expiry = 600;
            sender.running = true;
        }
    }
    Timer {
        interval: 8500; running: true
        onTriggered: {
            root.check(!root.stack.active && Notifications.popupList.length === 0, "service timeout completes liquid exit");
            root.check(Notifications.list.length > 0, "timed-out notifications remain in history");
            console.log(root.failed ? "INTEGRATION CHECK FAILED" : "INTEGRATION CHECK PASSED");
            Qt.quit();
        }
    }
}
