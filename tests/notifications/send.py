"""Send deterministic test notifications to the private test bus."""
import subprocess
import sys

mode = sys.argv[1]
base = ["gdbus", "call", "--session", "--dest", "org.freedesktop.Notifications",
        "--object-path", "/org/freedesktop/Notifications", "--method", "org.freedesktop.Notifications.Notify", "--"]
if mode == "queue":
    for number in range(1, 7):
        subprocess.run(base + ["Queue test", "0", "", f"Queued {number}", "A full timeout after promotion", "[]", "{}", "-1"], check=True, capture_output=True)
else:
    hints = "{'desktop-entry': <'end4-bubble-source'>}" if mode in ("source", "default") else "{}"
    actions = '["default", "Open"]' if mode == "default" else "[]"
    subprocess.run(base + ["Bubble Source" if mode == "source" else "Positions", "0", "", mode, "", actions, hints, "0"], check=True, capture_output=True)
