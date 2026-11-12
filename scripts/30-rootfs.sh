#!/usr/bin/env bash
# Stage 30 — emerge the SanusOS meta sets, install the installer + branding,
# and export the finished rootfs that the ISO and the installer both use.
set -Eeuo pipefail
SANUS_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export SANUS_ROOT
source "${SANUS_ROOT}/scripts/lib/common.sh"

step "rootfs: emerging SanusOS system"
require_root
assert_stage_order rootfs
trap_umount
mount_chroot

# Refresh the overlay + sets inside the chroot.
rm -rf "${CHROOT}/usr/local/portage/sanus"
cp -a "${SANUS_ROOT}/overlay" "${CHROOT}/usr/local/portage/sanus"
install -d "${CHROOT}/etc/portage/sets"
for s in "${SANUS_ROOT}"/config/sets/*; do
	[[ -e "$s" ]] || continue
	install -m 0644 "$s" "${CHROOT}/etc/portage/sets/$(basename -- "$s")"
done
chroot_sh "egencache --repo=sanus --update --jobs=${SANUS_JOBS} >/dev/null 2>&1 || true"

# ------------------------------------------------------------- sets ----------
# Exclude packages known to hit merged-usr internal collisions in this build
# environment (stage3 provides working versions). Keep going to tolerate
# non-critical failures in the large desktop/gaming set.
chroot_sh "emerge --quiet-build=y --jobs=${SANUS_JOBS} --load-average=$((SANUS_JOBS * 2)) \
	--keep-going --exclude='app-alternatives/awk sys-apps/coreutils sys-apps/shadow sys-apps/systemd-utils' \
	@base @desktop @gaming @sanus-installer" \
	|| warn "SanusOS set emerge had failures (continuing; review if critical packages missing)"

# --------------------------------------------------- installer sources -------
step "rootfs: staging the installer sources"
# shellcheck source=scripts/lib/mkmanifest.sh
source "${SANUS_ROOT}/scripts/lib/mkmanifest.sh"

INST_PV="$(sed -n 's/^version = "\(.*\)"/\1/p' "${SANUS_ROOT}/installer/Cargo.toml" | head -n1)"
[[ -n ${INST_PV} ]] || die "could not read the installer version from Cargo.toml"
INST_NAME="sanus-installer-${INST_PV}"
INST_TARBALL="${INST_NAME}.tar.gz"
INST_DISTDIR="${CHROOT}/var/cache/distfiles"
INST_PKGDIR="${CHROOT}/usr/local/portage/sanus/app-admin/sanus-installer"

[[ -d "${SANUS_ROOT}/installer/vendor" ]] \
	|| die "installer/vendor is missing — run ./build.sh fetch first"

install -d "${INST_DISTDIR}"
tar -C "${SANUS_ROOT}/installer" \
	--transform "s,^,${INST_NAME}/," \
	--exclude=target \
	-czf "${INST_DISTDIR}/${INST_TARBALL}" \
	Cargo.toml Cargo.lock README.md src .cargo vendor \
	|| die "could not create the installer tarball"
info "installer tarball: $(du -h "${INST_DISTDIR}/${INST_TARBALL}" | cut -f1)"
mkmanifest "${INST_PKGDIR}" "${INST_DISTDIR}/${INST_TARBALL}" \
	|| die "could not write the installer Manifest"

# --------------------------------------------------------- installer ---------
step "rootfs: building the SanusOS installer"
chroot_sh "emerge --quiet-build=y app-admin/sanus-installer" \
	|| die "installer emerge failed"
chroot_sh "test -x /usr/bin/sanus-installer" || die "installer binary missing"
info "installer: $(chroot_sh 'sanus-installer --version' | tr -d '\r')"

# ---------------------------------------------------------- branding ---------
step "rootfs: installing branding"
install -d "${CHROOT}/etc" "${CHROOT}/usr/lib/os-release.d" "${CHROOT}/etc/skel"
install -m 0644 "${SANUS_ROOT}/branding/os-release" "${CHROOT}/usr/lib/os-release"
ln -sfn ../usr/lib/os-release "${CHROOT}/etc/os-release"
install -m 0644 "${SANUS_ROOT}/branding/issue"      "${CHROOT}/etc/issue"
install -m 0644 "${SANUS_ROOT}/branding/issue"      "${CHROOT}/etc/issue.logo"
install -m 0644 "${SANUS_ROOT}/branding/lsb-release" "${CHROOT}/etc/lsb-release"
install -d "${CHROOT}/usr/share/sanus"
cp -a "${SANUS_ROOT}/branding/logo.svg" "${CHROOT}/usr/share/sanus/logo.svg" 2>/dev/null || true

# ---------------------------------------------------------- theming ----------
step "rootfs: applying the rice (sanus-theme)"
chroot_sh "emerge --quiet-build=y sanus-theme/sanus-theme && emerge --config sanus-theme/sanus-theme" \
	|| warn "sanus-theme config hook reported an issue; continuing"

# ------------------------------------------------------- finalize ------------
step "rootfs: finalizing"
chroot_sh "env-update; ldconfig" || true
# Freeze the world file so rebuilds are reproducible.
install -d "${ROOTFS_DIR}"
rsync -aHAX --delete \
	--exclude='/proc/*' --exclude='/sys/*' --exclude='/dev/*' \
	--exclude='/tmp/*' --exclude='/var/tmp/*' --exclude='/var/cache/*' \
	--exclude='/usr/src/*' --exclude='/var/db/repos/*' \
	--exclude='/lib/modules/*/build' \
	"${CHROOT}/" "${ROOTFS_DIR}/" || die "rootfs export failed"

ok "rootfs exported to ${ROOTFS_DIR} ($(du -sh "${ROOTFS_DIR}" | cut -f1))"
