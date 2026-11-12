#!/usr/bin/env bash
set -Eeuo pipefail
cd /home/brah/sanusos
INTERVAL=${STATUS_INTERVAL:-1800}
LOG=/home/brah/sanusos/build/status-updater.log
while true; do
  {
    echo "=== $(date -u +'%Y-%m-%dT%H:%M:%SZ') ==="
    if [[ -f build/desktop-fix.log ]]; then
      tr '\r' '\n' < build/desktop-fix.log | grep -E 'Jobs:|Emerging|Installing|Failed|rc=' | tail -5 || true
      grep -a '^rc=' build/desktop-fix.log 2>/dev/null || echo "desktop-fix: running"
    elif [[ -f build/rootfs-build.log ]]; then
      tr '\r' '\n' < build/rootfs-build.log | grep -E '==>|Jobs:|Emerging|Failed|rc=' | tail -5 || true
    fi
    if [[ -f build/iso-build.log ]]; then
      tr '\r' '\n' < build/iso-build.log | grep -E '==>|iso|squashfs|grub|xorriso|Failed|rc=' | tail -5 || true
    fi
    [[ -f build/sanus-1.0-Ashen-amd64.iso ]] && ls -lh build/sanus-1.0-Ashen-amd64.iso || true
  } > /tmp/sanus-status.txt 2>&1
  {
    echo
    echo "## Status update ($(date -u +'%Y-%m-%d %H:%M UTC'))"
    echo '```'
    cat /tmp/sanus-status.txt
    echo '```'
  } >> STATUS.md
  git add STATUS.md >/dev/null 2>&1 || true
  if ! git diff --cached --quiet 2>/dev/null; then
    git -c user.name='SanusOS Build' -c user.email='dev@sanusos.org' commit -q -m "status: automated update $(date -u +'%Y-%m-%dT%H:%MZ')" >/dev/null 2>&1 || true
    git push origin main >/dev/null 2>&1 || true
  fi
  if grep -aq '^rc=' build/iso-build.log 2>/dev/null || [[ -f build/sanus-1.0-Ashen-amd64.iso && -f build/.all-done ]]; then
    echo "done" >> "$LOG"; exit 0
  fi
  sleep "$INTERVAL"
done
