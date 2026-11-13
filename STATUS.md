# WebOS build status

_Last update: 2026-11-13 22:14 UTC — verified, copied to USB_

## Status: VERIFIED (not published)

- ISO: `build/webos-1.0-Ashen-amd64.iso` (3.7G), sha256 `545234d900bf8df0…`
- Fixes: system ownership forced to root:root; installer no longer wipes machine-id and generates a guaranteed 32-char `/etc/machine-id` + dbus id
- E2E install: `INSTALL_RC=0`
- Installed target checks (manual): /, /etc, /usr root:root; 32-char machine-id/dbus-id present
- Ventoy USB updated and checksum-verified, unmounted
- GitHub release not updated (awaiting approval)
