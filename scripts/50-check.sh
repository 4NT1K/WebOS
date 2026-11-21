#!/usr/bin/env bash
# Stage 99 — integrity checks across the tree. Run before a release.
set -Eeuo pipefail
WEBOS_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export WEBOS_ROOT
source "${WEBOS_ROOT}/scripts/lib/common.sh"

step "check: WebOS ${WEBOS_VERSION_FULL}"
fail=0
note() { printf '  %-6s %s\n' "$1" "$2" >&2; }
bad()  { note FAIL "$1"; fail=$((fail + 1)); }
good() { note ok   "$1"; }

# 1. every package directory has a Manifest and a metadata.xml
while IFS= read -r e; do
	d="$(dirname -- "$e")"
	rel="${d#${WEBOS_ROOT}/}"
	if [[ -f "${d}/Manifest" ]]; then good "Manifest ${rel}"
	elif grep -qE '^SRC_URI=""' "$e" 2>/dev/null; then
		# A no-distfile ebuild (SRC_URI="") needs no Manifest: there is nothing
		# to checksum. The webos-theme package installs only in-tree files.
		good "Manifest not required (no SRC_URI) ${rel}"
	else bad "missing Manifest in ${rel}"; fi
	if [[ -f "${d}/metadata.xml" ]]; then good "metadata ${rel}"
	else bad "missing metadata.xml in ${rel}"; fi
done < <(find "${WEBOS_ROOT}/overlay" -mindepth 3 -maxdepth 3 -name '*.ebuild' | sort)

# 2. branding consistency
if grep -q "ID=${WEBOS_ID}" "${WEBOS_ROOT}/branding/os-release"; then good "os-release ID"
else bad "os-release ID mismatch"; fi

# 3. kernel patchset is pinned
# Format: name | url | sha256 | target-series | description
# An empty patchset is valid: WebOS prefers a stock LTS kernel over carrying a
# patch it cannot explain. What must never happen is an entry that is missing
# its URL or hash, because fetch-patches.sh would then either fail at build
# time or silently skip the patch.
patch_entries="$(grep -vE '^[[:space:]]*(#|$)' "${WEBOS_ROOT}/kernel/patchset.conf" || true)"
if [[ -z "$patch_entries" ]]; then
	good "patchset empty (stock LTS, no patches)"
elif grep -qvE '^[a-zA-Z0-9_.-]+\|https?://[^|]+\|[0-9a-f]{64}\|[^|]+\|.+' <<<"$patch_entries"; then
	bad "patchset.conf has a malformed entry (name|url|sha256|series|description)"
else
	good "patchset has sources"
fi

# 3b. the single-source-of-truth symlinks resolve
for link in desktop kernel/webos-fragment.config; do
	if [[ -e "${WEBOS_ROOT}/${link}" ]]; then good "symlink ${link}"
	else bad "broken symlink ${link}"; fi
done

# 4. installer crate parses
if have cargo; then
	if cargo metadata --manifest-path "${WEBOS_ROOT}/installer/Cargo.toml" --format-version 1 >/dev/null 2>&1; then
		good "installer Cargo.toml"
	else bad "installer Cargo.toml invalid"; fi
else note skip "cargo not installed"; fi

# 5. shell syntax (scripts/, kernel/fetch-patches.sh, installer/vendor.sh, build.sh)
while IFS= read -r s; do
	if bash -n "${s}"; then good "sh ${s#${WEBOS_ROOT}/}"
	else bad "sh syntax ${s#${WEBOS_ROOT}/}"; fi
done < <(
	{
		# installer/vendor is third-party source, checked in verbatim
		# (some upstreams ship CRLF scripts). It is not ours to rewrite.
		find "${WEBOS_ROOT}" \
			\( -path "${WEBOS_ROOT}/build" -o -path "${WEBOS_ROOT}/installer/vendor" \) -prune \
			-o -name '*.sh' -print
		printf '%s\n' "${WEBOS_ROOT}/build.sh"
	} | sort -u
)

# 6. required rice files exist
for f in desktop/hypr/hyprland.lua desktop/hypr/webos-colors.lua desktop/waybar/config.jsonc desktop/wofi/config; do
	[[ -f "${WEBOS_ROOT}/${f}" ]] && good "rice ${f}" || bad "missing rice file ${f}"
done

# 7. regressions that broke the 1.01 release: CPU-FLAGS binaries and overlays
if grep -q 'dev-python/numpy dev-cpp/eigen' "${WEBOS_ROOT}/scripts/30-rootfs.sh"; then
	good "CPU_FLAGS-sensitive packages rebuilt"
else bad "no CPU_FLAGS-sensitive rebuild in 30-rootfs.sh"; fi
if grep -q "exclude='/var/db/repos/guru'" "${WEBOS_ROOT}/scripts/30-rootfs.sh"; then
	bad "third-party overlays excluded from rootfs (breaks @world)"
else good "third-party overlays shipped in rootfs"; fi
if grep -q 'kde-frameworks/kconfig-6.32.0 qml' "${WEBOS_ROOT}/config/package.use/gaming"; then
	good "kconfig qml USE preset"
else bad "kconfig qml USE missing"; fi

# 8. binary-package updater + native logind power + detailed stats
if grep -q -- '--getbinpkg' "${WEBOS_ROOT}/config/make.conf"; then
	good "emerge defaults prefer binpkgs (--getbinpkg)"
else bad "EMERGE_DEFAULT_OPTS lacks --getbinpkg"; fi
grep -qF -- '--binpkg-respect-use=n' "${WEBOS_ROOT}/config/make.conf" \
	&& grep -qF -- '--binpkg-changed-deps=n' "${WEBOS_ROOT}/config/make.conf" \
	&& good "emerge defaults stay binary-first on USE/deps mismatch" \
	|| bad "emerge defaults still compile on USE/deps mismatch"
if grep -q 'binpackages/23.0/x86-64-v3' "${WEBOS_ROOT}/config/binrepos.conf/gentoo.conf" 2>/dev/null; then
	good "v3 binhost pinned"
else bad "v3 binhost config missing"; fi
for s in 10-bootstrap.sh 30-rootfs.sh; do
	grep -q 'config/binrepos.conf/gentoo.conf' "${WEBOS_ROOT}/scripts/${s}" \
		&& good "binhost installed by ${s}" || bad "${s} does not install binhost config"
done
UPDATER="${WEBOS_ROOT}/overlay/webos-theme/webos-theme/files/system/webos-update"
grep -q 'prefers prebuilt binaries; falls back to source' "$UPDATER" \
	&& good "updater binary message" || bad "updater still claims source-only"
grep -qF -- '--binpkg-respect-use=n' "$UPDATER" \
	&& grep -qF -- '--binpkg-changed-deps=n' "$UPDATER" \
	&& grep -qF -- '--strict-use' "$UPDATER" \
	&& good "updater is binary-first with a strict-use opt-out" || bad "updater lacks binary-first mode"
grep -qF -- '--buildpkg' "$UPDATER" \
	&& good "updater can cache builds" || bad "updater lacks buildpkg mode"
grep -q 'reboot with: loginctl reboot' "$UPDATER" \
	&& good "logind reboot hint" || bad "stale reboot hint"
grep -qF '/^\[(ebuild|binary)/' "${WEBOS_ROOT}/overlay/webos-theme/webos-theme/files/rice/waybar/scripts/updates.sh" \
	&& good "binary-aware update counter" || bad "update counter ignores binaries"
RICE="${WEBOS_ROOT}/overlay/webos-theme/webos-theme/files/rice"
if grep -Rq 'systemctl' "$RICE/hypr/hypridle.conf" "$RICE/wlogout/layout"; then
	bad "stale systemctl power action"
else good "power actions use loginctl only"; fi
for verb in 'loginctl suspend' 'loginctl hibernate' 'loginctl reboot' 'loginctl poweroff'; do
	grep -q "\"action\" : \"${verb}\"" "$RICE/wlogout/layout" \
		&& good "wlogout: ${verb}" || bad "wlogout missing ${verb}"
done
grep -q '"custom/power"' "$RICE/waybar/config.jsonc" \
	&& good "waybar power widget present" || bad "waybar power widget missing"
grep -q '"format": "⏻"' "$RICE/waybar/config.jsonc" \
	&& good "power glyph matches" || bad "power glyph wrong"
grep -q '"on-click": "wlogout"' "$RICE/waybar/config.jsonc" \
	&& good "power widget opens wlogout" || bad "power widget click wrong"
grep -q '#custom-power' "$RICE/waybar/style.css" \
	&& good "power widget styled" || bad "power widget unstyled"
MONO="${WEBOS_ROOT}/overlay/webos-theme/webos-theme/files/dotfiles/mono/waybar"
grep -q '"custom/power"' "$MONO/config.jsonc" \
	&& good "mono dotfiles power widget present" || bad "mono dotfiles power widget missing"
grep -q '#custom-power' "$MONO/style.css" \
	&& good "mono dotfiles power widget styled" || bad "mono dotfiles power widget unstyled"
LOCK="${WEBOS_ROOT}/overlay/webos-theme/webos-theme/files/rice/hypr/hyprlock.conf"
grep -q 'placeholder_text = <span foreground="##' "$LOCK" \
	&& good "hyprlock placeholder color escaped" || bad "hyprlock placeholder markup truncated"
! grep -Eq '^[[:space:]]*(grace|no_fade_in)[[:space:]]*=' "$LOCK" \
	&& good "hyprlock has no removed options" || bad "hyprlock uses removed options"
IDLE="${WEBOS_ROOT}/overlay/webos-theme/webos-theme/files/rice/hypr/hypridle.conf"
grep -q "hl.dispatch(hl.dsp.dpms({ action = \"off\" }))" "$IDLE" \
	&& good "DPMS off uses Lua dispatcher" || bad "DPMS off still uses old syntax"
grep -q 'brightnessctl -c backlight' "$IDLE" \
	&& good "idle dim targets backlights only" || bad "idle dim still targets keyboard LEDs"
grep -q 'hyprlock --grace 0 --no-fade-in' "$IDLE" \
	&& good "lock cmd passes hyprlock flags" || bad "lock cmd misses hyprlock flags"
grep -q '"ipc": false' "$RICE/waybar/config.jsonc" \
	&& good "waybar IPC warning disabled" || bad "waybar IPC still warns"
STATS="${WEBOS_ROOT}/overlay/webos-theme/webos-theme/files/system/webos-stats"
grep -q 'def ram_details' "$STATS" && grep -q 'used / %.1fG' "$STATS" \
	&& good "RAM shows used/total" || bad "RAM still percentage-only"
grep -q 'def core_temperatures' "$STATS" && grep -q 'c%d   %d%% %s' "$STATS" \
	&& good "per-core usage/temp rows" || bad "per-core stats missing"
grep -q 'webos-stats-catcher' "$STATS" && grep -q 'button-press-event' "$STATS" \
	&& good "stats dropdown dismisses on outside click" || bad "stats dropdown has no outside-click dismiss"

MUSIC="${WEBOS_ROOT}/overlay/webos-theme/webos-theme/files/system/webos-music"
grep -q 'fallback_position' "$MUSIC" && grep -q 'hl.dsp.window.move' "$MUSIC" \
	&& good "music dropdown anchors under the bar" || bad "music dropdown can land in the middle"
grep -q 'def slide_down' "$MUSIC" && grep -q 'PANEL_SIZE \* eased' "$MUSIC" \
	&& good "music panel slides downwards" || bad "music panel does not slide downwards"
grep -q 'GaussianBlur(radius=9)' "$MUSIC" \
	&& good "music art is lightly frosted" || bad "music art frosting is wrong"
grep -q '#music-card { background-image: url' "$MUSIC" \
	&& grep -q 'background-size: cover' "$MUSIC" \
	&& good "song image fills the whole card" || bad "song image is not the card background"
grep -q 'convert("RGB")' "$MUSIC" && ! grep -q 'convert("L")' "$MUSIC" \
	&& good "music cover art stays in colour" || bad "music cover art is still greyscale"
grep -q 'PANEL_SIZE = 340' "$MUSIC" && grep -q 'set_default_size(PANEL_SIZE, PANEL_SIZE)' "$MUSIC" \
	&& good "music player is a compact square" || bad "music player size is wrong"
grep -q 'Gtk.DrawingArea' "$MUSIC" && grep -q 'class AudioVisualizer' "$MUSIC" \
	&& good "music player has an audio visualizer" || bad "music player lacks a visualizer"
grep -q 'art_palette(path, visualizer.BANDS)' "$MUSIC" \
	&& good "visualizer follows the cover colours" || bad "visualizer colours are not tied to the art"
grep -q '"cava", "-p", self.config' "$MUSIC" \
	&& grep -q 'method = pipewire' "$MUSIC" && grep -q 'source = %s' "$MUSIC" \
	&& ! grep -q '@DEFAULT_SINK@.monitor' "$MUSIC" \
	&& good "visualizer only captures the music player" || bad "visualizer captures all system audio"
grep -q 'webos-music-catcher' "$MUSIC" && grep -q 'button-press-event' "$MUSIC" \
	&& good "music dropdown dismisses on outside click" || bad "music dropdown has no outside-click dismiss"
grep -Fq 'class = "^(webos-music)$"' "$RICE/hypr/hyprland.lua" \
	&& good "music dropdown excluded from blur" || bad "music dropdown not excluded from blur"
grep -q 'webos-theme-1.0-r3.ebuild' "${WEBOS_ROOT}/scripts/30-rootfs.sh" \
	&& good "ISO pins theme r3" || bad "ISO still pins an older theme"
grep -q 'gtk-layer-shell\[introspection\]' \
	"${WEBOS_ROOT}/overlay/webos-theme/webos-theme/webos-theme-1.0-r3.ebuild" \
	&& good "theme requires layer-shell introspection" || bad "theme can install without introspection"

step "check: ${fail} problem(s)"
exit "$((fail > 0))"
