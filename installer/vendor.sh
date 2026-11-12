#!/usr/bin/env bash
# Vendor the installer's Rust dependencies so the ebuild can build offline.
#
# Run this once (it needs the network) before `./build.sh fetch`, or let the
# fetch stage run it for you. The result — `vendor/` plus `.cargo/config.toml`
# — is what makes `cargo build --offline` work inside the build chroot.
set -Eeuo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "${HERE}"

if ! command -v cargo >/dev/null 2>&1; then
	printf 'vendor.sh: cargo not found — install Rust or skip the installer\n' >&2
	exit 1
fi

# A complete, reproducible lockfile is a precondition for --offline.
cargo generate-lockfile --quiet

rm -rf vendor
mkdir -p .cargo
cargo vendor --locked vendor > .cargo/config.toml

n="$(find vendor -mindepth 1 -maxdepth 1 -type d | wc -l)"
printf 'vendored %s crates into %s/vendor\n' "${n}" "${HERE}"
printf 'cargo config written to %s/.cargo/config.toml\n' "${HERE}"
