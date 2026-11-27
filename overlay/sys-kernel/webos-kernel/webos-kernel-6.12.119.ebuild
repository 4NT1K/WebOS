EAPI=8

ETYPE="sources"

K_NOUSENAME="yes"
K_NOSETEXTRAVERSION="yes"
K_DEBLOB_AVAILABLE="0"

inherit kernel-2
detect_version
detect_arch

inherit webos-kernel

DESCRIPTION="WebOS Linux kernel — gaming tuned build"
HOMEPAGE="https://github.com/ugss96/WebOS/ https://www.kernel.org/"
# kernel-2.eclass handles three-component versions as base tarball + stable
# patch. Let detect_version() supply both; do not pin the combined tarball.
SRC_URI="${KERNEL_URI}"

LICENSE="GPL-2"
SLOT="6.12"
KEYWORDS="~amd64 ~arm64"
IUSE="+initramfs +zstd savedconfig debug"

S="${WORKDIR}/linux-6.12.119"

RDEPEND="
	initramfs? ( sys-kernel/dracut )
	zstd? ( app-arch/zstd )
	sys-kernel/linux-firmware
"
DEPEND="
	${RDEPEND}
	>=sys-devel/bc-1.06.95
	>=sys-devel/flex-2.5.35
	>=sys-devel/bison-1.875
	dev-libs/elfutils
	dev-libs/openssl
	app-arch/xz-utils
	app-arch/zstd
	sys-apps/which
"
BDEPEND="
	app-arch/xz-utils
	sys-apps/which
"

src_prepare() {
	default
	webos_apply_patchset
	# GCC 15+ defaults to C23, where bool/true/false are keywords.  Kernel
	# 6.12 headers are C11.  The decompressor in 6.12.119 already carries the
	# upstream CC_FLAGS_DIALECT fix (KBUILD_CFLAGS += -std=gnu11); the EFI
	# stub still resets KBUILD_CFLAGS and drops it.  Keep gnu11 in both and
	# silence GCC 16's new warning in each subtree.
	sed -i \
		'/^KBUILD_CFLAGS += -std=gnu11$/ s/$/ -Wno-unterminated-string-initialization/' \
		arch/x86/boot/compressed/Makefile || die "failed to patch compressed boot Makefile"
	grep -q '^KBUILD_CFLAGS += -std=gnu11 -Wno-unterminated-string-initialization' \
		arch/x86/boot/compressed/Makefile \
		|| die "compressed boot Makefile still lacks C11 flags"
	sed -i \
		'/^KBUILD_CFLAGS.*subst.*CC_FLAGS_FTRACE/ s/ \\$/ -std=gnu11 -Wno-unterminated-string-initialization \\/' \
		drivers/firmware/efi/libstub/Makefile || die "failed to patch EFI libstub Makefile"
	grep -q '^KBUILD_CFLAGS.*subst.*-std=gnu11' drivers/firmware/efi/libstub/Makefile \
		|| die "EFI libstub Makefile still lacks -std=gnu11"
	webos_kernel_make defconfig
	if [[ -f ${FILESDIR}/webos-fragment.config ]]; then
		webos_merge_config "${FILESDIR}/webos-fragment.config" "${S}/.config"
	fi
	webos_kernel_make olddefconfig
	eapply_user
}

src_compile() {
	webos_kernel_make bzImage modules
}

src_install() {
	local release
	release="$(webos_kernel_release)"
	[[ -n ${release} ]] || release="${PV}-webos"

	local arch image
	arch="$(tc-arch-kernel)"
	case "${arch}" in
		x86)   image="arch/x86/boot/bzImage" ;;
		arm64) image="arch/arm64/boot/Image.gz" ;;
		*)     die "unsupported kernel arch: ${arch}" ;;
	esac

	insinto /boot
	newins "${image}" "vmlinuz-${release}"
	[[ -f System.map ]] && { insinto /boot; newins System.map "System.map-${release}"; }
	[[ -f .config ]] && { insinto /boot; newins .config "config-${release}"; }

	# Stamp the exact fragment used for this build so the build script can
	# force a rebuild when the fragment changes without an ebuild revision.
	if [[ -f ${FILESDIR}/webos-fragment.config ]]; then
		local fragment_sha
		fragment_sha="$(sha256sum "${FILESDIR}/webos-fragment.config" | cut -d' ' -f1)"
		printf '%s\n' "${fragment_sha}" > "${T}/webos-fragment.sha256"
		insinto /boot
		newins "${T}/webos-fragment.sha256" webos-fragment.sha256
	fi

	webos_kernel_make INSTALL_MOD_PATH="${ED}" INSTALL_MOD_STRIP=1 modules_install

	dodir "/usr/src/linux-${release}"
	doins -r include scripts tools/Makefile Module.symvers 2>/dev/null || true
	dodir "/lib/modules/${release}/build"
	dosym "../../../usr/src/linux-${release}" "/lib/modules/${release}/build"

	echo "${release}" > "${T}/kernel-release" || die
}

pkg_postinst() {
	local release
	release="$(cat "${T}/kernel-release" 2>/dev/null || true)"
	[[ -n ${release} ]] || release="$(ls -1 /lib/modules 2>/dev/null | sort -V | tail -n1)"
	if [[ -n ${release} ]]; then
		/sbin/depmod -a "${release}" || true
	fi
	if use initramfs && [[ -x /usr/bin/dracut && -n ${release} ]]; then
		dracut --force --kver "${release}" "/boot/initramfs-${release}.img" || ewarn "dracut failed"
	fi
	elog "WebOS kernel ${release} installed."
}
