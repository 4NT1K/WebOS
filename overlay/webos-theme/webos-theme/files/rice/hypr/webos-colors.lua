-- ─────────────────────────────────────────────────────────────────────────────
--  WebOS palette — "Ashen" (refined greyscale)
--  Pure black base, near-opaque surfaces, soft-white accents.
--  Matches waybar/style.css, kitty.conf, foot.ini and the Plasma/Konsole scheme.
--
--  Required by hyprland.lua:
--      local colors = require("webos-colors")
--
--  Keep in sync with the other palette-bearing files under the rice tree.
-- ─────────────────────────────────────────────────────────────────────────────

return {
	base        = "rgb(000000)",
	base_soft   = "rgb(0a0a0a)",

	-- 92% black panels
	surface     = "rgba(000000eb)",
	-- hover / active surface
	surface_hi  = "rgba(1a1a1aeb)",
	-- recessed wells
	surface_lo  = "rgba(000000cc)",

	-- soft white / greys
	text        = "rgb(d8d8d8)",
	text_dim    = "rgb(7a7a7a)",
	text_faint  = "rgb(4a4a4a)",

	-- soft white: focus/cursor
	accent      = "rgb(e8e8e8)",
	accent_soft = "rgba(e8e8e833)",
	accent_glow = "rgba(e8e8e859)",

	border      = "rgba(e8e8e833)",
	border_hi   = "rgba(e8e8e859)",

	urgent      = "rgb(d27878)",
	warn        = "rgb(c2c2c2)",
	good        = "rgb(d8d8d8)",
}
