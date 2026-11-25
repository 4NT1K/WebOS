# WebOS kernel

`sys-kernel/webos-kernel` is a *dist-kernel* style ebuild: it builds the
upstream Linux sources with the WebOS patch series and config fragment, and
installs `vmlinuz-*-webos`, modules, and a dracut initramfs.

## Pieces

| File | Purpose |
|---|---|
| `patchset.conf` | Declarative list of upstream patches (BORE, fsync, ntsync, BBRv3, …) with pinned hashes. |
| `fetch-patches.sh` | Downloads and verifies the series; pins `auto` hashes on first run. |
| `webos-fragment.config` | `merge_config.sh` fragment applied over upstream `defconfig`. |
| `../overlay/sys-kernel/webos-kernel/` | The ebuild that does the build. |
| `../overlay/sys-kernel/webos-kernel-sources/` | Sources + patch application. |

## Why a fragment and not a full `.config`

A full `.config` is ~10 000 lines and rots the moment upstream renames a symbol.
A fragment is ~400 lines, reviewable, and survives `olddefconfig`. If a symbol
in the fragment no longer exists, `merge_config.sh` warns and `olddefconfig`
drops it — the build does not break.

## Why patches are fetched, not vendored

WebOS is a build system, not a patch dump. Patches come from the projects that
maintain them (firelzrd's BORE, the CachyOS kernel-patches tree, Frogging
Family) so that credit and license stay with them. `fetch-patches.sh` hashes
every patch; a rebuild either reproduces the exact kernel or fails.

```bash
# First run pins all the `auto` hashes into patchset.conf:
kernel/fetch-patches.sh

# Later, in CI, detect an upstream rewrite without downloading:
kernel/fetch-patches.sh --verify

# See what would be applied for a series:
kernel/fetch-patches.sh --series 6.12 --list
```

## Bumping the series

1. Edit `branding/version`: `WEBOS_KERNEL_SERIES=6.13`.
2. Update `kernel/patchset.conf` target-series column and URLs.
3. `kernel/fetch-patches.sh --series 6.13` to pin the new hashes.
4. Bump `sys-kernel/webos-kernel-sources` version in the overlay.
5. Rebuild: `sudo ./build.sh kernel`.

A stable point release **within** the series (for example 6.12 → 6.12.119)
does not change `WEBOS_KERNEL_SERIES`. Rename both ebuilds to the new `PV`,
keep `SRC_URI="${KERNEL_URI}"` so `kernel-2.eclass` fetches the base tarball
and incremental patch, refresh both `Manifest` files, and keep the
`/usr/src/linux-6.12` build-tree path stable for out-of-tree module builds.

## What is deliberately *not* enabled

* `CONFIG_MODULE_SIG` — modules are unsigned so DKMS/NVIDIA builds work.
* `CONFIG_DEBUG_INFO` — debuginfo costs gigabytes and buys a gamer nothing.
* Full LTO / `-O3` kernel builds — measurable build-time cost, negligible
  runtime benefit outside microbenchmarks.
* `CONFIG_HZ=250` (the upstream default) — 1000 Hz is better for input latency.
