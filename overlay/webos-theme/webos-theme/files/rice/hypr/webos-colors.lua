-- ─────────────────────────────────────────────────────────────────────────────
--  WebOS palette — "Deep Black"
--  Pure black base, translucent surfaces, white accents. Matches KDE Deep Black.
--
--  Required by hyprland.lua:
--      local colors = require("webos-colors")
--
--  Keep in sync with waybar/style.css and wofi/style.css.
-- ─────────────────────────────────────────────────────────────────────────────

return {
	base        = "rgb(000000)",
	base_soft   = "rgb(0a0a0a)",

	-- 55% black panels
	surface     = "rgba(0000008c)",
	-- hover / active surface
	surface_hi  = "rgba(1c1c1c8c)",
	-- recessed wells
	surface_lo  = "rgba(00000066)",

	-- near-white
	text        = "rgb(ededed)",
	text_dim    = "rgb(8f8f8f)",
	text_faint  = "rgb(5b5b5b)",

	-- white: focus/cursor
	accent      = "rgb(ffffff)",
	accent_soft = "rgba(ffffff22)",
	accent_glow = "rgba(ffffff55)",

	border      = "rgba(ffffff29)",
	border_hi   = "rgba(ffffff33)",

	urgent      = "rgb(d27878)",
	warn        = "rgb(c8c8c8)",
	good        = "rgb(b4d2b4)",
}
