The active Hyprland configuration is `~/.config/hypr/hyprland.lua`, running Hyprland 0.57.2. The cloned Lua hyprsplit library is at `~/.config/hypr/hyprsplit/`; its user configuration is `~/.config/hypr/custom/hyprsplit.lua`, required at the end of `custom/keybinds.lua`.

Explicit monitor priority assigns `eDP-1` workspaces 1–10 and `HDMI-A-5` workspaces 11–20. Workspace rules pin each range. Super+1–0 focuses local workspaces; Super+Shift+1–0 silently moves a window there. Existing Super+Alt+numbers and keypad bindings also use hyprsplit. Number keys use raw codes with prior keysym bindings removed to prevent duplicate actions. Existing relative workspace navigation and movement shortcuts use hyprsplit too.

Super+Shift+Tab swaps windows between the two active monitor workspaces. It does not preserve the exact tiled layout. Super+Tab retains overview. Super+G recovers rogue windows, replacing the previous widget overlay shortcut; Super+D retains maximize.

Validated the staged full config with `Hyprland --verify-config`, tested the real library against mocked monitor/window APIs, and checked live bindings, monitor ranges, window placement, and an empty `hyprctl configerrors`. The swap was tested with mocks, not with the user's live windows. Existing external workspace 2 windows were moved to 12 and original monitor focus restored. Backup: `~/.config/hypr/backups/hyprsplit-20261120-221148/`.

This version rejects legacy `movetoworkspacesilent` through hyprctl; use `hyprctl eval` with `hl.dispatch(hl.dsp.window.move({...}))`. The Ryoku vault remains absent and its installed skill symlink is broken in this environment.
