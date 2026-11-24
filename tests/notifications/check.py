"""Exercise bubble stacking and animation in an isolated, offscreen Quickshell."""
from pathlib import Path
import os
import argparse
import shutil
import subprocess
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--graphics", action="store_true", help="Render on the active Wayland desktop")
args = parser.parse_args()

repo = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix="end4-bubble-check-") as directory:
    temp = Path(directory)
    module = temp / "modules/ii/notificationPopup"
    module.mkdir(parents=True)
    for name in ("BubbleCard.qml", "BubbleStack.qml", "DripMotion.js", "shaders"):
        source = repo / "modules/ii/notificationPopup" / name
        if source.is_dir(): shutil.copytree(source, module / name)
        else: shutil.copy2(source, module / name)
    (temp / "shell.qml").write_text(Path(__file__).with_suffix(".qml").read_text().replace("../../modules", "modules"))
    for name in ("config", "state", "cache", "runtime"):
        (temp / name).mkdir()
    environment = os.environ | {
        "QT_QPA_PLATFORM": "wayland" if args.graphics else "offscreen",
        "QT_QUICK_BACKEND": "rhi" if args.graphics else "software",
        "XDG_RUNTIME_DIR": os.environ["XDG_RUNTIME_DIR"] if args.graphics else str(temp / "runtime"),
        "XDG_CONFIG_HOME": str(temp / "config"),
        "XDG_STATE_HOME": str(temp / "state"),
        "XDG_CACHE_HOME": str(temp / "cache"),
    }
    try:
        result = subprocess.run(["qs", "--no-color", "-p", str(temp)],
                                env=environment, capture_output=True, text=True, timeout=20)
    except subprocess.TimeoutExpired as error:
        print((error.stdout or b" ").decode(), end="")
        print((error.stderr or b" ").decode(), end="")
        raise
    output = result.stdout + result.stderr
    print(output, end="")
    assert result.returncode == 0, f"Quickshell exited with {result.returncode}"
    assert "FAIL:" not in output, "Bubble assertion failed"
    assert "BUBBLE CHECK PASSED" in output, "Bubble check did not finish"
    for error in ("ReferenceError", "TypeError", "Unable to assign", "Failed to create", "ShaderEffect: shader"):
        assert error not in output, f"Runtime error: {error}"

    if args.graphics:
        from PIL import Image
        image = Image.open("/tmp/end4-bubble-stack.png").convert("RGBA")
        center = image.width // 2
        assert image.getpixel((center - 120, 5)) == (48, 48, 56, 255), "Existing bar island was overpainted"
        assert image.getpixel((center, 45)) == (0, 0, 0, 255), "Detached capsule did not render black"
        assert image.getpixel((0, 100))[3] == 0, "Empty space must remain transparent"
        print("LIQUID RENDER CHECK PASSED")
