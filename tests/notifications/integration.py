"""Test actual notification delivery and style routing with isolated config and DBus."""
from pathlib import Path
import os
import argparse
import subprocess
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--scenario", choices=("integration", "queue", "click"), default="integration")
args = parser.parse_args()

repo = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix="end4-bubble-integration-") as directory:
    temp = Path(directory)
    for name in ("modules", "services", "GlobalStates.qml", "assets", "translations", "scripts"):
        (temp / name).symlink_to(repo / name)
    for name in ("config", "state", "cache"):
        (temp / name).mkdir()
    (temp / "config/illogical-impulse").mkdir()
    (temp / "config/illogical-impulse/config.json").write_text('{"bar":{"cornerStyle":4,"layouts":{"leftLayout":[],"middleLayout":["clockWidget"],"rightLayout":[]}},"notifications":{"position":"top_center"}}')
    (temp / "shell.qml").write_text(Path(__file__).with_name(args.scenario + ".qml").read_text())
    applications = temp / "data/applications"
    applications.mkdir(parents=True)
    (applications / "end4-bubble-source.desktop").write_text(
        "[Desktop Entry]\nType=Application\nName=Bubble Source\nExec=/usr/bin/touch " + str(temp / "source-opened") + "\n")
    helper = Path(__file__).with_name("send.py")
    (temp / "send.py").write_text(helper.read_text() if helper.exists() else "")
    (temp / "click_sender.py").write_text(Path(__file__).with_name("click_sender.py").read_text())
    environment = os.environ | {
        "QT_QPA_PLATFORM": "wayland",
        "QT_NO_XDG_DESKTOP_PORTAL": "1",
        "QT_ACCESSIBILITY": "0",
        "NO_AT_BRIDGE": "1",
        "XDG_CONFIG_HOME": str(temp / "config"),
        "XDG_STATE_HOME": str(temp / "state"),
        "XDG_CACHE_HOME": str(temp / "cache"),
        "XDG_DATA_HOME": str(temp / "data"),
        "BUBBLE_TEST_ROOT": str(temp),
    }
    bus_config = temp / "bus.conf"
    bus_config.write_text('<busconfig><type>session</type><listen>unix:tmpdir=/tmp</listen><policy context="default"><allow send_destination="*"/><allow receive_sender="*"/><allow own="*"/></policy></busconfig>')
    try:
        result = subprocess.run(["dbus-run-session", "--config-file", str(bus_config), "--", "qs", "--no-color", "-p", str(temp)],
                                env=environment, capture_output=True, text=True, timeout=20)
    except subprocess.TimeoutExpired as error:
        output = (error.stdout or b" ").decode() + (error.stderr or b" ").decode()
        Path("/tmp/end4-bubble-integration.log").write_text(output)
        print(output, end="")
        raise
    output = result.stdout + result.stderr
    (Path("/tmp/end4-bubble-integration.log")).write_text(output)
    print(output, end="")
    assert result.returncode == 0, f"Quickshell exited with {result.returncode}"
    assert "FAIL:" not in output, "Notification integration assertion failed"
    assert "INTEGRATION CHECK PASSED" in output, "Integration check did not finish"
    for error in ("ReferenceError", "TypeError", "Unable to assign", "Binding loop", "Failed to load configuration"):
        assert error not in output, f"Runtime error: {error}"

    if args.scenario == "queue":
        assert (temp / "source-opened").exists(), "Click did not launch the notification source"

    if args.scenario == "click":
        import json
        for action in ("default", "view"):
            events = json.loads((temp / ("click-" + action + ".json")).read_text())
            assert events.count(["action", action]) == 1, events
