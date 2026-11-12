#!/usr/bin/env bash
# Generate a Gentoo package Manifest without a working Portage.
#
#   mkmanifest <package-dir> [distfile ...]
#
# Writes <package-dir>/Manifest containing one line per ebuild and per
# distfile, in the format Portage expects:
#
#   EBUILD foo-1.0.ebuild 1234 BLAKE2B <base64> SHA512 <hex>
#   DIST   foo-1.0.tar.gz 5678 BLAKE2B <base64> SHA512 <hex>
#
# This exists because the installer tarball is produced by the SanusOS build
# system at build time and therefore cannot be listed in the committed
# Manifest; the build regenerates it here.
#
# Sourced by the build scripts; also runnable on its own.

mkmanifest() {
	local pkgdir="$1"
	shift
	local -a dists=("$@")

	if [[ ! -d ${pkgdir} ]]; then
		printf 'mkmanifest: no such directory: %s\n' "${pkgdir}" >&2
		return 1
	fi

	# Prefer python3 (always present on a Gentoo build host).
	if command -v python3 >/dev/null 2>&1; then
		python3 - "$pkgdir" "${dists[@]}" <<-'PY'
			import base64, hashlib, os, sys

			pkgdir, dists = sys.argv[1], sys.argv[2:]

			entries = []
			for name in sorted(os.listdir(pkgdir)):
			    if name.endswith(".ebuild"):
			        entries.append(("EBUILD", os.path.join(pkgdir, name), name))
			for d in dists:
			    entries.append(("DIST", d, os.path.basename(d)))

			lines = []
			for kind, path, name in entries:
			    with open(path, "rb") as fh:
			        data = fh.read()
			    blake = base64.b64encode(
			        hashlib.blake2b(data, digest_size=64).digest()
			    ).decode()
			    sha = hashlib.sha512(data).hexdigest()
			    lines.append(f"{kind} {name} {len(data)} BLAKE2B {blake} SHA512 {sha}")

			with open(os.path.join(pkgdir, "Manifest"), "w") as fh:
			    fh.write("\n".join(lines) + "\n")
			print(f"  manifest: {os.path.join(pkgdir, 'Manifest')} ({len(entries)} entries)")
		PY
		return
	fi

	# Fall back to pkgdev, which does the same thing but needs Portage config.
	if command -v pkgdev >/dev/null 2>&1; then
		( cd "${pkgdir}/.." && pkgdev manifest --force "$(basename "${pkgdir}")" )
		return
	fi

	printf 'mkmanifest: need python3 or pkgdev\n' >&2
	return 1
}

if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
	set -Eeuo pipefail
	mkmanifest "$@"
fi
