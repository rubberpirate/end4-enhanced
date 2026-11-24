# Notification bubbles

The user wants Drip-style smooth liquid notifications as an optional Standard /
Bubble setting. Their explicit correction: use the current Quickshell bar's
center island (currently M3 Hug). Do not create another notch or island.

Implementation:
- Config.options.notifications.style defaults to standard; both Bar settings
  presentations expose Standard/Bubble.
- BarContent owns BubbleNotifications and supplies its actual center island item
  and fill color. Bar.qml temporarily expands its transparent window and input
  mask while preserving the explicit exclusive zone.
- BubbleStack / BubbleCard use the Drip spring solver and phases in DripMotion.js.
  The liquid shader draws only the extension below the existing island and then
  detached capsules. Bottom bars reverse the flow with upright content.
- Notifications service supplies actions, timers, history and queue data. Bubble
  mode bypasses Dynamic Island's old inline notification provider.
- The checked-in liquid.frag.qsb is built from liquid.frag using qsb; the exact
  rebuild command and Drip's MIT attribution are in notificationPopup/THIRD_PARTY.md.

Validation commands:
- node tests/notifications/motion.mjs
- python tests/notifications/check.py --graphics (temporary Wayland preview)
- python tests/notifications/integration.py (private DBus session and config)

The Ryoku vault path ~/.local/share/ryoku/rashin/AGENTS.md was absent, and both
installed ryoku skill links were unreadable. The available environment reports
Arch Linux / Hyprland. Installed into the running shell at ~/.config/quickshell/end4-enhanced on
2026-11-24. Bubble mode is enabled in ~/.config/illogical-impulse/config.json.
The current bar remains M3 Hug, with clockWidget and resources in the middle.
Backup: ~/.local/state/quickshell/backups/notification-bubbles-20261124-181827.
A real five-second notification displayed correctly; reserved space stayed at
44 px and no new notification-related errors appeared in the running shell log.


Follow-up on 2026-11-24: queued Bubble notifications now keep their timers stopped
until the card is fully revealed. The service owns the timer start timestamp so
countdown rings, hover pause and changes to the configured default timeout agree.
Three cards are visible, excess items are counted, and queued items are promoted
with a full timeout after a slot is released.

Clicking a bubble invokes its native default action when available; otherwise it
focuses a matching source window through WM or launches the resolved desktop
entry. Source desktop-entry metadata is retained in notification history. A
sender with no resolvable source opens history as a fallback.

All six position settings work in Bubble mode. The center position matching the
bar edge still uses the existing island inside BarContent. Other positions use
a transparent BubblePopup with no painted source/notch. The position picker is
now enabled for Bubble mode, and sender-defined persistent/explicit timeouts keep
their existing behavior.

Installed nine changed files into the current shell, with backup at
~/.local/state/quickshell/backups/notification-bubbles-20261124-184526.
Validated private-session queue promotion, hidden timers, live timeout changes,
source launch/focus, native default actions, all six positions and Standard mode.
Live five-notification capture showed three cards plus count 2, then promoted
cards 4 and 5. Test notifications were transient; user settings were preserved.
