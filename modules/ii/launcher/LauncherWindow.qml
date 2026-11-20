// Adapted from Nebula by LilaccFlowerr (AGPL-3.0); see README.md and LICENSE.
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.services
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.shapes
import "Curves.js" as Curves

PanelWindow {
    id: window

    readonly property bool open: GlobalStates.launcherOpen
    property real progress: 0
    readonly property real pillT: Curves.phase(progress, 0.45, 0.45)

    NumberAnimation {
        id: openAnim
        target: window
        property: "progress"
        to: 1
        duration: LauncherStyle.slow + LauncherStyle.medium
        easing.type: Easing.Linear
    }

    NumberAnimation {
        id: closeAnim
        target: window
        property: "progress"
        to: 0
        duration: LauncherStyle.slow
        easing.type: Easing.Linear
    }

    visible: open || progress > 0
    screen: Quickshell.screens.find(s => s.name === WM.focusedMonitor?.name) ?? Quickshell.screens[0]

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:launcher"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property int selected: 0
    property int cursor: 0
    readonly property var results: Launcher.results
    onResultsChanged: { cursor = 0; selected = 0; }

    property bool rushing: false

    function step(delta, repeat) {
        rushing = repeat;
        if (repeat) rushTimer.restart();
        if (results.length === 0) return;
        cursor = (cursor + delta + results.length) % results.length;
        selected = cursor;
    }

    Timer {
        id: rushTimer
        interval: LauncherStyle.medium
        onTriggered: window.rushing = false
    }

    Component.onCompleted: { if (open) beginOpen(); }

    function beginOpen() {
        input.text = "";
        Launcher.query = "";
        selected = 0;
        cursor = 0;
        closeAnim.stop();
        openAnim.restart();
        Qt.callLater(() => input.forceActiveFocus());
    }

    onOpenChanged: {
        if (open) {
            beginOpen();
        } else {
            openAnim.stop();
            closeAnim.restart();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Appearance.m3colors.m3scrim, LauncherStyle.backdropDim * window.progress)

        MouseArea {
            anchors.fill: parent
            onClicked: Launcher.close()
        }
    }

    WheelHandler {
        property real delta: 0

        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            delta += event.angleDelta.y;
            if (Math.abs(delta) < 120) return;
            window.step(delta < 0 ? 1 : -1, false);
            delta = 0;
        }
    }

    Item {
        id: cloverGlow

        readonly property real pad: ring.width * LauncherStyle.glassPad

        x: ring.x - pad
        y: ring.y - pad
        width: ring.width + pad * 2
        height: ring.height + pad * 2

        Rectangle {
            id: cloverLight
            anchors.fill: parent
            visible: false
            layer.enabled: true
            gradient: Gradient {
                GradientStop { position: cloverGlow.pad / cloverGlow.height; color: Qt.rgba(1, 1, 1, LauncherStyle.glassLight) }
                GradientStop { position: (cloverGlow.pad + ring.height * 0.55) / cloverGlow.height; color: Qt.rgba(1, 1, 1, 0) }
            }
        }

        Item {
            id: cloverLightMask
            anchors.fill: parent
            visible: false
            layer.enabled: true

            ShapeCanvas {
                x: cloverGlow.pad
                y: cloverGlow.pad
                width: ring.width
                height: ring.height
                scale: ring.clover.scale
                rotation: ring.clover.rotation
                roundedPolygon: ring.clover.roundedPolygon
                animation: NumberAnimation { duration: LauncherStyle.island; easing.type: Easing.OutBack; easing.overshoot: LauncherStyle.overshoot }
                color: "black"
            }
        }

        MultiEffect {
            anchors.fill: parent
            source: cloverLight
            maskEnabled: true
            maskSource: cloverLightMask
        }
    }

    LauncherRing {
        id: ring
        anchors.centerIn: parent
        intro: window.progress
        selected: window.selected
        rushing: window.rushing
    }

    Rectangle {
        id: pill
        anchors.centerIn: parent
        width: LauncherStyle.searchHeight + (LauncherStyle.searchWidth - LauncherStyle.searchHeight) * Math.max(0, Curves.back(window.pillT, LauncherStyle.overshoot))
        height: LauncherStyle.searchHeight
        scale: Math.min(1, window.pillT * 4)
        radius: height / 2
        color: Appearance.m3colors.m3surfaceContainerLowest
        border.width: 1
        border.color: Appearance.m3colors.m3outlineVariant

        Text {
            x: 12
            anchors.verticalCenter: parent.verticalCenter
            opacity: input.opacity
            text: "search"
            font.family: Fonts.iconMaterialFamily
            font.pixelSize: LauncherStyle.searchIconSize
            color: Appearance.m3colors.m3onSurfaceVariant
        }

        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: 12 + LauncherStyle.searchIconSize + 8
            anchors.rightMargin: 16
            focus: window.open
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            opacity: Math.max(0, window.pillT * 3 - 2)
            color: text === ">" ? "transparent" : Appearance.m3colors.m3onSurface
            selectionColor: Appearance.m3colors.m3primary
            font.family: Appearance.font.family.main
            font.pixelSize: 14
            onTextChanged: Launcher.query = text

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) Launcher.close();
                else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) window.step(-1, event.isAutoRepeat);
                else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down || event.key === Qt.Key_Tab) window.step(1, event.isAutoRepeat);
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) Launcher.activate(window.results[window.cursor]);
                else return;
                event.accepted = true;
            }
        }

        Text {
            x: input.x
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text === "" || input.text === ">"
            text: input.text === ">" ? "> " + Translation.tr("Commands") : Translation.tr("Search")
            color: Appearance.m3colors.m3onSurfaceVariant
            opacity: input.opacity
            font: input.font
        }
    }
}
