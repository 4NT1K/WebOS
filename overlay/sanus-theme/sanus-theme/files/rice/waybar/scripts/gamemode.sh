#!/usr/bin/env bash
# waybar custom module: is gamemode active for any process?
# Prints a gamepad glyph while a game is in gamemode, nothing otherwise.
set -u

if pgrep -x gamemoded >/dev/null 2>&1; then
	if command -v gamemoderun >/dev/null 2>&1 && \
	   pgrep -af 'gamemoderun|gamescope' >/dev/null 2>&1; then
		printf '{"text":"󰊗","class":"on","tooltip":"gamemode active"}\n'
	else
		printf '{"text":"","class":"off","tooltip":"gamemode idle"}\n'
	fi
else
	printf '{"text":"","class":"off","tooltip":"gamemode not running"}\n'
fi
