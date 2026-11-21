#!/usr/bin/env bash
REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO"
notify(){ ./scripts/notify-user.sh "$1" "WebOS Build" >/dev/null 2>&1 || true; }
seen=/tmp/webos-issues-seen.txt
touch "$seen"
while true; do
  # ISO build completion/failure handled by step-watcher, but also catch here
  if grep -aq '^rc=0' build/iso-build.log 2>/dev/null && (ls build/webos-*.iso >/dev/null 2>&1 || ls build/webos-*.iso >/dev/null 2>&1); then
    if ! grep -q '^iso-done$' "$seen"; then echo 'iso-done' >> "$seen"; notify "ISO build finished successfully (rc=0). Verification in progress/done."; fi
    # don't exit immediately; verification may follow
  fi
  if grep -aq '^rc=[1-9]' build/iso-build.log 2>/dev/null; then
    if ! grep -q '^iso-fail$' "$seen"; then echo 'iso-fail' >> "$seen"; notify "Issue: ISO build failed. Check build/iso-build.log"; fi
  fi
  # scan for errors/warnings that may indicate trouble while running
  if [[ -f build/iso-build.log ]]; then
    tail -n 80 build/iso-build.log 2>/dev/null | tr '\r' '\n' | grep -Ei '(^fail |mksquashfs:.*error|xorriso.*FAILURE|grub-mkrescue: error|dracut.*(error|failed)|cp: cannot stat|No space left|I/O error)' | tail -n 3 | while read -r line; do
      key=$(printf '%s' "$line" | md5sum | awk '{print $1}')
      if ! grep -q "^$key$" "$seen"; then
        echo "$key" >> "$seen"
        notify "Issue detected: ${line:0:140}"
      fi
    done
  fi
  # squashfs process died unexpectedly? (if no mksquashfs, no rc, and log stale for long during compress phase)
  sleep 45
done
