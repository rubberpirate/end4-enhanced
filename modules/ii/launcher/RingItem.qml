// Adapted from Nebula by LilaccFlowerr (AGPL-3.0); see README.md and LICENSE.
import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.modules.common.models
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.shapes

Item {
    id: root

    property real angle: 0
    property var entry: null
    property int shape: MaterialShape.Shape.Circle
    property int delay: 0
    property bool rushing: false
    property bool selected: false

    Behavior on angle {
        SequentialAnimation {
            PauseAnimation { duration: root.delay }
            RotationAnimation {
                direction: RotationAnimation.Shortest
                duration: root.rushing ? LauncherStyle.medium : LauncherStyle.island
                easing.type: root.rushing ? Easing.OutCubic : Easing.OutBack
                easing.overshoot: LauncherStyle.overshoot
            }
        }
    }

    property var shownEntry: null
    Component.onCompleted: shownEntry = entry
    function key(e) {
        return e ? e.id || e.name : "";
    }

    function sync() {
        if (key(entry) !== key(shownEntry)) swap.restart();
    }

    onEntryChanged: Qt.callLater(sync)

    SequentialAnimation {
        id: swap
        NumberAnimation { target: root; property: "scale"; to: 0; duration: LauncherStyle.fast; easing.type: Easing.InCubic }
        ScriptAction { script: root.shownEntry = root.entry }
        NumberAnimation { target: root; property: "scale"; to: 1; duration: LauncherStyle.medium; easing.type: Easing.OutBack; easing.overshoot: LauncherStyle.overshoot }
    }

    readonly property bool empty: shownEntry === null
    readonly property bool systemIcon: shownEntry?.iconType === LauncherSearchResult.IconType.System
    readonly property bool textIcon: shownEntry?.iconType === LauncherSearchResult.IconType.Text
    readonly property real radians: (angle - 90) * Math.PI / 180

    width: LauncherStyle.labelWidth
    height: LauncherStyle.itemSize + LauncherStyle.labelGap + label.height
    x: parent.width / 2 + LauncherStyle.ringRadius * Math.cos(radians) - width / 2
    y: parent.height / 2 + LauncherStyle.ringRadius * Math.sin(radians) - height / 2

    MaterialShape {
        id: shape
        anchors.horizontalCenter: parent.horizontalCenter
        width: LauncherStyle.itemSize
        height: LauncherStyle.itemSize
        shape: mouse.containsMouse && !root.empty ? MaterialShape.Shape.Cookie9Sided : root.shape
        color: (root.selected ? Appearance.m3colors.m3primaryContainer : mouse.containsMouse ? Appearance.m3colors.m3surfaceContainerHighest : Appearance.m3colors.m3surfaceContainerHigh)
        opacity: root.empty ? 0.25 : 1

        Behavior on color {
            ColorAnimation { duration: LauncherStyle.medium }
        }
    }

    IconImage {
        anchors.centerIn: shape
        implicitSize: LauncherStyle.iconSize
        source: root.systemIcon ? Quickshell.iconPath(root.shownEntry.iconName, true) : ""
        visible: source !== ""
    }

    MaterialSymbol {
        anchors.centerIn: shape
        visible: !root.empty && !root.systemIcon && !root.textIcon
        text: root.shownEntry?.iconName ?? ""
        color: root.selected ? Appearance.m3colors.m3onPrimaryContainer : Appearance.m3colors.m3onSurface
        iconSize: LauncherStyle.iconSize
    }

    StyledText {
        anchors.centerIn: shape
        visible: root.textIcon
        text: root.shownEntry?.iconName ?? ""
        font.pixelSize: LauncherStyle.iconSize
    }

    Rectangle {
        anchors.centerIn: label
        width: Math.min(root.width + 8, label.contentWidth + 16)
        height: label.contentHeight + 4 * 2
        radius: height / 2
        color: Appearance.m3colors.m3secondaryContainer
        visible: root.selected && !root.empty
    }

    Text {
        id: label
        anchors.top: shape.bottom
        anchors.topMargin: LauncherStyle.labelGap
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: root.shownEntry?.name ?? ""
        color: root.selected ? Appearance.m3colors.m3onSecondaryContainer : Appearance.m3colors.m3onSurfaceVariant
        font.family: Appearance.font.family.main
        font.pixelSize: LauncherStyle.labelSize
        font.weight: root.selected ? Font.Medium : Font.Normal
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: !root.empty
        cursorShape: Qt.PointingHandCursor
        onClicked: Launcher.activate(root.shownEntry)
    }
}
