# @ECLASS: sanus-kernel.eclass
# @MAINTAINER:
#   SanusOS <dev@sanusos.org>
# @SUPPORTED_EAPIS: 8
# @BLURB: Shared helpers for the SanusOS kernel packages.
# @DESCRIPTION:
#   Provides patch-series application and config-fragment merging for
#   sys-kernel/sanus-kernel and sys-kernel/sanus-kernel-sources.
#
#   Patch series are resolved at build time by kernel/fetch-patches.sh into
#   ${SANU_KERNEL_PATCHDIR} (default /var/cache/sanus/patches) and listed, one
#   absolute path per line, in a `series` file.  If the directory is absent the
#   eclass falls back to any patches shipped in ${FILESDIR} and warns loudly.

case ${EAPI} in
	8) ;;
	*) die "sanus-kernel.eclass does not support EAPI ${EAPI}" ;;
esac

inherit toolchain-funcs

# @ECLASS_VARIABLE: SANU_KERNEL_PATCHDIR
# @USER_VARIABLE
# @DEFAULT_UNSET
# @DESCRIPTION:
#   Directory holding the resolved patch series. Set by the build system.
: "${SANU_KERNEL_PATCHDIR:=/var/cache/sanus/patches}"

# @FUNCTION: sanus_apply_patchset
# @DESCRIPTION:
#   Apply every patch listed in ${SANU_KERNEL_PATCHDIR}/series to ${S}.
#   Missing patch files are fatal: a partial patch series produces a kernel
#   that boots but misbehaves, which is far worse than a failed build.
sanus_apply_patchset() {
	debug-print-function "${FUNCNAME}" "$@"

	local series="${SANU_KERNEL_PATCHDIR}/series"
	local patch

	if [[ -f ${series} ]]; then
		while IFS= read -r patch; do
			[[ -n ${patch} ]] || continue
			if [[ ! -f ${patch} ]]; then
				eerror "patch listed in series is missing: ${patch}"
				die "incomplete patch series"
			fi
			einfo "Applying $(basename "${patch}")"
			eapply --no-backup-if-mismatch "${patch}"
		done < "${series}"
	else
		local fallback=( "${FILESDIR}"/*.patch )
		if [[ -e ${fallback[0]} ]]; then
			ewarn "no resolved series in ${SANU_KERNEL_PATCHDIR}; using ${FILESDIR}/*.patch"
			local p
			for p in "${fallback[@]}"; do
				einfo "Applying $(basename "${p}")"
				eapply --no-backup-if-mismatch "${p}"
			done
		else
			ewarn "no kernel patch series found — building a stock kernel"
			ewarn "run kernel/fetch-patches.sh to resolve the SanusOS series"
		fi
	fi
}

# @FUNCTION: sanus_merge_config <fragment> [config]
# @DESCRIPTION:
#   Overlay a Kconfig fragment onto a .config. Unlike merge_config.sh this is
#   deterministic: each CONFIG_* symbol in the fragment replaces whatever the
#   base config said, including a prior `# CONFIG_FOO is not set`. Run
#   `make olddefconfig` afterwards to resolve anything new.
sanus_merge_config() {
	debug-print-function "${FUNCNAME}" "$@"

	local fragment="$1"
	local config="${2:-${S}/.config}"
	local line sym count=0

	[[ -f ${fragment} ]] || die "config fragment not found: ${fragment}"
	[[ -f ${config} ]] || die "base config not found: ${config}"

	while IFS= read -r line; do
		case ${line} in
			CONFIG_*=*) sym="${line%%=*}" ;;
			"# CONFIG_"*" is not set") sym="${line#\# }"; sym="${sym%% is not set}" ;;
			*) continue ;;
		esac
		sed -i \
			-e "/^${sym}=/d" \
			-e "/^# ${sym} is not set/d" \
			"${config}"
		printf '%s\n' "${line}" >> "${config}"
		count=$((count + 1))
	done < "${fragment}"

	einfo "sanus_merge_config: applied ${count} symbols from $(basename "${fragment}")"
}

# @FUNCTION: sanus_kernel_make
# @DESCRIPTION:
#   Run make in the kernel tree with the correct ARCH/CC/LD and job count.
sanus_kernel_make() {
	debug-print-function "${FUNCNAME}" "$@"

	emake \
		ARCH="$(tc-arch-kernel)" \
		CC="$(tc-getCC)" \
		LD="$(tc-getLD)" \
		AR="$(tc-getAR)" \
		NM="$(tc-getNM)" \
		OBJCOPY="$(tc-getOBJCOPY)" \
		HOSTCC="$(tc-getBUILD_CC)" \
		HOSTCXX="$(tc-getBUILD_CXX)" \
		KCFLAGS="${KCFLAGS:-} -Wno-unterminated-string-initialization -Wno-error=unterminated-string-initialization" \
		-j"$(makeopts_jobs)" \
		"$@"
}

# @FUNCTION: sanus_kernel_release
# @DESCRIPTION:
#   Echo the kernel release string, e.g. 6.12.0-sanusos.
sanus_kernel_release() {
	cd "${S}" || die
	"${S}"/scripts/setlocalversion --save-scmversion 2>/dev/null || true
	make -s ARCH="$(tc-arch-kernel)" kernelrelease
}

# @FUNCTION: sanus_kernel_install
# @DESCRIPTION:
#   Install the built kernel image, modules, and the pieces out-of-tree module
#   builds (NVIDIA, vhba, scx) need.
sanus_kernel_install() {
	debug-print-function "${FUNCNAME}" "$@"

	local release="$1"
	local arch; arch="$(tc-arch-kernel)"

	# Compressed image
	local image
	case "${arch}" in
		x86)   image="arch/x86/boot/bzImage" ;;
		arm64) image="arch/arm64/boot/Image.gz" ;;
		*)     die "unsupported kernel arch: ${arch}" ;;
	esac

	insinto /boot
	newins "${image}" "vmlinuz-${release}"
	insinto /boot
	newins "System.map" "System.map-${release}"
	insinto /boot
	newins ".config" "config-${release}"

	# Modules
	sanus_kernel_make INSTALL_MOD_PATH="${ED}" INSTALL_MOD_STRIP=1 modules_install

	# Header tree so DKMS/out-of-tree modules can build against this kernel.
	insinto "/usr/src/linux-${release}"
	doins -r include scripts tools/Makefile Module.symvers 2>/dev/null || true
	dodir "/lib/modules/${release}/build"
	dosym "../../../usr/src/linux-${release}" "/lib/modules/${release}/build"
}
