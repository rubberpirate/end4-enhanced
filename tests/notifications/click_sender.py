"""Keep a real sender connected and record the action delivered by a bubble click."""
from pathlib import Path
import json
import sys
import dbus
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

DBusGMainLoop(set_as_default=True)
bus = dbus.SessionBus()
loop = GLib.MainLoop()
expected = sys.argv[2]
events = []
notification_id = 0

def action_invoked(identifier, action):
    if identifier == notification_id:
        events.append(["action", str(action)])
        GLib.timeout_add(250, lambda: (loop.quit(), False)[1])

def notification_closed(identifier, reason):
    if identifier == notification_id:
        events.append(["closed", int(reason)])

bus.add_signal_receiver(action_invoked, signal_name="ActionInvoked", dbus_interface="org.freedesktop.Notifications")
bus.add_signal_receiver(notification_closed, signal_name="NotificationClosed", dbus_interface="org.freedesktop.Notifications")
interface = dbus.Interface(bus.get_object("org.freedesktop.Notifications", "/org/freedesktop/Notifications"), "org.freedesktop.Notifications")
notification_id = int(interface.Notify("Pointer Source", 0, "", "Click source test", "Open the source window", ["default", "Open", "view", "View"], {"desktop-entry": sys.argv[1]}, 0))
GLib.timeout_add_seconds(12, lambda: (loop.quit(), False)[1])
loop.run()
Path(sys.argv[3], "click-" + expected + ".json").write_text(json.dumps(events))
assert events.count(["action", expected]) == 1, events
assert len([event for event in events if event[0] == "action"]) == 1, events
assert len([event for event in events if event[0] == "closed"]) == 1, events
