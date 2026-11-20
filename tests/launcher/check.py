"""Run a short launcher check on Wayland with temporary shell config and state."""
from pathlib import Path
import os
import subprocess
import tempfile


repo = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix="end4-launcher-check-") as directory:
    temp = Path(directory)
    for name in ("modules", "services", "GlobalStates.qml", "assets", "translations", "scripts"):
        (temp / name).symlink_to(repo / name)
    for name in ("config", "state", "cache"):
        (temp / name).mkdir()
    (temp / "config/illogical-impulse").mkdir()
    (temp / "config/illogical-impulse/config.json").write_bytes(
        (repo / "config/illogical-impulse/config.json").read_bytes()
    )
    (temp / "shell.qml").symlink_to(Path(__file__).with_name("check.qml"))
    environment = os.environ | {
        "QT_QPA_PLATFORM": "wayland",
        "XDG_CONFIG_HOME": str(temp / "config"),
        "XDG_STATE_HOME": str(temp / "state"),
        "XDG_CACHE_HOME": str(temp / "cache"),
    }
    result = subprocess.run(
        ["qs", "--no-color", "-p", str(temp)],
        env=environment, capture_output=True, text=True, timeout=20,
    )
    output = result.stdout + result.stderr
    print(output, end="")
    assert result.returncode == 0, f"Quickshell exited with {result.returncode}"
    assert "FAIL:" not in output, "Launcher assertion failed"
    assert "LAUNCHER CHECK PASSED" in output, "Launcher check did not finish"
