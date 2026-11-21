#!/usr/bin/env bash
# Stage 20 — build the WebOS kernel (sys-kernel/webos-kernel) inside the
# chroot and install it under /boot.
set -Eeuo pipefail
WEBOS_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export WEBOS_ROOT
source "${WEBOS_ROOT}/scripts/lib/common.sh"

step "kernel: sys-kernel/webos-kernel (${WEBOS_KERNEL_SERIES}-webos)"
require_root
assert_stage_order kernel
trap_umount

mount_chroot

# Make sure the overlay inside the chroot is current.
rm -rf "${CHROOT}/usr/local/portage/webos"
cp -a "${WEBOS_ROOT}/overlay" "${CHROOT}/usr/local/portage/webos"
# Patches resolved by the fetch stage.
install -d "${CHROOT}/var/cache/webos/patches"
cp -a "${CACHE_DIR}/kernel-patches/." "${CHROOT}/var/cache/webos/patches/" 2>/dev/null || true

# egencache so the new ebuild is visible immediately.
chroot_sh "egencache --repo=webos --update --jobs=${WEBOS_JOBS} >/dev/null 2>&1 || true"

# The kernel tarball is a remote distfile, so its hash cannot be in the
# committed Manifest. Regenerate the kernel Manifests here — this also
# downloads linux-${WEBOS_KERNEL_SERIES}.tar.xz into DISTDIR, which the
# emerge below would have done anyway.
step "kernel: refreshing overlay manifests"
chroot_sh 'for p in sys-kernel/webos-kernel-sources sys-kernel/webos-kernel; do
	e=$(ls /usr/local/portage/webos/$p/*.ebuild 2>/dev/null | head -n1)
	[[ -n "$e" ]] && ebuild "$e" manifest >/dev/null 2>&1 || true
done' || warn "manifest refresh reported problems"

# A reused chroot still carries the pre-rename sanus-* kernel packages. They
# own /usr/src/linux-6.12 and /boot/vmlinuz-* with the OLD config, so the new
# webos-kernel collides on install. Remove them before emerging the replacement
# (the earlier build skipped this because it never rebuilt the kernel).
step "kernel: removing legacy sanus kernel packages"
chroot_sh "emerge --quiet --unmerge sys-kernel/sanus-kernel sys-kernel/sanus-kernel-sources >/dev/null 2>&1 || true"

step "kernel: emerging sources + kernel"
# The WebOS fragment can change without an ebuild revision, so Portage would
# otherwise keep the old kernel (and its old config). The ebuild stamps the
# fragment hash in /boot; rebuild when that stamp is missing or stale. Old
# images have no stamp at all, so they are rebuilt once.
FRAGMENT="${WEBOS_ROOT}/overlay/sys-kernel/webos-kernel/files/webos-fragment.config"
FRAGMENT_SHA="$(sha256sum "${FRAGMENT}" | awk '{print $1}')"
INSTALLED_SHA="$(chroot_sh "cat /boot/webos-fragment.sha256 2>/dev/null || true" | tr -d '\r')"
if [[ "${INSTALLED_SHA}" != "${FRAGMENT_SHA}" ]]; then
	step "kernel: fragment changed, forcing a rebuild"
	chroot_sh "emerge --quiet --unmerge sys-kernel/webos-kernel >/dev/null 2>&1 || true"
fi
chroot_sh "emerge --quiet-build=y --jobs=${WEBOS_JOBS} \
	sys-kernel/webos-kernel-sources sys-kernel/webos-kernel" \
	|| die "kernel emerge failed"

step "kernel: installing to /boot"
chroot_sh "emerge --quiet-build=y sys-kernel/webos-kernel && \
	eselect kernel list && \
	ln -sfn \$(eselect kernel list | awk '/\\*/{print \$2}') /usr/src/linux 2>/dev/null || true"

KREL="$(chroot_sh "ls /lib/modules | sort -V | tail -n1" | tr -d '\r')"
[[ -n "${KREL}" ]] || die "could not determine installed kernel release"
info "installed kernel: ${KREL}"
chroot_sh "ls -lh /boot/vmlinuz-${KREL} /boot/initramfs-${KREL}.img 2>/dev/null || true"

printf '%s\n' "${KREL}" > "${BUILD_DIR}/.kernel-release"
ok "kernel ${KREL} built"
