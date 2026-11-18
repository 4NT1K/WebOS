#!/usr/bin/env bash
# Shared shell library for the WebOS build pipeline.
# Sourced by build.sh and by every scripts/NN-*.sh stage.

# ---------------------------------------------------------------- guards -----
[[ -n "${WEBOS_COMMON_SOURCED:-}" ]] && return 0
WEBOS_COMMON_SOURCED=1

# ---------------------------------------------------------------- output -----
if [[ -t 1 ]]; then
	C_RESET=$'\033[0m'; C_DIM=$'\033[2m'; C_BOLD=$'\033[1m'
	C_RED=$'\033[31m'; C_GRN=$'\033[32m'; C_YEL=$'\033[33m'; C_BLU=$'\033[34m'
	C_CYN=$'\033[36m'
else
	C_RESET=; C_DIM=; C_BOLD=; C_RED=; C_GRN=; C_YEL=; C_BLU=; C_CYN=
fi

_msg()  { printf '%s\n' "$*" >&2; }
step()  { printf '%s==>%s %s%s%s\n' "${C_BLU}${C_BOLD}" "${C_RESET}" "${C_BOLD}" "$*" "${C_RESET}" >&2; }
info()  { printf '%s  ->%s %s\n' "${C_CYN}" "${C_RESET}" "$*" >&2; }
ok()    { printf '%s  ok%s %s\n' "${C_GRN}" "${C_RESET}" "$*" >&2; }
warn()  { printf '%swarn%s %s\n' "${C_YEL}" "${C_RESET}" "$*" >&2; }
die()   { printf '%sfail%s %s\n' "${C_RED}" "${C_RESET}" "$*" >&2; exit 1; }
debug() { [[ -n "${WEBOS_DEBUG:-}" ]] && printf '%sdebug%s %s\n' "${C_DIM}" "${C_RESET}" "$*" >&2 || true; }

# --------------------------------------------------------------- branding ----
load_branding() {
	# shellcheck source=/dev/null
	source "${WEBOS_ROOT}/branding/version"
}

# --------------------------------------------------------------- defaults ----
load_branding
: "${WEBOS_ARCH:=amd64}"
: "${WEBOS_STAGE3_VARIANT:=openrc}"
: "${WEBOS_JOBS:=$(nproc 2>/dev/null || echo 4)}"
: "${WEBOS_BUILD_DIR:=${WEBOS_ROOT}/build}"
: "${WEBOS_MIRROR:=https://distfiles.gentoo.org}"
: "${WEBOS_PORTAGE_MIRROR:=https://snapshots.gentoo.org}"
: "${WEBOS_LOG_LEVEL:=info}"

export WEBOS_ARCH WEBOS_JOBS WEBOS_BUILD_DIR WEBOS_STAGE3_VARIANT

BUILD_DIR="${WEBOS_BUILD_DIR}"
CHROOT="${BUILD_DIR}/chroot"
DL_DIR="${BUILD_DIR}/downloads"
CACHE_DIR="${BUILD_DIR}/cache"
ROOTFS_DIR="${BUILD_DIR}/rootfs"
ISO_STAGING="${BUILD_DIR}/iso-staging"
ISO_OUT="${BUILD_DIR}/${WEBOS_ID:-webos}-${WEBOS_VERSION_FULL}-${WEBOS_ARCH}.iso"

# Map our arch names onto Gentoo's stage3 naming.
case "${WEBOS_ARCH}" in
	amd64) STAGE3_ARCH="amd64" ;;
	arm64) STAGE3_ARCH="arm64" ;;
	*)     die "unsupported WEBOS_ARCH: ${WEBOS_ARCH} (want amd64 or arm64)" ;;
esac
STAGE3_FLAVOR="${WEBOS_STAGE3_VARIANT}"

# --------------------------------------------------------------- helpers -----
have() { command -v "$1" >/dev/null 2>&1; }

require_root() {
	[[ ${EUID} -eq 0 ]] || die "this stage needs root (try: sudo ./build.sh ...)"
}

require_gentoo() {
	[[ -f /etc/gentoo-release || -n "${WEBOS_FORCE:-}" ]] && return 0
	die "WebOS builds on Gentoo. Set WEBOS_FORCE=1 to override (unsupported)."
}

require_cmd() {
	local c
	for c in "$@"; do have "$c" || die "missing host tool: $c"; done
}

check_host_tools() {
	local missing=()
	local t
	for t in curl tar xz zstd gzip sha256sum; do have "$t" || missing+=("$t"); done
	if ((${#missing[@]})); then
		warn "missing optional host tools: ${missing[*]}"
	fi
}

# Run a command, echoing it first when debugging.
run() {
	debug "+ $*"
	"$@"
}

# Run a command inside the build chroot. The chroot must be mounted.
chroot_run() {
	[[ -d "${CHROOT}/etc" ]] || die "chroot not bootstrapped (${CHROOT})"
	debug "+ chroot ${CHROOT} $*"
	env -i \
		HOME=/root \
		TERM="${TERM:-dumb}" \
		PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
		LANG=C.UTF-8 \
		chroot "${CHROOT}" "$@"
}

# chroot_run with a shell snippet.
chroot_sh() {
	chroot_run /bin/bash -c "$*"
}

# ------------------------------------------------------- chroot mounting -----
CHROOT_MOUNTS=()

mount_chroot() {
	local m
	for m in proc sys dev dev/pts dev/shm; do
		if ! mountpoint -q "${CHROOT}/${m}"; then
			mkdir -p "${CHROOT}/${m}"
			mount --rbind "/${m}" "${CHROOT}/${m}" 2>/dev/null \
				|| mount --bind "/${m}" "${CHROOT}/${m}"
			CHROOT_MOUNTS+=("${CHROOT}/${m}")
		fi
	done
	# keep the build chroot's DNS working
	if [[ -f /etc/resolv.conf ]]; then
		mkdir -p "${CHROOT}/etc"
		cp -fL /etc/resolv.conf "${CHROOT}/etc/resolv.conf" 2>/dev/null || true
	fi
	# portage needs a writable /tmp with exec
	if [[ -d "${CHROOT}/tmp" ]]; then
		mountpoint -q "${CHROOT}/tmp" || mount -t tmpfs -o mode=1777,size=8G tmpfs "${CHROOT}/tmp" || true
	fi
	debug "mounted chroot filesystems: ${CHROOT_MOUNTS[*]:-none}"
}

umount_chroot() {
	local m
	# reverse order, best effort
	for ((i = ${#CHROOT_MOUNTS[@]} - 1; i >= 0; i--)); do
		m="${CHROOT_MOUNTS[i]}"
		umount -R "$m" 2>/dev/null || umount -l "$m" 2>/dev/null || true
	done
	umount -R "${CHROOT}/tmp" 2>/dev/null || true
	CHROOT_MOUNTS=()
	debug "unmounted chroot filesystems"
}

trap_umount() {
	trap 'umount_chroot 2>/dev/null || true' EXIT
}

# ------------------------------------------------------------- downloads -----
# fetch <url> <dest>  — resume-capable, hash-checked by the caller.
fetch() {
	local url="$1" dest="$2"
	mkdir -p "$(dirname -- "${dest}")"
	if [[ -s "${dest}" ]]; then
		debug "cached: ${dest}"
		return 0
	fi
	info "downloading $(basename -- "${dest}")"
	curl --fail --location --retry 3 --retry-delay 2 \
		--continue-at - --output "${dest}.part" "${url}" \
		|| die "download failed: ${url}"
	mv -f "${dest}.part" "${dest}"
}

# ------------------------------------------------------------- overlays ------
# Third-party ebuild repositories WebOS builds against. ::gentoo and our own
# ::webos overlay are handled separately.
# Format: name|clone-url
# Priority order (higher wins) is webos > gentoo > these.
# removed because its upstream URL is currently inaccessible; WebOS ships
# sys-apps/pacman in its own overlay instead.
WEBOS_OVERLAYS=(
	"guru|https://github.com/gentoo-mirror/guru.git"
	"hyproverlay|https://codeberg.org/hyproverlay/hyproverlay.git"
	"steam-overlay|https://github.com/anyc/steam-overlay.git"
)

# overlay_url <name> — print the clone URL for a known overlay.
overlay_url() {
	local want="$1" entry
	for entry in "${WEBOS_OVERLAYS[@]}"; do
		if [[ "${entry%%|*}" == "${want}" ]]; then
			printf '%s\n' "${entry#*|}"
			return 0
		fi
	done
	return 1
}

# clone_overlay <name> <dest> — shallow-clone (or reuse) a third-party overlay.
clone_overlay() {
	local name="$1" dest="$2" url
	url="$(overlay_url "${name}")" || die "unknown overlay: ${name}"
	if [[ -d "${dest}/.git" ]]; then
		debug "overlay cached: ${dest}"
		return 0
	fi
	have git || die "git is required to fetch the ${name} overlay"
	mkdir -p "$(dirname -- "${dest}")"
	rm -rf "${dest}"
	info "cloning overlay ${name} (${url})"
	git clone --depth=1 --quiet "${url}" "${dest}" \
		|| die "failed to clone ${name} from ${url}"
}

# fetch_latest_stage3 — resolves the newest stage3 tarball for our arch/flavor
# and writes its URL to stdout.
resolve_stage3_url() {
	local latest="${WEBOS_MIRROR}/releases/${STAGE3_ARCH}/autobuilds/latest-stage3-${STAGE3_ARCH}-${STAGE3_FLAVOR}.txt"
	local line
	# The latest file is PGP-signed, so skip headers/signatures and extract the
	# actual stage3 tarball path.
	line="$(curl --fail --silent --show-error --location "${latest}" \
		| grep -oE '^[0-9TZ]+/stage3-[^[:space:]]+\.tar\.(xz|zst|bz2|gz)' | head -n1)"
	[[ -n "${line}" ]] || die "could not resolve stage3 from ${latest}"
	printf '%s/releases/%s/autobuilds/%s\n' "${WEBOS_MIRROR}" "${STAGE3_ARCH}" "${line}"
}

# fetch_portage_snapshot — newest portage snapshot URL.
resolve_portage_url() {
	local latest="${WEBOS_PORTAGE_MIRROR}/latest/"
	curl --fail --silent --show-error --location "${latest}" \
		| grep -oE 'portage-[0-9]{8}\.tar\.(xz|zst|bz2|gz)' \
		| sort -u | tail -n1 \
		| sed "s|^|${latest}|"
}

# ------------------------------------------------------------ iso helpers ----
mksquashfs_root() {
	local src="$1" out="$2" label="${3:-webos}"
	require_cmd mksquashfs
	# Prefer zstd: it decompresses fastest on the live medium. Some hosts
	# build squashfs-tools without the zstd USE flag, so fall back to xz
	# instead of failing the whole ISO after a 20-minute rootfs build.
	local comp=(-comp zstd -Xcompression-level 19)
	if ! mksquashfs -help-section compression 2>&1 | grep -qw zstd; then
		warn "mksquashfs has no zstd support; compressing with xz"
		comp=(-comp xz -Xbcj x86)
	fi
	info "squashfs: $(du -sh "${src}" | cut -f1) -> ${out}"
	mksquashfs "${src}" "${out}" \
		-noappend "${comp[@]}" \
		-b 1M -no-progress -wildcards \
		-e 'var/cache/*' 'var/tmp/*' 'tmp/*' 'usr/src/*' 'proc/*' 'sys/*' 'dev/*'
}

sha256_of() { sha256sum "$1" | awk '{print $1}'; }

# --------------------------------------------------------------- checks ------
assert_stage_order() {
	local stage="$1"
	case "${stage}" in
		bootstrap) ;;
		kernel)  [[ -d "${CHROOT}/etc" ]] || die "run ./build.sh bootstrap first" ;;
		rootfs)  [[ -d "${CHROOT}/etc" ]] || die "run ./build.sh bootstrap first" ;;
		iso)     [[ -d "${ROOTFS_DIR}/etc" ]] || die "run ./build.sh rootfs first" ;;
	esac
}
