#!/usr/bin/env bash
# Stage 10 — unpack the stage3 into ${CHROOT}, install the WebOS portage
# configuration, add the webos overlay, and emerge the base @world.
set -Eeuo pipefail
WEBOS_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export WEBOS_ROOT
source "${WEBOS_ROOT}/scripts/lib/common.sh"

step "bootstrap: preparing ${CHROOT}"
require_root
require_gentoo
require_cmd tar
assert_stage_order bootstrap
trap_umount

STAGE3_FILE="$(cat "${BUILD_DIR}/.stage3-path" 2>/dev/null || true)"
PORTAGE_FILE="$(cat "${BUILD_DIR}/.portage-path" 2>/dev/null || true)"
[[ -f "${STAGE3_FILE}" ]] || die "stage3 missing; run ./build.sh fetch"
[[ -f "${PORTAGE_FILE}" ]] || die "portage snapshot missing; run ./build.sh fetch"

# ------------------------------------------------------------- unpack --------
if [[ ! -d "${CHROOT}/etc" ]]; then
	mkdir -p "${CHROOT}"
	info "unpacking $(basename -- "${STAGE3_FILE}")"
	tar -xpf "${STAGE3_FILE}" --xattrs --numeric-owner -C "${CHROOT}" \
		--exclude='dev/*' || die "stage3 extraction failed"
	ok "stage3 unpacked"
else
	info "chroot already populated; skipping unpack"
fi

# --------------------------------------------------- portage tree ------------
if [[ ! -d "${CHROOT}/var/db/repos/gentoo/metadata" ]]; then
	info "unpacking $(basename -- "${PORTAGE_FILE}")"
	mkdir -p "${CHROOT}/var/db/repos/gentoo"
	tar -xpf "${PORTAGE_FILE}" --numeric-owner -C "${CHROOT}/var/db/repos/gentoo" \
		--strip-components=1 || die "portage snapshot extraction failed"
	ok "portage tree installed"
fi

# ------------------------------------------------- install our config --------
step "bootstrap: installing WebOS portage configuration"
install -d "${CHROOT}/etc/portage/repos.conf" \
           "${CHROOT}/etc/portage/package.use" \
           "${CHROOT}/etc/portage/package.accept_keywords" \
           "${CHROOT}/etc/portage/package.license" \
           "${CHROOT}/etc/portage/package.mask" \
           "${CHROOT}/etc/portage/package.env" \
           "${CHROOT}/etc/portage/env" \
           "${CHROOT}/etc/portage/sets" \
           "${CHROOT}/usr/local/portage/webos" \
           "${CHROOT}/etc/portage/binrepos.conf" \
           "${CHROOT}/var/db/repos" \
           "${CHROOT}/var/cache/distfiles"

install -m 0644 "${WEBOS_ROOT}/config/make.conf"        "${CHROOT}/etc/portage/make.conf"
install -m 0644 "${WEBOS_ROOT}/config/world"            "${CHROOT}/var/lib/portage/world"
for f in "${WEBOS_ROOT}"/config/package.use/*; do
	install -m 0644 "$f" "${CHROOT}/etc/portage/package.use/$(basename -- "$f")"
done
for d in package.accept_keywords package.license package.mask; do
	for f in "${WEBOS_ROOT}/config/${d}"/*; do
		[[ -e "$f" ]] || continue
		install -m 0644 "$f" "${CHROOT}/etc/portage/${d}/$(basename -- "$f")"
	done
done
for f in "${WEBOS_ROOT}"/config/repos.conf/*.conf; do
	install -m 0644 "$f" "${CHROOT}/etc/portage/repos.conf/$(basename -- "$f")"
done

# The overlay is bind-available at build time, but we want it *inside* the
# chroot so emerge works with no host bind mounts: copy it.
rm -rf "${CHROOT}/usr/local/portage/webos"
cp -a "${WEBOS_ROOT}/overlay" "${CHROOT}/usr/local/portage/webos"
ok "overlay copied to /usr/local/portage/webos"

# Third-party overlays (::guru, ::hyproverlay, ::steam-overlay). These are
# cloned into the build cache by the fetch stage; materialise them where the
# repos.conf entries expect them. They keep their .git so `emerge --sync`
# on the target can update them later.
for entry in "${WEBOS_OVERLAYS[@]}"; do
	name="${entry%%|*}"
	clone_overlay "${name}" "${CACHE_DIR}/repos/${name}"
	dest="${CHROOT}/var/db/repos/${name}"
	rm -rf "${dest}"
	cp -a "${CACHE_DIR}/repos/${name}" "${dest}"
	chown -R root:root "${dest}"
	ok "overlay ${name} installed to /var/db/repos/${name}"
done

# The installer crate is built by its ebuild; nothing to do here.

# ------------------------------------------------- profile + env ------------
step "bootstrap: selecting profile"
mount_chroot
chroot_sh "eselect profile set webos:default/linux/${STAGE3_ARCH}/webos 2>/dev/null \
	|| eselect profile list | sed -n '1,200p'"

# ------------------------------------------------- emerge base ---------------
step "bootstrap: emerging base system (this is the long part)"
# Exclude packages with known merged-usr internal collision issues in this
# environment; stage3 already provides working versions. Can be revisited later.
chroot_sh "emerge --quiet-build=y --jobs=${WEBOS_JOBS} --load-average=$((WEBOS_JOBS * 2)) \
	--newuse --update --deep --keep-going \
	--exclude='app-alternatives/awk sys-apps/coreutils sys-apps/shadow sys-apps/systemd-utils' @world" \
	|| warn "base @world emerge had failures (continuing; check logs if needed)"

step "bootstrap: toolchain sanity"
chroot_sh "gcc-config -l; eselect news read --quiet 2>/dev/null || true"

ok "bootstrap complete"
info "next: ./build.sh kernel"
