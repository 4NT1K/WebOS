EAPI=8

ETYPE="sources"

K_NOUSENAME="yes"
K_NOSETEXTRAVERSION="yes"
K_SECURITY_UNSUPPORTED="1"
K_DEBLOB_AVAILABLE="0"

inherit kernel-2
detect_version
detect_arch

inherit sanus-kernel

DESCRIPTION="SanusOS Linux kernel — gaming tuned build"
HOMEPAGE="https://sanusos.org/ https://www.kernel.org/"
SRC_URI="https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.12.tar.xz"

LICENSE="GPL-2"
SLOT="6.12"
KEYWORDS="~amd64 ~arm64"
IUSE="+initramfs +zstd savedconfig debug"

S="${WORKDIR}/linux-6.12"

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
	sanus_apply_patchset
	# GCC 15+ defaults to C23, where bool/true/false are keywords.  Kernel
	# 6.12 headers are C11.  Two boot subtrees overwrite KBUILD_CFLAGS and
	# drop the top-level -std=gnu11, so with a C23-default compiler they fail
	# with "cannot use keyword 'false' as enumeration constant" /
	# "'bool' cannot be defined via 'typedef'":
	#   arch/x86/boot/compressed/Makefile   (decompressor)
	#   drivers/firmware/efi/libstub/Makefile (EFI stub; x86 drops KBUILD_CFLAGS)
	# Force gnu11 in both, mirroring the upstream CC_FLAGS_DIALECT fix.
	sed -i \
		's|^KBUILD_CFLAGS := -m$(BITS) -O2 $(CLANG_FLAGS)$|& -std=gnu11 -Wno-unterminated-string-initialization|' \
		arch/x86/boot/compressed/Makefile || die "failed to patch compressed boot Makefile"
	grep -q '^KBUILD_CFLAGS := .*-std=gnu11' arch/x86/boot/compressed/Makefile \
		|| die "compressed boot Makefile still lacks -std=gnu11"
	sed -i \
		'/^KBUILD_CFLAGS.*subst.*CC_FLAGS_FTRACE/ s/ \\$/ -std=gnu11 \\/' \
		drivers/firmware/efi/libstub/Makefile || die "failed to patch EFI libstub Makefile"
	grep -q '^KBUILD_CFLAGS.*subst.*-std=gnu11' drivers/firmware/efi/libstub/Makefile \
		|| die "EFI libstub Makefile still lacks -std=gnu11"
	sanus_kernel_make defconfig
	if [[ -f ${FILESDIR}/sanus-fragment.config ]]; then
		sanus_merge_config "${FILESDIR}/sanus-fragment.config" "${S}/.config"
	fi
	sanus_kernel_make olddefconfig
	eapply_user
}

src_compile() {
	sanus_kernel_make bzImage modules
}

src_install() {
	local release
	release="$(sanus_kernel_release)"
	[[ -n ${release} ]] || release="6.12-sanusos"

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

	sanus_kernel_make INSTALL_MOD_PATH="${ED}" INSTALL_MOD_STRIP=1 modules_install

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
	elog "SanusOS kernel ${release} installed."
}
