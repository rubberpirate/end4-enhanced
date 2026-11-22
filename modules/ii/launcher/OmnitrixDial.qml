import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.modules.common.models
import qs.modules.common.widgets

Item {
    id: root
    property var entry: null
    property real intro: 1
    property int turns: 0
    property var shownEntry: entry
    signal activated()

    // ben1.png: 1397px watch diameter, 1059px center crop, 171px lamp housings.
    readonly property real faceRatio: 1059 / 1397
    readonly property real lampRatio: 171 / 1397

    Canvas {
        objectName: "omnitrixBezel"
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.scale(width / 320, height / 320);
            function circle(radius, fill, stroke, thickness) {
                ctx.beginPath();
                ctx.arc(160, 160, radius, 0, Math.PI * 2);
                ctx.fillStyle = fill;
                ctx.fill();
                if (stroke) { ctx.strokeStyle = stroke; ctx.lineWidth = thickness; ctx.stroke(); }
            }
            circle(156.4, "#232122", "#000000", 1.3);
            circle(136.5, "#000000", "#080808", 1);
        }
    }

    Rectangle {
        id: faceMask
        width: root.width * root.faceRatio
        height: width
        radius: width / 2
        color: "white"
        visible: false
        layer.enabled: true
    }

    Image {
        objectName: "omnitrixFace"
        anchors.centerIn: parent
        width: root.width * root.faceRatio
        height: width
        source: Quickshell.shellPath("assets/launcher/omnitrix-reference.png")
        sourceClipRect: Qt.rect(263, 263, 1059, 1059)
        smooth: true
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: faceMask
        }
    }

    Item {
        objectName: "omnitrixLamps"
        anchors.fill: parent
        rotation: -root.turns * 90
        Behavior on rotation {
            NumberAnimation { duration: 450; easing.type: Easing.OutCubic }
        }

        Item {
            anchors.fill: parent

            Repeater {
                model: 4
                delegate: Item {
                    required property int index
                    anchors.fill: parent
                    rotation: index * 90

                    Image {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: root.height / 2 - root.height * 614 / 1397 - height / 2
                        width: root.width * root.lampRatio
                        height: width
                        source: Quickshell.shellPath("assets/launcher/omnitrix-reference.png")
                        sourceClipRect: Qt.rect(707, 93, 171, 171)
                        smooth: true
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: lampMask
                        }
                        Rectangle {
                            id: lampMask
                            anchors.fill: parent
                            radius: width / 2
                            color: "white"
                            visible: false
                            layer.enabled: true
                        }
                    }
                }
            }
        }
    }

    Item {
        id: emblem
        width: root.width * 0.24
        height: width
        anchors.centerIn: parent
        readonly property bool systemIcon: root.shownEntry?.iconType === LauncherSearchResult.IconType.System
        readonly property bool textIcon: root.shownEntry?.iconType === LauncherSearchResult.IconType.Text
        readonly property bool wallpaper: root.shownEntry?.kind === "wallpaper"

        IconImage {
            anchors.fill: parent
            source: emblem.systemIcon ? Quickshell.iconPath(root.shownEntry.iconName, true) : ""
            visible: emblem.systemIcon
            layer.enabled: true
            layer.effect: MultiEffect { saturation: -1; brightness: -0.85 }
        }
        MaterialSymbol {
            anchors.centerIn: parent
            text: root.shownEntry?.kind === "theme" ? "palette" : root.shownEntry?.iconName ?? "search_off"
            visible: !emblem.systemIcon && !emblem.textIcon && !emblem.wallpaper
            iconSize: emblem.width
            color: "#051001"
        }
        Image {
            anchors.fill: parent
            source: emblem.wallpaper ? "file://" + root.shownEntry.path : ""
            fillMode: Image.PreserveAspectCrop
            clip: true
            visible: emblem.wallpaper
        }
        Text {
            anchors.centerIn: parent
            text: root.shownEntry?.iconName ?? ""
            visible: emblem.textIcon
            font.pixelSize: emblem.width * 0.8
            color: "#051001"
        }
    }

    onEntryChanged: swap.restart()
    SequentialAnimation {
        id: swap
        NumberAnimation { target: emblem; property: "opacity"; to: 0; duration: 110 }
        ScriptAction { script: root.shownEntry = root.entry }
        NumberAnimation { target: emblem; property: "opacity"; to: 1; duration: 180 }
    }

    MouseArea {
        anchors.centerIn: parent
        width: parent.width * 0.65
        height: width
        cursorShape: root.entry ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: { if (root.entry) root.activated(); }
    }
}
