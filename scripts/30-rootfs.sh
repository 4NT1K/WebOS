#!/usr/bin/env bash
# Stage 30 — emerge the WebOS meta sets, install the installer + branding,
# and export the finished rootfs that the ISO and the installer both use.
set -Eeuo pipefail
SANUS_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export SANUS_ROOT
source "${SANUS_ROOT}/scripts/lib/common.sh"

step "rootfs: emerging WebOS system"
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

# --------------------------------------------------- installer sources -------
# Stage the installer tarball and Manifest *before* any emerge that can pull
# app-admin/sanus-installer (@sanus-installer includes it). Otherwise Portage
# validates a distfile left over from a previous build against the freshly
# generated Manifest and aborts on a checksum mismatch.
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

# DISTDIR must be writable by the portage user.
chroot_sh "install -d -m 0775 -o root -g portage /var/cache/distfiles" \
	|| install -d "${INST_DISTDIR}"

# (Re)build the deterministic tarball and Manifest as a matched pair. Any
# leftover tarball (or Portage's `._checksum_failure_` copy) from an earlier
# run is removed first, so its bytes can never be checked against this run's
# Manifest. Fixed mtimes/owners and sorted entries make rebuilding the same
# sources produce identical bytes; `gzip -n` suppresses gzip's own timestamp.
stage_installer_tarball() {
	rm -f "${INST_DISTDIR}/${INST_TARBALL}" \
	      "${INST_DISTDIR}/${INST_TARBALL}"._checksum_failure_*
	tar -C "${SANUS_ROOT}/installer" \
		--sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner \
		--transform "s,^,${INST_NAME}/," \
		--exclude='./target' \
		-I 'gzip -n' -cf "${INST_DISTDIR}/${INST_TARBALL}" \
		Cargo.toml Cargo.lock README.md src .cargo vendor \
		|| die "could not create the installer tarball"
	info "installer tarball: $(du -h "${INST_DISTDIR}/${INST_TARBALL}" | cut -f1)"
	mkmanifest "${INST_PKGDIR}" "${INST_DISTDIR}/${INST_TARBALL}" \
		|| die "could not write the installer Manifest"
}
stage_installer_tarball

# ------------------------------------------------------------- sets ----------
# Exclude packages known to hit merged-usr internal collisions in this build
# environment (stage3 provides working versions). Keep going to tolerate
# non-critical failures in the large desktop/gaming set.
chroot_sh "emerge --quiet-build=y --jobs=${SANUS_JOBS} --load-average=$((SANUS_JOBS * 2)) \
	--keep-going --exclude='app-alternatives/awk sys-apps/coreutils sys-apps/shadow sys-apps/systemd-utils' \
	@base @desktop @gaming @sanus-installer" \
	|| warn "WebOS set emerge had failures (continuing; review if critical packages missing)"

# --------------------------------------------------------- installer ---------
step "rootfs: building the WebOS installer"
# If an interrupted earlier run left a mismatched distfile/Manifest pair,
# rebuild the pair and retry rather than failing the whole stage.
installed=0
for attempt in 1 2 3; do
	if chroot_sh "emerge --quiet-build=y app-admin/sanus-installer"; then
		installed=1
		break
	fi
	warn "installer emerge attempt ${attempt} failed; rebuilding the tarball + Manifest"
	stage_installer_tarball
done
[[ ${installed} == 1 ]] || die "installer emerge failed"
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
	--exclude='/usr/src/*' \
	--exclude='/var/db/repos/guru' \
	--exclude='/var/db/repos/hyproverlay' \
	--exclude='/var/db/repos/steam-overlay' \
	--exclude='/lib/modules/*/build' \
	"${CHROOT}/" "${ROOTFS_DIR}/" || die "rootfs export failed"

# The ::gentoo tree ships with the image so `emerge` works on a fresh install
# and in the live session without a network round-trip. The optional overlays
# are build-time only; disable their (otherwise dangling) repo entries so
# Portage does not warn about them on every invocation.
install -d "${ROOTFS_DIR}/etc/portage/repos.conf.disabled"
for _repo in guru hyproverlay steam-overlay; do
	if [[ -f "${ROOTFS_DIR}/etc/portage/repos.conf/${_repo}.conf" ]]; then
		mv -f "${ROOTFS_DIR}/etc/portage/repos.conf/${_repo}.conf" \
		      "${ROOTFS_DIR}/etc/portage/repos.conf.disabled/${_repo}.conf"
	fi
done

ok "rootfs exported to ${ROOTFS_DIR} ($(du -sh "${ROOTFS_DIR}" | cut -f1))"
