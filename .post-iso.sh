#!/bin/bash
set -Eeuo pipefail
export WEBOS_ROOT=/sanusos
source /sanusos/scripts/lib/common.sh 2>/dev/null || true
cd /sanusos
OUT=/sanusos/build/verify.log
exec >"$OUT" 2>&1
echo "== verify $(date -u +'%Y-%m-%dT%H:%M:%SZ') =="
# Pick this release's ISO, never an older one that happens to sort first.
ISO="/sanusos/build/${WEBOS_ID:-webos}-${WEBOS_VERSION_FULL:-}-${WEBOS_ARCH:-amd64}.iso"
if [[ ! -f "$ISO" ]]; then
  ISO=$(ls -1t /sanusos/build/webos-*.iso 2>/dev/null | head -1 || true)
fi
if [[ -z "${ISO}" ]]; then echo "FAIL: no ISO found"; echo rc=1; exit 1; fi
echo "ISO: ${ISO} $(du -h "$ISO" | cut -f1)"
( cd "$(dirname "$ISO")" && sha256sum -c "$(basename "$ISO").sha256" ) && echo "checksum: OK" || echo "checksum: FAIL"

EXTRACT=/tmp/iso-extract
rm -rf "$EXTRACT"; mkdir -p "$EXTRACT"
MNT=/tmp/iso-mnt; mkdir -p "$MNT"
MOUNTED=0
if mount -o loop,ro "$ISO" "$MNT" 2>/dev/null; then
  MOUNTED=1
  echo "-- source: loop mount --"
  ls -la "$MNT" | head -20 || true
  find "$MNT/boot" -maxdepth 2 -type f 2>/dev/null | head -20 || true
  ls -lh "$MNT/live" 2>/dev/null || true
  grep -n 'WebOS\|root=live\|webos.squashfs\|rd.live' "$MNT/boot/grub/grub.cfg" 2>/dev/null | head -20 || true
  cat "$MNT/webos/version" 2>/dev/null || cat "$MNT/webos/version" 2>/dev/null || true
  cp -f "$MNT/live/webos.squashfs" "$EXTRACT/webos.squashfs" 2>/dev/null || true
else
  echo "-- source: xorriso extract (loop mount unavailable) --"
  xorriso -osirrox on -indev "$ISO" -extract / "$EXTRACT" 2>&1 | tail -20 || echo "xorriso extract failed"
  ls -la "$EXTRACT" | head -20 || true
  find "$EXTRACT/boot" -maxdepth 2 -type f 2>/dev/null | head -20 || true
  ls -lh "$EXTRACT/live" 2>/dev/null || true
  grep -n 'WebOS\|root=live\|webos.squashfs\|rd.live' "$EXTRACT/boot/grub/grub.cfg" 2>/dev/null | head -20 || true
  cat "$EXTRACT/webos/version" 2>/dev/null || cat "$EXTRACT/webos/version" 2>/dev/null || true
fi

SQ="${EXTRACT}/webos.squashfs"
[[ ! -f "$SQ" && -f "$MNT/live/webos.squashfs" ]] && SQ="$MNT/live/webos.squashfs"
if [[ -f "$SQ" ]]; then
  echo "-- squashfs info --"; unsquashfs -s "$SQ" 2>/dev/null | head -20 || true
  echo "-- key files in squashfs --"
  unsquashfs -ll "$SQ" 2>/dev/null | grep -E 'usr/bin/webos-installer$|usr/bin/Hyprland$|usr/bin/startplasma-wayland$|usr/bin/plasmashell$|usr/bin/waybar$|etc/os-release$|etc/webos-release$|etc/issue$|usr/local/bin/webos-live-session$|usr/share/webos/WEBOS-INFO.txt$|usr/share/webos/logo.svg$' | head -40 || true
  echo "-- webos info --"; unsquashfs -cat "$SQ" usr/share/webos/WEBOS-INFO.txt 2>/dev/null | head -6 || true
  echo "-- os-release --"; unsquashfs -cat "$SQ" etc/os-release 2>/dev/null | head -20 || true
  echo "-- issue head --"; unsquashfs -cat "$SQ" etc/issue 2>/dev/null | head -8 || true
fi
[[ $MOUNTED -eq 1 ]] && umount "$MNT" || true
echo "== verify done =="
echo rc=0
