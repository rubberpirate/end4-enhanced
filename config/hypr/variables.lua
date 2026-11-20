local mainMod = "SUPER"

local vars = {
    terminal             = "ghostty",
    browser              = "firefox",
    files                = "nautilus",
    editor               = "code",
    launcher             = "qs -c nebula ipc call launcher toggle",

    mainMod              = mainMod,

    borderSize           = 1,
    roundingPower        = 2,
    resizeOnBorder       = false,

    shadowEnabled        = true,
    shadowRange          = 15,

    kbLayout             = "us",
    naturalScroll        = false,

    kbTerminal           = mainMod .. " + T",
    kbBrowser            = mainMod .. " + W",
    kbEditor             = mainMod .. " + C",
    kbFiles              = mainMod .. " + E",
    kbLauncher           = mainMod .. " + SUPER_L",
    kbClose              = mainMod .. " + Q",
    kbFloat              = mainMod .. " + V",
    kbFullscreen         = mainMod .. " + F",
    kbPseudo             = mainMod .. " + P",
    kbToggleSplit        = mainMod .. " + J",
    kbLock               = mainMod .. " + L",
    kbRecord             = mainMod .. " + SHIFT + R",
    kbRecordRegion       = mainMod .. " + SHIFT + ALT + R",
    kbMedia              = mainMod .. " + SHIFT + N",
    kbMissed             = mainMod .. " + N",
    kbEditWidgets        = mainMod .. " + SHIFT + E",
    kbScreenshotRegion   = mainMod .. " + SHIFT + S",
    kbScreenshotScreen   = "Print",
    kbClipboard          = mainMod .. " + SHIFT + V",
    kbExit               = mainMod .. " + M",
    kbSpecial            = mainMod .. " + S",
    kbMoveToSpecial      = mainMod .. " + ALT + S",
}

local function override(file)
    local ok, chosen = pcall(require, file)
    if ok and type(chosen) == "table" then
        for key, value in pairs(chosen) do
            vars[key] = value
        end
    end
end

override("apps")
override("hypr-vars")

return vars
