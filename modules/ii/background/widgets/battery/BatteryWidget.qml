// Adapted from Nebula by LilaccFlowerr (AGPL-3.0); see README.md and LICENSE.
import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell.Services.UPower
import qs.modules.ii.background.widgets
import qs.modules.common
import qs.modules.common.widgets
import qs.services

AbstractBackgroundWidget {
    id: root
    configEntryName: "battery"
    hoverEnabled: true

    property var battery: Battery

    property real size: Math.max(100, root.configEntry.size)
    readonly property color textColor: Appearance.m3colors.m3onSecondaryContainer
    readonly property real gap: 14

    readonly property real level: battery.available ? Math.max(0, Math.min(1, battery.percentage)) : 0
    readonly property int percent: Math.round(level * 100)
    property real shownLevel: level

    Behavior on shownLevel {
        NumberAnimation {
            duration: 500
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
        }
    }

    readonly property bool critical: battery.available && level <= Config.options.battery.low / 100
    readonly property bool halfway: battery.available && level <= 0.5
    property color accent: !battery.available ? Appearance.m3colors.m3outline : critical ? Appearance.m3colors.m3error : halfway ? Appearance.m3colors.m3tertiary : Appearance.m3colors.m3primary

    Behavior on accent {
        ColorAnimation { duration: 300 }
    }

    readonly property real ringWidth: size * 0.07
    readonly property real ringRadius: size * 0.37
    readonly property real sweep: Math.min(360, 360 * shownLevel)
    readonly property real trackSweep: Math.max(0, 360 - sweep - gap * 2)

    readonly property real numberSize: ringRadius * (root.percent >= 100 ? 0.62 : 0.8)
    readonly property real percentSize: ringRadius * 0.27
    readonly property real percentGap: ringRadius * 0.03
    readonly property real lineGap: ringRadius * 0.03
    readonly property real pillPadding: ringRadius * 0.1
    readonly property real pillPaddingY: ringRadius * 0.05
    readonly property real iconSize: ringRadius * 0.22
    readonly property real iconGap: ringRadius * 0.05

    readonly property real innerRadius: ringRadius - ringWidth / 2 - size * 0.03
    readonly property real pillWidth: statusMetrics.advanceWidth + pillPadding * 2 + (battery.isCharging ? iconSize + iconGap : 0)
    readonly property real blockHeight: (battery.available ? numberMetrics.height + lineGap : 0) + statusMetrics.height + pillPaddingY * 2
    readonly property real numberReach: numberMetrics.advanceWidth / 2 + percentGap + percentMetrics.advanceWidth
    readonly property real reach: Math.max(Math.hypot(pillWidth / 2, blockHeight / 2), battery.available ? Math.hypot(numberReach, blockHeight / 2) : 0)
    readonly property real fit: reach > 0 ? Math.min(1, innerRadius / reach) : 1

    function duration(seconds) {
        const minutes = Math.round(seconds / 60);
        if (!Number.isFinite(seconds) || seconds <= 0 || minutes < 1) return "";
        return minutes >= 60 ? Math.floor(minutes / 60) + "h " + (minutes % 60) + "m" : minutes + "m";
    }

    readonly property string status: {
        if (!battery.available) return Translation.tr("No battery");
        if (battery.chargeState === UPowerDeviceState.FullyCharged) return Translation.tr("Full");
        const time = duration(battery.isCharging ? battery.timeToFull : battery.timeToEmpty);
        if (battery.isCharging) return time !== "" ? Translation.tr("%1 to full").arg(time) : Translation.tr("Charging");
        if (!UPower.onBattery) return Translation.tr("Plugged in");
        return time !== "" ? Translation.tr("%1 left").arg(time) : Translation.tr("On battery");
    }

    implicitWidth: size
    implicitHeight: size

    MaterialShape {
        id: body
        anchors.fill: parent
        shape: MaterialShape.Shape.Cookie12Sided
        color: Qt.alpha(Appearance.m3colors.m3secondaryContainer, 0.72)
    }

    Rectangle {
        id: light
        anchors.fill: parent
        visible: false
        layer.enabled: true
        gradient: Gradient {
            GradientStop { position: 0.17; color: Qt.rgba(1, 1, 1, 0.08) }
            GradientStop { position: 0.55; color: "transparent" }
        }
    }

    MaterialShape {
        id: lightMask
        anchors.fill: parent
        shape: body.shape
        color: "black"
        visible: false
        layer.enabled: true
    }

    MultiEffect {
        anchors.fill: parent
        source: light
        maskEnabled: true
        maskSource: lightMask
    }

    Shape {
        anchors.fill: parent
        visible: battery.available
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: root.ringWidth
            strokeColor: root.accent
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: root.ringRadius
                radiusY: root.ringRadius
                startAngle: -90
                sweepAngle: root.sweep
            }
        }

        ShapePath {
            strokeWidth: root.trackSweep > 0 ? root.ringWidth : 0
            strokeColor: Qt.alpha(root.textColor, 0.2)
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: root.ringRadius
                radiusY: root.ringRadius
                startAngle: -90 + root.sweep + root.gap
                sweepAngle: root.trackSweep
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: root.lineGap * root.fit

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: battery.available
            implicitWidth: number.implicitWidth
            implicitHeight: number.implicitHeight

            Text {
                id: number
                text: root.percent
                font.family: Appearance.font.family.main
                font.pixelSize: root.numberSize * root.fit
                font.weight: Font.DemiBold
                color: root.textColor
            }

            Text {
                anchors.left: number.right
                anchors.leftMargin: root.percentGap * root.fit
                anchors.top: parent.top
                anchors.topMargin: root.ringRadius * 0.12 * root.fit
                text: "%"
                font.family: Appearance.font.family.main
                font.pixelSize: root.percentSize * root.fit
                font.weight: Font.Medium
                color: root.textColor
                opacity: 0.8
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            implicitWidth: statusRow.implicitWidth + root.pillPadding * 2 * root.fit
            implicitHeight: statusRow.implicitHeight + root.pillPaddingY * 2 * root.fit
            radius: height / 2
            color: Qt.alpha(root.textColor, 0.16)

            Row {
                id: statusRow
                anchors.centerIn: parent
                spacing: root.iconGap * root.fit

                Text {
                    visible: battery.isCharging
                    text: "bolt"
                    font.family: Fonts.iconMaterialFamily
                    font.pixelSize: root.iconSize * root.fit
                    color: root.accent
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.status
                    font.family: Appearance.font.family.main
                    font.pixelSize: statusMetrics.font.pixelSize * root.fit
                    font.weight: Font.Medium
                    color: root.textColor
                }
            }
        }
    }

    TextMetrics {
        id: numberMetrics
        text: root.percent
        font.family: Appearance.font.family.main
        font.pixelSize: root.numberSize
        font.weight: Font.DemiBold
    }

    TextMetrics {
        id: percentMetrics
        text: "%"
        font.family: Appearance.font.family.main
        font.pixelSize: root.percentSize
        font.weight: Font.Medium
    }

    TextMetrics {
        id: statusMetrics
        text: root.status
        font.family: Appearance.font.family.main
        font.pixelSize: root.ringRadius * (battery.available ? 0.19 : 0.3)
        font.weight: Font.Medium
    }

    ResizeHandler {
        anchorItem: body
        hoverActive: root.containsMouse
        locked: Config.options.background.widgetsLocked
        currentWidth: root.size
        resizeMode: "diagonal"
        onResized: newValue => root.size = Math.max(100, newValue)
        onResizeFinished: root.configEntry.size = root.size
    }
}
