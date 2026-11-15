#!/bin/bash
set -Eeuo pipefail
export WEBOS_ROOT=/sanusos
source /sanusos/scripts/lib/common.sh
source /sanusos/scripts/lib/mkmanifest.sh
trap_umount
mount_chroot

# refresh overlay/sets
rm -rf "${CHROOT}/usr/local/portage/webos"
cp -a "${WEBOS_ROOT}/overlay" "${CHROOT}/usr/local/portage/webos"
install -d "${CHROOT}/etc/portage/sets"
for s in "${WEBOS_ROOT}"/config/sets/*; do
  [[ -e "$s" ]] || continue
  install -m 0644 "$s" "${CHROOT}/etc/portage/sets/$(basename -- "$s")"
done

# branding in chroot
step "rootfs: applying WebOS branding in chroot"
install -d "${CHROOT}/etc" "${CHROOT}/usr/lib/os-release.d" "${CHROOT}/usr/share/webos"
install -m 0644 "${WEBOS_ROOT}/branding/os-release" "${CHROOT}/usr/lib/os-release"
ln -sfn ../usr/lib/os-release "${CHROOT}/etc/os-release"
install -m 0644 "${WEBOS_ROOT}/branding/issue"      "${CHROOT}/etc/issue"
install -m 0644 "${WEBOS_ROOT}/branding/issue"      "${CHROOT}/etc/issue.logo"
install -m 0644 "${WEBOS_ROOT}/branding/lsb-release" "${CHROOT}/etc/lsb-release"
printf 'WebOS %s\n' "${WEBOS_VERSION_FULL}" > "${CHROOT}/etc/webos-release"
printf 'WebOS %s\n' "${WEBOS_VERSION_FULL}" > "${CHROOT}/etc/webos-release"
cp -a "${WEBOS_ROOT}/branding/logo.svg" "${CHROOT}/usr/share/webos/logo.svg" 2>/dev/null || true

# rebuild WebOS-branded installer
step "rootfs: rebuilding WebOS-branded installer"
INST_PV="$(sed -n 's/^version = "\(.*\)"/\1/p' "${WEBOS_ROOT}/installer/Cargo.toml" | head -n1)"
INST_NAME="webos-installer-${INST_PV}"
INST_TARBALL="${INST_NAME}.tar.gz"
INST_DISTDIR="${CHROOT}/var/cache/distfiles"
INST_PKGDIR="${CHROOT}/usr/local/portage/webos/app-admin/webos-installer"
chroot_sh "install -d -m 0775 -o root -g portage /var/cache/distfiles"
rm -f "${INST_DISTDIR}/${INST_TARBALL}" "${INST_DISTDIR}/${INST_TARBALL}"._checksum_failure_*
tar -C "${WEBOS_ROOT}/installer" --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner --transform "s,^,${INST_NAME}/," --exclude='./target' -I 'gzip -n' -cf "${INST_DISTDIR}/${INST_TARBALL}" Cargo.toml Cargo.lock README.md src .cargo vendor
mkmanifest "${INST_PKGDIR}" "${INST_DISTDIR}/${INST_TARBALL}"
chroot_sh "emerge --quiet-build=y app-admin/webos-installer"
chroot_sh "test -x /usr/bin/webos-installer"

# export rootfs
step "rootfs: re-exporting with WebOS branding and both desktops"
install -d "${ROOTFS_DIR}"
rsync -aHAX --delete \
  --exclude='/proc/*' --exclude='/sys/*' --exclude='/dev/*' \
  --exclude='/tmp/*' --exclude='/var/tmp/*' --exclude='/var/cache/*' \
  --exclude='/usr/src/*' --exclude='/var/db/repos/*' \
  --exclude='/lib/modules/*/build' \
  "${CHROOT}/" "${ROOTFS_DIR}/" || die "rootfs export failed"
ok "rootfs exported to ${ROOTFS_DIR} ($(du -sh "${ROOTFS_DIR}" | cut -f1))"
echo rc=0
