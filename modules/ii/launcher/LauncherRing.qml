// Adapted from Nebula by LilaccFlowerr (AGPL-3.0); see README.md and LICENSE.
import QtQuick
import "Curves.js" as Curves
import "LauncherShapes.js" as LauncherShapes
import qs.services
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.shapes

Item {
    id: root

    property int selected: 0
    property bool rushing: false
    property real intro: 1
    readonly property real cloverT: Curves.phase(intro, 0, 0.6)
    property real shownMorph: Launcher.commandMode ? 1 : 0

    Behavior on shownMorph {
        NumberAnimation { duration: LauncherStyle.island; easing.type: Easing.OutBack; easing.overshoot: LauncherStyle.overshoot }
    }
    readonly property var results: Launcher.results
    readonly property int slots: Launcher.slots
    readonly property var shapes: [MaterialShape.Shape.Cookie4Sided, MaterialShape.Shape.Clover4Leaf, MaterialShape.Shape.Cookie6Sided, MaterialShape.Shape.Circle, MaterialShape.Shape.Cookie9Sided, MaterialShape.Shape.Clover8Leaf, MaterialShape.Shape.Cookie12Sided, MaterialShape.Shape.Cookie7Sided]

    property alias clover: cloverShape

    width: LauncherStyle.size
    height: LauncherStyle.size

    ShapeCanvas {
        id: cloverShape

        readonly property real leafOffset: 180 / Launcher.appSlots + (180 / Launcher.commandSlots - 180 / Launcher.appSlots) * root.shownMorph

        anchors.fill: parent
        scale: Math.max(0, Curves.back(root.cloverT, LauncherStyle.overshoot))
        roundedPolygon: LauncherShapes.clover(Launcher.commandMode ? Launcher.commandSlots : Launcher.appSlots)
        animation: NumberAnimation { duration: LauncherStyle.island; easing.type: Easing.OutBack; easing.overshoot: LauncherStyle.overshoot }
        rotation: root.shownMorph * 360 / Launcher.commandSlots - leafOffset - (1 - Curves.decel(root.cloverT)) * 120
        readonly property color accent: Launcher.commandMode ? Appearance.m3colors.m3tertiaryContainer : Appearance.m3colors.m3primaryContainer
        color: Qt.alpha(accent, LauncherStyle.glassTint)

        Behavior on color {
            ColorAnimation { duration: LauncherStyle.island; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: mouse => {
            if (Math.hypot(mouse.x - width / 2, mouse.y - height / 2) > width / 2) Launcher.close();
        }
    }

    Repeater {
        model: Launcher.appSlots

        RingItem {
            required property int index
            readonly property int position: (index - root.selected + root.slots) % root.slots
            angle: position * 360 / root.slots
            delay: root.rushing ? 0 : Math.min(position, root.slots - position) * LauncherStyle.stagger
            rushing: root.rushing
            entry: root.results[index] ?? null
            shape: root.shapes[index]
            selected: position === 0
            readonly property real appear: Math.max(0, Curves.back(Curves.phase(root.intro, 0.3 + position * 0.04, 0.35), LauncherStyle.overshoot))
            opacity: Math.min(1, appear * 2)
            transform: Scale {
                origin.x: LauncherStyle.labelWidth / 2
                origin.y: LauncherStyle.itemSize / 2
                xScale: appear
                yScale: appear
            }
            visible: index < root.slots
        }
    }

}
