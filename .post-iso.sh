#!/bin/bash
set -Eeuo pipefail
export SANUS_ROOT=/sanusos
source /sanusos/scripts/lib/common.sh 2>/dev/null || true
cd /sanusos
OUT=/sanusos/build/verify.log
exec >"$OUT" 2>&1
echo "== verify $(date -u +'%Y-%m-%dT%H:%M:%SZ') =="
ISO=$(ls -1 /sanusos/build/webos-*.iso 2>/dev/null | head -1 || ls -1 /sanusos/build/sanus-*.iso 2>/dev/null | head -1 || true)
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
  grep -n 'WebOS\|root=live\|sanus.squashfs\|rd.live' "$MNT/boot/grub/grub.cfg" 2>/dev/null | head -20 || true
  cat "$MNT/sanus/version" 2>/dev/null || cat "$MNT/webos/version" 2>/dev/null || true
  cp -f "$MNT/live/sanus.squashfs" "$EXTRACT/sanus.squashfs" 2>/dev/null || true
else
  echo "-- source: xorriso extract (loop mount unavailable) --"
  xorriso -osirrox on -indev "$ISO" -extract / "$EXTRACT" 2>&1 | tail -20 || echo "xorriso extract failed"
  ls -la "$EXTRACT" | head -20 || true
  find "$EXTRACT/boot" -maxdepth 2 -type f 2>/dev/null | head -20 || true
  ls -lh "$EXTRACT/live" 2>/dev/null || true
  grep -n 'WebOS\|root=live\|sanus.squashfs\|rd.live' "$EXTRACT/boot/grub/grub.cfg" 2>/dev/null | head -20 || true
  cat "$EXTRACT/sanus/version" 2>/dev/null || cat "$EXTRACT/webos/version" 2>/dev/null || true
fi

SQ="${EXTRACT}/sanus.squashfs"
[[ ! -f "$SQ" && -f "$MNT/live/sanus.squashfs" ]] && SQ="$MNT/live/sanus.squashfs"
if [[ -f "$SQ" ]]; then
  echo "-- squashfs info --"; unsquashfs -s "$SQ" 2>/dev/null | head -20 || true
  echo "-- key files in squashfs --"
  unsquashfs -ll "$SQ" 2>/dev/null | grep -E 'usr/bin/sanus-installer$|usr/bin/Hyprland$|usr/bin/startplasma-wayland$|usr/bin/plasmashell$|usr/bin/waybar$|etc/os-release$|etc/webos-release$|etc/issue$|usr/local/bin/sanus-live-session$' | head -40 || true
  echo "-- os-release --"; unsquashfs -cat "$SQ" etc/os-release 2>/dev/null | head -20 || true
  echo "-- issue head --"; unsquashfs -cat "$SQ" etc/issue 2>/dev/null | head -8 || true
fi
[[ $MOUNTED -eq 1 ]] && umount "$MNT" || true
echo "== verify done =="
echo rc=0
