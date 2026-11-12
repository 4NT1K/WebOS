#!/usr/bin/env bash
# Stage 99 — integrity checks across the tree. Run before a release.
set -Eeuo pipefail
SANUS_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export SANUS_ROOT
source "${SANUS_ROOT}/scripts/lib/common.sh"

step "check: SanusOS ${SANUS_VERSION_FULL}"
fail=0
note() { printf '  %-6s %s\n' "$1" "$2" >&2; }
bad()  { note FAIL "$1"; fail=$((fail + 1)); }
good() { note ok   "$1"; }

# 1. every package directory has a Manifest and a metadata.xml
while IFS= read -r e; do
	d="$(dirname -- "$e")"
	rel="${d#${SANUS_ROOT}/}"
	if [[ -f "${d}/Manifest" ]]; then good "Manifest ${rel}"
	else bad "missing Manifest in ${rel}"; fi
	if [[ -f "${d}/metadata.xml" ]]; then good "metadata ${rel}"
	else bad "missing metadata.xml in ${rel}"; fi
done < <(find "${SANUS_ROOT}/overlay" -mindepth 3 -maxdepth 3 -name '*.ebuild' | sort)

# 2. branding consistency
if grep -q "ID=${SANUS_ID}" "${SANUS_ROOT}/branding/os-release"; then good "os-release ID"
else bad "os-release ID mismatch"; fi

# 3. kernel patchset is pinned
# Format: name | url | sha256 | target-series | description
if grep -qE '^[a-zA-Z0-9_.-]+\|https?://' "${SANUS_ROOT}/kernel/patchset.conf"; then
	good "patchset has sources"
else
	bad "patchset.conf has no sources"
fi

# 3b. the single-source-of-truth symlinks resolve
for link in desktop kernel/sanus-fragment.config; do
	if [[ -e "${SANUS_ROOT}/${link}" ]]; then good "symlink ${link}"
	else bad "broken symlink ${link}"; fi
done

# 4. installer crate parses
if have cargo; then
	if cargo metadata --manifest-path "${SANUS_ROOT}/installer/Cargo.toml" --format-version 1 >/dev/null 2>&1; then
		good "installer Cargo.toml"
	else bad "installer Cargo.toml invalid"; fi
else note skip "cargo not installed"; fi

# 5. shell syntax (scripts/, kernel/fetch-patches.sh, installer/vendor.sh, build.sh)
while IFS= read -r s; do
	if bash -n "${s}"; then good "sh ${s#${SANUS_ROOT}/}"
	else bad "sh syntax ${s#${SANUS_ROOT}/}"; fi
done < <(
	{
		find "${SANUS_ROOT}" -path "${SANUS_ROOT}/build" -prune -o -name '*.sh' -print
		printf '%s\n' "${SANUS_ROOT}/build.sh"
	} | sort -u
)

# 6. required rice files exist
for f in desktop/hypr/hyprland.conf desktop/waybar/config.jsonc desktop/wofi/config; do
	[[ -f "${SANUS_ROOT}/${f}" ]] && good "rice ${f}" || bad "missing rice file ${f}"
done

step "check: ${fail} problem(s)"
exit "$((fail > 0))"
