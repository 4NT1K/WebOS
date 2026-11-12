#!/usr/bin/env bash
# Stage 20 — build the SanusOS kernel (sys-kernel/sanus-kernel) inside the
# chroot and install it under /boot.
set -Eeuo pipefail
SANUS_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export SANUS_ROOT
source "${SANUS_ROOT}/scripts/lib/common.sh"

step "kernel: sys-kernel/sanus-kernel (${SANUS_KERNEL_SERIES}-sanusos)"
require_root
assert_stage_order kernel
trap_umount

mount_chroot

# Make sure the overlay inside the chroot is current.
rm -rf "${CHROOT}/usr/local/portage/sanus"
cp -a "${SANUS_ROOT}/overlay" "${CHROOT}/usr/local/portage/sanus"
# Patches resolved by the fetch stage.
install -d "${CHROOT}/var/cache/sanus/patches"
cp -a "${CACHE_DIR}/kernel-patches/." "${CHROOT}/var/cache/sanus/patches/" 2>/dev/null || true

# egencache so the new ebuild is visible immediately.
chroot_sh "egencache --repo=sanus --update --jobs=${SANUS_JOBS} >/dev/null 2>&1 || true"

# The kernel tarball is a remote distfile, so its hash cannot be in the
# committed Manifest. Regenerate the kernel Manifests here — this also
# downloads linux-${SANUS_KERNEL_SERIES}.tar.xz into DISTDIR, which the
# emerge below would have done anyway.
step "kernel: refreshing overlay manifests"
chroot_sh 'for p in sys-kernel/sanus-kernel-sources sys-kernel/sanus-kernel; do
	e=$(ls /usr/local/portage/sanus/$p/*.ebuild 2>/dev/null | head -n1)
	[[ -n "$e" ]] && ebuild "$e" manifest >/dev/null 2>&1 || true
done' || warn "manifest refresh reported problems"

step "kernel: emerging sources + kernel"
chroot_sh "emerge --quiet-build=y --jobs=${SANUS_JOBS} \
	sys-kernel/sanus-kernel-sources sys-kernel/sanus-kernel" \
	|| die "kernel emerge failed"

step "kernel: installing to /boot"
chroot_sh "emerge --quiet-build=y sys-kernel/sanus-kernel && \
	eselect kernel list && \
	ln -sfn \$(eselect kernel list | awk '/\\*/{print \$2}') /usr/src/linux 2>/dev/null || true"

KREL="$(chroot_sh "ls /lib/modules | sort -V | tail -n1" | tr -d '\r')"
[[ -n "${KREL}" ]] || die "could not determine installed kernel release"
info "installed kernel: ${KREL}"
chroot_sh "ls -lh /boot/vmlinuz-${KREL} /boot/initramfs-${KREL}.img 2>/dev/null || true"

printf '%s\n' "${KREL}" > "${BUILD_DIR}/.kernel-release"
ok "kernel ${KREL} built"
