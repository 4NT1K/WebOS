#!/usr/bin/env bash
# Publish WebOS v1.034 to GitHub only after the release build is confirmed good.
# Safe to run repeatedly: exits quietly while the build is still running, on
# any failed verification, or once the release has been created.
set -uo pipefail

export HOME=/home/brah
export PATH="/home/brah/.local/bin:/usr/local/bin:/usr/bin:/bin"

VER=1.034
NAME="webos-${VER}-Ashen-amd64.iso"
REPO=/home/brah/WebOS
BUILD="${REPO}/build"
WORK="/home/brah/release-${VER}"
LOG="/home/brah/webos-release-${VER}.log"
MARK="/home/brah/webos-published-${VER}"
PUBLISH_LOG="/home/brah/webos-publish-${VER}.log"

exec >>"${PUBLISH_LOG}" 2>&1
log() { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }

[[ -e "${MARK}" ]] && exit 0

# Never publish while a build is still writing artifacts.
if pgrep -f '[r]elease-iso\.sh' >/dev/null || pgrep -f '[b]uild\.sh all' >/dev/null; then
	log "build still running; waiting"
	exit 0
fi

# The release helper writes this only after all of its own checks pass.
if ! grep -qF 'release: done' "${LOG}" 2>/dev/null; then
	log "no successful-build marker in ${LOG}; not publishing"
	exit 0
fi

need_file() {
	[[ -s "$1" ]] || { log "missing or empty: $1"; exit 0; }
}
need_file "${BUILD}/${NAME}"
need_file "${BUILD}/${NAME}.sha256"
need_file "${REPO}/docs/releases/v${VER}.md"
[[ -d "${WORK}" ]] || { log "missing asset dir ${WORK}"; exit 0; }
need_file "${WORK}/README.txt"
need_file "${WORK}/SHA256SUMS.txt"
need_file "${WORK}/${NAME}.b2"
shopt -s nullglob
parts=("${WORK}"/"${NAME}".part-*)
shopt -u nullglob
[[ ${#parts[@]} -gt 0 ]] || { log "no split ISO parts"; exit 0; }

if ! ( cd "${BUILD}" && sha256sum -c "${NAME}.sha256" ) >/dev/null 2>&1; then
	log "ISO SHA-256 verification failed; not publishing"
	exit 0
fi
if ! ( cd "${WORK}" && sha256sum -c SHA256SUMS.txt ) >/dev/null 2>&1; then
	log "split-part SHA-256 verification failed; not publishing"
	exit 0
fi

verify_dir="$(mktemp -d /tmp/opencode/webos-publish.XXXXXX)"
trap 'rm -rf "${verify_dir}"' EXIT
if ! xorriso -osirrox on -indev "${BUILD}/${NAME}" \
	-extract /webos/version "${verify_dir}/version" >/dev/null 2>&1; then
	log "cannot read /webos/version from ISO; not publishing"
	exit 0
fi
if ! grep -qF 'WEBOS_VERSION=1.034-Ashen' "${verify_dir}/version"; then
	log "ISO has the wrong version stamp; not publishing"
	exit 0
fi
if ! grep -qF 'WEBOS_KERNEL=6.12.119-webos' "${verify_dir}/version"; then
	log "ISO has the wrong kernel stamp; not publishing"
	exit 0
fi

if gh release view "v${VER}" --repo 4NT1K/WebOS >/dev/null 2>&1; then
	log "release v${VER} already exists; nothing to do"
	touch "${MARK}"
	exit 0
fi

if ! git -C "${REPO}" rev-parse -q --verify "refs/tags/v${VER}" >/dev/null; then
	git -C "${REPO}" tag -a "v${VER}" -m "WebOS ${VER} \"Ashen\"" || {
		log "could not create tag v${VER}"; exit 0; }
fi
git -C "${REPO}" push origin "v${VER}" >/dev/null 2>&1 || {
	log "could not push tag v${VER}"; exit 0; }

log "publishing v${VER} with ${#parts[@]} ISO parts"
cd "${WORK}"
if gh release create "v${VER}" \
	--repo 4NT1K/WebOS \
	--verify-tag \
	--latest \
	--title "WebOS ${VER} \"Ashen\"" \
	--notes-file "${REPO}/docs/releases/v${VER}.md" \
	README.txt SHA256SUMS.txt "${NAME}.b2" "${NAME}".part-*; then
	touch "${MARK}"
	log "PUBLISHED https://github.com/4NT1K/WebOS/releases/tag/v${VER}"
else
	log "gh release create failed; will retry on the next check"
fi
