#!/usr/bin/env bash
# Generate a Gentoo package Manifest without a working Portage.
#
#   mkmanifest <package-dir> [distfile ...]
#
# Writes <package-dir>/Manifest containing one line per ebuild and per
# distfile, in the format Portage expects (all hashes hex-encoded):
#
#   EBUILD foo-1.0.ebuild 1234 BLAKE2B <hex> SHA512 <hex>
#   DIST   foo-1.0.tar.gz 5678 BLAKE2B <hex> SHA512 <hex>
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
			import hashlib, os, sys, time

			pkgdir, dists = sys.argv[1], sys.argv[2:]

			entries = []
			for name in sorted(os.listdir(pkgdir)):
			    if name.endswith(".ebuild"):
			        entries.append(("EBUILD", os.path.join(pkgdir, name), name))
			for d in dists:
			    entries.append(("DIST", d, os.path.basename(d)))

			def digest(path):
			    with open(path, "rb") as fh:
			        data = fh.read()
			    # Gentoo Manifests store every digest, including BLAKE2B, as
			    # hex; Portage compares against hexdigest().
			    blake = hashlib.blake2b(data, digest_size=64).hexdigest()
			    return len(data), blake, hashlib.sha512(data).hexdigest()

			# A distfile may still be settling (or another process may be
			# rewriting it); hash, write, then re-hash to prove the Manifest
			# matches what Portage will actually read.
			for attempt in range(1, 6):
			    records = [(kind, name, path, digest(path))
			               for kind, path, name in entries]
			    lines = [f"{kind} {name} {n} BLAKE2B {b} SHA512 {s}"
			             for kind, name, _path, (n, b, s) in records]
			    manifest = os.path.join(pkgdir, "Manifest")
			    with open(manifest, "w") as fh:
			        fh.write("\n".join(lines) + "\n")
			    stable = all(digest(path) == rec
			                 for _k, _n, path, rec in records)
			    if stable:
			        break
			    print(f"  manifest: distfile changed while hashing "
			          f"(attempt {attempt}); retrying", file=sys.stderr)
			    time.sleep(0.5)
			else:
			    print("  manifest: distfile kept changing; refusing to write "
			          "an inconsistent Manifest", file=sys.stderr)
			    sys.exit(1)
			print(f"  manifest: {manifest} ({len(entries)} entries)")
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
