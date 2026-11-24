import QtQuick
import Quickshell
import "../../modules/ii/notificationPopup"

ShellRoot {
    id: root
    property bool failed: false
    function check(condition, message) {
        if (!condition) { failed = true; console.error("FAIL: " + message); }
    }
    function notification(id, title, body, actions) {
        return { notificationId: id, summary: title, body: body ?? "", actions: actions ?? [], appIcon: "", urgency: "normal" };
    }
    function capture(name) { stage.grabToImage(result => result.saveToFile("/tmp/end4-bubble-" + name + ".png")); }
    Window {
        visible: true
        width: 680; height: 360
        minimumWidth: 680; maximumWidth: 680
        minimumHeight: 360; maximumHeight: 360
        color: "#34372f"
        Item {
            id: stage
            anchors.fill: parent
            Rectangle {
                id: existingIsland
                anchors.horizontalCenter: parent.horizontalCenter
                width: 300; height: 32
                color: "#303038"
                bottomLeftRadius: 12; bottomRightRadius: 12
                Text { anchors.centerIn: parent; text: "Tue, 24/11   6:05 PM   RAM 26   CPU 4"; color: "#d9d9df"; font.pixelSize: 12 }
            }
            BubbleStack { id: stack; width: parent.width; anchorWidth: existingIsland.width; anchorColor: existingIsland.color }
        }
    }
    Timer {
        interval: 40; running: true
        onTriggered: stack.notifications = [root.notification(1, "Deployed to staging", "v1.4.0 in 2m 41s", [{ identifier: "view", text: "View" }])]
    }
    Timer { interval: 180; running: true; onTriggered: root.capture("neck") }
    Timer { interval: 290; running: true; onTriggered: root.capture("drop") }
    Timer {
        interval: 1800; running: true
        onTriggered: {
            root.check(stack.cards.length === 1, "first capsule appears");
            root.check(stack.cards[0].sidesOpacity === 1, "delayed content fully visible");
            root.check(Math.abs(stack.cards[0].width - stack.cards[0].pillWidth) < 1, "capsule settles at measured content width");
            root.capture("open");
            stack.notifications = stack.notifications.concat([
                root.notification(2, "Claude needs you", "Allow Bash: npm run migrate", [{ identifier: "later", text: "Later" }, { identifier: "allow", text: "Allow" }]),
                root.notification(3, "Lint passed", "0 warnings in 212 files"),
                root.notification(4, "Fourth"), root.notification(5, "Fifth")]);
        }
    }
    Timer {
        interval: 4700; running: true
        onTriggered: {
            root.check(stack.cards.length === 3, "stack capped at three cards");
            root.check(stack.overflowCount === 2 && stack.counterCard !== null, "overflow drop counts pending cards");
            root.capture("stack");
            stack.notifications = stack.notifications.filter(n => n.notificationId !== 2);
            root.check(stack.cards.length === 3, "exiting card retained for liquid return");
        }
    }
    Timer {
        interval: 7600; running: true
        onTriggered: {
            root.check(stack.cards.some(c => c.notificationId === 4), "queued card promoted after dismissal");
            root.check(!stack.cards.some(c => c.notificationId === 2), "dismissed card destroyed after return");
            root.check(stack.overflowCount === 1, "overflow count updates");
            stack.notifications = [];
        }
    }
    Timer {
        interval: 10300; running: true
        onTriggered: {
            root.check(!stack.active, "last exit releases popup window");
            stack.reducedMotion = true;
            stack.notifications = [root.notification(6, "Reduced motion")];
        }
    }
    Timer {
        interval: 10700; running: true
        onTriggered: {
            root.check(stack.cards.length === 1 && !stack.cards[0].moving, "reduced motion settles without a spring: " + stack.cards.length + " moving=" + stack.cards[0]?.moving + " reduced=" + stack.cards[0]?.reducedMotion + " clock=" + stack.cards[0]?.clock + " end=" + stack.cards[0]?.motion?.end);
            stack.notifications = [];
        }
    }
    Timer {
        interval: 11200; running: true
        onTriggered: {
            root.check(!stack.active, "reduced motion exits cleanly");
            console.log(root.failed ? "BUBBLE CHECK FAILED" : "BUBBLE CHECK PASSED");
            Qt.quit();
        }
    }
}
