import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.ii.launcher

ShellRoot {
    id: root
    property bool failed: false
    property var ring: null
    property var input: null
    property real lampPhaseBefore: 0

    function check(condition, message) {
        if (!condition) { failed = true; console.error("FAIL: " + message); }
    }
    function findItem(item, predicate) {
        if (predicate(item)) return item;
        for (const child of item.data ?? item.children ?? []) {
            const found = findItem(child, predicate);
            if (found) return found;
        }
        return null;
    }

    LauncherWindow { id: launcher }

    Timer {
        interval: 1200
        running: true
        onTriggered: {
            Launcher.open();
            // Physical scrolling on the shared desktop must not alter scripted navigation.
            findItem(launcher.contentItem, item => item.objectName === "launcherWheel").enabled = false;
        }
    }
    Timer {
        interval: 2500
        running: true
        onTriggered: {
            root.ring = findItem(launcher.contentItem, item => item.objectName === "omnitrixRing");
            root.input = findItem(launcher.contentItem, item => typeof item.selectAll === "function");
            root.check(root.ring !== null && launcher.omnitrix, "skin loads through launcher");
            root.check(root.input.activeFocus, "Omnitrix keeps keyboard search focus");
            root.check(Launcher.results.length === Launcher.apps.length, "full app catalog is available");
            root.check(root.ring.slotCount === Math.min(9, Launcher.results.length), "catalog shows a bounded window");
            const seen = [];
            for (let i = 0; i < root.ring.slotCount; i++) seen.push(root.ring.resultIndex(i));
            root.check(new Set(seen).size === seen.length, "neighbor slots have unique results");
            root.check(findItem(root.ring, item => item.objectName === "omnitrixSelectedName").text === root.ring.currentEntry.name, "selected app name replaces catalog heading");
            const face = findItem(root.ring, item => item.objectName === "omnitrixFace");
            root.check(face.status === Image.Ready && face.rotation === 0, "reference face loads upright");
            root.check(launcher.skinScale <= 0.82, "Omnitrix uses the smaller layout");
            root.lampPhaseBefore = findItem(root.ring, item => item.objectName === "omnitrixLamps").rotation;
            const image = Quickshell.env("LAUNCHER_CHECK_IMAGE");
            if (image) root.ring.grabToImage(result => result.saveToFile(image));
        }
    }
    Timer {
        interval: 2800
        running: true
        onTriggered: {
            root.check(findItem(root.ring, item => item.objectName === "omnitrixLamps").rotation === root.lampPhaseBefore, "lamps remain still while idle");
            launcher.step(1, false);
            root.check(root.ring.currentEntry === Launcher.results[1], "next selection updates center");
            root.check(root.ring.resultIndex(0) === 1, "selected catalog slot follows cursor");
        }
    }
    Timer {
        interval: 3400
        running: true
        onTriggered: {
            const dial = findItem(launcher.contentItem, item => item.objectName === "omnitrixDial");
            root.check(dial.shownEntry === Launcher.results[1], "center icon swap completes");
            root.check(findItem(root.ring, item => item.objectName === "omnitrixSelectedName").text === Launcher.results[1].name, "selected name follows navigation");
            const face = findItem(root.ring, item => item.objectName === "omnitrixFace");
            const bezel = findItem(root.ring, item => item.objectName === "omnitrixBezel");
            const lamps = findItem(root.ring, item => item.objectName === "omnitrixLamps");
            root.check(face.rotation === 0 && face.scale === 1 && bezel.rotation === 0, "watch face and bezel remain fixed during selection");
            root.check(lamps.rotation === -90, "lamps finish one quarter-turn and stop after selection");
            launcher.selectIndex(Launcher.results.length - 1);
            root.check(launcher.cursor === Launcher.results.length - 1, "previous selection wraps through full catalog");
            root.check(root.ring.resultIndex(1) === 0, "upcoming app wraps at end of catalog");
            root.input.text = ">";
            launcher.step(-1, false);
            root.check(launcher.cursor === Launcher.commands.length - 1 && root.ring.slotCount === Launcher.commands.length, "command ring wraps with available commands");
            root.input.text = ">no-such-command";
            root.check(root.ring.slotCount === 0 && root.ring.currentEntry === null, "empty query clears center and catalog");
            launcher.step(1, false);
            Launcher.activate(null);
            root.check(GlobalStates.launcherOpen, "empty selection stays open");
            Config.options.launcher.skin = "clover";
            root.check(!launcher.omnitrix, "can switch back while launcher is open");
            root.input.text = "";
            root.check(Launcher.results.length <= 8, "clover retains its original result limit");
        }
    }
    Timer {
        interval: 4200
        running: true
        onTriggered: {
            root.check(findItem(launcher.contentItem, item => item.objectName === "omnitrixRing") === null, "inactive skin unloads");
            root.check(root.input.activeFocus, "switching skins preserves keyboard focus");
            Config.options.launcher.skin = "omnitrix";
            root.input.text = ">Settings";
        }
    }
    Timer {
        interval: 5000
        running: true
        onTriggered: {
            const dial = findItem(launcher.contentItem, item => item.objectName === "omnitrixDial");
            root.check(Launcher.results.length === 1, "command search works in new skin");
            dial.activated();
            root.check(GlobalStates.settingsOpen && !GlobalStates.launcherOpen, "center click activates selected settings command");
        }
    }
    Timer {
        interval: 5800
        running: true
        onTriggered: {
            root.check(!launcher.visible, "closing animation hides Omnitrix window");
            if (!root.failed) console.log("LAUNCHER CHECK PASSED");
            Qt.quit();
        }
    }
}
