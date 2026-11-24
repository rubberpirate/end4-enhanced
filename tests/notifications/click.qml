import QtQuick
import QtTest
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.services
import qs.modules.ii.notificationPopup

ShellRoot {
    id: root
    property bool failed: false
    property int phase: 0
    property var sourceToplevel: null
    property var cards: popup.bubbleWindow.stack.cards
    function check(condition, message) {
        if (!condition) { failed = true; console.error("FAIL: " + message); }
    }
    function findButton(item) {
        if (item.text === "View" && item.down !== undefined) return item;
        for (const child of item.children ?? []) {
            const button = findButton(child);
            if (button) return button;
        }
        return null;
    }
    FloatingWindow {
        id: sourceWindow
        visible: true
        title: "Bubble source pointer test"
        implicitWidth: 420
        implicitHeight: 110
        color: "#242424"
        Text { anchors.centerIn: parent; text: "Notification source focus check"; color: "white" }
    }
    NotificationPopup { id: popup }
    TestCase { id: pointer; when: false; name: "NotificationPointer" }
    Connections {
        target: Notifications
        function onNotify(notification) {
            if (notification.appName !== "Pointer Source") Notifications.discardNotification(notification.notificationId);
        }
    }
    Process {
        id: sender
        property string expectedAction: "default"
        command: ["python3", Quickshell.env("BUBBLE_TEST_ROOT") + "/click_sender.py", root.sourceToplevel?.appId ?? "", expectedAction, Quickshell.env("BUBBLE_TEST_ROOT")]
        stderr: StdioCollector { onStreamFinished: { if (text) console.log("SENDER:", text); } }
        onExited: (code, status) => root.check(code === 0, "sender received exactly one " + expectedAction + " action and close")
    }
    Timer {
        interval: 100; repeat: true; running: true
        onTriggered: {
            if (!Config.ready) return;
            if (root.phase === 0) {
                Config.options.notifications.style = "bubble";
                Config.options.notifications.position = "top_right";
                root.sourceToplevel = ToplevelManager.toplevels.values.find(t => t.title === sourceWindow.title) ?? null;
                if (!root.sourceToplevel) return;
                console.log("POINTER SOURCE APP", root.sourceToplevel.appId);
                root.sourceToplevel.minimized = true;
                root.phase = 1;
            } else if (root.phase === 1 && !root.sourceToplevel.activated) {
                sender.running = true;
                root.phase = 2;
            } else if (root.phase === 2 && root.cards.some(c => c.presentedOnce && !c.leaving)) {
                const card = root.cards.find(c => !c.leaving);
                pointer.mouseClick(card, 65, card.height / 2, Qt.LeftButton);
                root.phase = 3;
            } else if (root.phase === 3 && root.sourceToplevel.activated && !sender.running) {
                root.check(!GlobalStates.sidebarRightOpen, "body click does not open history");
                root.sourceToplevel.minimized = true;
                root.phase = 4;
            } else if (root.phase === 4 && !root.sourceToplevel.activated && root.cards.length === 0) {
                sender.expectedAction = "view";
                sender.running = true;
                root.phase = 5;
            } else if (root.phase === 5 && root.cards.some(c => c.presentedOnce && !c.leaving)) {
                const button = root.findButton(root.cards.find(c => !c.leaving));
                root.check(button !== null, "inline action button found");
                if (button) pointer.mouseClick(button, button.width / 2, button.height / 2, Qt.LeftButton);
                root.phase = 6;
            } else if (root.phase === 6 && !sender.running) {
                root.check(!GlobalStates.sidebarRightOpen, "inline action does not also activate card/history");
                console.log(root.failed ? "INTEGRATION CHECK FAILED" : "INTEGRATION CHECK PASSED");
                Qt.quit();
            }
        }
    }
    Timer {
        interval: 15000; running: true
        onTriggered: {
            root.check(false, "pointer handoff timed out in phase " + root.phase + ", source activated=" + root.sourceToplevel?.activated);
            Qt.quit();
        }
    }
}
