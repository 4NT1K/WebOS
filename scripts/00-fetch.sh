#!/usr/bin/env bash
# Stage 00 — fetch everything the build needs: stage3, portage snapshot,
# kernel patchset, and the Gentoo binhost index (optional).
set -Eeuo pipefail
SANUS_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export SANUS_ROOT
source "${SANUS_ROOT}/scripts/lib/common.sh"

step "fetch: SanusOS ${SANUS_VERSION_FULL} (${SANUS_ARCH}/${SANUS_STAGE3_VARIANT})"
require_cmd curl tar sha256sum
mkdir -p "${DL_DIR}"

# ------------------------------------------------------------- stage3 --------
STAGE3_URL="$(resolve_stage3_url)"
STAGE3_FILE="${DL_DIR}/$(basename -- "${STAGE3_URL}")"
info "stage3: ${STAGE3_URL}"
fetch "${STAGE3_URL}" "${STAGE3_FILE}"

# Gentoo publishes a .sha256 sidecar next to each autobuild.
if curl --fail --silent --location --output "${STAGE3_FILE}.sha256" "${STAGE3_URL}.sha256" 2>/dev/null; then
	( cd "${DL_DIR}" && sha256sum --check --status "$(basename -- "${STAGE3_FILE}").sha256" ) \
		&& ok "stage3 checksum verified" \
		|| die "stage3 checksum mismatch"
else
	warn "no published checksum for stage3; recording local hash"
	sha256_of "${STAGE3_FILE}" > "${STAGE3_FILE}.local.sha256"
fi
printf '%s\n' "${STAGE3_FILE}" > "${BUILD_DIR}/.stage3-path"

# ------------------------------------------------------- portage snapshot ----
PORTAGE_FILE=""
if [[ -f "${BUILD_DIR}/.portage-path" ]]; then
	PORTAGE_FILE="$(cat "${BUILD_DIR}/.portage-path")"
fi
if [[ -n "${PORTAGE_FILE}" && -s "${PORTAGE_FILE}" ]]; then
	info "snapshot: using existing ${PORTAGE_FILE}"
else
	PORTAGE_URL="$(resolve_portage_url)"
	[[ -n "${PORTAGE_URL}" ]] || die "could not resolve a portage snapshot"
	PORTAGE_FILE="${DL_DIR}/$(basename -- "${PORTAGE_URL}")"
	info "snapshot: ${PORTAGE_URL}"
	fetch "${PORTAGE_URL}" "${PORTAGE_FILE}"
	printf '%s\n' "${PORTAGE_FILE}" > "${BUILD_DIR}/.portage-path"
fi

# ------------------------------------------------------- kernel patchset -----
step "fetch: kernel patchset (series ${SANUS_KERNEL_SERIES})"
bash "${SANUS_ROOT}/kernel/fetch-patches.sh" --out "${CACHE_DIR}/kernel-patches"

# --------------------------------------------------- third-party overlays ----
step "fetch: third-party ebuild overlays"
if have git; then
	for entry in "${SANUS_OVERLAYS[@]}"; do
		clone_overlay "${entry%%|*}" "${CACHE_DIR}/repos/${entry%%|*}"
	done
else
	warn "git not found — overlays will be cloned during bootstrap"
fi

# ------------------------------------------------------ installer vendor -----
step "fetch: vendoring the installer crate"
if have cargo; then
	bash "${SANUS_ROOT}/installer/vendor.sh" || die "cargo vendor failed"
else
	warn "cargo not found — the installer cannot be built offline"
	warn "install dev-lang/rust (or rust-bin) and re-run ./build.sh fetch"
fi

# ------------------------------------------------------------- done ----------
ok "downloads in ${DL_DIR}"
du -sh "${DL_DIR}" 2>/dev/null | sed 's/^/  /' >&2
