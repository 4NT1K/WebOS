-- ─────────────────────────────────────────────────────────────────────────────
--  WebOS — Hyprland
--  Black, translucent, blurred. Rounded, quiet, fast.
--
--  webos-rice: Hyprland configuration (Lua)
--
--  This file is installed to ~/.config/hypr/hyprland.lua by `webos-rice`.
--  Hyprland 0.57+ reads Lua configuration; hyprland.conf is no longer parsed.
--  Edit it freely — `webos-rice` will not overwrite a file you have modified
--  unless you pass --force.
-- ─────────────────────────────────────────────────────────────────────────────

local colors = require("webos-colors")

-- ── Programs ────────────────────────────────────────────────────────────────
local terminal  = "kitty"
local terminal2 = "foot"
local editor    = "nvim"
local fileman   = "dolphin"
local browser   = "firefox-bin"
local menu      = "webos-menu"
local settings  = "webos-settings"

-- ── Autostart ───────────────────────────────────────────────────────────────
-- Hyprland runs these once the compositor is up. Keeping them in one event
-- handler means a config reload never starts a second copy.
hl.on("hyprland.start", function()
	hl.exec_cmd("dbus-update-activation-environment --all 2>/dev/null || true")
	hl.exec_cmd("webos-rice --ensure >/dev/null 2>&1 || true")
	-- Portals, polkit, the mono shell (waybar+mako) and the wallpaper all
	-- start from one helper, so every WebOS session behaves the same.
	hl.exec_cmd("webos-autostart hyprland")
	hl.exec_cmd("nm-applet --indicator")
	hl.exec_cmd("blueman-applet")
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
	hl.exec_cmd("hyprctl setcursor Breeze_Light 24")
	hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true")
	hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark 2>/dev/null || true")
	hl.exec_cmd("gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark 2>/dev/null || true")
end)

-- ── Environment ─────────────────────────────────────────────────────────────
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Breeze_Light")
-- Breeze_Light is an XCursor theme; let Hyprland use the XCursor fallback.
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Breeze_Light")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("SDL_VIDEODRIVER", "wayland,x11")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")
-- hl.env("LIBVA_DRIVER_NAME", "radeonsi")  -- uncomment for AMD
-- hl.env("VDPAU_DRIVER", "radeonsi")
-- NVIDIA users: comment the two lines above and uncomment these.
-- hl.env("LIBVA_DRIVER_NAME", "nvidia")
-- hl.env("GBM_BACKEND", "nvidia-drm")
-- hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("EDITOR", "nvim")
hl.env("BROWSER", "firefox-bin")

-- ── Monitors ────────────────────────────────────────────────────────────────
-- Auto-detect; edit for HiDPI or multi-monitor layouts.
-- Pin the exact 170 Hz mode. "preferred" resolves to 60 Hz on this monitor
-- whenever the config reloads, and the refresh watcher then saves that 60 Hz
-- as the new default — so keep the real mode here as well.
hl.monitor({
	output   = "DP-1",
	mode     = "1920x1080@169.99699",
	position = "0x0",
	scale    = "1",
})
-- Example: internal 1.5x, external 144 Hz to the right.
-- hl.monitor({ output = "eDP-1", mode = "2880x1800@120", position = "0x0", scale = "1.5" })
-- hl.monitor({ output = "DP-1",  mode = "2560x1440@144", position = "2880x0", scale = "1" })

-- ── Look ────────────────────────────────────────────────────────────────────
hl.config({
	general = {
		gaps_in         = 6,
		gaps_out        = 14,
		border_size     = 2,
		col             = {
			active_border   = { colors = { colors.accent_glow, "rgba(e8e8e833)" }, angle = 40 },
			inactive_border = colors.border,
		},
		resize_on_border = true,
		allow_tearing    = false,
		layout           = "dwindle",
	},

	decoration = {
		rounding       = 14,
		rounding_power = 2,
		active_opacity   = 1.0,
		inactive_opacity = 0.90,
		fullscreen_opacity = 1.0,

		blur = {
			enabled           = true,
			size              = 7,
			passes            = 3,
			new_optimizations = true,
			xray              = false,
			noise             = 0.02,
			contrast          = 1.05,
			brightness        = 0.82,
			vibrancy          = 0.18,
			vibrancy_darkness = 0.35,
			popups            = true,
			input_methods     = true,
			special           = true,
		},

		shadow = {
			enabled      = true,
			range        = 28,
			render_power = 3,
			color        = "rgba(000000bb)",
		},

		dim_inactive = true,
		dim_strength = 0.14,
	},

	animations = {
		enabled = true,
		-- Keep 5 -> 1 wraps instant; a long slide across every workspace felt
		-- like a window sticking during Super + scroll.
		workspace_wraparound = false,
	},

	dwindle = {
		preserve_split = true,
		smart_split    = false,
		smart_resizing = true,
	},

	master = {
		new_status = "master",
		mfact      = 0.55,
	},

	misc = {
		disable_hyprland_logo        = true,
		disable_splash_rendering     = true,
		force_default_wallpaper      = 0,
		vrr                          = 0,
		mouse_move_enables_dpms      = true,
		key_press_enables_dpms       = true,
		focus_on_activate            = true,
		animate_manual_resizes       = false,
		animate_mouse_windowdragging = false,
		enable_swallow               = true,
		swallow_regex                = "^(kitty|foot|wezterm|Alacritty)$",
		middle_click_paste           = false,
		initial_workspace_tracking   = 1,
	},

	binds = {
		workspace_back_and_forth = true,
		allow_workspace_cycles   = true,
		pass_mouse_when_bound    = false,
	},

	layers = {
		layers_hog_keyboard_focus = true,
	},

	input = {
		kb_layout = "us",
		follow_mouse = 1,
		sensitivity  = 0,
		-- Pointer acceleration and "precision" are both off: a mouse must
		-- move the cursor exactly as far as the hand moves it.
		accel_profile = "flat",
		force_no_accel = true,

		touchpad = {
			natural_scroll = false,
		},
	},
})

-- ── Touchpad gestures ───────────────────────────────────────────────────────
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- ── Animations ──────────────────────────────────────────────────────────────
hl.curve("smooth",   { type = "bezier", points = { {0.22, 1.00}, {0.36, 1.00} } })
hl.curve("overshot", { type = "bezier", points = { {0.05, 0.90}, {0.10, 1.05} } })
hl.curve("soft",     { type = "bezier", points = { {0.25, 0.10}, {0.25, 1.00} } })
hl.curve("linear",   { type = "bezier", points = { {0.00, 0.00}, {1.00, 1.00} } })

hl.animation({ leaf = "windows",       enabled = true, speed = 5,  bezier = "overshot", style = "slide" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 5,  bezier = "overshot", style = "popin 92%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 4,  bezier = "smooth",   style = "popin 94%" })
-- `windowsMove` inherits the `windows` slide style; `fade` is not a valid
-- style there and was silently rejected, leaving windows visibly dragging
-- between workspaces. Disable it so windows snap out with the workspace.
hl.animation({ leaf = "windowsMove",   enabled = false })
hl.animation({ leaf = "border",        enabled = true, speed = 6,  bezier = "smooth" })
hl.animation({ leaf = "borderangle",   enabled = true, speed = 30, bezier = "linear",   style = "loop" })
hl.animation({ leaf = "fade",          enabled = true, speed = 4,  bezier = "soft" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 4,  bezier = "smooth" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 3,  bezier = "soft" })
hl.animation({ leaf = "layers",        enabled = true, speed = 4,  bezier = "smooth",   style = "slide" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,  bezier = "overshot", style = "slide" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 3,  bezier = "smooth",   style = "slide" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 3,  bezier = "smooth" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 3,  bezier = "soft" })
-- Smooth (no overshoot) so the workspace settles once and never sticks.
hl.animation({ leaf = "workspaces",    enabled = true, speed = 7,  bezier = "smooth",   style = "slide 20%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, bezier = "smooth", style = "fade" })

-- ── Per-window polish ───────────────────────────────────────────────────────
-- Terminals and anything that opts in get the translucent treatment.
-- kitty owns its own alpha (background_opacity). Do not stack a compositor
-- opacity on top of it or the two values multiply and the terminal looks
-- either opaque or almost invisible.
hl.window_rule({ match = { class = "^(kitty)$" },                    opacity = "1.0 1.0" })
hl.window_rule({ match = { class = "^(foot)$" },                     opacity = "0.86 0.80" })
hl.window_rule({ match = { class = "^(Alacritty)$" },                opacity = "0.90 0.85" })
hl.window_rule({ match = { class = "^(wezterm)$" },                  opacity = "0.92 0.88" })
hl.window_rule({ match = { class = "^(org.gnome.Nautilus|pcmanfm|Thunar)$" }, opacity = "0.94 0.90" })
hl.window_rule({ match = { class = "^(firefox|zen|chromium)$" },     opacity = "0.95 0.92" })
hl.window_rule({ match = { class = "^(mpv|imv|swayimg)$" },          opacity = "0.97 0.95" })
-- Electron apps can ignore app-level transparency and still paint an opaque
-- black surface. Force compositor alpha so wallpaper + blur always show through.
hl.window_rule({ match = { class = "^(vesktop|discord)$" }, opacity = "0.88 0.84" })
hl.window_rule({ match = { class = "^(spotify)$" },          opacity = "0.95 0.92" })

-- A fresh boot can race Electron/kitty startup: the window maps before the
-- compositor has finished applying static rules and paints an opaque surface.
-- Re-assert alpha the moment the window opens so transparency is there from
-- the first frame, every boot, without touching app-level CSS.
local BOOT_ALPHA = {
	kitty      = "1.0 override 1.0 override",  -- kitty draws its own alpha
	foot       = "0.86 override 0.80 override",
	Alacritty  = "0.90 override 0.85 override",
	wezterm    = "0.92 override 0.88 override",
	vesktop    = "0.88 override 0.84 override",
	discord    = "0.88 override 0.84 override",
	spotify    = "0.95 override 0.92 override",
}
hl.on("window.open_early", function(w)
	if not w then
		return
	end
	local value = BOOT_ALPHA[w.class] or BOOT_ALPHA[w.initial_class]
	if value then
		hl.dispatch(hl.dsp.window.set_prop({
			window = w.address, prop = "opacity", value = value,
		}))
	end
end)

-- Utilities should not be transparent at all.
hl.window_rule({
	match   = { class = "^(pavucontrol|blueman-manager|nm-connection-editor|kvantummanager|qt6ct|qt5ct)$" },
	opacity = "1.0 override 1.0 override",
})
hl.window_rule({
	match   = { class = "^(xdg-desktop-portal-gtk)$" },
	opacity = "1.0 override 1.0 override",
})

-- Steam and games: opaque, no blur, no rounding, no shadows. Frames first.
hl.window_rule({ match = { class = "^(steam)$" },     opacity = "1.0 override 1.0 override" })
hl.window_rule({ match = { class = "^(gamescope)$" }, opacity = "1.0 override 1.0 override" })
hl.window_rule({ match = { class = "^(cs2|dota2|hl2_linux|wine|.*\\.exe)$" }, opacity = "1.0 override 1.0 override" })
hl.window_rule({ match = { class = "^(steam|gamescope|wine)$" }, no_shadow = true, no_blur = true })
hl.window_rule({ match = { class = "^(gamescope)$" }, rounding = 0, immediate = true, fullscreen = true })
hl.window_rule({ match = { class = ".*" }, idle_inhibit = "fullscreen" })

-- Float the small stuff.
hl.window_rule({
	match = { class = "^(pavucontrol|blueman-manager|nm-connection-editor|file-roller|xdg-desktop-portal-gtk)$" },
	float = true,
})
hl.window_rule({ match = { class = "^(pavucontrol)$" },     size = "60% 65%" })
hl.window_rule({ match = { class = "^(blueman-manager)$" }, size = "70% 70%" })
hl.window_rule({
	match  = { class = "^(pavucontrol|blueman-manager|nm-connection-editor)$" },
	center = true,
})

-- Picture-in-picture, dialogs.
hl.window_rule({
	match = { title = "^(Picture-in-Picture)$" },
	float = true,
	pin   = true,
	size  = "30% 30%",
	move  = "69% 6%",
})
hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })

-- Music dropdown: the script anchors it under the bar via layer-shell when
-- available. If the introspection typelib is missing it falls back to a
-- floating window, so keep that one crisp and out of the compositor blur.
hl.window_rule({
	match   = { class = "^(webos-music)$" },
	float   = true,
	no_blur = true,
})

-- ── Blur the panels and launchers ───────────────────────────────────────────
hl.layer_rule({ match = { namespace = "^waybar$" },       blur = true, ignore_alpha = 0.25 })
hl.layer_rule({ match = { namespace = "^wofi$" },         blur = true, ignore_alpha = 0.25 })
hl.layer_rule({ match = { namespace = "^notifications$" }, blur = true, ignore_alpha = 0.25 })
hl.layer_rule({ match = { namespace = "^logout_dialog$" }, blur = true, ignore_alpha = 0.25 })
hl.layer_rule({ match = { namespace = "^selection$" },    blur = true, ignore_alpha = 0.25 })

-- ── Binds ───────────────────────────────────────────────────────────────────
local mod = "SUPER"

hl.bind(mod .. " + Q",            hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + SHIFT + Return", hl.dsp.exec_cmd(terminal2))
hl.bind(mod .. " + C",            hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + Escape", hl.dsp.exit())
hl.bind(mod .. " + E",            hl.dsp.exec_cmd(fileman))
hl.bind(mod .. " + B",            hl.dsp.exec_cmd(browser))
hl.bind(mod .. " + D",            hl.dsp.exec_cmd(menu))
hl.bind(mod .. " + R",            hl.dsp.exec_cmd(menu))
hl.bind(mod .. " + M",            hl.dsp.exec_cmd("webos-music --toggle"))
hl.bind(mod .. " + I",            hl.dsp.exec_cmd(settings))
hl.bind(mod .. " + SHIFT + I",    hl.dsp.exec_cmd(settings .. " --display"))
hl.bind(mod .. " + V",            hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy"))
hl.bind(mod .. " + Escape",       hl.dsp.exec_cmd("hyprlock"))
hl.bind(mod .. " + P",            hl.dsp.exec_cmd("webos-rice --toggle-panel"))
hl.bind(mod .. " + N",            hl.dsp.exec_cmd("makoctl dismiss -a"))
hl.bind(mod .. " + F",            hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + SHIFT + F",    hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mod .. " + Space",        hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mod .. " + CTRL + J",     hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + S",            hl.dsp.workspace.toggle_special("magic"))
hl.bind(mod .. " + CTRL + S",     hl.dsp.window.move({ workspace = "special:magic" }))

-- Move focus
hl.bind(mod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + down",  hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + H",     hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + L",     hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + K",     hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + J",     hl.dsp.focus({ direction = "down" }))

-- Move windows
hl.bind(mod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

-- Resize
hl.bind(mod .. " + CTRL + left",  hl.dsp.window.resize({ x = -40, y = 0, relative = true }))
hl.bind(mod .. " + CTRL + right", hl.dsp.window.resize({ x =  40, y = 0, relative = true }))
hl.bind(mod .. " + CTRL + up",    hl.dsp.window.resize({ x = 0, y = -40, relative = true }))
hl.bind(mod .. " + CTRL + down",  hl.dsp.window.resize({ x = 0, y =  40, relative = true }))

-- Workspaces
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(mod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
	hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
-- Super + scroll: cycle only workspaces 1-5 (wraps 5 -> 1 and 1 -> 5).
hl.bind(mod .. " + mouse_down", hl.dsp.exec_cmd("/usr/bin/webos-workspace-scroll down"))
hl.bind(mod .. " + mouse_up",   hl.dsp.exec_cmd("/usr/bin/webos-workspace-scroll up"))
hl.bind(mod .. " + Tab",        hl.dsp.focus({ workspace = "previous" }))

-- Mouse
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(mod .. " + mouse:274", hl.dsp.window.float({ action = "toggle" }), { mouse = true })

-- Media keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),        { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),       { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),     { locked = true })
hl.bind("XF86AudioPlay",        hl.dsp.exec_cmd("playerctl play-pause"),                            { locked = true })
hl.bind("XF86AudioPause",       hl.dsp.exec_cmd("playerctl play-pause"),                            { locked = true })
hl.bind("XF86AudioNext",        hl.dsp.exec_cmd("playerctl next"),                                  { locked = true })
hl.bind("XF86AudioPrev",        hl.dsp.exec_cmd("playerctl previous"),                              { locked = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl set 5%+"),                           { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"),                          { locked = true, repeating = true })

-- Screenshots (webos-shot wraps grim/slurp; no extra package needed)
-- Super+Shift+S is the snip key: drag a region, saved to
-- ~/Pictures/Screenshots and copied to the clipboard.
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd("webos-shot region"))
hl.bind("Print",               hl.dsp.exec_cmd("webos-shot region --clipboard"))
hl.bind("SHIFT + Print",       hl.dsp.exec_cmd("webos-shot window --clipboard"))
hl.bind(mod .. " + Print",     hl.dsp.exec_cmd("webos-shot output --clipboard"))
hl.bind(mod .. " + SHIFT + Print", hl.dsp.exec_cmd("webos-shot region --save"))

-- Gaming helpers
hl.bind(mod .. " + G",        hl.dsp.exec_cmd("webos-gaming status"))
hl.bind(mod .. " + SHIFT + G", hl.dsp.exec_cmd("webos-gaming mangohud-toggle"))
hl.bind(mod .. " + CTRL + G", hl.dsp.exec_cmd("webos-gaming gamescope"))

-- ── Machine-local overrides ─────────────────────────────────────────────────
-- Hyprland puts this directory on package.path, so a file named local.lua is
-- found by require(). It is never installed or overwritten by webos-rice.
if package.searchpath and package.searchpath("local", package.path) then
	require("local")
end
