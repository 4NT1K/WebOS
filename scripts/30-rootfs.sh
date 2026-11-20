#!/usr/bin/env bash
# Stage 30 — emerge the WebOS meta sets, install the installer + branding,
# and export the finished rootfs that the ISO and the installer both use.
set -Eeuo pipefail
WEBOS_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export WEBOS_ROOT
source "${WEBOS_ROOT}/scripts/lib/common.sh"

step "rootfs: emerging WebOS system"
require_root
assert_stage_order rootfs
trap_umount
mount_chroot

# Legacy cleanup: earlier builds used sanus-* names. A reused chroot still has
# those packages installed, which would leave duplicate services/files next to
# the new webos-* ones.
# The legacy kernel packages are removed in 20-kernel.sh before the new
# webos-kernel is built; by this stage they are already gone.
chroot_sh "emerge --quiet --unmerge sanus-theme/sanus-theme app-admin/sanus-installer \
	sanus-base/sanus-base sanus-desktop/sanus-desktop sanus-gaming/sanus-gaming \
	2>/dev/null || true" || true
rm -rf "${CHROOT}/usr/local/portage/sanus" "${CHROOT}/usr/share/sanus"
# A reused chroot's profile symlink still points at the old overlay path.
if [[ -L "${CHROOT}/etc/portage/make.profile" ]] &&
   [[ "$(readlink "${CHROOT}/etc/portage/make.profile")" == *sanus* ]]; then
	ln -sfn ../../usr/local/portage/webos/profiles/default/linux/amd64/webos \
		"${CHROOT}/etc/portage/make.profile"
fi
rm -f "${CHROOT}"/etc/local.d/sanus.start "${CHROOT}"/etc/init.d/sanus \
	"${CHROOT}"/etc/profile.d/sanus.sh "${CHROOT}"/etc/environment.d/10-sanus.conf \
	"${CHROOT}"/usr/share/wayland-sessions/sanus.desktop \
	"${CHROOT}"/usr/share/xsessions/sanus.desktop \
	"${CHROOT}"/usr/share/applications/sanus*.desktop \
	"${CHROOT}"/etc/xdg/autostart/sanus*.desktop \
	"${CHROOT}"/usr/bin/sanus-* 2>/dev/null || true

# Refresh the overlay + sets inside the chroot.
rm -rf "${CHROOT}/usr/local/portage/webos"
cp -a "${WEBOS_ROOT}/overlay" "${CHROOT}/usr/local/portage/webos"
install -d "${CHROOT}/etc/portage/sets"
for s in "${WEBOS_ROOT}"/config/sets/*; do
	[[ -e "$s" ]] || continue
	install -m 0644 "$s" "${CHROOT}/etc/portage/sets/$(basename -- "$s")"
done

# Refresh the Portage configuration too. Bootstrap only copies these once, so
# a reused chroot keeps stale make.conf/package.use/repos.conf files and can
# silently mask packages or ship obsolete CPU_FLAGS_X86 (e.g. AVX-512 flags
# that crash NumPy on CPUs without AVX-512).
install -m 0644 "${WEBOS_ROOT}/config/make.conf" "${CHROOT}/etc/portage/make.conf"
install -d "${CHROOT}/etc/portage/repos.conf"
rm -f "${CHROOT}"/etc/portage/repos.conf/*.conf 2>/dev/null || true
cp -a "${WEBOS_ROOT}"/config/repos.conf/*.conf "${CHROOT}/etc/portage/repos.conf/"
for d in package.use package.license package.accept_keywords package.mask package.env env; do
	[[ -d "${WEBOS_ROOT}/config/${d}" ]] || continue
	install -d "${CHROOT}/etc/portage/${d}"
	rm -f "${CHROOT}/etc/portage/${d}"/* 2>/dev/null || true
	cp -a "${WEBOS_ROOT}/config/${d}/." "${CHROOT}/etc/portage/${d}/"
done
# The theme ebuild changed with the 1.01 rebuild (-r1 adds the new helpers).
# SRC_URI is empty, so there is no Manifest to regenerate; force a reinstall
# to guarantee the new files land.
chroot_sh "emerge --quiet --unmerge webos-theme/webos-theme 2>/dev/null || true"
chroot_sh "egencache --repo=webos --update --jobs=${WEBOS_JOBS} >/dev/null 2>&1 || true"

# Browsers moved from the source build to the prebuilt binary. Remove a stale
# source copy from a reused chroot before the set merge so the image does not
# carry (and recompile) both.
chroot_sh "emerge --quiet --unmerge www-client/firefox 2>/dev/null || true"

# --------------------------------------------------- installer sources -------
# Stage the installer tarball and Manifest *before* any emerge that can pull
# app-admin/webos-installer (@webos-installer includes it). Otherwise Portage
# validates a distfile left over from a previous build against the freshly
# generated Manifest and aborts on a checksum mismatch.
step "rootfs: staging the installer sources"
# shellcheck source=scripts/lib/mkmanifest.sh
source "${WEBOS_ROOT}/scripts/lib/mkmanifest.sh"

INST_PV="$(sed -n 's/^version = "\(.*\)"/\1/p' "${WEBOS_ROOT}/installer/Cargo.toml" | head -n1)"
[[ -n ${INST_PV} ]] || die "could not read the installer version from Cargo.toml"
INST_NAME="webos-installer-${INST_PV}"
INST_TARBALL="${INST_NAME}.tar.gz"
INST_DISTDIR="${CHROOT}/var/cache/distfiles"
INST_PKGDIR="${CHROOT}/usr/local/portage/webos/app-admin/webos-installer"

[[ -d "${WEBOS_ROOT}/installer/vendor" ]] \
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
	tar -C "${WEBOS_ROOT}/installer" \
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
# nvidia-drivers builds kernel modules against /usr/src/linux. The sources
# ebuild deliberately drops .config/Module.symvers, so restore the build tree
# from the /boot artifacts the webos-kernel ebuild installs.
step "rootfs: preparing the kernel build tree"
KREL="$(cat "${BUILD_DIR}/.kernel-release" 2>/dev/null || true)"
[[ -n ${KREL} ]] || KREL="$(chroot_sh "ls /lib/modules | sort -V | tail -n1" | tr -d '\r')"
[[ -n ${KREL} ]] || die "could not determine kernel release for module builds"
chroot_sh "set -e
KREL='${KREL}'
# Pin to the WebOS sources. A reused chroot can also hold newer vanilla
# gentoo-sources (e.g. 7.3.4), whose Kconfig syntax this kernel's kconfig
# parser cannot read; version-sorting would pick the wrong tree.
SRC='/usr/src/linux-${WEBOS_KERNEL_SERIES}'
[[ -d \"\$SRC\" ]] || { echo \"WebOS kernel sources missing at \$SRC\"; exit 1; }
ln -sfn \"\$SRC\" /usr/src/linux
ln -sfn \"\$SRC\" \"/lib/modules/\$KREL/build\"
cp -f \"/boot/config-\$KREL\" \"\$SRC/.config\"
cp -f /boot/Module.symvers \"\$SRC/Module.symvers\"
cp -a /boot/include/. \"\$SRC/include/\"
cp -a /boot/scripts/. \"\$SRC/scripts/\"
find \"\$SRC/scripts\" -type f -exec sh -c 'head -c2 \"\$1\" 2>/dev/null | grep -q \"#!\" && chmod +x \"\$1\"' _ {} \; 2>/dev/null || true
cd \"\$SRC\" && make olddefconfig >/dev/null && make modules_prepare >/dev/null
" || die "kernel build tree preparation failed"

# Exclude packages known to hit merged-usr internal collisions in this build
# environment (stage3 provides working versions). Keep going to tolerate
# non-critical failures in the large desktop/gaming set.
chroot_sh "emerge --quiet-build=y --jobs=${WEBOS_JOBS} --load-average=$((WEBOS_JOBS * 2)) \
	--keep-going --exclude='app-alternatives/awk sys-apps/coreutils sys-apps/shadow sys-apps/systemd-utils' \
	@base @desktop @gaming @webos-installer" \
	|| warn "WebOS set emerge had failures (continuing; review if critical packages missing)"

# A reused chroot can still hold Plasma from before it moved into @plasma.
# Strip it from the live rootfs so the image itself has no Plasma session;
# keep systemsettings (used by webos-settings) and breeze (the cursor theme).
# qlist -I prints "category/package" here (no version), while the find fallback
# prints "=package-version", so the keep-list must match both forms.
chroot_sh 'pkgs="$(qlist -I 2>/dev/null | grep "^kde-plasma/" | grep -Ev "^kde-plasma/(systemsettings|breeze)(-[0-9]|$)" || true)"; if [ -n "$pkgs" ]; then emerge --quiet --unmerge $pkgs >/dev/null 2>&1 || true; fi; rm -f /usr/share/wayland-sessions/plasma.desktop' || true

# The bar must be built with the WebOS USE flags (mpris/tray/logind). The
# plain set emerge above does not rebuild for USE changes on an existing
# chroot, so force it explicitly.
chroot_sh "emerge --quiet-build=y --changed-use --oneshot gui-apps/waybar" \
	|| warn "waybar rebuild with WebOS USE flags failed"

# Only the WebOS session should be offered by SDDM. The upstream
# hyprland.desktop starts a bare Hyprland with no rice, which is exactly the
# "no bar / no portals / no fastfetch" failure mode.
rm -f "${CHROOT}/usr/share/wayland-sessions/hyprland.desktop"
install -d "${CHROOT}/etc/sddm.conf.d"

# --------------------------------------------------------- installer ---------
step "rootfs: building the WebOS installer"
# The ebuild version does not change between fix rounds, so Portage considers
# the package installed and keeps the stale binary. Unmerge first, then build
# from the freshly staged tarball.
chroot_sh "emerge --quiet --unmerge app-admin/webos-installer" >/dev/null 2>&1 || true
# If an interrupted earlier run left a mismatched distfile/Manifest pair,
# rebuild the pair and retry rather than failing the whole stage.
installed=0
for attempt in 1 2 3; do
	if chroot_sh "emerge --quiet-build=y app-admin/webos-installer"; then
		installed=1
		break
	fi
	warn "installer emerge attempt ${attempt} failed; rebuilding the tarball + Manifest"
	stage_installer_tarball
done
[[ ${installed} == 1 ]] || die "installer emerge failed"
chroot_sh "test -x /usr/bin/webos-installer" || die "installer binary missing"
info "installer: $(chroot_sh 'webos-installer --version' | tr -d '\r')"

# ---------------------------------------------------------- branding ---------
step "rootfs: installing branding"
install -d "${CHROOT}/etc" "${CHROOT}/usr/lib/os-release.d" "${CHROOT}/etc/skel"
install -m 0644 "${WEBOS_ROOT}/branding/os-release" "${CHROOT}/usr/lib/os-release"
ln -sfn ../usr/lib/os-release "${CHROOT}/etc/os-release"
install -m 0644 "${WEBOS_ROOT}/branding/issue"      "${CHROOT}/etc/issue"
install -m 0644 "${WEBOS_ROOT}/branding/issue"      "${CHROOT}/etc/issue.logo"
install -m 0644 "${WEBOS_ROOT}/branding/lsb-release" "${CHROOT}/etc/lsb-release"
install -d "${CHROOT}/usr/share/webos"

# ----------------------------------------------------- legacy shells ---------
# The build chroot is reused across releases. Older trees installed Noctalia
# (and its niri template) even though 1.0 ships only the mono rice. Remove the
# package and every seed/session file before the rootfs is exported.
step "rootfs: stripping legacy shells"
chroot_sh "emerge --quiet --deselect gui-apps/noctalia >/dev/null 2>&1 || true"
chroot_sh "emerge --quiet --unmerge gui-apps/noctalia >/dev/null 2>&1 || true"
chroot_sh 'rm -rf /usr/share/webos/noctalia /usr/share/noctalia \
	/etc/skel/.config/noctalia /root/.config/noctalia /home/*/.config/noctalia \
	/usr/share/wayland-sessions/webos-noctalia.desktop \
	/usr/share/wayland-sessions/webos-niri.desktop' || true
chroot_sh 'rm -rf /var/log/portage/elog/*noctalia* /var/log/portage/elog/*niri* \
	/var/cache/distfiles/noctalia-* /var/cache/distfiles/niri-*' || true

# ---------------------------------------------------------- theming ----------
step "rootfs: applying the rice (webos-theme)"
THEME_EBUILD="webos-theme-1.0-r1.ebuild"
chroot_sh "test -f /usr/local/portage/webos/webos-theme/webos-theme/${THEME_EBUILD}" \
	|| die "${THEME_EBUILD} missing from the copied overlay"
# Same-package-version edits are not picked up by a plain emerge, so remove the
# package first. Without this the ISO keeps the previous rice, session helper
# and fastfetch wrapper.
chroot_sh "emerge --quiet --unmerge webos-theme/webos-theme" >/dev/null 2>&1 || true
chroot_sh "emerge --quiet-build=y webos-theme/webos-theme" \
	|| die "webos-theme merge failed (rice/session helpers would be missing)"
# 1.021 shipped hyprland.conf and webos-colors.conf; 1.0 uses hyprland.lua
# plus webos-colors.lua. The chroot is reused between builds, so remove the
# dead files from the seeded homes before the config hook applies the rice.
chroot_sh 'rm -f /root/.config/hypr/hyprland.conf /root/.config/hypr/hyprland.lua.webos-disabled /root/.config/hypr/webos-colors.conf /etc/skel/.config/hypr/hyprland.conf /etc/skel/.config/hypr/hyprland.lua.webos-disabled /etc/skel/.config/hypr/webos-colors.conf' || true
chroot_sh "emerge --config webos-theme/webos-theme" \
	|| warn "webos-theme config hook reported an issue; continuing"
chroot_sh "test -x /usr/bin/webos-shell" \
	|| die "webos-shell missing after webos-theme merge"
chroot_sh "test -f /usr/share/webos/rice/waybar/config.jsonc" \
	|| die "waybar config missing after webos-theme merge"
chroot_sh "test -x /usr/bin/webos-portals" \
	|| die "webos-portals missing after webos-theme merge"
chroot_sh "test -x /usr/bin/webos-autostart" \
	|| die "webos-autostart missing after webos-theme merge"
chroot_sh "test -x /usr/bin/webos-dotfiles" \
	|| die "webos-dotfiles missing after webos-theme merge"
chroot_sh "test -d /usr/share/webos/dotfiles" \
	|| die "dotfiles profiles missing after webos-theme merge"
chroot_sh "test -f /etc/bash/bashrc.d/00-webos-fastfetch.bash" \
	|| die "bash fastfetch hook missing after webos-theme merge"
chroot_sh "test -f /etc/zsh/zshrc" \
	|| die "zsh fastfetch hook missing after webos-theme merge"
chroot_sh "test -f /etc/fish/conf.d/00-webos-fastfetch.fish" \
	|| die "fish fastfetch hook missing after webos-theme merge"
chroot_sh "grep -q 'command-raw' /usr/share/webos/rice/fastfetch/fastfetch.json" \
	|| die "fastfetch config does not use the command-raw chafa logo"
chroot_sh "grep -q 'hyprland.lua' /usr/bin/webos-session" \
	|| die "webos-session does not use the Lua Hyprland config"
for helper in webos-menu webos-chafa-logo webos-music webos-refresh webos-stats; do
	chroot_sh "test -x /usr/bin/${helper}" \
		|| die "${helper} missing after webos-theme merge"
done

# -------------------------------------------------------- debranding ---------
step "rootfs: applying WebOS branding overrides (remove Gentoo identifiers)"
rm -f "${CHROOT}/etc/gentoo-release"
install -d "${CHROOT}/etc/xdg" "${CHROOT}/usr/local/share/applications"
install -m 0644 "${WEBOS_ROOT}/overlay/webos-theme/webos-theme/files/system/xdg/kcm-about-distrorc" \
	"${CHROOT}/etc/xdg/kcm-about-distrorc"
install -m 0644 "${WEBOS_ROOT}/overlay/webos-theme/webos-theme/files/system/locale.conf" \
	"${CHROOT}/etc/locale.conf"
install -m 0644 "${WEBOS_ROOT}/overlay/webos-theme/webos-theme/files/system/desktop-overrides/kdesystemsettings.desktop" \
	"${CHROOT}/usr/local/share/applications/kdesystemsettings.desktop"
install -m 0644 "${WEBOS_ROOT}/overlay/webos-theme/webos-theme/files/system/desktop-overrides/systemsettings.desktop" \
	"${CHROOT}/usr/local/share/applications/systemsettings.desktop"
install -d "${CHROOT}/usr/share/icons/default"
install -m 0644 "${WEBOS_ROOT}/overlay/webos-theme/webos-theme/files/system/icons-default/index.theme" \
	"${CHROOT}/usr/share/icons/default/index.theme"
# Ensure UTF-8 locale is the default in the live/installed environment.
printf 'LANG=C.UTF-8\nLC_CTYPE=C.UTF-8\n' > "${CHROOT}/etc/env.d/02locale"
chroot_sh "env-update" || true

# Patch OpenRC boot branding: "Gentoo Linux" -> "WebOS Linux" (binary strings)
chroot_sh "python3 -c '
from pathlib import Path
for path in [Path(\"/sbin/openrc\")]:
    if not path.exists(): continue
    data=bytearray(path.read_bytes()); c=0
    for old,new in [(b\"Gentoo Linux (%s)\", b\"WebOS  Linux (%s)\"), (b\"Gentoo Linux\", b\"WebOS Linux \")]:
        i=0
        while True:
            j=data.find(old,i)
            if j==-1: break
            data[j:j+len(old)]=new; c+=1; i=j+len(new)
    if c: path.write_bytes(bytes(data)); print(\"patched\",path,c)
'" || true

# ------------------------------------------------------- finalize ------------
step "rootfs: finalizing"
chroot_sh "env-update; ldconfig" || true
# NVIDIA's driver cannot load while nouveau owns the GPU. Harmless on AMD/Intel.
chroot_sh "printf 'blacklist nouveau\\n' > /etc/modprobe.d/blacklist-nouveau.conf" || true
# nvidia-drivers ships a dracut drop-in that *omits* the modules; since we ship
# the driver we want it in the initramfs for early KMS/modeset.
chroot_sh "rm -f /usr/lib/dracut/dracut.conf.d/10-nvidia-drivers.conf" || true
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

# rsync protects excluded paths from --delete, so stale build links survive.
# A dangling /lib/modules/*/build confuses module tooling on the target.
rm -f "${ROOTFS_DIR}"/lib/modules/*/build
# dbus-daemon-launch-helper must be setuid root and group messagebus. A
# root:root 0110 helper makes polkitd impossible to D-Bus activate, so no
# authentication agent ever appears on the desktop.
MB_GID="$(awk -F: '$1=="messagebus"{print $3}' "${ROOTFS_DIR}/etc/group" 2>/dev/null || true)"
[[ -n ${MB_GID} ]] || MB_GID=101
for _root in "${CHROOT}" "${ROOTFS_DIR}"; do
	_h="$_root/usr/libexec/dbus-daemon-launch-helper"
	[[ -e ${_h} ]] || continue
	chown 0:"${MB_GID}" "${_h}" 2>/dev/null || true
	chmod 4754 "${_h}"
done
[[ "$(stat -c '%a %u' "${ROOTFS_DIR}/usr/libexec/dbus-daemon-launch-helper" 2>/dev/null || true)" == "4754 0" ]] \
	|| die "dbus-daemon-launch-helper permissions are wrong in the rootfs"
# webos-theme is not always re-emerged (same version), so make sure the
# boot-glue script is the current one from the tree.
install -m 0755 "${WEBOS_ROOT}/overlay/webos-theme/webos-theme/files/system/local.d-webos.start" \
	"${ROOTFS_DIR}/etc/local.d/webos.start"

# Hyprland 0.57 reads Lua configuration (~/.config/hypr/hyprland.lua) and
# ignores hyprland.conf. It seeds that file from this upstream example on
# first run; the example has different keybinds and no WebOS autostart, so
# remove it and let webos-rice install the real config.
rm -f "${CHROOT}/usr/share/hypr/hyprland.lua" "${ROOTFS_DIR}/usr/share/hypr/hyprland.lua"

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
