The clover app launcher is adapted from [Nebula by LilaccFlowerr](https://github.com/LilaccFlowerr/Nebula), from the supplied `laucnher/quickshell/nebula/widgets/launcher` files and `components/Curves.js`. The adapted files retain Nebula's AGPL-3.0 license; see [LICENSE](LICENSE).

The port keeps the rotating clover, staggered icon entrance, spring rotation when selecting results, icon swaps, expanding search pill, glass highlight, and reversed exit. Shapes use end4-enhanced's existing polygon renderer, without adding M3Shapes as a dependency. Colors and fonts follow the main shell.

Tap **Super**, or click the bar/dock launcher button. Type to search; use arrows, Tab/Shift+Tab, or the mouse wheel to rotate results. Enter or a click activates the selected result. Escape or clicking outside dismisses it. Type `>` for Theme, Settings, Lock, Sleep, Restart, Shutdown, and Log out. Theme opens end4-enhanced's Color Schemes settings.

**Super+Tab** still opens the workspace overview. Clipboard and emoji shortcuts keep the existing search UI. The `search open/toggle/close` IPC commands open/toggle/close the app launcher; `search workspacesToggle` opens the overview. The launcher also exposes its own `launcher open/toggle/close` IPC target.

Run `python3 tests/launcher/check.py` in a running Wayland session for an isolated runtime check. It briefly shows the launcher, uses temporary configuration and state, and exits automatically. It checks application search, command filtering, navigation, result swapping, open/close reversal, and overview exclusion without executing applications or session actions.
