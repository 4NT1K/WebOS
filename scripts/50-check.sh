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
STATS="${WEBOS_ROOT}/overlay/webos-theme/webos-theme/files/system/webos-stats"
grep -q 'def ram_details' "$STATS" && grep -q 'used / %.1fG' "$STATS" \
	&& good "RAM shows used/total" || bad "RAM still percentage-only"
grep -q 'def core_temperatures' "$STATS" && grep -q 'c%d   %d%% %s' "$STATS" \
	&& good "per-core usage/temp rows" || bad "per-core stats missing"

step "check: ${fail} problem(s)"
exit "$((fail > 0))"
