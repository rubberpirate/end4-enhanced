pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    readonly property bool active: cards.length > 0 || counterCard !== null
    property color anchorColor: "black"
    property real anchorHeight: 32
    property real anchorWidth: 0
    property var cards: []
    property var counterCard: null
    property string fontFamily: "sans-serif"
    property bool growUp: false
    property real maximumWidth: 410
    property var notifications: []
    readonly property int overflowCount: Math.max(0, notifications.length - cards.filter(c =>
    !c.leaving).length)
    readonly property bool pending: notifications.some(n => !cards.some(c => c.notificationId
                                                                             === n.notificationId))
    property bool reducedMotion: false

    signal dismiss(int id)
    signal activate(int id)
    signal presented(int id)
    signal withdrawn(int id)
    signal hoverChanged(int id, bool hovered)
    signal invoke(int id, string action)
    signal openHistory

    function clear() {
        const oldCards = cards;
        const oldCounter = counterCard;
        cards = [];
        counterCard = null;
        oldCards.forEach(card => { withdrawn(card.notificationId); card.destroy(); });
        if (oldCounter)
            oldCounter.destroy();
    }
    function removeCard(card) {
        if (card === counterCard)
            counterCard = null;
        else
            cards = cards.filter(c => c !== card);
        card.destroy();
        Qt.callLater(sync);
    }
    function sync() {
        let top = anchorHeight + 12;
        let above = null;
        for (const card of cards) {
            if (!notifications.some(n => n.notificationId === card.notificationId))
                card.leave(above ? above.motion.center.target : null, above ? above.pillHeight : 0,
                           anchorHeight);
            if (!card.leaving) {
                card.move(top);
                top += card.pillHeight + 10;
                above = card;
            }
        }
        const next = notifications.find(n => !cards.some(c => c.notificationId === n.notificationId));
        // Wait until the preceding capsule has spread before feeding the next drop.
        if (next && cards.length < 3 && (!above || above.clock > above.motion.cue + 0.18)) {
            const card = cardComponent.createObject(root, {
                                                        notificationObject: next
                                                    });
            cards = cards.concat([card]);
            card.start(top, above ? above.motion.center.target : null, above ? above.motion.center.target
                                                                               + above.pillHeight / 2 :
                                                                               anchorHeight, anchorHeight);
        }
        const countTop = anchorHeight + 12 + cards.filter(c => !c.leaving).reduce((h, c) => h + c.pillHeight
                                                                                            + 10, 0);
        if (overflowCount > 0 && cards.length >= 3 && cards.every(c => c.clock > c.motion.cue + 0.18) &&
                !counterCard) {
            const last = cards[cards.length - 1];
            counterCard = cardComponent.createObject(root, {
                                                         notificationObject: null,
                                                         counter: true
                                                     });
            counterCard.start(countTop, last.motion.center.target, last.motion.center.target + last.pillHeight
                              / 2, anchorHeight);
        }
        if (counterCard) {
            counterCard.move(countTop);
            if (overflowCount === 0 || cards.length < 3) {
                const last = cards.filter(c => !c.leaving).slice(-1)[0];
                counterCard.leave(last ? last.motion.center.target : null, last ? last.pillHeight : 0,
                                  anchorHeight);
            }
        }
    }

    height: anchorHeight + 3 * 72 + 64

    transform: Scale {
        origin.y: root.anchorHeight / 2
        yScale: root.growUp ? -1 : 1
    }

    Component.onCompleted: Qt.callLater(sync)
    onNotificationsChanged: Qt.callLater(sync)
    onAnchorHeightChanged: Qt.callLater(sync)

    Timer {
        interval: 60
        repeat: true
        running: root.pending || (root.overflowCount > 0 && !root.counterCard)

        onTriggered: root.sync()
    }

    ShaderEffect {
        property vector4d anchor: Qt.vector4d(root.anchorHeight / 2, root.anchorWidth / 2, root.anchorHeight
                                              / 2, Math.min(10, root.anchorHeight / 3))
        property color anchorColor: root.anchorColor
        property vector4d drop0: root.cards[0]?.shape ?? Qt.vector4d(0, 0, 0, 0)
        property vector4d drop1: root.cards[1]?.shape ?? Qt.vector4d(0, 0, 0, 0)
        property vector4d drop2: root.cards[2]?.shape ?? Qt.vector4d(0, 0, 0, 0)
        property vector4d drop3: root.counterCard?.shape ?? Qt.vector4d(0, 0, 0, 0)
        property vector2d resolution: Qt.vector2d(width, height)

        anchors.fill: parent
        fragmentShader: Qt.resolvedUrl("shaders/liquid.frag.qsb")
        z: -1
    }

    Component {
        id: cardComponent

        BubbleCard {
            fontFamily: root.fontFamily
            growUp: root.growUp
            maximumWidth: root.maximumWidth
            overflowCount: root.overflowCount
            reducedMotion: root.reducedMotion

            onDismiss: id => root.dismiss(id)
            onActivate: id => root.activate(id)
            onPresented: id => root.presented(id)
            onFinished: root.removeCard(this)
            onHoverChanged: (id, hovered) => root.hoverChanged(id, hovered)
            onInvoke: (id, action) => root.invoke(id, action)
            onOpenHistory: root.openHistory()
        }
    }
}
