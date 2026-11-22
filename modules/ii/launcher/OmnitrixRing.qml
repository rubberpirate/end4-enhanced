import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import "Curves.js" as Curves

Item {
    id: root
    objectName: "omnitrixRing"
    property real intro: 1
    property int cursor: 0
    property int selected: 0
    property int turns: 0
    property bool rushing: false
    readonly property var results: Launcher.results
    readonly property int slotCount: Math.min(9, results.length)
    readonly property var currentEntry: results[cursor] ?? null
    signal selectRequested(int index)

    implicitWidth: 600
    implicitHeight: 600
    opacity: Math.min(1, intro * 3)
    transform: Scale {
        origin.x: 300; origin.y: 300
        xScale: Math.max(0, Curves.back(Curves.phase(root.intro, 0, 0.7), 0.65))
        yScale: xScale
    }

    function resultIndex(position) {
        if (results.length === 0) return -1;
        const offset = position <= Math.floor(slotCount / 2) ? position : position - slotCount;
        return (cursor + offset + results.length) % results.length;
    }

    Canvas {
        id: catalog
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const green = ctx.createLinearGradient(0, 18, 0, 582);
            green.addColorStop(0, "rgba(157, 222, 41, 0.94)");
            green.addColorStop(1, "rgba(184, 238, 69, 0.94)");
            ctx.beginPath();
            ctx.arc(300, 300, 236, 0, Math.PI * 2);
            ctx.strokeStyle = green;
            ctx.lineWidth = 92;
            ctx.stroke();
            // Stroke only the circumferences: no radial seam or app partitions.
            for (const radius of [282, 190]) {
                ctx.beginPath();
                ctx.arc(300, 300, radius, 0, Math.PI * 2);
                ctx.strokeStyle = "#c9fb69";
                ctx.lineWidth = 4;
                ctx.stroke();
            }
        }
    }

    Canvas {
        objectName: "omnitrixSelectedPanel"
        anchors.fill: parent
        visible: root.slotCount > 0
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const start = -108 * Math.PI / 180, end = -72 * Math.PI / 180;
            ctx.beginPath();
            ctx.arc(300, 300, 298, start, end);
            ctx.arc(300, 300, 190, end, start, true);
            ctx.closePath();
            const green = ctx.createLinearGradient(0, 2, 0, 120);
            green.addColorStop(0, "#609b06");
            green.addColorStop(1, "#77b51a");
            ctx.fillStyle = green;
            ctx.fill();
            ctx.strokeStyle = "#c9ff66";
            ctx.lineWidth = 4;
            ctx.stroke();
        }
    }

    Repeater {
        model: root.slotCount
        delegate: Item {
            id: slot
            objectName: "omnitrixSlot"
            required property int index
            readonly property int position: root.slotCount ? ((index - root.selected) % root.slotCount + root.slotCount) % root.slotCount : 0
            readonly property int resultIndex: root.resultIndex(position)
            readonly property var entry: root.results[resultIndex] ?? null
            readonly property bool isCurrent: position === 0
            readonly property bool systemIcon: entry?.iconType === LauncherSearchResult.IconType.System
            readonly property bool textIcon: entry?.iconType === LauncherSearchResult.IconType.Text
            readonly property bool wallpaper: entry?.kind === "wallpaper"
            property real angle: position * 360 / root.slotCount
            property real orbitRadius: isCurrent ? 244 : 236
            width: 64
            height: 64
            x: 300 + orbitRadius * Math.cos((angle - 90) * Math.PI / 180) - width / 2
            y: 300 + orbitRadius * Math.sin((angle - 90) * Math.PI / 180) - height / 2
            opacity: Math.min(1, Curves.phase(root.intro, 0.28 + index * 0.025, 0.3) * 2)

            Behavior on angle {
                RotationAnimation {
                    direction: RotationAnimation.Shortest
                    duration: root.rushing ? 190 : 420
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on orbitRadius {
                NumberAnimation { duration: root.rushing ? 190 : 420; easing.type: Easing.OutCubic }
            }

            IconImage {
                anchors.centerIn: parent
                implicitSize: slot.isCurrent ? 58 : 46
                source: slot.systemIcon ? Quickshell.iconPath(slot.entry.iconName, true) : ""
                visible: slot.systemIcon
            }
            MaterialSymbol {
                anchors.centerIn: parent
                text: slot.entry?.kind === "theme" ? "palette" : slot.entry?.iconName ?? ""
                visible: !slot.systemIcon && !slot.textIcon && !slot.wallpaper
                iconSize: slot.isCurrent ? 58 : 46
                color: slot.entry?.kind === "theme" ? slot.entry.previewColor : "#537e12"
            }
            Image {
                anchors.centerIn: parent
                width: slot.isCurrent ? 58 : 46
                height: width
                source: slot.wallpaper ? "file://" + slot.entry.path : ""
                fillMode: Image.PreserveAspectCrop
                clip: true
                visible: slot.wallpaper
            }
            Text {
                anchors.centerIn: parent
                text: slot.entry?.iconName ?? ""
                visible: slot.textIcon
                font.pixelSize: slot.isCurrent ? 56 : 44
            }
            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.selectRequested(slot.resultIndex)
                onDoubleClicked: Launcher.activate(slot.entry)
            }
        }
    }

    OmnitrixDial {
        objectName: "omnitrixDial"
        width: 320; height: 320
        anchors.centerIn: parent
        entry: root.currentEntry
        intro: root.intro
        turns: root.turns
        onActivated: Launcher.activate(root.currentEntry)
    }

    Text {
        objectName: "omnitrixSelectedName"
        anchors.horizontalCenter: parent.horizontalCenter
        y: 118
        width: 160
        horizontalAlignment: Text.AlignHCenter
        text: root.currentEntry?.name ?? Translation.tr("No matches")
        textFormat: Text.PlainText
        elide: Text.ElideRight
        font.family: Appearance.font.family.main
        font.pixelSize: 16
        font.weight: Font.DemiBold
        color: "#dbffb7"
    }
}
