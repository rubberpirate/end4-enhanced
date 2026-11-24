pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import "DripMotion.js" as Motion

Item {
    id: root

    readonly property real actionWidth: actions.length ? actionRow.implicitWidth : 20
    readonly property var actions: (notificationObject?.actions ?? []).filter(a => a.identifier !== "default")
    property real clock: 0
    property bool counter: false
    readonly property string detail: (notificationObject?.body ?? "").replace(/<[^>]*>/g, " ").replace(/\s+/g,
                                                                                                       " ").trim(
                                         )
    property real detailOpacity: 0
    property string fontFamily: "sans-serif"
    property bool growUp: false
    property bool leaving: motion?.leaving ?? false
    property real maximumWidth: 410
    property var motion: null
    property bool moving: motion !== null && clock < motion.end
    property bool presentedOnce: false
    readonly property int notificationId: notificationObject?.notificationId ?? -1
    required property var notificationObject
    property int overflowCount: 0
    readonly property bool persistent: !notificationObject?.timer
    readonly property real pillHeight: counter ? 32 : (detail.length ? 60 : 48)
    readonly property real pillWidth: counter ? 32 : Math.min(maximumWidth, Math.max(200, 14 + 24 + 10
                                                                                     + Math.max(
                                                                                         titleMetrics.advanceWidth,
                                                                                         detailMetrics.advanceWidth)
                                                                                     + 10 + actionWidth + 14))
    property bool reducedMotion: false
    property real remaining: 1
    property vector4d shape: Qt.vector4d(0, 0, 0, 0)
    property double shownAt: Date.now()
    property real sidesOpacity: 0
    readonly property string summary: notificationObject?.summary ?? ""

    signal dismiss(int id)
    signal activate(int id)
    signal presented(int id)
    signal finished
    signal hoverChanged(int id, bool hovered)
    signal invoke(int id, string action)
    signal openHistory

    function leave(anchorCenter, anchorHeight, notchHeight) {
        if (!motion || leaving)
            return;
        Motion.leave(motion, anchorCenter, anchorHeight, notchHeight, clock, reducedMotion);
        motionChanged();
        updateFrame();
    }
    function move(top) {
        if (!motion)
            return;
        Motion.move(motion, top, clock, reducedMotion);
        motionChanged();
    }
    function start(top, anchorCenter, anchorBottom, notchHeight) {
        clock = 0;
        motion = Motion.enter(pillWidth, pillHeight, top, anchorCenter, anchorBottom, notchHeight, clock,
                              reducedMotion);

        updateFrame();
    }
    function updateFrame() {
        if (!motion)
            return;
        shape = Qt.vector4d(Motion.sample(motion.center, clock), Math.max(1, Motion.sample(motion.width,
                                                                                           clock)), Math.max(1,
                                                                                                             Motion.sample(
                                                                                                                 motion.height,
                                                                                                                 clock)), Math.max(
                                0, Motion.sample(motion.blend, clock)));
        sidesOpacity = Motion.opacity(motion, clock, false);
        detailOpacity = Motion.opacity(motion, clock, true);
        if (!counter && !leaving && !presentedOnce && sidesOpacity >= 1 && detailOpacity >= 1) {
            presentedOnce = true;
            presented(notificationId);
        }
        if (leaving && !moving)
            finished();
    }

    ToolTip.delay: 800
    ToolTip.text: root.summary + (root.detail ? "\n" + root.detail : "")
    ToolTip.visible: hover.hovered && !root.counter
    clip: true
    enabled: !leaving && sidesOpacity > 0.8
    height: Math.max(0, shape.z)
    visible: width > 0 && height > 0
    width: Math.max(0, shape.y)
    x: (parent.width - width) / 2
    y: shape.x - shape.z / 2

    transform: Scale {
        origin.y: root.height / 2
        yScale: root.growUp ? -1 : 1
    }

    onPillWidthChanged: {
        if (motion && !leaving) {
            Motion.resize(motion, pillWidth, clock, reducedMotion);
            motionChanged();
        }
    }

    FrameAnimation {
        running: root.moving

        onTriggered: {
            root.clock += frameTime;
            root.updateFrame();
        }
    }

    Timer {
        interval: 33
        repeat: true
        running: !root.counter && !root.leaving && !root.persistent && !hover.hovered && (root.notificationObject?.timer?.running ?? true)

        onTriggered: root.remaining = Math.max(0, 1 - (Date.now() - (root.notificationObject?.popupStartedAt || root.shownAt)) / Math.max(1,
                                                                                             root.notificationObject
                                                                                             ?.timer?.interval
                                                                                             ?? 7000))
    }

    TextMetrics {
        id: titleMetrics

        font.family: root.fontFamily
        font.pixelSize: 13
        font.weight: Font.DemiBold
        text: root.summary
    }

    TextMetrics {
        id: detailMetrics

        font.family: root.fontFamily
        font.pixelSize: 11
        text: root.detail
    }

    HoverHandler {
        id: hover

        onHoveredChanged: {
            if (root.counter)
                return;
            if (!hovered) {
                root.shownAt = Date.now();
                root.remaining = 1;
            }
            root.hoverChanged(root.notificationId, hovered);
        }
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

        onTapped: (eventPoint, button) => {
            if (root.counter)
                root.openHistory();
            else if (button !== Qt.LeftButton)
                root.dismiss(root.notificationId);
            else
                root.activate(root.notificationId);
        }
    }

    Item {
        anchors.centerIn: parent
        height: root.pillHeight
        opacity: root.sidesOpacity
        visible: !root.counter
        width: root.pillWidth

        Item {
            anchors.verticalCenter: parent.verticalCenter
            height: 24
            width: 24
            x: 14

            IconImage {
                anchors.fill: parent
                source: root.notificationObject?.appIcon ? (root.notificationObject.appIcon.startsWith("/")
                                                            || root.notificationObject.appIcon.startsWith(
                                                                "file:") ? root.notificationObject.appIcon :
                                                                           Quickshell.iconPath(
                                                                               root.notificationObject.appIcon,
                                                                               "dialog-information")) : ""
                visible: source.toString() !== ""
            }

            Rectangle {
                anchors.fill: parent
                color: root.notificationObject?.urgency === "critical" ? "#ffab00" : "#009dff"
                radius: 12
                visible: !root.notificationObject?.appIcon

                Text {
                    anchors.centerIn: parent
                    color: "white"
                    font.bold: true
                    font.pixelSize: 17
                    text: root.notificationObject?.urgency === "critical" ? "!" : "i"
                }
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            width: Math.max(0, parent.width - 48 - 10 - root.actionWidth - 14)
            x: 48

            Text {
                color: "#f5f5f5"
                elide: Text.ElideRight
                font.family: root.fontFamily
                font.pixelSize: 13
                font.weight: Font.DemiBold
                text: root.summary
                textFormat: Text.PlainText
                width: parent.width
            }

            Text {
                color: "#999999"
                elide: Text.ElideRight
                font.family: root.fontFamily
                font.pixelSize: 11
                opacity: root.sidesOpacity > 0 ? root.detailOpacity / root.sidesOpacity : 0
                text: root.detail
                textFormat: Text.PlainText
                visible: root.detail.length > 0
                width: parent.width
            }
        }

        Row {
            id: actionRow

            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            visible: root.actions.length > 0

            Repeater {
                model: root.actions

                delegate: Button {
                    id: actionButton

                    required property int index
                    required property var modelData

                    Accessible.name: text
                    implicitHeight: 28
                    implicitWidth: Math.max(28, Math.min(100, (root.maximumWidth - 134) / root.actions.length
                                                         - 6, actionText.implicitWidth + 24))
                    padding: 0
                    text: modelData.text

                    background: Rectangle {
                        border.color: "white"
                        border.width: actionButton.visualFocus ? 2 : 0
                        color: actionButton.down ? "#444444" : actionButton.index === root.actions.length - 1 ? (
                                                                                                                    actionButton.hovered
                                                                                                                    ? "#22863a" :
                                                                                                                      "#1b7130") :
                                                                                                                (actionButton.hovered
                                                                                                                 ? "#383838" :
                                                                                                                   "#242424")
                        radius: height / 2
                    }
                    contentItem: Text {
                        id: actionText

                        color: "#f5f5f5"
                        elide: Text.ElideRight
                        font.family: root.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        text: actionButton.text
                        textFormat: Text.PlainText
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: root.invoke(root.notificationId, modelData.identifier)
                }
            }
        }

        Canvas {
            id: countdown

            property real progress: root.remaining

            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            height: 20
            visible: !root.actions.length
            width: 20

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                if (root.persistent) {
                    ctx.fillStyle = "#dddddd";
                    ctx.beginPath();
                    ctx.arc(10, 10, 3, 0, 2 * Math.PI);
                    ctx.fill();
                } else {
                    ctx.lineWidth = 2.5;
                    ctx.strokeStyle = "#163e23";
                    ctx.beginPath();
                    ctx.arc(10, 10, 8, 0, 2 * Math.PI);
                    ctx.stroke();
                    ctx.strokeStyle = "#22c55e";
                    ctx.lineCap = "round";
                    ctx.beginPath();
                    ctx.arc(10, 10, 8, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * root.remaining);
                    ctx.stroke();
                }
            }
            onProgressChanged: requestPaint()
        }
    }

    Text {
        anchors.centerIn: parent
        color: "#f5f5f5"
        font.family: root.fontFamily
        font.pixelSize: 12
        font.weight: Font.DemiBold
        opacity: root.sidesOpacity
        text: root.overflowCount
        visible: root.counter
    }
}
