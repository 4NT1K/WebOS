#!/usr/bin/env bash
# Build and package the current WebOS ISO release.
#
#   sudo ./scripts/release-iso.sh            # reuse the existing chroot
#   sudo ./scripts/release-iso.sh --fresh     # full fetch/bootstrap/kernel/rootfs/iso
#
# The script verifies the source tree first, builds the ISO, checks the version
# stamped inside it and its SHA-256, then prepares split GitHub assets in
# /home/brah/release-<version>. It does NOT publish to GitHub and never powers
# the machine off.
set -Eeuo pipefail

WEBOS_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export WEBOS_ROOT
# shellcheck source=lib/common.sh
source "${WEBOS_ROOT}/scripts/lib/common.sh"

[[ ${EUID} -eq 0 ]] || die "this script needs root (sudo ./scripts/release-iso.sh)"

FRESH=0
case "${1:-}" in
	'')        ;;
	--fresh)   FRESH=1 ;;
	*)         die "usage: $0 [--fresh]" ;;
esac

NAME="${WEBOS_ID:-webos}-${WEBOS_VERSION_FULL}-${WEBOS_ARCH}.iso"
ISO="${BUILD_DIR}/${NAME}"
WORK="/home/brah/release-${WEBOS_VERSION}"
LOG="/home/brah/webos-release-${WEBOS_VERSION}.log"

exec > >(tee -a "${LOG}") 2>&1

step "release ${WEBOS_VERSION_FULL}: source regression gate"
bash "${WEBOS_ROOT}/scripts/50-check.sh" >/dev/null \
	|| die "50-check.sh failed; fix the tree before building"

export WEBOS_FORCE="${WEBOS_FORCE:-1}"
cd "${WEBOS_ROOT}"

if [[ ${FRESH} -eq 1 ]]; then
	step "release: full clean build (distclean -> fetch -> bootstrap -> kernel -> rootfs -> iso)"
	# bootstrap deliberately skips stage3 unpack when ${CHROOT}/etc exists,
	# so 'all' alone would reuse the old tree. Remove it for a real fresh build.
	./build.sh distclean
	./build.sh all
else
	step "release: incremental build (kernel -> rootfs -> iso, reusing chroot)"
	./build.sh kernel
	./build.sh rootfs
	./build.sh iso
fi

[[ -s "${ISO}" ]] || die "ISO missing at ${ISO}"
[[ -s "${ISO}.sha256" ]] || die "ISO checksum sidecar missing"

step "release: verifying the ISO"
( cd "${BUILD_DIR}" && sha256sum -c "${NAME}.sha256" ) \
	|| die "ISO SHA-256 mismatch"

EXTRACT="$(mktemp -d /tmp/opencode/webos-iso-verify.XXXXXX)"
trap 'rm -rf "${EXTRACT}"' EXIT
xorriso -osirrox on -indev "${ISO}" -extract /webos/version "${EXTRACT}/version" >/dev/null 2>&1 \
	|| die "could not read /webos/version from the ISO"
info "ISO /webos/version:"
sed 's/^/    /' "${EXTRACT}/version"
grep -qF "WEBOS_VERSION=${WEBOS_VERSION_FULL}" "${EXTRACT}/version" \
	|| die "ISO stamps the wrong version"
grep -q "WEBOS_KERNEL=6.12.119-webos" "${EXTRACT}/version" \
	|| die "ISO does not stamp the 6.12.119 kernel"

step "release: preparing split assets in ${WORK}"
rm -rf "${WORK}"
mkdir -p "${WORK}"
cp -a "${ISO}" "${ISO}.sha256" "${WORK}/"
cd "${WORK}"

b2sum "${NAME}" > "${NAME}.b2"
rm -f "${NAME}.part-"*
split -b 2086666240 -d -a 2 "${NAME}" "${NAME}.part-"

cat > README.txt <<EOF
WebOS ${WEBOS_VERSION} "Ashen" (amd64)
Linux/macOS reassemble: cat ${NAME}.part-* > ${NAME}
Windows reassemble:     copy /b ${NAME}.part-* ${NAME}
Verify: sha256sum -c SHA256SUMS.txt
Source: https://github.com/4NT1K/WebOS
EOF
sha256sum "${NAME}".part-* > SHA256SUMS.txt

step "release: done"
info "ISO:        ${ISO}"
info "SHA256:     $(cut -d' ' -f1 "${ISO}.sha256")"
info "Parts:      $(printf '%s\n' "${NAME}".part-* | wc -l) x 2086666240 bytes max"
info "Assets:     ${WORK}"
info "Notes:      ${WEBOS_ROOT}/docs/releases/v${WEBOS_VERSION}.md"
info "Publish with: gh release create v${WEBOS_VERSION} --repo 4NT1K/WebOS --verify-tag \\"
info "  --title 'WebOS ${WEBOS_VERSION} \"Ashen\"' \\"
info "  --notes-file ${WEBOS_ROOT}/docs/releases/v${WEBOS_VERSION}.md \\"
info "  ${WORK}/README.txt ${WORK}/SHA256SUMS.txt ${WORK}/${NAME}.b2 ${WORK}/${NAME}.part-*"
