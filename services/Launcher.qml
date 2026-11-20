pragma Singleton
// Adapted from Nebula's launcher; attribution and AGPL-3.0 license: modules/ii/launcher/.

import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.models

Singleton {
    id: root

    readonly property int appSlots: 8
    readonly property int commandSlots: 7
    property string query: ""
    readonly property bool commandMode: query.startsWith(">")
    readonly property int slots: commandMode ? commandSlots : appSlots
    readonly property var apps: AppSearch.list.filter(e => !e.noDisplay).sort((a, b) => a.name.localeCompare(b.name))
    readonly property var commands: [
        { name: Translation.tr("Theme"), iconName: "palette", execute: () => GlobalStates.openSettingsAt("interface", Translation.tr("Color Schemes")) },
        { name: Translation.tr("Settings"), iconName: "settings", execute: () => GlobalStates.settingsOpen = true },
        { name: Translation.tr("Lock"), iconName: "lock", execute: () => Session.lock() },
        { name: Translation.tr("Sleep"), iconName: "bedtime", execute: () => Session.suspend() },
        { name: Translation.tr("Restart"), iconName: "restart_alt", execute: () => Session.reboot() },
        { name: Translation.tr("Shutdown"), iconName: "power_settings_new", execute: () => Session.poweroff() },
        { name: Translation.tr("Log out"), iconName: "logout", execute: () => Session.logout() }
    ]

    // Reuse end4's search providers, including settings, math and shell prefixes.
    onQueryChanged: {
        if (!commandMode) LauncherSearch.query = query;
    }

    readonly property var results: {
        if (commandMode) {
            const search = query.slice(1).trim().toLowerCase();
            return commands.filter(c => c.name.toLowerCase().includes(search));
        }
        if (query.trim() !== "") return LauncherSearch.results.slice(0, appSlots);
        const recent = Persistent.states.launcherRecentApps.map(id => apps.find(e => e.id === id)).filter(Boolean);
        return recent.concat(apps.filter(e => !recent.includes(e))).slice(0, appSlots).map(entry => ({
            id: entry.id,
            name: entry.name,
            iconName: entry.icon,
            iconType: LauncherSearchResult.IconType.System,
            execute: () => {
                if (!entry.runInTerminal) entry.execute();
                else Quickshell.execDetached(["bash", "-c", `${Config.options.apps.terminal} -e '${StringUtils.shellSingleQuoteEscape(entry.command.join(' '))}'`]);
            }
        }));
    }

    function close() { GlobalStates.launcherOpen = false; }
    function open() { GlobalStates.launcherOpen = true; }
    function toggle() { GlobalStates.launcherOpen = !GlobalStates.launcherOpen; }

    function activate(item) {
        if (!item) return;
        close();
        item.execute();
        if (item.id && item.iconType === LauncherSearchResult.IconType.System) {
            Persistent.states.launcherRecentApps = [item.id, ...Persistent.states.launcherRecentApps.filter(id => id !== item.id)].slice(0, 20);
        }
    }

    Connections {
        target: GlobalStates
        function onScreenLockedChanged() { if (GlobalStates.screenLocked) root.close(); }
    }

    Connections {
        target: WM
        function onActiveWorkspaceChanged() { root.close(); }
        function onFocusedMonitorChanged() { root.close(); }
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open(); }
        function close(): void { root.close(); }
    }
}
