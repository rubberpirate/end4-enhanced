pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.modules.common
import qs.services

PanelWindow {
    id: root
    readonly property string position: Notifications.popupPosition
    readonly property bool isTop: position.startsWith("top")
    readonly property alias stack: bubbles
    visible: bubbles.allowed && bubbles.active
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors {
        top: root.isTop
        bottom: !root.isTop
        left: root.position.endsWith("left")
        right: root.position.endsWith("right")
    }
    margins { left: 4; right: 4; top: 4; bottom: 4 }
    implicitWidth: Math.min(screen?.width ?? 680, Math.max(200, ...bubbles.cards.map(card => card.pillWidth)) + 32)
    implicitHeight: bubbles.height
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.namespace: "quickshell:notificationBubble"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    mask: Region {
        Region { item: bubbles.cards[0] ?? null; radius: (bubbles.cards[0]?.height ?? 0) / 2 }
        Region { item: bubbles.cards[1] ?? null; radius: (bubbles.cards[1]?.height ?? 0) / 2 }
        Region { item: bubbles.cards[2] ?? null; radius: (bubbles.cards[2]?.height ?? 0) / 2 }
        Region { item: bubbles.counterCard; radius: 16 }
    }
    BubbleNotifications {
        id: bubbles
        screenName: root.screen?.name ?? ""
        embeddedInBar: false
        maximumWidth: Math.min(Appearance.sizes.notificationPopupWidth, (root.screen?.width ?? 680) - 32)
        width: parent.width
        x: 0
        y: root.isTop ? 0 : height
    }
}
