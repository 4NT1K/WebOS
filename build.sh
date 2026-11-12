#!/usr/bin/env bash
# SanusOS top-level build entry point.
#
#   ./build.sh all | fetch | bootstrap | kernel | rootfs | iso
#   ./build.sh clean | distclean | status | help
#
# Environment knobs (all optional):
#   SANUS_ARCH=amd64|arm64      target architecture            (default amd64)
#   SANUS_JOBS=N                make/emerge parallelism        (default nproc)
#   SANUS_BUILD_DIR=path        scratch directory              (default ./build)
#   SANUS_STAGE3_VARIANT=openrc|systemd|nomultilib
#   SANUS_MIRROR=url            Gentoo distfiles mirror
#   SANUS_PORTAGE_MIRROR=url    Gentoo portage snapshot mirror
#   SANUS_KERNEL_SERIES=6.12    kernel series (also selects the patchset)
#   SANUS_FORCE=1               run on a non-Gentoo host
#   SANUS_DEBUG=1               echo every command
#
set -Eeuo pipefail

SANUS_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export SANUS_ROOT
# shellcheck source=scripts/lib/common.sh
source "${SANUS_ROOT}/scripts/lib/common.sh"

usage() {
	# Print the comment header (everything after the shebang, up to the first
	# line of code) with the leading "# " stripped.
	awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "${BASH_SOURCE[0]}"
	cat <<-'EOF'

	Stages:
	  fetch      download stage3, portage snapshot and the kernel patchset
	  bootstrap  unpack stage3, apply config/, emerge the base system
	  kernel     build sys-kernel/sanus-kernel inside the chroot
	  rootfs     emerge sanus-base/desktop/gaming/theme, install branding
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
	step "SanusOS ${SANUS_VERSION_FULL} built"
	step "  ISO: ${ISO_OUT}"
	step "  sha256: $(cut -d' ' -f1 "${ISO_OUT}.sha256" 2>/dev/null || echo n/a)"
}

cmd_fetch()      { bash "${SANUS_ROOT}/scripts/00-fetch.sh"; }
cmd_bootstrap()  { bash "${SANUS_ROOT}/scripts/10-bootstrap.sh"; }
cmd_kernel()     { bash "${SANUS_ROOT}/scripts/20-kernel.sh"; }
cmd_rootfs()     { bash "${SANUS_ROOT}/scripts/30-rootfs.sh"; }
cmd_iso()        { bash "${SANUS_ROOT}/scripts/40-iso.sh"; }

cmd_clean() {
	step "removing ${SANUS_BUILD_DIR}/{rootfs,iso,iso-staging}"
	rm -rf -- "${SANUS_BUILD_DIR}/rootfs" "${SANUS_BUILD_DIR}/iso" \
	          "${SANUS_BUILD_DIR}/iso-staging" "${SANUS_BUILD_DIR}/cache"
	ok "cleaned (chroot and downloads kept; use distclean to remove those too)"
}

cmd_distclean() {
	cmd_clean
	step "removing ${SANUS_BUILD_DIR} entirely"
	umount_chroot 2>/dev/null || true
	rm -rf -- "${SANUS_BUILD_DIR}"
	ok "distcleaned"
}

cmd_status() {
	require_root
	load_branding
	printf '%s\n' "SanusOS ${SANUS_VERSION_FULL} (${SANUS_CODENAME})"
	printf '  root        : %s\n' "${SANUS_ROOT}"
	printf '  build dir   : %s\n' "${SANUS_BUILD_DIR}"
	printf '  arch        : %s (%s)\n' "${SANUS_ARCH}" "${SANUS_STAGE3_VARIANT}"
	printf '  jobs        : %s\n' "${SANUS_JOBS}"
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
