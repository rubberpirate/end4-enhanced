The battery widget is adapted from Nebula by LilaccFlowerr, using the supplied `laucnher/quickshell/nebula/widgets/desktop/BatteryWidget.qml` and `components/GlassShape.qml`. The adapted widget is licensed under AGPL-3.0; see [LICENSE](LICENSE).

It keeps the translucent scalloped background, animated ring with a gap, percentage, charging icon, and time estimate. It uses end4-enhanced's existing battery service, colors, fonts, shape renderer, and desktop widget placement. Low charge uses the configured battery warning threshold.

The base configuration enables it at `(600, 100)` with a size of 200 pixels. Toggle it under **Settings → Desktop → Widgets → Battery** or **desktop menu → Widgets → Battery**. Unlock widget positions to drag it; drag its corner handle to resize. Position and size are saved with the other desktop widgets. Systems without a battery show a “No battery” badge.

Run `python3 tests/battery/check.py` on Wayland for an isolated preview and checks of the loader, settings catalog, charging/full/missing states, estimates, and ring animation. Test configuration and state are temporary.
