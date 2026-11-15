#!/usr/bin/env bash
# WebOS top-level build entry point.
#
#   ./build.sh all | fetch | bootstrap | kernel | rootfs | iso
#   ./build.sh clean | distclean | status | help
#
# Environment knobs (all optional):
#   WEBOS_ARCH=amd64|arm64      target architecture            (default amd64)
#   WEBOS_JOBS=N                make/emerge parallelism        (default nproc)
#   WEBOS_BUILD_DIR=path        scratch directory              (default ./build)
#   WEBOS_STAGE3_VARIANT=openrc|systemd|nomultilib
#   WEBOS_MIRROR=url            Gentoo distfiles mirror
#   WEBOS_PORTAGE_MIRROR=url    Gentoo portage snapshot mirror
#   WEBOS_KERNEL_SERIES=6.12    kernel series (also selects the patchset)
#   WEBOS_FORCE=1               run on a non-Gentoo host
#   WEBOS_DEBUG=1               echo every command
#
set -Eeuo pipefail

WEBOS_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export WEBOS_ROOT
# shellcheck source=scripts/lib/common.sh
source "${WEBOS_ROOT}/scripts/lib/common.sh"

usage() {
	# Print the comment header (everything after the shebang, up to the first
	# line of code) with the leading "# " stripped.
	awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "${BASH_SOURCE[0]}"
	cat <<-'EOF'

	Stages:
	  fetch      download stage3, portage snapshot and the kernel patchset
	  bootstrap  unpack stage3, apply config/, emerge the base system
	  kernel     build sys-kernel/webos-kernel inside the chroot
	  rootfs     emerge webos-base/desktop/gaming/theme, install branding
	  iso        build squashfs + initramfs + hybrid GRUB ISO
	  all        fetch -> bootstrap -> kernel -> rootfs -> iso
	EOF
}

cmd_all() {
	cmd_fetch
	cmd_bootstrap
	cmd_kernel
	cmd_rootfs
	cmd_iso
	step "WebOS ${WEBOS_VERSION_FULL} built"
	step "  ISO: ${ISO_OUT}"
	step "  sha256: $(cut -d' ' -f1 "${ISO_OUT}.sha256" 2>/dev/null || echo n/a)"
}

cmd_fetch()      { bash "${WEBOS_ROOT}/scripts/00-fetch.sh"; }
cmd_bootstrap()  { bash "${WEBOS_ROOT}/scripts/10-bootstrap.sh"; }
cmd_kernel()     { bash "${WEBOS_ROOT}/scripts/20-kernel.sh"; }
cmd_rootfs()     { bash "${WEBOS_ROOT}/scripts/30-rootfs.sh"; }
cmd_iso()        { bash "${WEBOS_ROOT}/scripts/40-iso.sh"; }

cmd_clean() {
	step "removing ${WEBOS_BUILD_DIR}/{rootfs,iso,iso-staging}"
	rm -rf -- "${WEBOS_BUILD_DIR}/rootfs" "${WEBOS_BUILD_DIR}/iso" \
	          "${WEBOS_BUILD_DIR}/iso-staging" "${WEBOS_BUILD_DIR}/cache"
	ok "cleaned (chroot and downloads kept; use distclean to remove those too)"
}

cmd_distclean() {
	cmd_clean
	step "removing ${WEBOS_BUILD_DIR} entirely"
	umount_chroot 2>/dev/null || true
	rm -rf -- "${WEBOS_BUILD_DIR}"
	ok "distcleaned"
}

cmd_status() {
	require_root
	load_branding
	printf '%s\n' "WebOS ${WEBOS_VERSION_FULL} (${WEBOS_CODENAME})"
	printf '  root        : %s\n' "${WEBOS_ROOT}"
	printf '  build dir   : %s\n' "${WEBOS_BUILD_DIR}"
	printf '  arch        : %s (%s)\n' "${WEBOS_ARCH}" "${WEBOS_STAGE3_VARIANT}"
	printf '  jobs        : %s\n' "${WEBOS_JOBS}"
	printf '  chroot      : %s\n' "$([ -d "${CHROOT}/etc" ] && echo present || echo absent)"
	printf '  kernel tree : %s\n' "$([ -d "${CHROOT}/usr/src/linux" ] && echo present || echo absent)"
	printf '  rootfs      : %s\n' "$([ -d "${BUILD_DIR}/rootfs" ] && du -sh "${BUILD_DIR}/rootfs" | cut -f1 || echo absent)"
	printf '  iso         : %s\n' "$([ -f "${ISO_OUT}" ] && du -h "${ISO_OUT}" | cut -f1 || echo absent)"
	check_host_tools
}

main() {
	[[ $# -ge 1 ]] || { usage; exit 1; }
	case "$1" in
		all)       cmd_all ;;
		fetch)     cmd_fetch ;;
		bootstrap) cmd_bootstrap ;;
		kernel)    cmd_kernel ;;
		rootfs)    cmd_rootfs ;;
		iso)       cmd_iso ;;
		clean)     cmd_clean ;;
		distclean) cmd_distclean ;;
		status)    cmd_status ;;
		help|-h|--help) usage ;;
		*) die "unknown stage: $1 (try: ./build.sh help)" ;;
	esac
}
main "$@"
