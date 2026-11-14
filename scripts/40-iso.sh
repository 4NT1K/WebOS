#!/usr/bin/env bash
# Stage 40 — assemble the live ISO: initramfs, squashfs, GRUB hybrid image.
#
# Layout produced:
#   /boot/grub/grub.cfg
#   /boot/vmlinuz-sanus
#   /boot/initramfs-sanus.img
#   /live/sanus.squashfs          <- the live system, also the install source
#   /sanus/version                <- branding, read by the live session
set -Eeuo pipefail
SANUS_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export SANUS_ROOT
source "${SANUS_ROOT}/scripts/lib/common.sh"

step "iso: building live medium"
require_root
require_cmd mksquashfs xorriso grub-mkrescue mformat
assert_stage_order iso
trap_umount

KREL="$(cat "${BUILD_DIR}/.kernel-release" 2>/dev/null || ls "${ROOTFS_DIR}/lib/modules" | sort -V | tail -n1)"
[[ -n "${KREL}" ]] || die "kernel release unknown"

rm -rf "${ISO_STAGING}"
install -d "${ISO_STAGING}/boot/grub" \
           "${ISO_STAGING}/live" \
           "${ISO_STAGING}/sanus"

# ------------------------------------------------------------ kernel ---------
info "copying kernel ${KREL}"
cp -f "${ROOTFS_DIR}/boot/vmlinuz-${KREL}" "${ISO_STAGING}/boot/vmlinuz-sanus"

# ---------------------------------------------------------- initramfs --------
# Build inside the chroot so dracut sees the real module tree.
step "iso: building live initramfs (dracut, dmsquash-live)"
mount_chroot
chroot_sh "mkdir -p /etc/dracut.conf.d && \
	cat > /etc/dracut.conf.d/sanus-live.conf <<-'EOF'
	add_dracutmodules+=\" dmsquash-live pollcdrom \"
	omit_dracutmodules+=\" network-legacy \"
	force_drivers+=\" overlay squashfs loop isofs sr_mod sd_mod ahci nvme usb-storage xhci_pci virtio_blk virtio_pci nvidia nvidia_modeset nvidia_uvm nvidia_drm \"
	compress=\"zstd\"
	hostonly=\"no\"
	use_fstab=\"no\"
	early_microcode=\"yes\"
	EOF
	dracut --force --kver ${KREL} /boot/initramfs-sanus.img" \
	|| die "dracut failed"
if [[ -f "${CHROOT}/boot/initramfs-sanus.img" ]]; then
	cp -f "${CHROOT}/boot/initramfs-sanus.img" "${ISO_STAGING}/boot/initramfs-sanus.img"
elif [[ -f "${ROOTFS_DIR}/boot/initramfs-sanus.img" ]]; then
	cp -f "${ROOTFS_DIR}/boot/initramfs-sanus.img" "${ISO_STAGING}/boot/initramfs-sanus.img"
else
	die "initramfs not found in chroot or rootfs"
fi

# microcode blobs, if present
for f in intel-uc.img amd-uc.img; do
	[[ -f "${ROOTFS_DIR}/boot/${f}" ]] && cp -f "${ROOTFS_DIR}/boot/${f}" "${ISO_STAGING}/boot/${f}"
done

# ----------------------------------------------------------- squashfs --------
step "iso: compressing live filesystem"
if [[ -n "${SANUS_REUSE_SQUASHFS:-}" && -f "${SANUS_REUSE_SQUASHFS}" ]]; then
	info "reusing existing squashfs: ${SANUS_REUSE_SQUASHFS}"
	cp -f "${SANUS_REUSE_SQUASHFS}" "${ISO_STAGING}/live/sanus.squashfs"
else
	# The live overlay: strip anything the live session must generate itself.
	LIVE_ROOT="${BUILD_DIR}/live-root"
	rm -rf "${LIVE_ROOT}"
	cp -a "${ROOTFS_DIR}" "${LIVE_ROOT}"
	rm -rf "${LIVE_ROOT}/etc/machine-id" "${LIVE_ROOT}/var/lib/systemd" 2>/dev/null || true
	: > "${LIVE_ROOT}/etc/machine-id"
	rm -f "${LIVE_ROOT}/etc/ssh/ssh_host_"* 2>/dev/null || true
	# live-specific files
	cp -a "${SANUS_ROOT}/livecd/." "${LIVE_ROOT}/" 2>/dev/null || true
	chmod +x "${LIVE_ROOT}/usr/local/bin/sanus-live-session" 2>/dev/null || true

	# The live tree is the install source: the installer rsyncs it with
	# --numeric-ids, so every owner here is copied to the target verbatim.
	# Normalize ownership without stripping setuid/setgid bits.
	chown 0:0 "${LIVE_ROOT}" 2>/dev/null || true
	find "${LIVE_ROOT}" -xdev \( ! -uid 0 -o ! -gid 0 \) -exec chown 0:0 {} + 2>/dev/null || true
	[[ "$(stat -c %u "${LIVE_ROOT}")" == 0 ]] || die "live root is not owned by root"
	[[ "$(stat -c %u "${LIVE_ROOT}/usr")" == 0 ]] || die "live /usr is not owned by root"
	[[ "$(stat -c %u "${LIVE_ROOT}/etc")" == 0 ]] || die "live /etc is not owned by root"

	# --- live-only autologin -----------------------------------------------------
	# tty1 logs in as root and runs the live session. Two mechanisms, because a
	# stage3 may use either: OpenRC's agetty services (livecd/etc/conf.d) and
	# sysvinit's /etc/inittab. The inittab is patched here, with a backup the
	# installer restores so the target system boots to a normal login.
	if [[ -f "${LIVE_ROOT}/etc/inittab" ]]; then
		cp -a "${LIVE_ROOT}/etc/inittab" "${LIVE_ROOT}/etc/inittab.sanus-orig"
		# Autologin root on tty1..tty6: the live root password is locked, so a
		# plain login prompt on tty2+ would be a dead end. The installer
		# restores inittab.sanus-orig on the target, which undoes this.
		sed -i -E '/tty[1-6]/ s|(/sbin/agetty)([[:space:]])|\1 --autologin root\2|' \
			"${LIVE_ROOT}/etc/inittab"
		# Also give the live medium a serial console (headless installs and
		# automated testing). The installer restores inittab.sanus-orig.
		sed -i -E 's|^#s0:.*|s0:12345:respawn:/sbin/agetty --autologin root -L 115200 ttyS0 vt100|' \
			"${LIVE_ROOT}/etc/inittab"
	elif [[ -f "${LIVE_ROOT}/etc/init.d/agetty.tty1" ]]; then
		# OpenRC-only stage3: enable the agetty service in the default runlevel.
		mkdir -p "${LIVE_ROOT}/etc/runlevels/default"
		ln -sfn /etc/init.d/agetty.tty1 "${LIVE_ROOT}/etc/runlevels/default/agetty.tty1"
	fi

	mksquashfs_root "${LIVE_ROOT}" "${ISO_STAGING}/live/sanus.squashfs" sanus
fi

# ------------------------------------------------------------- branding ------
{
	printf 'SANUS_VERSION=%s\n' "${SANUS_VERSION_FULL}"
	printf 'SANUS_CODENAME=%s\n' "${SANUS_CODENAME}"
	printf 'SANUS_KERNEL=%s\n' "${KREL}"
	printf 'SANUS_ARCH=%s\n' "${SANUS_ARCH}"
	printf 'SANUS_BUILD=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} > "${ISO_STAGING}/sanus/version"
cp -f "${SANUS_ROOT}/branding/logo.svg" "${ISO_STAGING}/sanus/logo.svg" 2>/dev/null || true

# -------------------------------------------------------------- grub ---------
step "iso: writing the GRUB configuration"
VOLID="WEBOS_${SANUS_VERSION}"
sed -e "s|@VOLID@|${VOLID}|g" \
    -e "s|@VERSION_FULL@|${SANUS_VERSION_FULL}|g" \
    "${SANUS_ROOT}/livecd/boot/grub/grub.cfg" \
    > "${ISO_STAGING}/boot/grub/grub.cfg"

# --------------------------------------------------------------- iso ---------
# grub-mkrescue builds the BIOS El Torito image and the EFI system image for
# us; hand-rolling them with xorriso means keeping two sets of GRUB modules in
# sync, which is a bug factory. Extra xorriso arguments go after `--`.
step "iso: building the hybrid image (grub-mkrescue)"
grub-mkrescue \
	--output="${ISO_OUT}" \
	--product-name="WebOS" \
	--product-version="${SANUS_VERSION_FULL}" \
	"${ISO_STAGING}" \
	|| die "grub-mkrescue failed"

# ------------------------------------------------------------ checksums ------
( cd "$(dirname -- "${ISO_OUT}")" && sha256sum "$(basename -- "${ISO_OUT}")" > "$(basename -- "${ISO_OUT}").sha256" )

ok "ISO built: ${ISO_OUT} ($(du -h "${ISO_OUT}" | cut -f1))"
ok "checksum:  ${ISO_OUT}.sha256"
info "flash with:  sudo dd if=${ISO_OUT} of=/dev/sdX bs=4M status=progress oflag=sync"
info "or boot in QEMU:"
info "  qemu-system-x86_64 -m 4096 -enable-kvm -cdrom ${ISO_OUT} -boot d"
