import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import qs.services
import qs.modules.common
import qs.modules.ii.background

ShellRoot {
    id: root
    property bool failed: false
    property var widget: null

    function check(condition, message) {
        if (!condition) {
            failed = true;
            console.error("FAIL: " + message);
        }
    }

    function findBattery(item) {
        if (item.configEntryName === "battery") return item;
        for (const child of item.children ?? []) {
            const found = findBattery(child);
            if (found) return found;
        }
        return null;
    }

    QtObject {
        id: sample
        property bool available: true
        property real percentage: 0.58
        property bool isCharging: true
        property int chargeState: UPowerDeviceState.Charging
        property real timeToFull: 1140
        property real timeToEmpty: 7200
    }

    PanelWindow {
        id: preview
        implicitWidth: 250
        implicitHeight: 250
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "end4-battery-test"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        WidgetsLoader {
            id: widgets
            anchors.fill: parent
            screen: ({name: "test", width: 250, height: 250})
            wallpaperItem: null
            wallpaperSafetyTriggered: false
        }
    }

    Timer {
        interval: 1000
        running: true
        onTriggered: {
            root.widget = root.findBattery(widgets);
            root.check(root.widget !== null, "enabled base config loads battery widget");
            root.check(DesktopWidgets.catalog.some(w => w.key === "battery"), "battery appears in widget catalog");
            root.widget.battery = sample;
            root.check(root.widget.percent === 58, "percentage uses battery data");
            root.check(root.widget.status === "19m to full", "charging estimate");
            root.check(root.widget.duration(3600) === "1h 0m", "hour estimate");
            root.check(root.widget.duration(0) === "" && root.widget.duration(-60) === "" && root.widget.duration(NaN) === "", "unknown estimates are omitted");
        }
    }

    Timer {
        interval: 2000
        running: true
        onTriggered: {
            root.check(Math.abs(root.widget.sweep - 208.8) < 0.01, "charge ring animation reaches level");
            // Set BATTERY_CHECK_IMAGE for an optional capture of just this widget.
            const path = Quickshell.env("BATTERY_CHECK_IMAGE");
            if (path) root.widget.grabToImage(result => result.saveToFile(path));
        }
    }

    Timer {
        interval: 2300
        running: true
        onTriggered: {
            sample.timeToFull = 0;
            root.check(root.widget.status === "Charging", "charging without an estimate");
            sample.isCharging = false;
            sample.chargeState = UPowerDeviceState.FullyCharged;
            sample.percentage = 1;
            root.check(root.widget.status === "Full" && root.widget.percent === 100, "fully charged state");
            sample.available = false;
            root.check(root.widget.status === "No battery" && root.widget.percent === 0, "missing battery state");
            root.widget.size = 240;
            root.check(root.widget.implicitWidth === 240 && root.widget.implicitHeight === 240, "resizing keeps widget square");
        }
    }

    Timer {
        interval: 3100
        running: true
        onTriggered: {
            root.check(root.widget.sweep === 0, "empty ring animation settles");
            DesktopWidgets.setEnabled("battery", false);
            root.check(!Config.options.background.widgets.battery.enable, "menu toggle updates config");
            if (!root.failed) console.log("BATTERY CHECK PASSED");
            Qt.quit();
        }
    }
}
