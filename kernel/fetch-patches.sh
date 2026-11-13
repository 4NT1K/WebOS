#!/usr/bin/env bash
# Resolve, download and hash the WebOS kernel patch series.
#
#   kernel/fetch-patches.sh [--out DIR] [--verify] [--kernel-series 6.12]
#
#   --out DIR     where to place the patches (default: ./build/cache/kernel-patches)
#   --verify      do not download; re-check every pinned hash and exit non-zero
#                 on any mismatch.  Use this in CI to detect upstream rewrites.
#   --series S    only fetch entries whose target-series matches S
#   --list        print the resolved series and exit
#
# After a successful fetch the output directory contains:
#   *.patch                 the individual patches
#   series                  ordered list of patches (for `git am` / `quilt`)
#   INDEX                   human-readable table: name, hash, series, desc
#   .lock                   machine-readable name=sha256 lines
#
# When patchset.conf contains the word `auto` in the hash column, this script
# computes the real digest and rewrites patchset.conf in place so the pin is
# committed.  It never rewrites a non-auto hash.
set -Eeuo pipefail

SANUS_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SANUS_ROOT}/scripts/lib/common.sh"

PATCHSET_CONF="${SANUS_ROOT}/kernel/patchset.conf"
OUT_DIR="${SANUS_ROOT}/build/cache/kernel-patches"
SERIES="${SANUS_KERNEL_SERIES:-6.12}"
MODE="fetch"

while [[ $# -gt 0 ]]; do
	case "$1" in
		--out)    OUT_DIR="$2"; shift 2 ;;
		--verify) MODE="verify"; shift ;;
		--series) SERIES="$2"; shift 2 ;;
		--list)   MODE="list"; shift ;;
		-h|--help) awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "${BASH_SOURCE[0]}"; exit 0 ;;
		*) die "unknown argument: $1" ;;
	esac
done

require_cmd sha256sum
[[ -f "${PATCHSET_CONF}" ]] || die "missing ${PATCHSET_CONF}"

mkdir -p "${OUT_DIR}"
: > "${OUT_DIR}/series"
: > "${OUT_DIR}/INDEX"
: > "${OUT_DIR}/.lock"

# Parse the pipe-delimited entries, skipping comments and blanks.
entries() {
	grep -vE '^[[:space:]]*#|^[[:space:]]*$' "${PATCHSET_CONF}"
}

# Should this entry be fetched for the requested series?
applies() {
	local target="$1"
	[[ "${target}" == "*" || "${target}" == "${SERIES}" || "${target}" == "${SERIES}".* ]]
}

rewrite_hash_in_conf() {
	local name="$1" newhash="$2" tmp
	tmp="$(mktemp)"
	awk -v n="${name}" -v h="${newhash}" -F'|' '
		BEGIN { OFS="|" }
		/^[[:space:]]*#/ || /^[[:space:]]*$/ { print; next }
		{
			if ($1 == n && $3 ~ /auto/) { $3 = h }
			print
		}
	' "${PATCHSET_CONF}" > "${tmp}"
	mv -f "${tmp}" "${PATCHSET_CONF}"
}

total=0 checked=0 failed=0 skipped=0

while IFS='|' read -r name url sha series desc; do
	name="$(echo "${name}" | xargs)"; url="$(echo "${url}" | xargs)"
	sha="$(echo "${sha}" | xargs)"; series="$(echo "${series}" | xargs)"
	desc="$(echo "${desc}" | xargs)"

	if ! applies "${series}"; then
		skipped=$((skipped + 1))
		continue
	fi
	total=$((total + 1))

	if [[ "${MODE}" == "list" ]]; then
		printf '%-16s %-8s %s\n' "${name}" "${series}" "${desc}"
		continue
	fi

	dest="${OUT_DIR}/${name}.patch"

	if [[ "${MODE}" == "verify" ]]; then
		if [[ "${sha}" == "auto" ]]; then
			warn "${name}: unpinned (auto) — cannot verify"
			continue
		fi
		[[ -f "${dest}" ]] || { warn "${name}: not downloaded"; failed=$((failed + 1)); continue; }
		got="$(sha256_of "${dest}")"
		if [[ "${got}" == "${sha}" ]]; then
			ok "${name}: hash ok"
			checked=$((checked + 1))
		else
			printf '  %sMISMATCH%s %s\n' "${C_RED}" "${C_RESET}" "${name}" >&2
			printf '      expected %s\n      got      %s\n' "${sha}" "${got}" >&2
			failed=$((failed + 1))
		fi
		continue
	fi

	# --- fetch mode ---------------------------------------------------------
	if [[ -s "${dest}" ]]; then
		info "${name}: cached"
	else
		info "${name}: downloading"
		curl --fail --location --retry 3 --retry-delay 2 --silent --show-error \
			--output "${dest}.part" "${url}" \
			|| { warn "${name}: download failed (${url})"; failed=$((failed + 1)); rm -f "${dest}.part"; continue; }
		mv -f "${dest}.part" "${dest}"
	fi

	got="$(sha256_of "${dest}")"
	if [[ "${sha}" == "auto" ]]; then
		warn "${name}: pinning hash ${got:0:16}…"
		rewrite_hash_in_conf "${name}" "${got}"
		sha="${got}"
	elif [[ "${got}" != "${sha}" ]]; then
		printf '  %sHASH MISMATCH%s %s\n' "${C_RED}" "${C_RESET}" "${name}" >&2
		printf '      pinned   %s\n      got      %s\n' "${sha}" "${got}" >&2
		printf '      refusing to continue: upstream rewrote this patch.\n' >&2
		printf '      re-pin deliberately, after reviewing the diff.\n' >&2
		failed=$((failed + 1))
		continue
	fi

	printf '%s\n' "${dest}" >> "${OUT_DIR}/series"
	printf '%s=%s\n' "${name}" "${sha}" >> "${OUT_DIR}/.lock"
	printf '%-16s %-8s %s  %s\n' "${name}" "${sha:0:12}…" "${series}" "${desc}" >> "${OUT_DIR}/INDEX"
	checked=$((checked + 1))
done < <(entries)

if [[ "${MODE}" != "list" ]]; then
	# Deterministic order for the series file.
	sort -o "${OUT_DIR}/series" "${OUT_DIR}/series"
	step "patchset: ${checked} ok, ${failed} failed, ${skipped} skipped (series ${SERIES})"
	[[ -s "${OUT_DIR}/series" ]] || warn "no patches resolved for series ${SERIES}"
	[[ "${failed}" -eq 0 ]] || die "patchset resolution failed"
fi
