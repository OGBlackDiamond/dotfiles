-- Hyprland Lua config
-- Converted from hyprland.conf to the new Lua config system (Hyprland 0.55+)
-- See https://wiki.hypr.land/Configuring/Start/
------------------
---- MONITORS ----
------------------
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "1",
})
local dockMonitorScript = "/home/caden/bin/hypr-dock-monitors"
hl.on("monitor.added", function()
    hl.exec_cmd("sh -lc 'sleep 1; " .. dockMonitorScript .. "'")
end)
hl.on("monitor.removed", function()
    hl.exec_cmd("sh -lc 'sleep 1; " .. dockMonitorScript .. "'")
end)
---------------------
---- MY PROGRAMS ----
---------------------
local terminal    = "kitty"
local fileManager = "nemo"
local menu        = "WAYLAND_DISPLAY=$WAYLAND_DISPLAY rofi -show drun"
local browser     = "firefox"
-------------------
---- AUTOSTART ----
-------------------
-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("dunst -conf ~/.config/dunstrc")
    hl.exec_cmd("kwalletd6")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("waybar")
    hl.exec_cmd("udiskie")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("sh -lc 'case \"$(uname -n)\" in *gameboy*) pkill -x kanshi 2>/dev/null; sleep 2; pgrep -f \"[h]ypr-dock-monitors --watch\" >/dev/null || setsid -f " .. dockMonitorScript .. " --watch >/tmp/hypr-dock-monitors.log 2>&1 ;; esac'")
end)
-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("HYPRCURSOR_THEME", "broodwar")
hl.env("XCURSOR_THEME",    "broodwar")
hl.env("HYPRCURSOR_SIZE",  "6")
hl.env("XCURSOR_SIZE",     "6")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("GTK_THEME", "Breeze:dark")
hl.env("GTK_ICON_THEME", "breeze-dark")
-----------------------
---- LOOK AND FEEL ----
-----------------------
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 10,
        border_size = 2,
        col = {
            active_border   = { colors = { "rgba(ffcc55ff)", "rgba(ff9999ee)" }, angle = 360 },
            inactive_border = "rgba(59595988)",
        },
        allow_tearing = false,
        layout        = "dwindle",
    },
    decoration = {
        rounding = 10,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        blur = {
            enabled = true,
            size    = 5,
            passes  = 2,
        },
        shadow = {
            enabled      = true,
            range        = 10,
            render_power = 3,
            color        = 0x66000000,
        },
    },
    animations = {
        enabled = true,
    },
})
-- Curves
hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
-- Animations
hl.animation({ leaf = "windows",    enabled = true, speed = 7,  bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7,  bezier = "default",  style = "popin 80%" })
hl.animation({ leaf = "border",     enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 25, bezier = "linear", style = "loop" })
hl.animation({ leaf = "fade",       enabled = true, speed = 7,  bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6,  bezier = "default" })
----------------------
---- LAYOUT CONFIG ----
----------------------
hl.config({
    dwindle = {
        preserve_split = true,
    },
    master = {
        new_status = "master",
    },
})
----------------
----  MISC  ----
----------------
hl.config({
    misc = {
        force_default_wallpaper = -1,
    },
})
---------------
---- INPUT ----
---------------
hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",
        follow_mouse = 1,
        sensitivity = 0, -- -1.0 to 1.0, 0 means no modification
        touchpad = {
            natural_scroll = false,
        },
    },
})
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})
-- Per-device config
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})
---------------------
---- KEYBINDINGS ----
---------------------
local mainMod = "SUPER"
-- Applications
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind("ALT + SPACE",     hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())      -- dwindle
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle
-- Fullscreen
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
-- Lock screen
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
-- Screenshot
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("hyprshot -m region"))
-- Media / Volume keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%+"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-"), { repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
-- Brightness keys
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set +5%"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { repeating = true })
-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))
-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------
-- Opacity: slightly transparent inactive windows (except kitty which stays fully opaque)
hl.window_rule({
    name  = "opacity-inactive",
    match = { class = ".*" },
    opacity = "1.0 0.9"--{ active = 1, inactive = 0.9 },
})
hl.window_rule({
    name  = "opacity-kitty-override",
    match = { class = "kitty" },
    opacity = "1.0 1.0"--{ active = 1, inactive = 1 },
})
-- Fullscreen screensaver windows
hl.window_rule({
    name  = "fullscreen-screensaver",
    match = { class = "Screensaver" },
    fullscreen = true,
})
-- Float Photon title windows
hl.window_rule({
    name  = "float-photon",
    match = { title = "Photon" },
    float = true,
})
-- Suppress maximize events (recommended)
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})
-- Fix XWayland drag issues
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})
