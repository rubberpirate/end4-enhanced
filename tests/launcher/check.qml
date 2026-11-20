import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.ii.launcher
import qs.modules.ii.overview

ShellRoot {
    id: root
    property bool failed: false
    property var firstApp: null

    function check(condition, message) {
        if (!condition) {
            failed = true;
            console.error("FAIL: " + message);
        }
    }

    function findItem(parent, predicate) {
        if (predicate(parent)) return parent;
        for (const child of parent.children ?? []) {
            const found = findItem(child, predicate);
            if (found) return found;
        }
        return null;
    }

    LauncherWindow { id: launcher }
    Overview {}

    Timer {
        interval: 1200
        running: true
        onTriggered: {
            Launcher.open();
            root.check(Launcher.results.length > 0 && Launcher.results.length <= 8, "initial app results");
            root.firstApp = Launcher.results[0];
        }
    }

    Timer {
        interval: 2200
        running: true
        onTriggered: {
            root.check(launcher.progress === 1 && launcher.visible, "open animation finishes");
            const input = root.findItem(launcher.contentItem, item => typeof item.selectAll === "function");
            root.check(input !== null && input.activeFocus, "search input has keyboard focus");
            input.text = root.firstApp.name;
            root.check(Launcher.results.some(e => e.id === root.firstApp.id), "typing finds app");
            input.text = ">";
            root.check(Launcher.results.length === 7 && Launcher.slots === 7, "seven commands");
            launcher.step(-1, false);
            root.check(launcher.cursor === 6, "reverse navigation wraps");
            launcher.step(1, false);
            root.check(launcher.cursor === 0, "forward navigation wraps");
            input.text = ">Settings";
            root.check(Launcher.results.length === 1, "command filtering");
        }
    }

    Timer {
        interval: 3200
        running: true
        onTriggered: {
            const top = root.findItem(launcher.contentItem, item => item.shownEntry !== undefined && item.selected);
            root.check(top?.shownEntry?.name === Launcher.results[0]?.name, "same-slot result swaps update label and action");
            root.check(top?.scale === 1, "result swap returns icons to full size");
            Launcher.query = ">no-such-command";
            launcher.step(1, false);
            root.check(Launcher.results.length === 0, "empty command results");
            Launcher.activate(null);
            root.check(GlobalStates.launcherOpen, "empty activation stays open");
            Launcher.close();
            root.check(launcher.visible, "window remains visible during exit");
        }
    }

    Timer {
        interval: 3400
        running: true
        onTriggered: Launcher.open()
    }

    Timer {
        interval: 4400
        running: true
        onTriggered: {
            root.check(launcher.progress === 1 && Launcher.query === "", "reopening reverses exit and clears query");
            GlobalStates.overviewOpen = true;
            root.check(!GlobalStates.launcherOpen, "overview closes launcher");
            Launcher.open();
            root.check(!GlobalStates.overviewOpen, "launcher closes overview");
            Launcher.close();
        }
    }

    Timer {
        interval: 5100
        running: true
        onTriggered: {
            root.check(!launcher.visible && launcher.progress === 0, "close animation ends and window hides");
            if (!root.failed) console.log("LAUNCHER CHECK PASSED");
            Qt.quit();
        }
    }
}
