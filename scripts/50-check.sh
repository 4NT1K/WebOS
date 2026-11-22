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
if grep -q 'kde-frameworks/kconfig qml' "${WEBOS_ROOT}/config/package.use/gaming"; then
	good "kconfig qml USE preset"
else bad "kconfig qml USE missing"; fi

# 8. binary-package updater + native logind power + detailed stats
if grep -q -- '--getbinpkg' "${WEBOS_ROOT}/config/make.conf"; then
	good "emerge defaults prefer binpkgs (--getbinpkg)"
else bad "EMERGE_DEFAULT_OPTS lacks --getbinpkg"; fi
if grep -Eq -- '--binpkg-respect-use=n|--getbinpkgonly|(^|[[:space:]])-G([[:space:]]|$)|(^|[[:space:]])-K([[:space:]]|$)' \
	"${WEBOS_ROOT}/config/make.conf"; then
	bad "forbidden binary flag in make.conf"
else good "make.conf never forces wrong-USE binaries"; fi
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
if grep -Eq -- '--binpkg-respect-use=n|--getbinpkgonly' "$UPDATER"; then
	bad "updater forces wrong-USE binaries"
else good "updater keeps strict USE matching"; fi
grep -qF -- '--binpkg-changed-deps=n' "$UPDATER" \
	&& grep -qF -- '--strict-use' "$UPDATER" \
	&& grep -qF -- '--respect-use' "$UPDATER" \
	&& grep -qF -- '--fast-binpkg' "$UPDATER" \
	&& good "updater has fast and strict-use controls" || bad "updater lacks binary-first controls"
grep -qF -- '--buildpkg' "$UPDATER" \
	&& good "updater can cache builds" || bad "updater lacks buildpkg mode"
grep -qF -- '--no-compile' "$UPDATER" && grep -qF 'count_plan' "$UPDATER" \
	&& grep -qF '^[[:space:]]*\[ebuild' "$UPDATER" \
	&& good "updater can refuse all source builds" || bad "updater lacks no-compile pre-flight"
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
grep -q 'def core_temperatures' "$STATS" && grep -q '<small>c%d</small>' "$STATS" \
	&& good "per-core usage/temp rows" || bad "per-core stats missing"
grep -q 'webos-stats-catcher' "$STATS" && grep -q 'button-press-event' "$STATS" \
	&& good "stats dropdown dismisses on outside click" || bad "stats dropdown has no outside-click dismiss"
grep -q 'for version in ("0.1", "1.0")' "$STATS" && grep -q 'GtkLayerShell.Edge.TOP, 100' "$STATS" \
	&& good "stats uses layer-shell below the top bar" || bad "stats fallback leaves an empty window"

MUSIC="${WEBOS_ROOT}/overlay/webos-theme/webos-theme/files/system/webos-music"
grep -q 'fallback_position' "$MUSIC" && grep -q 'hl.dsp.window.move' "$MUSIC" \
	&& good "music dropdown anchors under the bar" || bad "music dropdown can land in the middle"
grep -q 'def slide_down' "$MUSIC" && grep -q 'PANEL_SIZE \* eased' "$MUSIC" \
	&& good "music panel slides downwards" || bad "music panel does not slide downwards"
grep -q 'GaussianBlur(radius=2.5)' "$MUSIC" \
	&& good "music art is lightly frosted" || bad "music art frosting is wrong"
grep -q '#music-card { background-image: url' "$MUSIC" \
	&& grep -q 'background-size: cover' "$MUSIC" \
	&& good "song image fills the whole card" || bad "song image is not the card background"
grep -q 'convert("RGB")' "$MUSIC" && grep -q 'def art_is_light' "$MUSIC" \
	&& good "music cover art stays in colour" || bad "music cover art is still greyscale"
grep -q 'PANEL_SIZE = 340' "$MUSIC" && grep -q 'set_default_size(PANEL_SIZE, PANEL_SIZE)' "$MUSIC" \
	&& good "music player is a compact square" || bad "music player size is wrong"
grep -q 'Gtk.DrawingArea' "$MUSIC" && grep -q 'class VinylVisualizer' "$MUSIC" \
	&& good "music player has a vinyl visualizer" || bad "music player lacks a vinyl visualizer"
grep -q 'self.surface' "$MUSIC" && grep -q 'set_art(path)' "$MUSIC" \
	&& good "vinyl label follows the cover art" || bad "vinyl label is not tied to the art"
grep -q 'def set_volume(value)' "$MUSIC" && grep -q 'set-sink-input-volume' "$MUSIC" \
	&& ! grep -q '@DEFAULT_AUDIO_SINK@' "$MUSIC" \
	&& good "volume changes Spotify streams only" || bad "volume changes the system sink"
grep -q 'webos-music-catcher' "$MUSIC" && grep -q 'button-press-event' "$MUSIC" \
	&& good "music dropdown dismisses on outside click" || bad "music dropdown has no outside-click dismiss"
grep -q 'for version in ("0.1", "1.0")' "$MUSIC" && grep -q 'GtkLayerShell.Edge.TOP, 100' "$MUSIC" \
	&& good "music uses layer-shell below the top bar" || bad "music fallback leaves an empty window"
grep -Fq 'class = "^(webos-music)$"' "$RICE/hypr/hyprland.lua" \
	&& good "music dropdown excluded from blur" || bad "music dropdown not excluded from blur"
grep -q 'webos-theme-1.0-r47.ebuild' "${WEBOS_ROOT}/scripts/30-rootfs.sh" \
	&& good "ISO pins theme r47" || bad "ISO still pins an older theme"
grep -q 'gtk-layer-shell\[introspection\]' \
	"${WEBOS_ROOT}/overlay/webos-theme/webos-theme/webos-theme-1.0-r47.ebuild" \
	&& good "theme requires layer-shell introspection" || bad "theme can install without introspection"

# 9. v1.02 identity and shipped guide
for f in branding/version branding/os-release branding/lsb-release branding/issue \
	config/make.conf overlay/profiles/default/linux/amd64/webos/make.defaults \
	overlay/profiles/default/linux/arm64/webos/make.defaults \
	overlay/webos-theme/webos-theme/files/system/webos-rice \
	overlay/webos-theme/webos-theme/files/system/webos-update \
	overlay/webos-theme/webos-theme/files/system/xdg/kcm-about-distrorc \
	installer/src/main.rs; do
	grep -q '1\.02' "${WEBOS_ROOT}/${f}" \
		&& good "v1.02 identity ${f}" || bad "stale version in ${f}"
done
grep -qF 'ANSI_COLOR="38;2;216;216;216"' "${WEBOS_ROOT}/branding/os-release" \
	&& good "greyscale ANSI_COLOR" || bad "ANSI_COLOR is not greyscale"
GUIDE="${WEBOS_ROOT}/overlay/webos-theme/webos-theme/files/WEBOS-INFO.txt"
for pat in 'WebOS 1.02' 'WHAT CHANGED IN 1.02' 'webos-theme-1.0-r47' \
	'--binpkg-changed-deps=n' 'loginctl' 'per-core CPU' \
	'WEBOS_VERSION=1.02-Ashen'; do
	grep -qF -- "$pat" "$GUIDE" && good "guide: ${pat}" || bad "guide missing: ${pat}"
done
[[ -f "${WEBOS_ROOT}/docs/releases/v1.02.md" ]] \
	&& good "v1.02 release notes" || bad "missing docs/releases/v1.02.md"
grep -qF 'webos-1.02-Ashen-amd64.iso' "${WEBOS_ROOT}/docs/releases/v1.02.md" \
	&& good "v1.02 asset names" || bad "v1.02 notes have wrong asset names"

# 10. power widget in both profiles, with safe mono migration
WAYBAR_DIR="${WEBOS_ROOT}/overlay/webos-theme/webos-theme/files"
for cfg in "${WAYBAR_DIR}/rice/waybar/config.jsonc" \
	"${WAYBAR_DIR}/dotfiles/mono/waybar/config.jsonc"; do
	grep -qF '"ipc": false' "$cfg" && good "waybar ipc off ${cfg##*/files/}" \
		|| bad "waybar ipc still on in ${cfg##*/files/}"
	grep -qF '"custom/power"' "$cfg" \
		&& good "power widget ${cfg##*/files/}" || bad "power widget missing in ${cfg##*/files/}"
	grep -qF '"format": "⏻"' "$cfg" \
		&& good "power glyph ${cfg##*/files/}" || bad "power glyph wrong in ${cfg##*/files/}"
	grep -qF 'Power — open session menu (reboot, shut down, suspend)' "$cfg" \
		&& good "power tooltip ${cfg##*/files/}" || bad "power tooltip wrong in ${cfg##*/files/}"
	grep -qF '"on-click": "wlogout"' "$cfg" \
		&& good "power click ${cfg##*/files/}" || bad "power click wrong in ${cfg##*/files/}"
done
for css in "${WAYBAR_DIR}/rice/waybar/style.css" \
	"${WAYBAR_DIR}/dotfiles/mono/waybar/style.css"; do
	grep -qF '#custom-power' "$css" \
		&& good "power styling ${css##*/files/}" || bad "power styling missing in ${css##*/files/}"
done
RICE_TOOL="${WAYBAR_DIR}/system/webos-rice"
grep -qF 'migrate_legacy_waybar()' "$RICE_TOOL" \
	&& good "legacy waybar migration defined" || bad "migrate_legacy_waybar missing"
grep -qF 'migrate_legacy_waybar "$home"' "$RICE_TOOL" \
	&& good "legacy waybar migration called" || bad "migration not applied"
grep -qF '2b3fc6c9c3f0d46bcebebdff9787054cf117e6cba2936505a19ba3de6e978081' "$RICE_TOOL" \
	&& good "known mono hash pinned" || bad "legacy mono hash missing"
grep -qF 'backup_once' "$RICE_TOOL" \
	&& good "legacy config backed up once" || bad "legacy backup missing"

# 11. lock screen and idle session fixes
HYPRLOCK="${WAYBAR_DIR}/rice/hypr/hyprlock.conf"
HYPRLIDLE="${WAYBAR_DIR}/rice/hypr/hypridle.conf"
grep -qF 'foreground="##7A7A7A"' "$HYPRLOCK" \
	&& good "escaped hyprlock colour" || bad "unescaped hyprlock colour"
if grep -Eq '^[[:space:]]*(grace|no_fade_in)[[:space:]]*=' "$HYPRLOCK"; then
	bad "obsolete hyprlock config key remains"
else good "hyprlock obsolete keys removed"; fi
grep -qF 'hyprlock --grace 0 --no-fade-in' "$HYPRLIDLE" \
	&& good "hyprlock CLI flags" || bad "hyprlock CLI flags missing"
grep -qF 'hl.dispatch(hl.dsp.dpms({ action = "off" }))' "$HYPRLIDLE" \
	&& good "Lua DPMS off" || bad "Lua DPMS off missing"
grep -qF 'hl.dispatch(hl.dsp.dpms({ action = "on" }))' "$HYPRLIDLE" \
	&& good "Lua DPMS on" || bad "Lua DPMS on missing"
grep -qF '/sys/class/backlight' "$HYPRLIDLE" \
	&& good "backlight guard present" || bad "backlight guard missing"
grep -qF 'brightnessctl -c backlight' "$HYPRLIDLE" \
	&& good "dim scoped to backlight" || bad "dim not scoped to backlight"
if grep -qF 'hyprctl dispatch dpms' "$HYPRLIDLE"; then
	bad "old dpms dispatch remains"
else good "old dpms dispatch gone"; fi

# 12. theme revision reaches installed machines
THEME="${WEBOS_ROOT}/overlay/webos-theme/webos-theme/webos-theme-1.0-r47.ebuild"
[[ -f "$THEME" ]] && good "r47 theme ebuild" || bad "missing r47 theme ebuild"
grep -qF 'gui-libs/gtk-layer-shell[introspection]' "$THEME" \
	&& good "r47 ships layer-shell introspection" || bad "r47 lacks introspection dependency"
grep -qF 'THEME_EBUILD="webos-theme-1.0-r47.ebuild"' "${WEBOS_ROOT}/scripts/30-rootfs.sh" \
	&& good "rootfs pins r47" || bad "rootfs does not pin r47"

# 13. binary-first updater controls, without forbidden flags
UPDATER="${WAYBAR_DIR}/system/webos-update"
for pat in '--fast' '--fast-binpkg' '--strict-use' '--respect-use' '--buildpkg' \
	'--no-compile' '--binpkg-changed-deps=n' \
	'prefers prebuilt binaries; falls back to source' \
	'reboot with: loginctl reboot' 'archive/refs/heads/main.tar.gz'; do
	grep -qF -- "$pat" "$UPDATER" && good "updater: ${pat}" || bad "updater missing: ${pat}"
done
for f in "$UPDATER" "${WEBOS_ROOT}/config/make.conf"; do
	if grep -Eq -- '--binpkg-respect-use=n|--getbinpkgonly|(^|[[:space:]])-G([[:space:]]|$)|(^|[[:space:]])-K([[:space:]]|$)' "$f"; then
		bad "forbidden binary flag in ${f##*/}"
	else good "no forbidden binary flags in ${f##*/}"; fi
done

# 14. music/stats dropdown details
MUSIC="${WAYBAR_DIR}/system/webos-music"
STATS="${WAYBAR_DIR}/system/webos-stats"
for pat in 'PANEL_SIZE = 340' 'TOP_GAP = 100' \
	'for version in ("0.1", "1.0")' \
	'GtkLayerShell.set_namespace(window, "webos-music")' \
	'GtkLayerShell.set_layer(window, GtkLayerShell.Layer.OVERLAY)' \
	'webos-music-catcher' 'button-press-event' 'GaussianBlur(radius=2.5)' \
	'enhance(1.0)' 'background-size: cover' 'art_is_light(path)' \
	'class VinylVisualizer' 'box-shadow: none' \
	'run_quiet(["hyprctl", "seterror", "disable"])'; do
	grep -qF -- "$pat" "$MUSIC" && good "music: ${pat}" || bad "music missing: ${pat}"
done
for pat in 'for version in ("0.1", "1.0")' \
	'GtkLayerShell.set_layer(window, GtkLayerShell.Layer.OVERLAY)' \
	'GtkLayerShell.set_margin(window, GtkLayerShell.Edge.TOP, 100)' \
	'webos-stats-catcher' 'button-press-event' \
	'run_quiet(["hyprctl", "seterror", "disable"])' 'def ram_details' \
	'<small>c%d</small>'; do
	grep -qF -- "$pat" "$STATS" && good "stats: ${pat}" || bad "stats missing: ${pat}"
done
if have python3; then
	PYTHONPYCACHEPREFIX="/tmp/opencode/webos-pycache-check" \
		python3 -m py_compile "$MUSIC" "$STATS" \
		&& good "music/stats python syntax" || bad "music/stats python syntax"
else bad "python3 not available to compile helpers"; fi

# 15. installer, manifest and build-tooling audit
APP="${WEBOS_ROOT}/installer/src/app.rs"
INSTALL="${WEBOS_ROOT}/installer/src/install.rs"
CFG="${WEBOS_ROOT}/installer/src/config.rs"
grep -qF '"Installing the bootloader"' "$APP" \
	&& good "bootloader phase present" || bad "bootloader phase missing"
grep -qF 'pub const INSTALL_STAGES: [&str; 13]' "$APP" \
	&& good "13 installer stages" || bad "installer stage list is not 13"
grep -qF 'Encryption::None' "$APP" \
	&& good "stage count follows encryption" || bad "stage count ignores encryption"
grep -qF '/etc/webos/gaming-not-installed.txt' "$INSTALL" \
	&& good "gaming-off marker" || bad "gaming-off marker missing"
grep -qF 'Steam (Flatpak fallback)' "$APP" \
	&& good "Steam extra label is honest" || bad "Steam extra label is stale"
grep -qF 'Steam as a Flatpak fallback' "$CFG" \
	&& good "Steam wording is honest" || bad "Steam wording still promises native install"
grep -qF 'Flatpak is enabled by default' "$INSTALL" \
	&& good "Flatpak Steam fallback recorded" || bad "Flatpak Steam fallback missing"
manifest_bad=0
while IFS= read -r m; do
	if grep -E '^(EBUILD|MISC) ' "$m" \
		| grep -Ev ' BLAKE2B [0-9a-f]{128} SHA512 [0-9a-f]{128}$' >/dev/null; then
		bad "non-hex EBUILD/MISC digest in ${m#${WEBOS_ROOT}/}"
		manifest_bad=$((manifest_bad + 1))
	fi
done < <(find "${WEBOS_ROOT}/overlay" -name Manifest -print | sort)
((manifest_bad == 0)) && good "all Manifest digests hex"
grep -qF 'webos-fragment.sha256' "${WEBOS_ROOT}/overlay/sys-kernel/webos-kernel/webos-kernel-6.12.ebuild" \
	&& good "kernel fragment stamp" || bad "kernel fragment stamp missing"
grep -qF 'webos-fragment.sha256' "${WEBOS_ROOT}/scripts/20-kernel.sh" \
	&& good "kernel rebuild checks stamp" || bad "kernel rebuild ignores stamp"
for s in setup-container-build.sh .issue-watcher.sh .step-watcher.sh; do
	grep -qF "compgen -G 'build/webos-*.iso'" "${WEBOS_ROOT}/${s}" \
		&& good "ISO glob uses compgen in ${s}" || bad "invalid ISO glob test in ${s}"
done
grep -qF 'WEBOS_STATUS_UPDATER' "${WEBOS_ROOT}/scripts/status-updater.sh" \
	&& good "status updater is opt-in" || bad "status updater auto-runs"
if grep -REq '/home/brah/sanusos|/sanusos|git add|git commit|git push' \
	"${WEBOS_ROOT}/.issue-watcher.sh" "${WEBOS_ROOT}/.step-watcher.sh" \
	"${WEBOS_ROOT}/scripts/status-updater.sh"; then
	bad "watchers still use foreign paths or auto-commit"
else good "watchers are path-independent and non-committing"; fi
if have cargo; then
	(cd "${WEBOS_ROOT}/installer" && cargo check --offline >/dev/null 2>&1) \
		&& good "installer cargo check --offline" || bad "installer cargo check failed"
else note skip "cargo not installed"; fi

step "check: ${fail} problem(s)"
exit "$((fail > 0))"
