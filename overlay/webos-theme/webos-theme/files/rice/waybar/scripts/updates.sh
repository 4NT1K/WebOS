#!/bin/sh
# waybar custom module: show an icon when system updates are pending.
# Uses a cached check to avoid running emerge on every poll.
set -u

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/webos-updates"
TTL=3600 # seconds
ICON="󰏔" # nerd font download/update icon

mkdir -p "$(dirname "$CACHE")"

refresh() {
	# Count pending package updates (pretend). Works best after `emerge --sync`.
	# Run as user; if it fails, keep previous result.
	count="$(emerge -puDN --quiet @world 2>/dev/null | awk '/^\[ebuild/ {n++} END{print n+0}')"
	[ -n "$count" ] || count=0
	printf '%s\n' "$count" > "$CACHE" 2>/dev/null || true
	printf '%s' "$count"
}

get_count() {
	if [ -f "$CACHE" ]; then
		now="$(date +%s 2>/dev/null || echo 0)"
		mt="$(stat -c %Y "$CACHE" 2>/dev/null || echo 0)"
		age=$((now - mt))
		if [ "$age" -lt "$TTL" ] && [ "$age" -ge 0 ]; then
			cat "$CACHE" 2>/dev/null && return 0
		fi
	fi
	refresh
}

count="$(get_count 2>/dev/null || echo 0)"
case "$count" in ''|*[!0-9]*) count=0 ;; esac

if [ "$count" -gt 0 ]; then
	printf '{"text":"%s %s","class":"pending","tooltip":"%s update(s) available — click to check/apply"}\n' "$ICON" "$count" "$count"
else
	printf '{"text":"","class":"none","tooltip":"System up to date"}\n'
fi
