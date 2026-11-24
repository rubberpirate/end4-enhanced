pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs
import qs.modules.common
import qs.services

BubbleStack {
    id: root

    property string screenName: barWindow?.screen?.name ?? ""
    readonly property string targetScreenName: Hyprland.focusedMonitor?.name ?? Quickshell.screens[0]?.name ?? ""
    readonly property bool allowed: Config.options.notifications.style === "bubble"
        && !GlobalStates.screenLocked && !Config.options.bar.vertical && screenName === targetScreenName
        && embeddedInBar === Notifications.bubbleFromBar
    property bool embeddedInBar: true
    property Item anchorItem: null
    // Read the live item geometry so bar layout, scale and auto-hide remain the source of truth.
    readonly property point anchorPosition: {
        if (!anchorItem) return Qt.point(parent.width / 2, 0);
        const geometry = [anchorItem.x, anchorItem.y, anchorItem.width, anchorItem.height, parent.width,
                          parent.height];
        return anchorItem.mapToItem(parent, anchorItem.width / 2, 0);
    }
    readonly property var barWindow: root.QsWindow.window

    anchorHeight: anchorItem?.height ?? 0
    anchorWidth: anchorItem?.width ?? 0
    fontFamily: Appearance.font.family.main
    growUp: embeddedInBar ? Config.options.bar.bottom : Notifications.popupPosition.startsWith("bottom")
    maximumWidth: Math.min(Appearance.sizes.notificationPopupWidth, parent.width - 24)
    notifications: allowed ? Notifications.popupList : []
    reducedMotion: !Config.options.hyprland.animations.enable
    width: Math.min(parent.width, 680)
    x: anchorPosition.x - width / 2
    y: anchorPosition.y
    z: 10

    onAllowedChanged: {
        if (!allowed)
            clear();
    }
    onDismiss: id => Notifications.discardNotification(id)
    onActivate: id => {
        if (!Notifications.activateNotification(id)) GlobalStates.sidebarRightOpen = true;
    }
    onPresented: id => Notifications.presentPopup(id)
    onWithdrawn: id => Notifications.suspendPopup(id)
    onHoverChanged: (id, hovered) => {
        const notification = Notifications.list.find(n => n.notificationId === id);
        if (!notification?.timer)
            return;
        if (hovered)
            Notifications.cancelTimeout(id);
        else if (notification.popup)
            Notifications.restartPopupTimeout(id);
    }
    onInvoke: (id, action) => Notifications.attemptInvokeAction(id, action)
    onOpenHistory: GlobalStates.sidebarRightOpen = true
}
