import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.services
import qs.modules.ii.notificationPopup
import qs.modules.ii.bar

ShellRoot {
    id: root
    property bool failed: false
    property var stack: popup.bubbleWindow.stack
    property var positions: ["top_left", "top_center", "top_right", "bottom_left", "bottom_center", "bottom_right"]
    property int positionIndex: 0
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
        Loader { id: fixture; active: Config.ready; width: parent.width; sourceComponent: BarContent { id: barContent; height: 36 } }
    }
    Connections {
        target: Notifications
        function onNotify(notification) {
            if (!["Queue test", "Bubble Source", "Positions"].includes(notification.appName)) {
                Notifications.discardNotification(notification.notificationId);
                return;
            }
            console.log("TEST NOTIFICATION", notification.notificationId, notification.summary);
        }
    }
    Process {
        id: sender
        stderr: StdioCollector { onStreamFinished: { if (text) console.log("SENDER:", text); } }
        property string mode: "queue"
        command: ["python3", Quickshell.env("BUBBLE_TEST_ROOT") + "/send.py", mode]
    }
    Timer {
        interval: 700; running: true
        onTriggered: {
            Config.options.notifications.style = "bubble";
            Config.options.notifications.position = "top_right";
            Config.options.notifications.timeout = 2500;
            sender.running = true;
        }
    }
    property int phase: 0
    property string focusedWindow: ""
    QtObject {
        id: fakeWindowManager
        property var windowList: [{ id: "source-window", appId: "end4-bubble-source" }]
        function focusWindow(id) { root.focusedWindow = id; }
    }
    Timer {
        interval: 100; repeat: true; running: true
        onTriggered: {
            if (root.phase === 0 && root.stack.cards.length === 3 && root.stack.counterCard) {
                root.check(root.stack.overflowCount === 3, "three waiting notifications in bottom count");
                root.check(Notifications.popupList.length === 6, "queue has retained every notification");
                const visible = root.stack.cards.map(card => card.notificationId);
                root.check(Notifications.popupList.filter(n => !visible.includes(n.notificationId)).every(n => !n.timer.running && !n.popupPresented), "hidden notification timers never started");
                root.phase = 1;
            } else if (root.phase === 1) {
                const promoted = Notifications.list.find(n => n.summary === "Queued 4");
                if (!promoted?.popupPresented) return;
                root.check(promoted.popup && promoted.timer.running, "promoted card starts its own timeout");
                root.check(promoted.popupStartedAt - promoted.time > 2500, "timeout starts on reveal rather than receipt");
                Config.options.notifications.timeout = 1400;
                root.check(promoted.timer.interval === 1400, "settings timeout applies to current and queued notifications");
                Notifications.timeoutAll();
                root.phase = 2;
            } else if (root.phase === 2 && !root.stack.active) {
                sender.mode = "source"; sender.running = true; root.phase = 3;
            } else if (root.phase === 3 || root.phase === 4) {
                const notification = Notifications.popupList.find(n => n.summary === "source" && n.popupPresented);
                if (!notification) return;
                root.check(notification.desktopEntry === "end4-bubble-source", "source desktop entry preserved");
                if (root.phase === 3) {
                    const card = root.stack.cards.find(c => c.notificationId === notification.notificationId);
                    card.activate(card.notificationId);
                    root.check(!notification.popup, "click opens the source and closes popup");
                    sender.running = true;
                    root.phase = 4;
                } else {
                    const original = WM.backend;
                    WM.backend = fakeWindowManager;
                    Notifications.activateNotification(notification.notificationId);
                    root.check(root.focusedWindow === "source-window", "click focuses the existing source window");
                    WM.backend = original;
                    root.phase = 5;
                }
            } else if (root.phase === 5 && !root.stack.active) {
                sender.mode = "default"; sender.running = true; root.phase = 6;
            } else if (root.phase === 6) {
                const notification = Notifications.popupList.find(n => n.summary === "default" && n.popupPresented);
                if (!notification) return;
                const card = root.stack.cards.find(c => c.notificationId === notification.notificationId);
                const original = WM.backend;
                WM.backend = fakeWindowManager;
                root.focusedWindow = "";
                card.activate(card.notificationId);
                root.check(root.focusedWindow === "source-window", "default action also focuses its source window");
                WM.backend = original;
                root.check(!Notifications.list.some(n => n.notificationId === notification.notificationId), "click invokes the app's default action");
                root.phase = 7;
            } else if (root.phase === 7 && !root.stack.active) {
                sender.mode = "positions"; sender.running = true; positionChecks.start();
                root.phase = 8;
                stop();
            }
        }
    }
    Timer {
        id: positionChecks
        interval: 400; repeat: true
        onTriggered: {
            if (root.positionIndex > 0) {
                const position = root.positions[root.positionIndex - 1];
                const embedded = fixture.item.notificationBubbles;
                if (position === "top_center") {
                    root.check(embedded.active && !popup.bubbleWindow.visible, "top center uses existing bar island");
                } else {
                    root.check(popup.bubbleWindow.visible && !embedded.active, position + " uses positioned bubble stack");
                    root.check(popup.bubbleWindow.anchors.top === position.startsWith("top"), position + " vertical anchor");
                    root.check(popup.bubbleWindow.anchors.left === position.endsWith("left"), position + " left anchor");
                    root.check(popup.bubbleWindow.anchors.right === position.endsWith("right"), position + " right anchor");
                    root.check(root.stack.growUp === position.startsWith("bottom"), position + " correct animation direction");
                }
            }
            if (root.positionIndex < root.positions.length) {
                Config.options.notifications.position = root.positions[root.positionIndex++];
            } else {
                stop();
                console.log(root.failed ? "INTEGRATION CHECK FAILED" : "INTEGRATION CHECK PASSED");
                Qt.quit();
            }
        }
    }
}
